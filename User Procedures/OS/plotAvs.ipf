#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#include "OS_AveragingSuite"

// flags from "OS_Parameters"
variable Display_averages = OS_Parameters[%Display_Stuff]
variable use_znorm = OS_Parameters[%Use_Znorm]
variable LineDuration = OS_Parameters[%LineDuration]
variable Triggermode = OS_Parameters[%Trigger_Mode]
variable Ignore1stXseconds = OS_Parameters[%Ignore1stXseconds]
variable IgnoreLastXseconds = OS_Parameters[%IgnoreLastXseconds]
variable Ignore1stXTriggers = OS_Parameters[Skip_First_Triggers]
variable IgnoreLastXTriggers = OS_Parameters[Skip_Last_Triggers]
variable AverageStack_make = OS_Parameters[%AverageStack_make]
variable X_cut = OS_Parameters[%LightArtifact_cut]
variable nStimSegments =  OS_Parameters[%Stim_Marker]
variable nTrace_Max_full =  OS_Parameters[%PlotOnlyMeans]
variable nTrace_Max_trace =  OS_Parameters[%PlotOnlyHeatMap]
variable nLines_Lumped = OS_Parameters[%nLines_lumped]

wavexists($"OS_Parameters")

//////////////////////////////////////////////////////////////
// Unfinished, broken, a bit crap -->Solve in Python instead
//////////////////////////////////////////////////////////////
 

function plotAvs(AveWave)
	wave AveWave
	wave Triggertimes
	variable nStimSegments, Display_averages, use_znorm, LineDuration, Triggermode, Ignore1stXseconds
	variable IgnoreLastXseconds, AverageStack_make, X_cut, nTrace_Max_full, nTrace_Max_trace, nLines_Lumped
	variable Ignore1stXTriggers, IgnoreLastXTriggers
	variable SnippetDuration = Triggertimes[TriggerMode+Ignore1stXTriggers]-Triggertimes[0+Ignore1stXTriggers] // in seconds
	
	// 1 // check for Parameter Table
	if (waveexists($"OS_Parameters")==0)
		print "Warning: OS_Parameters wave not yet generated - doing that now..."
		OS_ParameterTable()
		DoUpdate
	endif
	wave OS_Parameters
	// 2 //  check for Detrended Data stack
	variable Channel = OS_Parameters[%Data_Channel]
	if (waveexists($"wDataCh"+Num2Str(Channel)+"_detrended")==0)
		print "Warning: wDataCh"+Num2Str(Channel)+"_detrended wave not yet generated - doing that now..."
		OS_DetrendStack()
	endif
	// 3 //  check for ROI_Mask
	if (waveexists($"ROIs")==0)
		print "Warning: ROIs wave not yet generated - doing that now (using correlation algorithm)..."
		OS_AutoRoiByCorr()
		DoUpdate
	endif
	// 4 //  check if Traces and Triggers are there
	if (waveexists($"Triggertimes")==0)
		print "Warning: Traces and Trigger waves not yet generated - doing that now..."
		OS_TracesAndTriggers()
		DoUpdate
	endif

	
	// data handling
	string input_name = "wDataCh"+Num2Str(Channel)+"_detrended"
	string traces_name = "Traces"+Num2Str(Channel)+"_raw"
	if (use_znorm==1)
		traces_name = "Traces"+Num2Str(Channel)+"_znorm"
	endif
	string tracetimes_name = "Tracetimes"+Num2Str(Channel)
	duplicate /o $input_name InputStack
	duplicate /o $traces_name InputTraces
	duplicate /o $tracetimes_name InputTraceTimes

	variable nF = DimSize(InputTraces,0)
	variable nRois = DimSize(InputTraces,1)
	variable nX = DimSize(InputStack,0)
	variable nY = DimSize(InputStack,1)

	string output_name1 = "Snippets"+Num2Str(Channel)
	string output_name2 = "Averages"+Num2Str(Channel)
	string output_name3 = "AverageStack"+Num2Str(Channel)
	string output_name4 = "SnippetsTimes"+Num2Str(Channel) // andre addition 2016 04 13


	// Stolen from OS_BasicAveraging and passed AveWave instead of Averages0:)))))))
	display /k=1
	make /o/n=(1) M_Colors
	Colortab2Wave Rainbow256
	
	if (nStimSegments>0) // if there is a resgular stimulus to be plotted
		make /o/n=(nStimSegments) StimMarker = 1
		variable counter
		for (counter=1;counter<nStimSegments;counter+=2)
			StimMarker[counter]=0
		endfor
		Setscale x,0,SnippetDuration,"s" StimMarker

		Appendtograph /l=StimY StimMarker
		ModifyGraph fSize=8,noLabel(StimY)=2,axThick(StimY)=0,lblPos(StimY)=47;DelayUpdate
		ModifyGraph axisEnab(StimY)={0.05,1},freePos(StimY)={0,kwFraction}
		ModifyGraph mode=5,hbFill=2
		ModifyGraph rgb(StimMarker)=(56576,56576,56576)
		if (nROIs>nTrace_Max_trace)
			ModifyGraph hbFill=0 // if heatmap, then just plot the skeleton
		endif
	endif

	
	if (nROIs>nTrace_Max_trace)
		print "more than", nTrace_Max_trace, "ROIs. Just plotting heatmap of means" 
	elseif (nROIs>nTrace_Max_full)
		print "more than", nTrace_Max_full, "ROIs. Skipping individual repeats in the plot" 
	endif
	
	variable tt,rr,ll,pp,xx,yy,ff

	
	// Get Snippet Duration, nLoops etc..
	variable nTriggers
