/* TODO
 dans le Init, un dialog avec : - affichage Plot, -Virtual stack puis import windowless (ou que la toute première fois c'est avec windows, puis après, c'est sans)
 prévoir 3 mode de sauvegarde: full size / manual ROI / fixed height & width
 prévoir de travailler en BatchMode ( initialisation notamment et Create XYt tstack)
 export des X(t),Y(t),Z(t) ?
 Prevoir de pouvoir extraire des ROI en XYZt (suivi temprelle Cell par cell)
*/


/* List Functions :
 *  [1] Time-
 *  [2] Time+
 *  [3] Store XYZ(t)
 *  [4] Clear XYZ(t)
 *  [5] Semi Auto Tracer
 *  [6] Create XYt stack (if rectangle have been drawn, creat a stack with that size) 
 *  [9] Parameters
 *  [0] Import hyperstack (if not selected) or initialize variables
 *	[h] this help window";
 */
var SzeC=-1;
var SzeZ=-1;
var SzeT=-1;;
var XNucl=newArray(0);
var YNucl=newArray(0);
var ZNucl=newArray(0);
var XNuclFit=newArray(0);
var YNuclFit=newArray(0);
var ZNuclFit=newArray(0);
var TNucl=newArray(0);
var DT=0;
var OrgID=0;
var SuffixName="-Sample"; // for saving the XYt movie
var SuffixNum=1; // for saving the XYt movie
var IsFirstTime=true ; // to show the first time the parameters
var ShowPlot=false;
var DoRegister=false;
var MyROISelect="Manual Rect";
var	MyROIWidth=550;
var	MyROIHeight=550;
var XYtXYZtMode="Single Z (XYt)";
var StopQuickSelect=true;
var DoFinish="Save";
var Do8bit=true;
var NNucl=1;
var iT=1;

//=============================================================================================================
macro "Starting"{	
	run("Install...", "install=["+getDirectory("macros")+"Seb\\Man_Z_Select.ijm]");
	setTool("point");
}

//=============================================================================================================
macro "Load & Init [0]"{
	if (nImages>0){
		Stack.getDimensions(w, h, c, z, t);
		OpenZStack=z>1;
	}
	else OpenZStack=false;
	if (!OpenZStack) run("Bio-Formats Importer", "");
	
	InitVar();
	setTool("point");
	run("Select None");
	Stack.setPosition(1,floor(SzeZ/2),1);
	if (IsFirstTime) run("Parameters [9]");
}

//=============================================================================================================
macro "PreviousT [1]"{
	Stack.getPosition(channel, slice, frame);"
	if (frame>1) {
		Stack.setPosition(channel, slice, frame-1);
		RoiManager.select(frame-2);
	}
	else {
		Stack.setPosition(channel, slice, frame);
		RoiManager.select(frame-1);	
	}
}
//=============================================================================================================
macro "NextT [2]"{
	Stack.getPosition(channel, slice, frame);
	Stack.getDimensions(width, height, channels, SzeZ, SzeT);
	if (frame<SzeT) {
		Stack.setPosition(channel, slice, frame+1);
		RoiManager.select(frame);
	}
	else {
		Stack.setPosition(channel, slice, frame);
		RoiManager.select(frame-1);
	}	
}
//=============================================================================================================
macro "StoreZ [3]"{
//	IsBatchMode=is("Batch Mode");
//	if (IsBatchMode==false) setBatchMode("true");
	
	if (OrgID!=0) selectImage(OrgID);	
	Stack.getPosition(channel, slice, frame);
	MySelectionType=selectionType();
	if (MySelectionType!=10) getCursorLoc(x, y, z, flags);	
	if (MySelectionType==10) {
		getSelectionCoordinates(x0, y0);
		x=x0[0];
		y=y0[0];
	}
	print(x);
	if (ZNucl.length==0) InitVar();
	XNucl[frame-1]=x;
	YNucl[frame-1]=y;
	ZNucl[frame-1]=slice;
	roiManager("select", frame-1);
	makePoint(x, y, "large yellow hybrid");
	roiManager("update");
	TmpName3="T="+frame+" : "+x+"/"+y+"/"+slice;
	roiManager("rename",TmpName3);
	iT=frame+1;
	Stack.setPosition(channel, slice, iT);		
	if (ShowPlot) PlotZ();
	if (MySelectionType==-1) run("Select None");
//	if (IsBatchMode==false) setBatchMode("exit and display");
}

