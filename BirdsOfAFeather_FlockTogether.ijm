/*
 * Description: transforms images of birds into rectangular boxes with patterns and colors
 * Developed for: Carole, Manceau's team
 * Author:Thomas Caille @ ORION-CIRB 
 * Date: January 2025
 * Repository: https://github.com/orion-cirb/BirdsOfAFeather_FlockTogether
 * Dependencies: orders_families.csv file and the color palette available on github
*/


/* TODO:
 * Texte en anglais (dans boîtes de dialogue, fenetres pop-up, ROI Manager, fichier CSV) 
 * faire deux points à la place de la ligne pour la calibration
 * Fichier CSV, à améliorer, rajouter des variables
 *
 */

/////////////VARIABLES//////////////////
sizeX = 50 ;
couleurMotif = 0;
couleurFond = 0;
colorMotif = 0;
colorFond = 0;

array = newArray(6*6);
X = newArray(0);
Y = newArray(0);

items = newArray("yes","no"); 
verticalBoundariesTypes = newArray("Line","U","U inverse","V","V inverse"); 
motifs = newArray("Bars","Scales","Spots","uniforme");

////////////////////////////////////////


// Retrieve list of orders
orders_families_dir = getDirectory("Choose the Directory with the orders_families.csv file ");
orders_families_path = orders_families_dir + "orders_families.csv"; 
orders_families = Table.open(orders_families_path);  
orders = split(Table.headings, "\t");
close("orders_families.csv");

Dir = getDirectory("Choose an image Directory ");
inputFiles = getFileList(Dir);
outDir = Dir  + "Results"+ File.separator();
if (!File.isDirectory(outDir)) {File.makeDirectory(outDir);}
if (!File.exists(outDir + "results_global.csv")) {
			fileResultsGlobal = File.open(outDir + "results_global.csv");
		print(fileResultsGlobal, "Image name,Order,Family,Genus,Species,Subspecies,Sex,Experimenter,nbVerticalBoundaries");
		File.close(fileResultsGlobal);
		}   
