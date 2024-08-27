#pragma rtGlobals=3		// Use modern global access method and strict wave access.

function OS_AveragingSuite_Chopup()

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
// NEEDS COMPLETING!

wave AverageStack0

wave Triggertimes_frame
// Sometimes a rouge trigger is present at the very beginning of recording (0s)
// the following checks for it and gets rid of it accordingly
Duplicate /o Triggertimes_frame, Triggertimes_frame_cleaned// copy to avoid overwriting anything
if (Triggertimes_frame[0] < OS_Parameters[%Ignore1stXseconds])
	DeletePoints 0,1, Triggertimes_frame_cleaned
endif

variable AverageStack_Chopup = 1 // every how many triggers to chop

variable ss
variable Triggermode = OS_Parameters[%Trigger_Mode]

variable nX = Dimsize(AverageStack0,0)
variable nY = Dimsize(AverageStack0,1)
variable nF = Dimsize(AverageStack0,2)

variable nSubStacks = Ceil(Triggermode / AverageStack_Chopup)
variable nF_Substacks = Ceil(nF/nSubStacks)
			
make /o/n=(nX * nSubStacks, nY, nF_SubStacks) AverageStack0_Chopped = NaN			
			
for (ss=0;ss<nSubStacks;ss+=1)
	variable SubStart = Triggertimes_frame_cleaned[ss*AverageStack_Chopup] - Triggertimes_frame_cleaned[0] 
	print SubStart
	string SubStackName = "AverageSubStack_"+Num2Str(ss)
	make /o/n=(nX,nY,nF_SubStacks) TempStack = AverageStack0[p][q][r+SubStart]
	AverageStack0_Chopped[ss*nX, (ss+1)*nX-1][][]=TempStack[p-(ss*nX)][q][r]
	duplicate /o TempStack  $SubStackName
endfor
killwaves TempStack, Triggertimes_frame_cleaned



end