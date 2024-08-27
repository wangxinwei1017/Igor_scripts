#pragma rtGlobals=1		// Use modern global access method.
#include <ProcedureBrowser>
#include "ImgAnalCP"
#include "NaNBust"
#include "LoadScanImage"
#include "OneClickSmooth"
#include "AnalLS"
#include "IPLPosCP"
#include "ResultsByCoef"
#include "PopWaveBrowser3"
#include "ExpDataBase2"
#include "ExpDB2_Extraction"
#include "RGBmerge"
#include "DeltaFByF0Tools"
#include "RotateGUI"
#include "Movies"
#include "HiCluCP"
#include "AutoRegistration"
#include "Crop"
#include "SubtractBleach"
#include "MultiROIBeams"
#include "EventDetection_MT"
#include "DistanceTransform"
#include "LoadOMEtif"



Menu "SARFIA"

"About SARFIA", /Q,  AboutSARFIA();
"Image Analysis /S0", /Q, ImgAnalCP();
"Get IPL Position /S1", /Q, IPLPosCP();
"Pop Browser/S9",/Q,PoPWaveBrowser();
"Add to Database /S8",/Q,EDB2_CP();
"-"
"Quick Registration", /Q, QuickReg();
"AutoRegistration",/Q,AutoRegistration();
"Filter", /Q, OCS();
"Load Movie", /Q, LM1();
"MultiROI Beams", /Q, MultiROIBeams_prompt();
"Make a movie",/Q,Pop2MovieFromMenu();
"Clear ROI marquee /S2", /Q, ClearROIMarquee();
"Merry-Go-Round",/Q,RotateGUI();
"Analyse Linescan", /Q, CallAnalLS();
"Hierarchical Clustering",/Q,ClusteringCP();
"Bleach Subtraction",/Q, SubtractBleach_Auto();
"-"
Submenu "Image Resizing"
	"150", /Q, SizeImage(150);
	"300", /Q,  SizeImage(300);
	"600", /Q,  SizeImage(600);
	"No Axes",/Q, ModifyGraph noLabel=2,axThick=0,standoff=0, margin=-1;DelayUpdate;
	"Crop XY", /q, CropXYFromWindow();
	"Crop Z", /Q, CropZFromWindow();
end
"Load OME tif Movie/S5",/Q,LoadOMEtifMenu();


End

Function AboutSARFIA()

	String Version = "SARFIA\rVersion: 1.07\rBuild: Jan/11/2016"

	DoAlert 0, version

end


Function LM1()

string mname = LoadMovie()
variable zdim

if (stringmatch(mname, "-1"))
	return -1
endif

applyheaderinfo($mname)

Prompt zdim, "Enter Time Interval (ms)"
DoPrompt "Time Interval", zdim

setscale /P z, 0, zdim/1000,"s",$mname

end