//	variable Ignore1stXTriggers = 0
//	variable IgnoreLastXTriggers = 0
	variable last_data_time_allowed = InputTraceTimes[nF-1][0]-IgnoreLastXseconds
	
	for (tt=0;tt<Dimsize(triggertimes,0);tt+=1)
		if (NumType(Triggertimes[tt])==0)
			if (Ignore1stXseconds>Triggertimes[tt])
				Ignore1stXTriggers+=1
			endif
			if (Triggertimes[tt]<=last_data_time_allowed)
				nTriggers+=1
			endif
		else
			break
		endif
	endfor
	if (Ignore1stXTriggers>0)
		print "ignoring first", Ignore1stXTriggers, "Triggers"
	endif
	variable nLoops = floor((nTriggers-Ignore1stXTriggers-IgnoreLastXTriggers) / TriggerMode)

	// Snipperting and Averaging

	make /o/n=(SnippetDuration * 1/(LineDuration*nLines_Lumped),nLoops,nRois) OutputTraceSnippets = 0 // in line precision
	make /o/n=(SnippetDuration * 1/(LineDuration*nLines_Lumped),nLoops,nRois) OutputTimeSnippets = 0 // Andre 2016 04 13
	make /o/n=(SnippetDuration * 1/(LineDuration*nLines_Lumped),nRois) OutputTraceAverages = 0 // in line precision
	// export handling
	duplicate /o OutputTraceSnippets $output_name1
	duplicate /o OutputTraceAverages $output_name2
	duplicate /o OutputTimeSnippets $output_name4

	if (nROIs<=nTrace_Max_trace)
		for (rr=0;rr<nRois;rr+=1)
			string YAxisName = "YAxis_Roi"+Num2Str(rr)
			string tracename
			
			if (nROIs<=nTrace_Max_full)
				for (ll=0;ll<nLoops;ll+=1)
					tracename = output_name1+"#"+Num2Str(rr*nLoops+ll)
					if (ll==0 && rr==0)
						tracename = output_name1
					endif
					Appendtograph /l=$YAxisName $output_name1[][ll][rr]
					ModifyGraph rgb($tracename)=(52224,52224,52224)
				endfor	
			endif
			tracename = output_name2+"#"+Num2Str(rr)
			if (rr==0)
				tracename = output_name2
			endif
			Appendtograph /l=$YAxisName $output_name2[][rr]
			variable colorposition = 255 * (rr+1)/nRois
			ModifyGraph rgb($tracename)=(M_Colors[colorposition][0],M_Colors[colorposition][1],M_Colors[colorposition][2])
			ModifyGraph lsize($tracename)=1.5
					
			variable plotfrom = (1-((rr+1)/nRois))*0.8+0.2
			variable plotto = (1-(rr/nRois))*0.8+0.2
			
			ModifyGraph fSize($YAxisName)=8,axisEnab($YAxisName)={plotfrom,plotto};DelayUpdate
			ModifyGraph freePos($YAxisName)={0,kwFraction};DelayUpdate
			Label $YAxisName "\\Z10"+Num2Str(rr)
			ModifyGraph noLabel($YAxisName)=1,axThick($YAxisName)=0;DelayUpdate
			ModifyGraph lblRot($YAxisName)=-90
		endfor
	else
		Appendimage /l=HeatMapY $output_name2
		ModifyGraph fSize=8,lblPos(HeatMapY)=47,axisEnab(HeatMapY)={0.05,1};DelayUpdate
		ModifyGraph freePos(HeatMapY)={0,kwFraction};DelayUpdate
		Label HeatMapY "\\Z10ROI"
	endif
	
	ModifyGraph fSize(bottom)=8,axisEnab(bottom)={0.05,1};DelayUpdate
	Label bottom "\\Z10Time (\U)"
end