for (f = 0; f < inputFiles.length; f++) {
	if (endsWith(inputFiles[f], ".JPG") ||endsWith(inputFiles[f], ".tiff") ||endsWith(inputFiles[f], ".png") || endsWith(inputFiles[f], ".jpg")) {
		
		rootname = File.getNameWithoutExtension(inputFiles[f]);	
		if ( File.exists(outDir+rootname+".png") ) {
			continue;
		}
		
		open(Dir + inputFiles[f]);   
		imageName = getTitle();


		// Dialog box to get order
		Dialog.create("Select order");
		Dialog.addChoice("Order:", orders, orders[0]);
		Dialog.show();
		order = Dialog.getChoice();
		
		// Retrieve list of families for selected order
		orders_families = Table.open(orders_families_path);
		families = Table.getColumn(order);
		families = Array.deleteValue(families, NaN);
		close("orders_families.csv");
		
		// Dialog box to get other biological information
		Dialog.create("Enter biological info");
		Dialog.addMessage("You selected order: " + order);
		Dialog.addChoice("Family:", families, families[0]);  // Dropdown for family
		Dialog.addString("Genus:", "");                      // Text field for genus
		Dialog.addString("Species:", "");                    // Text field for species
		Dialog.addString("Subspecies:", "");                 // Text field for subspecies
		sexOptions = newArray("unknown", "female", "male");
		Dialog.addChoice("Sex:", sexOptions, sexOptions[0]); // Dropdown for sex
		Dialog.addString("Experimenter:", ""); 			     // Text field for experimenter
		Dialog.show();
		family = Dialog.getChoice();
		genus = Dialog.getString();      
		species = Dialog.getString();    
		subspecies = Dialog.getString();
		sex = Dialog.getChoice();
		experimenter = Dialog.getString();
		
		// Start up process
		run("Select None");
		roiManager("reset");
		setOption("Show All",false);
		
		// Dialog box asking head direction
		Dialog.createNonBlocking("");
		Dialog.addRadioButtonGroup("Tête à gauche ?", items,1,2,"yes")
		Dialog.show();
		orientation = Dialog.getRadioButton();
		if (orientation == items[1]) {
			run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear");
		}
		
		// Dialog box for calibration
		setTool("line"); 					
		Dialog.createNonBlocking("");
		Dialog.addMessage(" Draw 1 cm line ", 20, "black");
		Dialog.show();
		getLine(x1, y1, x2, y2, lineWidth);
		calibration(x1,y1,x2,y2);
		
		//Dialog box for Points Of Interest
		setTool("multipoint");
		Dialog.createNonBlocking("Place points ");
		Dialog.addMessage("1           2             3 \nx           x             x \n                       \n                           \n                           \n                       \nx           x             x \n6           5             4 ", 30, "black"); //TODO: décrire quels points doivent etre places et dans quel ordre
		Dialog.show();
		getSelectionCoordinates(xpoints, ypoints);
		Array.getStatistics(xpoints,x_min,x_max,mean,stdDev);
		Array.getStatistics(ypoints,y_min,y_max,mean,stdDev);
		
		// Get coordinates and make a rectangle 
		makeRectangle(x_min, y_min,(x_max)-(x_min),(y_max)-(y_min));
		run("Duplicate...", " ");
		close("\\Others");
		
		// CREATE VERTICAL REGIONS
		// Dialog box to retrieve the vertical boundaries numbers
		Dialog.createNonBlocking("");
		Dialog.addNumber("number of vertical boundaries", 1); 
		Dialog.show();
		verticalBoundaries = Dialog.getNumber(); 
		
		// Loop asking the type of boundary
		if (verticalBoundaries > 0) {
			Dialog.create("");
			Dialog.addMessage(" type of vertical boundary : ", 20, "black");
			for (i = 1; i <= verticalBoundaries; i++) { 
				Dialog.addChoice(" Vertical boundary "+i+" :", verticalBoundariesTypes)		
			}
			Dialog.show();
		}
		// Retrieve news info from the image  	
		choosen = newArray(verticalBoundaries); 
		height = getHeight(); 
		width = getWidth(); 
		imageID = getImageID(); 
		close("\\Others");
		
		// Get the boundary type
		for (j = 0; j < verticalBoundaries; j++) {
			choosen[j] = Dialog.getChoice();
		}
		
		// Make line depending on the boundary type, also make the first line at 0,0 and the last at width,height
		makeLine(0, 0,0, height);
		roiManager("add");
		roiManager("select", (roiManager("count")-1));
		roiManager("rename", "boundary : 0");
		if (lengthOf(choosen) > 0) {	
			for (k = 0; k < verticalBoundaries; k++) {	
				setOption("Show All",true);
			 	if (choosen [k] == verticalBoundariesTypes[0]) { 
			 		 makeLine((sizeX*(k+1)),0,(sizeX*(k+1)),height);
			 		
			 	}
			 	if (choosen [k] == verticalBoundariesTypes[1] || choosen [k] == verticalBoundariesTypes[2]) { 
			 		 makeLine((sizeX*j),0,(sizeX*j+50),(height/3),(sizeX*j+50),(height/1.5),(sizeX*j),height);
			 		 
				 }
				 if (choosen [k] == verticalBoundariesTypes[3] || choosen [k] == verticalBoundariesTypes[4]) { 
			  		makeLine((sizeX*j),0,(sizeX*j+50),(height/2),(sizeX*j),height);	
			  		
				 }
			 	makeFrontier(k);
			}
		}
		// Width-1 because if to large then line is place on the middle of the image
		makeLine((getWidth()-1), 0,(getWidth()-1), getHeight()); 
		roiManager("add");
		roiNumber = roiManager("count")-1 ; 
		
		// Loop to relocate all the line, fitting the border of the image in Y and the X axis 
		for (l = 0; l <= roiNumber ; l++) {
			roiManager("select", l);
			Roi.getCoordinates(xpoints, ypoints); 
			sizeY = lengthOf(ypoints);
			xpoints[0] = (xpoints[(sizeY-1)] + xpoints[0]) /2;
			ypoints[0] = 0;
			xpoints[(sizeY-1)] = xpoints[0];	
			ypoints[(sizeY-1)] = height;	
			if (sizeY == 4) {
				xpoints[1] = xpoints[2];
				ypoints[1] = (height/3);
				ypoints[2] = (height/1.5);
				makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1], xpoints[2], ypoints[2],xpoints[3],ypoints[3]);
				roiManager("add");	
			}
			else if (sizeY == 3) { 
				ypoints[1] = (height/2);
				makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1], xpoints[2], ypoints[2]);
				roiManager("add");	
			}
			else if (sizeY == 2) {
				makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1]);
				roiManager("add");			
			}
		}
		// Delete the old lines misplaced 
		roiManager("select",Array.getSequence(roiNumber+1));
		roiManager("delete");
		// Function to make polygon from lines
		borderDot (Y,X,l,roiNumber);
		roiArray = newArray(roiNumber);
		choosenLong = newArray(verticalBoundaries+1);
		// Function to rename polygon aka region
		renameROI(roiNumber);
		
		
		// CREATE LONGITUDINAL SUBREGIONS
		setOption("Show All",true);
		Dialog.createNonBlocking("");
		Dialog.addMessage("frontière longitudinale", 20, "black");
		for (i = 1; i <= (verticalBoundaries+1); i++) { 
			Dialog.addRadioButtonGroup(" Region : "+i, items,1,2,"no")
		}
		Dialog.show();
		
		for (j = 0; j < verticalBoundaries+1; j++) {
			choosenLong[j] = Dialog.getRadioButton();
		}
		for (k= 0; k < verticalBoundaries+1; k++){
			if (choosenLong[k] == "yes") {
				longi(k);
			}
		}
		
		regionOfInterest(choosenLong,roiNumber);
		
		// SCALE SCHEME AND ROIS TO FIXED SIZE
		
		run("Select None");
		run("Scale...", "x=- y=- width=500 height=250 interpolation=Bilinear average create");
		// Rescale the rois to covert all the image 
		RoiManager.scale(500/width,250/height,false)
		close("\\Others");
		imageID = getImageID();
		height = getHeight();
		width = getWidth();
		run("RGB Color");
		roiManager("sort");
		motifRegion = newArray(roiManager("count")-1);
		// Call the function gridArray 
		gridArray(array);
		
		// Create an array with all the colors inside the color range reference in hexadecimal format 
		couleurArray = newArray("#f3cf55","#e9cec3","#e7e1e1","#c99486","#c3d0e3","#5a7892","#dfb869","#d7b38f","#dfd9d9","#e08276","#819bc0","#74baaf","#92b798","#cc9264","#8f8989","#c85250","#7d7fa6","#69aabc","#aabc66","#985b3f","#636260","#f79443","#ca8298","#0087a7","#4d945c","#704032","#373735","#f45f35","#c4548e","#3f5493","#4d623b","#49342f","#212121","#b22825","#542e5f","#2b357a");
		
		// Loop through all region and ask for the pattern and the color inside the region
		for (i = 0; i <= (roiManager("count")-1); i++) {
			roiManager("select", i);
			roiName = Roi.getName;
			Dialog.createNonBlocking("");
			Dialog.addMessage("motif de la "+roiName+":                              ", 20, "black");	
				
			Dialog.addRadioButtonGroup("motif :", motifs,1,4,motifs[3]); 
			Dialog.addRadioButtonGroup("couleur motif:", array, 6 , 6,array[0]);
			Dialog.addToSameRow(); //TODO: à supprimer?
			Dialog.addRadioButtonGroup("couleur fond:", array, 6 , 6,array[0]);
			Dialog.show();
			motifRegion = Dialog.getRadioButton();
			couleurMotif = Dialog.getRadioButton();
			couleurFond = Dialog.getRadioButton();
				
			motif(motifRegion,imageID,width,height,array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond);				
		}
		// Save the 500x250 rectangle as .png
		saveAs("png", outDir + inputFiles[f]);
		File.append(rootname+","+ order +","+ family +","+ genus +","+species +","+ subspecies +","+ sex +","+experimenter +","+ verticalBoundaries ,outDir + "results_global.csv");
	}
}

  /////////////////////////////////
  ////////////////////////////////
  ///////// Functions ///////////
  //////////////////////////////
  /////////////////////////////
 