//=============================================================================================================
macro "ClearT [4]"{
	Stack.getPosition(channel, slice, frame);
	XNucl[frame-1]=0;
	YNucl[frame-1]=0;
	ZNucl[frame-1]=0;
	roiManager("select", frame-1);
	makePoint(0, 0, "large yellow hybrid");
	roiManager("update");
	TmpName="T="+frame+" : none";
	roiManager("rename",TmpName);
	iT=frame+1;
	Stack.setPosition(channel, slice, iT);		
	PlotZ();
}


//=============================================================================================================
macro "SemiAutoPlot [5]"{
// sequentially add new point	
//[Space] to stop the AutoPlot
	StopQuickSelect=false;
	if (OrgID!=0) selectImage(OrgID);	
	getDimensions(width, height, channels, slices, frames);
	while(!StopQuickSelect){
		run("Select None");
		setTool("point");
		Stack.getPosition(channel, slice, frame);
		while (selectionType()==-1) {
			if (isKeyDown("space")) return;
			wait(100);
			showStatus("T="+frame+"/"+frames+". Waiting For Clicking...");
		}
		run("StoreZ [3]");
		print("f"+frame+"/"+frames);
		if (frame==frames) run("Extract [6]");
//		break;
	}
	showStatus("[5] Done");
//	setKeyDown("esc");
}
//=============================================================================================================
macro "Extract [6]"{
	StopQuickSelect=true;
	if (IsFirstTime) run("Parameters [9]");
	if (MyROISelect=="Full Size"){
		width=0;
	}
	if (MyROISelect=="Manual Rect"){
		while (selectionType()!=0){
			setTool("rectangle");
			Dialog.createNonBlocking("Draw Your Rectangle ROI");
			Dialog.addMessage("Draw Your Rectangle ROI");
			Dialog.show();
		}
		Roi.getBounds(x, y, width, height);	
		MyROIWidth=width;	
		MyROIHeight=height;
	}
	if (MyROISelect=="Fixed Width / Height") {
		width=MyROIWidth;
		height=MyROIHeight;
	}
	run("Select None");
	getMinAndMax(MinGray, MaxGray);

	IsBatchMode=is("Batch Mode");
	if (IsBatchMode==false) setBatchMode(true);
	XNuclFit=LinFit(XNucl);
	YNuclFit=LinFit(YNucl);
	ZNuclFit=LinFit(ZNucl);
	
	if (ShowPlot) PlotZ2(ZNuclFit);

	selectImage(OrgID);
	OrgDir=getInfo("image.directory");
	OrgName=getInfo("image.filename");
	OrgTitle=getTitle();
	if (Do8bit) getMinAndMax(MinGray, MaxGray);
	
	Stack.getPosition(CurrCh, slice, frame);
	//setBatchMode("hide");
	setBatchMode("exit and display");
	for (i1=0;i1<ZNucl.length;i1++){
		selectImage(OrgID);
		showStatus("Img"+i1+1+"/"+ZNucl.length);
		showProgress(i1/ZNucl.length);
// Extract Single Z		
		if (width>0) {
			Stack.setPosition(CurrCh, i1+1, ZNuclFit[i1]);
			makeRectangle(XNuclFit[i1]-width/2, YNuclFit[i1]-height/2, width, height);
		}
		else run("Select None");
		if (XYtXYZtMode=="Single Z (XYt)") run("Duplicate...", "title=["+OrgTitle+"] duplicate slices="+ZNuclFit[i1]+" frames="+i1+1);
		if (XYtXYZtMode=="Full Z (XYZt)") run("Duplicate...", "title=["+OrgTitle+"] duplicate frames="+i1+1);
		if (i1>0){
			rename("pipo");
//			getDimensions(width, height, channels, slices, frames);
			run("Concatenate...", "open image1=[ZStack] image2=[pipo] image3=[-- None --]");
		}
		rename("ZStack");
	}
	if (XYtXYZtMode=="Full Z (XYZt)") run("Stack to Hyperstack...", "order=xyczt(default) channels="+SzeC+" slices="+SzeZ+" frames="+SzeT+" display=Color");
	if (DoRegister) {
		showStatus("Registering...");
		run("StackReg", "transformation=[Rigid Body]");
	}
	newName=""+CleanName(OrgName)+SuffixName+SuffixNum;
	SuffixNum++;
	rename(newName);
	if (Do8bit) {
		setMinAndMax(MinGray, MaxGray);
		run("8-bit");
	}
	if (IsBatchMode==false) setBatchMode("exit and display");
	if (DoFinish.startsWith("Save")) saveAs("Tiff",OrgDir+newName);
	if (DoFinish.endsWith("Close")) close();
}


