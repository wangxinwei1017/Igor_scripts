#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "OS_ParameterTable"
#include "OS_DetrendStack"
#include "OS_ManualROI"
#include "OS_AutoRoiByCorr"
#include "OS_TracesAndTriggers"
#include "OS_BasicAveraging"
#include "OS_hdf5Export"
#include "OS_LaunchCellLab"
#include "OS_STRFs"
#include "OS_EventFinder"
#include "OS_hdf5Import"
#include "OS_LineScanFormat"
#include "OS_LED_Noise"
#include "OS_Clustering"
#include "OS_KernelfromROI" 
#include "OS_Bars"
#include "OS_Register"  // Takeshi's
#include "OS_AutoROIs_SD" // Takeshi's
#include "OS_LoadScanImage" // ScanImageLoader - currently not included as button

//----------------------------------------------------------------------------------------------------------------------
Menu "ScanM", dynamic
	"-"
	" Open OS GUI",	/Q, 	OS_GUI()
	"-"	
End
//----------------------------------------------------------------------------------------------------------------------


function OS_GUI()
	NewPanel /N=OfficialScripts /k=1 /W=(500,100,750,660)
	ShowTools/A
	SetDrawLayer UserBack

	SetDrawEnv fstyle= 1
	DrawText 24,36,"(Step 0: Optional)"
	SetDrawEnv fstyle= 1
	DrawText 24,36+54,"Step 1: Parameter Table"
	SetDrawEnv fstyle= 1
	DrawText 24,90+54,"Step 2: Pre-formatting"
	SetDrawEnv fstyle= 1
	DrawText 24,149+54,"Step 3: ROI placement"
	SetDrawEnv fstyle= 1
	DrawText 24,272+54,"Step 4: Extract Traces and Triggers"
	SetDrawEnv fstyle= 1
	DrawText 24,334+54,"Step 5a: Further optional processes"
	SetDrawEnv fstyle= 1	
	DrawText 24,454+54,"Step 6: Database Export/Import (hdf5)"
	Button step0a,pos={60,39},size={60,26},proc=OS_GUI_Buttonpress,title="Linescan"
	Button step0b,pos={60+70,39},size={60,26},proc=OS_GUI_Buttonpress,title="Register"
	Button step0c,pos={78+122,39},size={25,26},proc=OS_GUI_Buttonpress,title="Do"	
	Button step1a,pos={60,39+54},size={107,26},proc=OS_GUI_Buttonpress,title="Make / Show"
	Button step1b,pos={192,39+54},size={34,26},proc=OS_GUI_Buttonpress,title="Kill"	
	Button step2a,pos={60,94+54},size={60,26},proc=OS_GUI_Buttonpress,title="Standard"
	Button step2b,pos={130,94+54},size={53,26},proc=OS_GUI_Buttonpress,title="Minimal"
	Button step2c,pos={191,94+54},size={33,26},proc=OS_GUI_Buttonpress,title="Save"
	Button step3a1,pos={60,155+54},size={53,20},proc=OS_GUI_Buttonpress,title="Manual"
	Button step3a2,pos={130,155+54},size={43,20},proc=OS_GUI_Buttonpress,title="Apply"
	Button step3a3,pos={181,155+54},size={43,20},proc=OS_GUI_Buttonpress,title="Pixels"
	Button step3a4,pos={60,179+54},size={165,20},proc=OS_GUI_Buttonpress,title="Use existing SARFIA Mask"	
	Button step3b,pos={60,203+54},size={71,20},proc=OS_GUI_Buttonpress,title="Auto Corr"
	Button step3c,pos={154,203+54},size={71,20},proc=OS_GUI_Buttonpress,title="Auto SD"
	Button step3d,pos={60,228+54},size={165,20},proc=OS_GUI_Buttonpress,title="Autom. CellLab"
	Button step4,pos={60,278+54},size={165,26},proc=OS_GUI_Buttonpress,title="Traces and Triggers"
	Button step5a,pos={60,341+54},size={43,26},proc=OS_GUI_Buttonpress,title="Ave"
	Button step5b,pos={110,341+54},size={53,26},proc=OS_GUI_Buttonpress,title="Events"			
	Button step5c,pos={170,341+54},size={54,26},proc=OS_GUI_Buttonpress,title="Kernels"	
	Button step5d,pos={60,371+54},size={53,26},proc=OS_GUI_Buttonpress,title=" Cluster "			
	Button step5e,pos={120,371+54},size={43,26},proc=OS_GUI_Buttonpress,title=" ROI-K"	
	Button step5f,pos={170,371+54},size={54,26},proc=OS_GUI_Buttonpress,title=" K-Map "	

	Button step5g,pos={60,401+54},size={71,26},proc=OS_GUI_Buttonpress,title=" Bars "			
	Button step5h,pos={154,401+54},size={71,26},proc=OS_GUI_Buttonpress,title=" STRFs "
	
	Button step6a,pos={60,462+54},size={71,26},proc=OS_GUI_Buttonpress,title="Export"
	Button step6b,pos={154,462+54},size={71,26},proc=OS_GUI_Buttonpress,title="Import"	
	
	HideTools/A
end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function OS_GUI_Buttonpress(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			strswitch (ba.ctrlName)
				case "step0a":
					OS_LineScanFormat()
					break
				case "step0b":
					OS_registration_rigiddrift()
					break
				case "step0c":
					OS_registration_recover()
					break
				case "step1a":
					OS_ParameterTable()
					break
				case "step1b":
					OS_ParameterTable_Kill()
					break					
				case "step2a":
					OS_DetrendStack()
					break
				case "step2b":
					OS_PreFormat_minimal()
					break		
				case "step2c":
					OS_SaveRawAsTiff()
					break									
				case "step3a1":
					OS_CallManualROI()
					break
				case "step3a2":
					OS_ApplyManualRoi()
					break	
				case "step3a3":
					OS_monoPixelApply()
					break						
				case "step3a4":
					OS_CloneSarfiaRoi()
					break																		
				case "step3b":
					OS_AutoRoiByCorr()
					break
				case "step3c":
					OS_autoROIs_SD()
					break
				case "step3d":
					OS_LaunchCellLab()
					break
				case "step4":
					OS_TracesAndTriggers()
					break					
				case "step5a":
					OS_BasicAveraging()
					break
				case "step5b":
					OS_EventFinder()
					break					
				case "step5c":
					OS_LED_Noise()
					break
				case "step5d":
					OS_Clustering()
					break
				case "step5e":
					OS_KernelfromROI()
					break
				case "step5f":
					OS_IPLKernels()
					break	
				case "step5g":
					OS_Bars()
					break		
				case "step5h":
					OS_STRFs()
					break																					
				case "step6a":
					OS_hdf5Export()
					break										
				case "step6b":
					OS_hdf5Import("")
					break
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
