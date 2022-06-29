# ManZSelect

## Goal
The goal is to extract data from large hyperstack to crop the data following manually the ROI of interested. with a user-friendly manipulation, we can extract either an XYt movie (manual Z selection and manually tracking in XY) or an XYZt hyperstack (manually tracking in XY)

## How to install

- Click on “Plugins” > “Macros” > Install…” and select the “ManZSelect.ijm” in your computer.

## How to Use

### Preparation HyperStack
- Clicking on [0] “Load & Init”. If there is no hyperstack (XYZT) opened, it proposes to open a file (.nd for instance)

- If the first time, it open the Parameter Window (can be recalled [9] “Parameters”).

### Parameters User-Defined
- Clicking on [9] “Parameters” you have access to some options:
	1)	« Show Plot »
At each step update a graph with the Z(t), the axial position per time point. Dots are the defined location (see…), the red line is the interpolating curve when missing some Z(t)
 
	2)	“Save 8-bit”
Convert the final stack (XYt or XYZt) in 8-bit based on the Gray level limits set before the [6] “Extract”
3)	“Region-Of-Interest”. Set the type of ROI you want:
a.	“Full Size” will select all the field of view (then the X(t) and Y(t) have no effect)
b.	“Manual Rect” will ask before [6] “Extract”to draw a rectangle have the stack width & height (the rectangle location doesn’t matter)
c.	“Fixed Width/Height” impose manually the size of the rectangle.
4)	“Single Z (XYt)” will extract per time point the Z(t) plane, whereas “Full Z (XYZt)” will extract all the Z stack (then Z(t) doesn’t matter).
5)	“Registration” apply StackReg (http://bigwww.epfl.ch/thevenaz/stackreg/ ) with rigid body.
6)	“Suffix” will rename the newly substack with Original_Name_Sample-1. This name will be used for saving (si below)
7)	“Saving”. You can decide of at the end you want do nothing, or automatically save the image and/or close it.

### Semi Auto Plot [5]
•	After Initializing the variables ([0] “Load & Init”), start [5] "SemiAutoPlot ".
•	Moving the Z (wheel alone), you can change the Z plan.
•	[Left Click] in the middle of the structure to be tracked
The macro will store/update the x,y,z location of the current time-point and open the subsequent frame
•	You can skip some timepoint (Either with [Alt]+[Wheel] or with the slider), they will be interpolated.
•	[Space bar] to stop the process. 
•	When last time-point is defined, it automatically run the [6] “Extract”

### Extract [6]
•	Based on the defined 3D location per time-point, the macro interpolates the potential missing coordinates.
•	If the user defined the ROI as “Manual Rect”, the macro waits until a rectangle ROI is drawn.
•	The macro then extract per time-point the XY image either full size image, or a rectangle centered on the x,y coordinates.
•	If selected, then the macro perform a StackReg>Rigid body
•	If “8-bit” has been selected, the macro will convert according the initial Gray-limits defined in Brightness&Contrast
•	At the end, if selected, the macro save automatically the results based on the original name wth its suffix as defined in “Parameters [9]”.

### Fine update
•	"PreviousT [1]" resp. "NextT [2]" will show you the previsou (resp. next) time-point with the x,y location and the selected Z plan.
You can also select in the ROI-Manager the time-point you want to reach directly. The ROI name tell the time-point, and x,y,z coordinate. If “none”, the time-point will be interpolated
                                                        
•	"StoreZ [3]". Creating or moving the current yellow cross in an updated Z-plan, you can store it pressing [3].
•	"ClearT [4]". Remove the current x,y,z coordinate and store it as “non” in the ROI-Manager.

## References

- More information are provided in *ManZSelect Manual.pdf*

- For more information, contact sebastien.schaub@imev-mer.fr