//=============================================================================================================
macro "Parameters [9]"{	
	Dialog.createNonBlocking("Extract XYt stack");
	Dialog.addCheckbox("Show Z Plot :", ShowPlot);
	Dialog.addCheckbox("Save in 8bit:", Do8bit);
	Dialog.addToSameRow();
	Dialog.addMessage("for 8-bit, set contrast before clicking [OK]");
	items1=newArray("Full Size","Manual Rect","Fixed Width / Height");
	Dialog.addRadioButtonGroup("", items1, 1, 3, MyROISelect); 
	Dialog.addNumber("Width", MyROIWidth);
	Dialog.addToSameRow();
	Dialog.addNumber("Height", MyROIHeight);
	items2=newArray("Single Z (XYt)","Full Z (XYZt)");
	Dialog.addRadioButtonGroup("", items2, 1, 2, XYtXYZtMode); 
	
	Dialog.addCheckbox("Registration [rigid body]", DoRegister);
	Dialog.addString("Suffix", SuffixName);
	Dialog.addToSameRow();
	Dialog.addNumber("#", SuffixNum);
	items3=newArray("Do nothing","Save","Save & Close");
	Dialog.addRadioButtonGroup("", items3, 1, 3, DoFinish); 
	Dialog.show();
	ShowPlot = Dialog.getCheckbox();
	Do8bit = Dialog.getCheckbox();
	MyROISelect= Dialog.getRadioButton;
	MyROIWidth = Dialog.getNumber();
	MyROIHeight = Dialog.getNumber();
	XYtXYZtMode = Dialog.getRadioButton;
	DoRegister = Dialog.getCheckbox();
	SuffixName = Dialog.getString();
	SuffixNum = Dialog.getNumber();
	DoFinish=Dialog.getRadioButton;	
	IsFirstTime=false;
}

