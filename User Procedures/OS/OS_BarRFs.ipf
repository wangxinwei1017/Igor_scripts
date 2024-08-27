#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


function OS_BarRFs()

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




// flags from "OS_Parameters"
variable Display_averages = OS_Parameters[%Display_Stuff]
variable use_znorm = OS_Parameters[%Use_Znorm]
variable nConditions = OS_Parameters[%Trigger_Mode] 

// compute bar specific things
variable nBars = nConditions / 2 // /2 becasue vert & horiz

// data handling
string traces_name = "Traces"+Num2Str(Channel)+"_raw"
if (use_znorm==1)
	traces_name = "Traces"+Num2Str(Channel)+"_znorm"
endif
duplicate /o $traces_name InputTraces

wave Triggertimes_Frame, Triggertimes, ROIs
variable nFrames = DimSize(InputTraces,0)
variable nROIs = DimSize(InputTraces,1)
variable nTriggers = Dimsize(Triggertimes,0)
variable nTrials= floor(nTriggers/ nConditions)



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

variable rr,cc,tt,ii

make/o/n=(nTriggers-1) SnippetDurations = Triggertimes_Frame[p+1]-Triggertimes_Frame[p]
wavestats/q SnippetDurations
variable SnippetDuration = round(V_avg) // some snippets do not have the same length so we take the average duration
killwaves SnippetDurations

//// Re-Snippeting into individual bar responses //// 
make/o/n=(SnippetDuration, nConditions, nTrials, nROIs) Bar_Individual = 0
make/o/n=(SnippetDuration, nConditions, nROIs) Bar_Averages = 0 
for (rr=0;rr<nRois;rr+=1)
	for (tt=0; tt<nTrials; tt+=1)
		for (cc=0; cc<nConditions; cc+=1)		
		make/o/n=(SnippetDuration) CurrentWave = InputTraces[p+Triggertimes_Frame[nConditions*tt + cc]][rr]
		Bar_Individual[][cc][tt][rr] = CurrentWave[p]
		Bar_Averages[][cc][rr]+= CurrentWave[p]/nTrials
		endfor
	endfor
endfor
killwaves CurrentWave


////Get AUC of snippets /////

variable response_start = 0.2 // i.e. 20% into the step-cycle duration
variable response_end = 0.6 // i.e. 60%

make/o/n=(nConditions,nROIs) Bar_Responses = nan
for (rr=0;rr<nROIs;rr+=1)
	for(cc=0;cc<nConditions;cc+=1)
		make/o/n=(SnippetDuration) CurrentWave = Bar_Averages[p][cc][rr]
		variable baseline = (currentwave[0]+currentwave[SnippetDuration-1]+currentwave[SnippetDuration-2])/3 // baseline defined as 1st entry + last 2
		variable response= mean(currentwave,(SnippetDuration*response_start)-1,(SnippetDuration*response_end)-1) // 
		Bar_Responses[cc][rr] =-(response-baseline) // inverted, as cones are OFF
		Bar_Averages[][cc][rr]=CurrentWave[p]-baseline // baseline update the Averages
	endfor
endfor
make /o/n=(nBars,nRois) Bar_Responses_vertical = Bar_Responses[(nBars-1)-p][q]
make /o/n=(nBars,nRois) Bar_Responses_horizontal = Bar_Responses[((2*nBars)-1)-p][q]

// make fake stimulus pictures to average RF from

make /o/n=(nBars,nBars,nConditions) Stim_lookup = 0 

variable bb
for(bb=0;bb<nBars;bb+=1) 
	Stim_Lookup[nBars-bb-1][][bb]=1 // vertical
	Stim_Lookup[][nBars-bb-1][bb+nBars]=1 // Horizontal
endfor	
	
	

// compute "RFs"

make /o/n=(nBars,nBars,nROIs) BarRFs_horiz = 0
make /o/n=(nBars,nBars,nROIs) BarRFs_vert = 0

make /o/n=(nBars,nBars,nROIs) BarRFs_combined = 0
make /o/n=(nBars,nBars) BarRF_population = 0

for (rr=0;rr<nROIs;rr+=1)
	for (bb=0;bb<nBars;bb+=1)
	
		BarRFs_vert[][][rr]+=Stim_lookup[p][q][bb] * Bar_Responses[bb][rr]
		BarRFs_horiz[][][rr]+=Stim_lookup[p][q][bb+nBars] * Bar_Responses[bb+nBars][rr]
	
	endfor
	BarRFs_combined[][][rr]=BarRFs_vert[p][q][rr] * BarRFs_horiz[p][q][rr]
	BarRF_population[][]+=BarRFs_combined[p][q][rr]/nROIs