// Calibrate the image depending on the line draw by the user
 function calibration (x1,y1,x2,y2) {
 	length = abs(x1-x2);
 	run("Set Scale...", "distance="+length+" known=10 unit=mm");
 }  
// Allow the user to move the line and add it to the manager
function makeFrontier(k) { 
	roiManager("add");
	roiManager("select", (roiManager("count")-1));
	roiManager("rename", "boundary : "+(k+1));
	Dialog.createNonBlocking("");
	Dialog.addMessage(" Déplacer les points", 20, "black");
	Dialog.show();
	roiManager("add");
	roiManager("select", k+1);
	roiManager("delete");
}
// Get the lines coordinates and reverse the first, concatenate them and then make and add the polygon to the manager
function borderDot (Y,X,l,roiNumber) {
	for (l = 0; l <roiNumber ; l++) {
		roiManager("select", l);
		Roi.getCoordinates(xpoints, ypoints); 
		Array.reverse(xpoints);
		Array.reverse(ypoints);
		
		roiManager("select", l+1);
		Roi.getCoordinates(xpoints2, ypoints2); 
		X = Array.concat(xpoints,xpoints2);
		Y = Array.concat(ypoints,ypoints2);
		makeSelection("polygon", X, Y);
		roiManager("add");
	}
	roiManager("select",Array.getSequence(roiNumber+1));
	roiManager("delete");			
}
// Rename all the ROI 
function renameROI (roiNumber) {
	for (o = 0; o < roiNumber ; o++) {
		roiManager("select", o);
		roiManager("rename", "region " + o+1);
	}
}
// Create a new "region" ROI if there is a longitudinal region inside, and delete the old one 
function regionOfInterest (choosenLong,roiNumber){
	for (o = 0; o < roiNumber ; o++) {
		if (choosenLong[o] == items[0]) {	
			name = RoiManager.getIndex("region " +(o+1));
			longName = RoiManager.getIndex("region " + (o+1)+ " longitudinale");
			cross = newArray(name,longName); 
			roiManager("Select",cross);
			roiManager("AND");
			roiManager("Add");
			cross [1] = (roiManager("count")-1) ;
			roiManager("Select",cross);
			roiManager("XOR");
			roiManager("Add");
			roiManager("Select",name);
			roiManager("delete");
			
			roiManager("Select",(roiManager("count")-1));
			roiManager("rename", "region " +(o+1));	
		}
	}
}
// Dialog box to make the user draw the longitudinal region, and rename it "region ... longitudinal"
function longi(k){
	setTool("Rectangle");
	run("Select None");
	Dialog.createNonBlocking("");
	Dialog.addMessage(" Tracer le rectangle longitudinale de la région"+(k+1), 20, "black"); //TODO: indiquer dans quelle région
	Dialog.show();
	roiManager("add");
	roiManager("Select",(roiManager("count")-1));
	roiManager("rename", "region " + (k+1)+" longitudinale");
	List.setMeasurements;
	centroidY = List.getValue("Y");
	run("Translate... ", "x=0 y="+ ((height/2)-centroidY));
	
	
}
// First : Loop and check which color the user choose for motif and background
// Second : For each motifs (except uniform) create an image with the motif, select the roi on the motif image, copy the motif and paste it on the original image 
function motif(motifRegion,imageID,width,height,array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond) {
	for (b = 0; b < 36; b++) {
		if (array [b] == couleurMotif){		
			colorMotif = couleurArray [b];			
		}
		if (array [b] == couleurFond){
			colorFond = couleurArray[b];
		}
	}
	if (motifRegion == motifs[3]) { 
		setColor(colorMotif);
		run("Fill", "slice");
		continue;
	}
		
	if (motifRegion == motifs[0]) { 
		roiManager("add");
		setBatchMode(true);
		spacing = 500/15;
		size = spacing/3;
		newImage("bars", "RGB black", 500, 250, 1);
		Color.setBackground(colorFond);
		run("Select All");
		run("Clear", "slice");
		for (i = 0; i < spacing; i++) {
			run("Specify...", "width="+size+" height="+500+" x="+size+i*spacing+" y=0");
			setColor(colorMotif);
			run("Fill", "slice");
		}
			applyMotif(imageID);	
			setBatchMode(false);	
	}
	
	if (motifRegion == motifs[1]) { 
		roiManager("add");
		setBatchMode(true);
		spacing = 500/15;
		size = spacing/4;
		newImage("scales", "RGB black", width, height/2, 1);
		Color.setBackground(colorFond);
		run("Select All");
		run("Clear", "slice");
		run("Specify...", "width="+size+" height="+height+" x=-"+4*spacing+" y=-"+height/4);
		run("Rotate...", " angle=45");
		for (i = 0; i < 4*width/spacing; i++) {
			run("Translate... ", "x="+spacing+" y=0");
			setColor(colorMotif);
			run("Fill", "slice");
		}
		run("Select None");
		run("Duplicate...", " ");
		run("Flip Vertically");
		run("Images to Stack", "  title=scales");
		run("Make Montage...", "columns=1 rows=2 scale=1");
		rename("scales");
		close("Stack");
			
		applyMotif(imageID);
		setBatchMode(false);
	}
		
	if (motifRegion == motifs[2]) { 
			
		roiManager("add");
		setBatchMode(true);
		spacing = (width+height)/20;
		size = spacing/2;
		newImage("spots", "RGB black", width, height, 1);
		Color.setBackground(colorFond);
		run("Select All");
		run("Clear", "slice");	
		for (i = 0; i < width/spacing; i++) {
			for (j = 0; j < height/spacing; j++) {
				if(i%2 == 0) {
					run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+j*spacing+" oval");
				} else {
					run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+size+j*spacing+" oval");
				}				
				setColor(colorMotif);
				run("Fill", "slice");									
			}
		}
			applyMotif(imageID);
			setBatchMode(false);		
	}	
}
// Create an array like "A1, B1, C1 ..."
function gridArray (array) {
	index =0;
	letters = "ABCDEF";
	for (j = 1; j <= 6; j++) {
		
		for (i = 0; i < 6; i++) {
			letter = substring(letters, i, i+1);	
			array[index] = letter + (j);
			index++;
			
		}	
	}
}
// Copy and paste motifs on an image 
function applyMotif (imageID) {
	run("Select None");
	roiManager("select", (roiManager("count")-1));
	roiManager("delete");
	run("Copy");
	run("Close");
	roiManager("deselect");
	selectImage(imageID);	
	run("Paste");
}