//=============================================================================================================
macro "ShowHelp [h]"{
	msg="<html><b><u>Shortcuts :</b></u><br>";
	msg+="[1] Time-<br>[2] Time+<br>[3] Store XYZ(t)<br>[4] Clear XYZ(t)<br>";
	msg+="[5] Semi Auto Tracer <br>&nbsp&nbsp&nbsp&nbsp&nbsp[Space] To stop the AutoPlot<br>";
	msg+="[6] Create XYt stack<br>&nbsp&nbsp&nbsp&nbsp&nbsp(if rectangle have been drawn, create a stack with that size)<br>";
	msg+="[9] Parameters window<br>";
	msg+="[0] Import hyperstack (if not selected) or (re)initialize variables<br>";
	msg+="[h] this help window<br><br>";
	msg+="<u><b>Using the wheel : </u></b><br>";
	msg+="<ul><li> Wheel: change the Z</li>";
	msg+="<li> [Ctrl]+Wheel: change the Zoom (centered on the pointer)</li>";
	msg+="<li> [Alt]+Wheel: change the Time <br>(click [Alt] again to give access to Z selection)</li></ul>";
	msg+="<br>contact: sebastien.schaub@imev-mer.fr";
	msg+="</html>";
	showMessage("Manual Z Selection",msg);
}
//=============================================================================================================
// FUNCTIONS
//=============================================================================================================
function InitVar(){
	roiManager("reset");
	Stack.getDimensions(width, height, SzeC, SzeZ, SzeT);
	Stack.getPosition(CurrCh, slice, frame);
	XNucl=newArray(SzeT);
	YNucl=newArray(SzeT);
	ZNucl=newArray(SzeT);
	TNucl=newArray(SzeT);
	DT=Stack.getFrameInterval();
	for (i1=1;i1<=SzeT;i1++) {
		Stack.setPosition(CurrCh, slice, i1);
		makePoint(-1, -1, "large yellow hybrid");
		roiManager("Add");
		roiManager("select",roiManager("count")-1);
		TmpName="T="+i1+" : none";
		roiManager("rename",TmpName);
		TNucl[i1-1]=(i1-1)*DT;
	}
	Stack.setPosition(CurrCh, slice, frame);	
	OrgID=getImageID();
}
//=============================================================================================================
function PlotZ(){
	precID=getImageID();
	if (!isOpen("MyPlot")){
		Stack.getUnits(X, Y, Z, Time, Value);
		Plot.create("MyPlot", "Time ["+Time+"]", "Z Location ["+Z+"]");
		Plot.add("circle", TNucl, ZNucl);
		Plot.setStyle(0, "blue,blue,6,Circle");
		Plot.addLegend("Selected Z");	
		k=newArray(1);
		k[0]=NaN;
		Plot.add("line", k, k);
		Plot.setStyle(1, "red,red,6,Circle");
		Plot.setFontSize(14);
		Plot.addLegend("Interpolated Z");	
		Plot.update; 
	}
	else {
		selectWindow("MyPlot");
		Plot.replace(0, "circle", TNucl, ZNucl);
		Plot.setStyle(0, "blue,blue,6,Circle");
	}
	Plot.setLimits(0, DT*iT, 1, SzeZ);
	selectImage(precID);
}
//=============================================================================================================
function PlotZ2(Z2){
	precID=getImageID();
	PlotZ();
	selectWindow("MyPlot");
	Plot.replace(1, "line", TNucl, ZNuclFit);
	Plot.setStyle(1, "red,red,3,Line");
	Plot.setLimits(0, DT*(SzeT-1), 1, SzeZ);
	selectImage(precID);

}

//=============================================================================================================
function LinFit(Y){
// Linear fit when Y[i]<=0
	print("\\Clear");
	YFit=newArray(Y.length);
	for (i1=0;i1<=Y.length-1;i1++) YFit[i1]=Y[i1];
	
	TPrec=-1;
	EndHole=-1;
	StartHole=-1;
	for (i1=0;i1<=Y.length-1;i1++){
		if (Y[i1]<=0){
			if (StartHole==-1) StartHole=i1; 			
		}
		else {
			if ((StartHole!=-1) & (EndHole==-1)) {
				EndHole=i1-1; 
//-----------------------------------------
// Fill the hole				
//-----------------------------------------
// Case Hole at the beginning				
				if (StartHole==0){
					for (i2=StartHole;i2<=EndHole;i2++)	YFit[i2]=Y[EndHole+1];
				}
// Case Hole in the middle				
				else{
				print("Filling i1="+i1+"CurrZ="+YFit[i1]+" ; StartHole="+StartHole+" ; EndHole="+EndHole);
					y1=Y[StartHole-1];
					y2=Y[EndHole+1];
					D=EndHole+1-StartHole+1;
					for (i2=StartHole;i2<EndHole+1;i2++){
						d1=(i2-(StartHole-1))/D;
						YFit[i2]=y2*d1+y1*(1-d1);"
						YFit[i2]=round(YFit[i2]);// to round					
						print("Z("+i2+") : "+Y[i2]+" ->" +YFit[i2]);
					}					
				}
				EndHole=-1;
				StartHole=-1;
			}
			TPrec=i1;
		}
	}
// Case Hole at the end	
	if ((EndHole==-1) & (StartHole!=-1)){
		for (i2=StartHole;i2<Y.length;i2++) YFit[i2]=Y[StartHole-1];
	}
	return YFit;
}

//=============================================================================================================
function CleanName(s) { 
// clear name from .ext
	n=s.indexOf('.');
	CropName=substring(s,0,n);
	return CropName;
}