endfor





// display

if (Display_averages==1)
	
	variable Profile_YScale = 5
	make /o/n=(nBars) ProfilePlot = x

	for (rr=0;rr<nROIs;rr+=1)
	
		string RF_Name = "BarRF_ROI"+Num2Str(rr)
		make /o/n=(nBars,nBars) NewRF = BarRFs_combined[p][q][rr]
		ImageStats/Q NewRF
		variable RF_MaxValue = V_Max
		duplicate /o NewRF $RF_Name
		
		display /k=1
		ModifyGraph width=283.465,height={Aspect,1.25}
		Appendimage $RF_Name 
		ModifyImage $RF_Name ctab= {-RF_MaxValue,RF_MaxValue,BlueBlackRed,1}
		
		ModifyGraph axisEnab(left)={0.25,0.75};DelayUpdate
		ModifyGraph axisEnab(bottom)={0.05,0.7}
		ModifyGraph noLabel(bottom)=2
		•SetAxis left nBars-0.5,-0.5
		•SetAxis bottom -0.5,nBars-0.5
				
		Appendtograph /l=VertTuningY  Bar_Responses_vertical[][rr]
		ModifyGraph axisEnab(VertTuningY)={0.80,1};DelayUpdate
		ModifyGraph freePos(VertTuningY)={0,kwFraction};DelayUpdate
		SetAxis VertTuningY 0,Profile_YScale
		
		
		Appendtograph /b=HorizTuningX ProfilePlot vs Bar_Responses_horizontal[][rr]
		ModifyGraph axisEnab(HorizTuningX)={0.75,1};DelayUpdate
		ModifyGraph freePos(HorizTuningX)={0.22,kwFraction};DelayUpdate
		SetAxis HorizTuningX 0,Profile_YScale
		ModifyGraph axThick(HorizTuningX)=0, noLabel(HorizTuningX)=2
		
		//ModifyGraph zero(VertTuningY)=1,zero(VertTuningX)=1
		
		ModifyGraph mode=3
		ModifyGraph fSize=8
		ModifyGraph mrkThick=2,marker(Bar_Responses_vertical)=10
		ModifyGraph marker(ProfilePlot)=9,mrkThick(ProfilePlot)=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph mirror=0
	
		// add the traces
		make /o/n=(1) M_Colors
		Colortab2Wave Rainbow256
		
		wave Averages0
		wave Snippets0
		variable nRepeats = Dimsize(Snippets0,1)
		variable ss
		for (ss=0;ss<nRepeats;ss+=1)
			string tracename = "Snippets0#"+Num2Str(ss)
			if (ss==0)
				tracename = "Snippets0"
			endif
			Appendtograph /l=TraceY /b=TraceX Snippets0[][ss][rr]
			ModifyGraph rgb($tracename)=(52224,52224,52224)
		endfor
		Appendtograph /l=TraceY /b=TraceX Averages0[][rr]
		variable colorposition = 255 * (rr+1)/nRois
		ModifyGraph rgb(Averages0)=(M_Colors[colorposition][0],M_Colors[colorposition][1],M_Colors[colorposition][2])
		ModifyGraph lsize(Averages0)=1.5
		
		
		ModifyGraph fSize=8,noLabel(TraceY)=2,noLabel(TraceX)=2,axThick(TraceY)=0;DelayUpdate
		ModifyGraph axThick(TraceX)=0,axisEnab(TraceY)={0.05,0.2};DelayUpdate
		ModifyGraph axisEnab(TraceX)={0.05,1};DelayUpdate
		ModifyGraph freePos(TraceY)={0,kwFraction},freePos(TraceX)={0,kwFraction}
		ModifyGraph noLabel(TraceX)=0;DelayUpdate
		ModifyGraph axThick(bottom)=0,axThick(TraceX)=1;DelayUpdate
		ModifyGraph lblPos(TraceX)=47
	
	
	endfor
	killwaves NewRF

	
	// population RF
	display /k=1 
	Appendimage BarRF_population
	ImageStats/Q BarRF_population
	RF_MaxValue = V_Max
	ModifyGraph width=283.465,height={Aspect,1}
	ModifyImage BarRF_population ctab= {-RF_MaxValue,RF_MaxValue,BlueBlackRed,1}	
	ModifyGraph fSize=8,axisEnab(left)={0.05,1},axisEnab(bottom)={0.05,1};DelayUpdate
	Label left "\\Z10Bar position (y)";DelayUpdate
	Label bottom "\\Z10Bar position (x)"
	SetAxis left nBars-0.5,-0.5
	
endif

end


