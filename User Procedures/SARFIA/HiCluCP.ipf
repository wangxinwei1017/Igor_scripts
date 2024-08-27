#pragma rtGlobals=1		// Use modern global access method.
#include "HClu"
#include "REsultsByCoef"


Function AutoCluster(PopWave, Options)

	Wave PopWave
	Variable Options //0=Euclidean, 1=Chebyshev, 2=Hamming/Bin, 3=Binning, 4=normalised Euclidean, 5=Pearson
					//6=Manhattan
	
	Wave Normalised=NormalizeTraces(PopWave,1)
	
	Wave DistanceMatrix=PopDistances(Normalised, Options)
	
	Wave DM2C=DistanceMatrix2Column(DistanceMatrix,index=1)
	
	Wave SortedDM=SortByFirst(DM2C,0)
	
//	Display /k=1 SortedDM[][0]
	
	
End

///////////////////////////////////////


Function ClusteringCP()

	String PopWaveName="", OptionStr, Select="", CutoffStr
	String CatName, WvName
	Variable Normalise=0, Option, Cutoff
	Variable MinDist, MaxDist, nClusters, ii, jj, nItems, DisplaySingles=0
	
	DFREF SaveDFR=GetDataFolderDFR(), WF
	
	if(DataFOlderExists("root:Clustering"))
		WF=root:Clustering
	else
		NewDataFolder root:Clustering
		WF=root:Clustering
	endif


	OptionStr="Pearson;Euclidean;Normalised Euclidean;Chebyshev;Hamming;Binned Data;Manhattan"

	Prompt PopWaveName,"Which DataSet to Analyse?",popUp,WaveList("*",";","DIMS:2")
	Prompt Select, "Choose Metric",popUp, OptionStr
	Prompt Normalise, "Normalise Data (0/1)?"
	Prompt DisplaySingles, "Display clusters with a single trace (0/1)?"

	DoPrompt "Hierarchical clustering", PopWaveName, Select, normalise, DisplaySingles
	
	if(v_flag)
		SetDataFolder SaveDFR
		return -1
	endif


	StrSwitch (Select)
		Case "Euclidean":
			Option=0
		Break
		
		Case "Chebyshev":
			OPtion=1
		Break
		
		Case "Hamming":
			Option=2
		Break
		
		Case "Binned Data":
			Option=3
		Break
		
		Case "Normalised Euclidean":
			Option=4
		Break
		
		Case "Pearson":
			Option=5
		Break	
		
		Case "Manhattan":
			Option=6
		Break
		
		
	EndSwitch
	
	SetDataFolder WF
	
	Wave PopWave=SaveDFR:$PopWaveName
	
	if(Normalise==0)
		
		Wave Normalised=PopWave
		
	Else
	
		Wave Normalised=NormalizeTraces(PopWave,1)
	
	Endif
	
	Wave DistanceMatrix=PopDistances(Normalised, Option)
	
	Wave DM2C=DistanceMatrix2Column(DistanceMatrix,index=1)
	
	Wave SortedDM=SortByFirst(DM2C,0)
	
	String GraphHisto, GraphMatrix

	ImageStats /m=1/g={0,DimSize(SortedDM,0)-1,0,0} SortedDM
	MinDist=v_min
	MaxDist=v_max
	CutOff=30

	Display/k=1/w=(20,20,420,220) SortedDM[][0]
	GraphHisto=S_name
	ModifyGraph swapXY=1
	Label left, "Pairs"
	Label bottom, "Distance"
	Display/k=1/w=(60,300,360,600);AppendImage DistanceMatrix
	GraphMatrix=S_Name
	DoUpDate
	SizeImage(300)
	DoUpDate
	
	
	Variable wm = WaveMax(DistanceMatrix)
	CutOff = wm/3

	sPrintf CutoffStr, "Cutoff to merge clusters? Maximum value = %f",wm
	

	Prompt CutOff, CutoffStr
	DoPrompt "Cutoff", Cutoff

	
	
	if(v_flag)		//user canceled
		KillWindow $GraphHisto
		KillWindow $GraphMatrix
		SetDataFolder SaveDFR
		return -1
	endif
	
	String ReorganisedStr=NameOfWave(PopWave)+"_mod"
	
	

	Wave Clusters=HiClu(SortedDM,cutoff)
	
	nClusters=WaveMax(Clusters)+1
	
	
	For(ii=0;ii<nClusters;ii+=1)
		Wave Results=PopByCat(Normalised,Clusters,ii)
		
		if(ii==0)
			duplicate/o Results, $ReorganisedStr
			Wave PWMod=$ReorganisedStr
		else
			Concatenate {Results}, PWMod
		endif
	
		CatName="Category"+Num2Str(ii)
		
		Duplicate/o Results $CatName
		Wave LatestCat=$CatName
		
		PopStats2(LatestCat,CatName)
		
		nItems=DimSize(LatestCat,1)
		
		
		
		if(nItems<2 && DisplaySingles > 0)
			Display/k=1;
			WvName=CatName+"_Avg"
		
			AppendToGraph $WvName
			ModifyGraph lsize($WvName)=3,rgb($WvName)=(0,0,0)
			
		elseif(nItems<2 && DisplaySingles <= 0)
			//do nothing
			
		Else
			Display/k=1;
			For(jj=0;jj<nItems;jj+=1)
			
				AppendToGraph LatestCat[][jj]
			
			EndFor
		
		WvName=CatName+"_Avg"
		
		AppendToGraph $WvName
		ModifyGraph lsize($WvName)=3,rgb($WvName)=(0,0,0)
		
		Endif
		
		
	
	EndFor
	
	Deletepoints/m=1 0,1,PWMod
	
	Edit/k=1 Clusters
	KillWaves/z results
	
	SetDataFolder SaveDFR
End




///////////////////////////

Static Function PopStats2(PopWave,BaseName)
	Wave PopWave
	String BaseName
	String name
	Variable ii, numTraces, numPoints
	numTraces=Dimsize(PopWave,1)
	numPoints=DimSize(PopWave,0)
	
	
	
	Duplicate /o/free PopWave, W_PopAvg, W_PopSD, W_PopSEM
	Redimension /n=(-1) W_PopAvg, W_PopSD, W_PopSEM
	W_PopAvg = 0
	W_PopSD = 0
	
	if(numtraces<2)
		W_PopAvg=PopWave
	else
	
	
	
		For(ii=0;ii<numTraces;ii+=1)
		
			W_PopAvg+=PopWave[p][ii]/numTraces
		
		EndFor
		
		For(ii=0;ii<numTraces;ii+=1)
		
			MultiThread W_PopSD[]+=(PopWave[p][ii]-W_PopAvg[p]) ^2
			
		
		EndFor
		
		MultiThread W_PopSD=sqrt(W_PopSD*(1/(NumTraces-1)))
		MultiThread W_PopSEM=W_PopSD/Sqrt(NumTraces)
	
	Endif
	
	name=baseName+"_Avg"
	Duplicate/o W_PopAvg $name
	 name=baseName+"_SD"
	Duplicate/o W_PopSD $name
	name=baseName+"_SEM"
	Duplicate/o W_PopSEM $name


End