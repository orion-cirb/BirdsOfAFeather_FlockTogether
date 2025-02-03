/*
 * Description: A tool that helps transforming birds pictures into drawings that highlight borders, patterns, and colors.
 * Developed for: Carole, Manceau's team
 * Author: Thomas Caille & Héloïse Monnet @ ORION-CIRB 
 * Date: February 2025
 * Repository: https://github.com/orion-cirb/BirdsOfAFeather_FlockTogether
 * Dependencies: orders_families.csv and color_palette.png files available on GitHub repository
*/


/* TODO: 
 * Pour une meilleure lisibilité: 
 * 		Noms de variables plus explicites :)
 * 		Pour le nom des variables, fonctions, etc, se décider entre: imgName ou img_name
 * 		setName(a, b, c) plutot que setName(a,b,c)
 * 		function setName(a) { plutot que function setName (a){
 * 		setPosition(x+1, y+1) plutot que setPosition((x+1), (y+1))
 */


/////////////// GLOBAL VARIABLES ///////////////
noYesArray = newArray("No", "Yes"); 

drawingWidthPix = 500;
drawingHeightPix = 250;

verticalBoundariesShapes = newArray("Line", "V", "Inverted V", "U", "Inverted U");

patternsTypes = newArray("Uniforme", "Bars", "Scales", "Spots");
colorsLabel = split("A1,B1,C1,D1,E1,F1,A2,B2,C2,D2,E2,F2,A3,B3,C3,D3,E3,F3,A4,B4,C4,D4,E4,F4,A5,B5,C5,D5,E5,F5,A6,B6,C6,D6,E6,F6",",");
colorsHexa = newArray("#f3cf55","#e9cec3","#e7e1e1","#c99486","#c3d0e3","#5a7892","#dfb869","#d7b38f","#dfd9d9","#e08276","#819bc0","#74baaf","#92b798","#cc9264","#8f8989","#c85250","#7d7fa6","#69aabc","#aabc66","#985b3f","#636260","#f79443","#ca8298","#0087a7","#4d945c","#704032","#373735","#f45f35","#c4548e","#3f5493","#4d623b","#49342f","#212121","#b22825","#542e5f","#2b357a");
/////////////////////////////////////////////////


// Retrieve list of orders
orders_families_dir = getDirectory("Choose directory with orders_families.csv file");
orders_families_path = orders_families_dir + "orders_families.csv"; 
orders_families = Table.open(orders_families_path);  
orders = split(Table.headings, "\t");
close("orders_families.csv");

// Ask for input directory
inputDir = getDirectory("Choose images directory");

// Get all files in the input directory
inputFiles = getFileList(inputDir);

// Create results directory (if it does not already exist)
outputDir = inputDir + "Results" + File.separator();
if (!File.isDirectory(outputDir)) {
	File.makeDirectory(outputDir);
}

// Create results files (if they do not already exist)
globalResultsFilePath = outputDir + "globalResults.csv";
regionsResultsFilePath = outputDir + "regionsResults.csv";
if (!File.exists(globalResultsFilePath)) {
	resultsFile = File.open(globalResultsFilePath);
	print(resultsFile, "Image name,Order,Family,Genus,Species,Subspecies,Sex,Experimenter,Drawing width (mm),Drawing height (mm)");
	File.close(resultsFile);
	
	resultsFile = File.open(regionsResultsFilePath);
	print(resultsFile, "Image name,Region ID,Boundary shape,X1,Y1,X2,Y2,X3,Y3,Pattern type,Background color,Pattern color,Crossed regions");
	File.close(resultsFile);
}
		
// Loop through all files in input directory	
for (f = 0; f < inputFiles.length; f++) {
	if (endsWith(inputFiles[f], ".JPG") || endsWith(inputFiles[f], ".jpg") || endsWith(inputFiles[f], ".png") || endsWith(inputFiles[f], ".tiff")) {
		
		// If drawing already exists for this image in output directory, image is skipped
		rootName = File.getNameWithoutExtension(inputFiles[f]);
		if (File.exists(outputDir+rootName+".png")) {
			continue;
		}
		
		// Open image
		open(inputDir + inputFiles[f]);

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
		
		// START DRAWING PROCESS
		run("Select None");
		roiManager("reset");
		setOption("Show All", false);
		
		// Dialog box asking for head direction
		Dialog.createNonBlocking("");
		Dialog.addRadioButtonGroup("Head on the right?", noYesArray, 1, 2, noYesArray[0]);
		Dialog.show();
		orientation = Dialog.getRadioButton();
		// Rotate image such that head is always on the left
		if (orientation == noYesArray[1]) {
			run("Rotate... ", "angle=180 grid=1 interpolation=Bilinear");
		}
		
		// Dialog box asking for image calibration
		setTool("multipoint"); 					
		Dialog.createNonBlocking("");
		Dialog.addMessage("Place 2 points at a distance of 1 cm apart");
		Dialog.show();
		// Calibrate the image depending on the 2 points drawn by the user
		getSelectionCoordinates(xpoints, ypoints);
	 	length = Math.sqrt(Math.pow(xpoints[0]-xpoints[1], 2) + Math.pow(ypoints[0]-ypoints[1], 2));
	 	run("Set Scale...", "distance="+length+" known=10 unit=mm");
	 	run("Select None");
		
		// Dialog box asking for landmarks
		setTool("multipoint");
		Dialog.createNonBlocking("");
		Dialog.addMessage("Place landmarks:");
		Dialog.addMessage("   1    2    3    4\n   x    x    x    x\n    \n   x    x    x    x\n   8    7    6    5");
		Dialog.show();
		getSelectionCoordinates(xpoints, ypoints);
		// Check that landmarks on the neck and on the tail have the same x-position
		xNeck = (xpoints[0] + xpoints[7]) / 2;
		xpoints[0] = xNeck;
		xpoints[7] = xNeck;
		xTail = (xpoints[3] + xpoints[4]) / 2;
		xpoints[3] = xTail;
		xpoints[4] = xTail;
		// Create drawing by cropping image around landmarks
		Array.getStatistics(xpoints, x_min, x_max, mean, stdDev);
		Array.getStatistics(ypoints, y_min, y_max, mean, stdDev);
		makeRectangle(x_min, y_min, x_max-x_min, y_max-y_min);
		run("Crop");
		
		// Retrieve drawing infos  
		List.setMeasurements;
		imgWidthMm = List.getValue("Width");
		imgHeightMm = List.getValue("Height");
		
		// Save parameters in globalResults.csv file
		File.append(rootName+","+order+","+family+","+genus+","+species+","+subspecies+","+sex+","+experimenter+","+imgWidthMm+","+imgHeightMm, globalResultsFilePath);
		
		// Scale drawing to fixed size
		run("Scale...", "x=- y=- width="+drawingWidthPix+" height="+drawingHeightPix+" interpolation=Bilinear average create");
		setVoxelSize(1, 1, 1, "pix");
		run("RGB Color");
		imageID = getImageID();
		close("\\Others");
		
		// CREATE VERTICAL REGIONS
		// Dialog box asking for number of vertical boundaries
		Dialog.createNonBlocking("");
		Dialog.addNumber("Number of vertical boundaries", 1); 
		Dialog.show();
		verticalBoundariesNb = Dialog.getNumber(); 
		
		// Dialog box asking for the shape of each vertical boundary
		if (verticalBoundariesNb > 0) {
			Dialog.create("");
			Dialog.addMessage("Shape of vertical boundaries:");
			for (i = 1; i <= verticalBoundariesNb; i++) { 
				Dialog.addChoice("Vertical boundary "+i+":", verticalBoundariesShapes)		
			}
			Dialog.show();
		}
		verticalBoundaries = newArray(verticalBoundariesNb); 
		for (i = 0; i < verticalBoundariesNb; i++) {
			verticalBoundaries[i] = Dialog.getChoice();
		}
		
		// Create vertical boundaries
		setTool("rectangle");
		for (i = 0; i < verticalBoundariesNb; i++) {
			setOption("Show All",true);
			createVerticalBoundary(i, verticalBoundaries[i]);
		 	moveVerticalBoundary(i);
		 	checkVerticalBoundary(i);
		}
		
		// Add first boundary, on the very left of the drawing
		makeLine(0, 0, 0, drawingHeightPix);
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Boundary 0");
		// Add last boundary, on the very right of the drawing
		makeLine(drawingWidthPix, 0, drawingWidthPix, drawingHeightPix);
		roiManager("add");
		roiManager("select", roiManager("count")-1);
		roiManager("rename", "Boundary "+verticalBoundariesNb+1);
		roiManager("sort");
		
		//TODO: calculer X1,Y1,X2,Y2,X3,Y3 pour chaque vertical boundary dans le nouveau système de coordonnées
		//		dans un array, stocker "boundary shape,X1,Y1,X2,Y2,X3,Y3" pour chaque vertical boundary
	
		// Create vertical regions from vertical boundaries
		verticalRegionsNb = verticalBoundariesNb+1;
		for (i = 0; i < verticalRegionsNb; i++) {
			createVerticalRegion(i);
		}
		roiManager("select", Array.getSequence(verticalBoundariesNb+2));
		roiManager("delete");
		
		// CREATE LONGITUDINAL REGIONS
		// Dialog box asking for number of longitudinal regions
		Dialog.createNonBlocking("");
		Dialog.addNumber("Number of longitudinal regions", 0); 
		Dialog.show();
		longitudinalRegionsNb = Dialog.getNumber();
		
		// Dialog box asking for vertical regions crossed by each longitudinal region
		if (longitudinalRegionsNb > 0) {
			regLabels = newArray(0);
			regDefaults = newArray(0);
			for(i = 1; i <= verticalRegionsNb; i++) {
				regLabels = Array.concat(regLabels, newArray("Region "+i));
				regDefaults = Array.concat(regDefaults, false);
			}
			
			Dialog.create("");
			Dialog.addMessage("Select vertical regions crossed by each longitudinal region: ");
			for (i = 1; i <= longitudinalRegionsNb; i++) { 
				Dialog.addMessage("Longitudinal region "+i+":");
				Dialog.addCheckboxGroup(1, verticalRegionsNb, regLabels, regDefaults);
			}
			Dialog.show();
			
			allCrossedVerticalRegionsBool = newArray(0);
			for (i = 0; i < longitudinalRegionsNb; i++) {
				for (j = 0; j < verticalRegionsNb; j++) {
					allCrossedVerticalRegionsBool = Array.concat(allCrossedVerticalRegionsBool, newArray(Dialog.getCheckbox()));
				}
			}
			//TODO: stocker (dans une list? un array?) quelles régions traverse chaque région
			
			for (i = 0; i < longitudinalRegionsNb; i++) {
				crossedVerticalRegionsBool = Array.slice(allCrossedVerticalRegionsBool, i*verticalRegionsNb, i*verticalRegionsNb+verticalRegionsNb);				
				crossedVerticalRegionsName = Array.copy(regLabels);
				for(j = 0; j < verticalRegionsNb; j++) {
					if(!crossedVerticalRegionsBool[j]) {
						crossedVerticalRegionsName = Array.deleteValue(crossedVerticalRegionsName, "Region "+j+1);
					}
				}
				
				drawLongitudinalRegion(i, crossedVerticalRegionsName);
				subtractLongFromVertRegions(i, crossedVerticalRegionsBool);
			}
			roiManager("sort");
		}
		
		// In each region, draw pattern with appropriate background and foreground colors
		for (i = 0; i <= (roiManager("count")-1); i++) {
			roiManager("select", i);
			roiName = Roi.getName;
			Dialog.createNonBlocking("");
			Dialog.addMessage(roiName+":");
				
			Dialog.addRadioButtonGroup("Pattern type: ", patternsTypes, 1, 4, patternsTypes[0]); 
			Dialog.addRadioButtonGroup("Background color: ", colorsLabel, 6, 6, colorsLabel[0]);
			Dialog.addRadioButtonGroup("Pattern color: ", colorsLabel, 6, 6, colorsLabel[0]);
			Dialog.show();
			
			patternRegion = Dialog.getRadioButton();
			colorLabelBgRegion = Dialog.getRadioButton();
			colorLabelPatternRegion = Dialog.getRadioButton();
			drawPattern(i, imageID, patternRegion, colorLabelBgRegion, colorLabelPatternRegion);	 			
		}
		
		// Save parameters in globalResults.csv file
		File.append(rootName, regionsResultsFilePath); 
		//TODO: sauver "Image name,Region ID,Boundary shape,X1,Y1,X2,Y2,X3,Y3,Pattern type,Background color,Pattern color,Crossed regions" pour chaque region
		
		// Save drawing as .png file
		saveAs("png", outputDir + inputFiles[f]);
		
		// Save ROIs as a .zip file
		roiManager("deselect");
		roiManager("Save", outputDir + rootName + ".zip");
		
    	roiManager("reset");
		close("*");
	}
}


/////////////// FUNCTIONS ///////////////

// Create a vertical boundary of the shape selected by the user
function createVerticalBoundary(boundId, shape) {
	//TODO: ajouter V inversé et U inversé
	shiftX = 50;
 	if (shape == verticalBoundariesShapes[0]) { 
    	makeLine(shiftX*(boundId+1), 0, shiftX*(boundId+1), drawingHeightPix);
    	
 	} else if (shape == verticalBoundariesShapes[1] || shape == verticalBoundariesShapes[2]) { 
 		makeLine(shiftX*(boundId+1), 0, shiftX*(boundId+1)+shiftX, drawingHeightPix/2, shiftX*(boundId+1), drawingHeightPix);
 		
	} else if (shape == verticalBoundariesShapes[3] || shape == verticalBoundariesShapes[4]) { 
    	makeLine(shiftX*(boundId+1), 0, shiftX*(boundId+1)+shiftX, drawingHeightPix/3, shiftX*(boundId+1)+shiftX, drawingHeightPix/1.5, shiftX*(boundId+1), drawingHeightPix);
	}
	
	roiManager("add");
	roiManager("select", boundId);
	roiManager("rename", "Boundary "+boundId+1);
}
 
// Allow the user to move the vertical boundary at the correct position
function moveVerticalBoundary(boundId) {
	Dialog.createNonBlocking("");
	Dialog.addMessage("Place correctly vertical boundary "+boundId+1);
	Dialog.show();
	
	roiManager("add");
	roiManager("select", boundId);
	roiManager("delete");
	roiManager("select", boundId);
	roiManager("rename", "Boundary "+boundId+1);
}

// Check position of the vertical boundary
function checkVerticalBoundary(boundId) {
	roiManager("select", boundId);
	Roi.getCoordinates(xpoints, ypoints);
	pointsNb = xpoints.length;
	
	// Check that the vertical border fits the top and bottom edges of the image 
	xpoints[0] = (xpoints[0] + xpoints[pointsNb-1]) / 2;
	xpoints[pointsNb-1] = xpoints[0];
	ypoints[0] = 0;
	ypoints[pointsNb-1] = drawingHeightPix;
	// Check that V and U lines are symmetric with respect to X-axis
	if (pointsNb == 2) {
		makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1]);
		roiManager("add"); //TODO: le mettre une seule fois après le if plutot que de le repeter 3 fois			
	} else if (pointsNb == 3) { 
		ypoints[1] = drawingHeightPix/2;
		makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1], xpoints[2], ypoints[2]);
		roiManager("add");
	} else if (pointsNb == 4) {
		xpoints[1] = xpoints[2];
		ypoints[1] = drawingHeightPix/3;
		ypoints[2] = drawingHeightPix/1.5;
		makeLine(xpoints[0], ypoints[0], xpoints[1], ypoints[1], xpoints[2], ypoints[2], xpoints[3], ypoints[3]);
		roiManager("add");
	}
	
	roiManager("select", boundId);
	roiManager("delete");
	roiManager("select", boundId);
	roiManager("rename", "Boundary "+boundId+1);
}

// Create polygon from two vertical boundaries composing it
function createVerticalRegion(regId) {
	roiManager("select", regId);
	Roi.getCoordinates(xpoints, ypoints); 
	Array.reverse(xpoints);
	Array.reverse(ypoints);
	
	roiManager("select", regId+1);
	Roi.getCoordinates(xpoints2, ypoints2);
	
	X = Array.concat(xpoints, xpoints2);
	Y = Array.concat(ypoints, ypoints2);
	makeSelection("polygon", X, Y);
	roiManager("add");
	
	roiManager("select", roiManager("count")-1);
	roiManager("rename", "Region "+regId+1);
}

// Dialog box asking the user to draw longitudinal region
function drawLongitudinalRegion(longId, crossedVerticalRegionsName) {
	setTool("Rectangle");
	run("Select None");
	Dialog.createNonBlocking("");
	Dialog.addMessage("Draw rectangle representing longitudinal region "+longId+1);
	Dialog.addMessage("It should cross "+String.join(crossedVerticalRegionsName));
	Dialog.show();
	roiManager("add");
	roiManager("Select", roiManager("count")-1);
	roiManager("rename", "Region longitudinal "+longId+1);
	
	// Check that longitudinal region is symmetric with respect to X-axis
	List.setMeasurements;
	centroidY = List.getValue("Y");
	run("Translate... ", "x=0 y="+drawingHeightPix/2 - centroidY);
}

// Subtract longitudinal region from vertical regions it crosses
function subtractLongFromVertRegions(longId, crossedVerticalRegionsBool) {
	for (i = 0; i < crossedVerticalRegionsBool.length; i++) {
		
		regId = RoiManager.getIndex("Region "+i+1);
		longRegId = RoiManager.getIndex("Region longitudinal "+longId+1);
		ids = newArray(regId, longRegId);
		
		// Create intersection of vertical region and longitudinal region
		roiManager("Select", ids);
		roiManager("AND");
		
		if(getValue("selection.size") != 0) {
			roiManager("Add");
			
			if(crossedVerticalRegionsBool[i]) {
				// Subtract obtained ROI from vertical region
				ids[1] = roiManager("count")-1;
				roiManager("Select", ids);
				roiManager("XOR");
				roiManager("Add");
				
				// Delete old full vertical region
				roiManager("Select", regId);
				roiManager("delete");
				roiManager("Select", roiManager("count")-1);
				roiManager("rename", "Region "+i+1);
			} else {
				// Subtract obtained ROI from longitudinal region		
				ids[0] = roiManager("count")-1;
				roiManager("Select", ids);
				roiManager("XOR");
				roiManager("Add");
				
				// Delete old full longitudinal region
				roiManager("Select", ids);
				roiManager("delete");
				roiManager("Select", roiManager("count")-1);
				roiManager("rename", "Region longitudinal "+longId+1);
			}
		}
	}
}

// Draw region with appropriate pattern, background color and pattern color
function drawPattern(roiID, imageID, patternRegion, colorLabelBgRegion, colorLabelPatternRegion) {
	// Retrieve which colors the user chose for background and pattern
	colorHexaBgRegion = "";
	colorHexaPatternRegion = "";
	for (i = 0; i < colorsLabel.length; i++) {
		if (colorLabelBgRegion == colorsLabel[i]){
			colorHexaBgRegion = colorsHexa[i];
		}
		if (colorLabelPatternRegion == colorsLabel[i]){		
			colorHexaPatternRegion = colorsHexa[i];			
		}
	}
	
	if (patternRegion == patternsTypes[0]) {
		setColor(colorHexaBgRegion);
		run("Fill", "slice");
	} else {
		// Draw pattern with appropriate background and pattern colors on a new image, copy & paste it on the drawing
		setBatchMode(true);
		
		if (patternRegion == patternsTypes[1]) {
			newImage("bars", "RGB black", drawingWidthPix, drawingHeightPix, 1);
			
			// Color background
			Color.setBackground(colorHexaBgRegion);
			run("Select All");
			run("Clear", "slice");
			
			// Draw and color pattern
			spacing = drawingWidthPix/15;
			size = spacing/3;
			for (i = 0; i < spacing; i++) {
				run("Specify...", "width="+size+" height="+drawingWidthPix+" x="+size+i*spacing+" y=0");
				setColor(colorHexaPatternRegion);
				run("Fill", "slice");
			}
			
		} else if (patternRegion == patternsTypes[2]) {
			newImage("scales", "RGB black", drawingWidthPix, drawingHeightPix/2, 1);
			
			// Color background
			Color.setBackground(colorHexaBgRegion);
			run("Select All");
			run("Clear", "slice");
			
			// Draw and color pattern
			spacing = drawingWidthPix/15;
			size = spacing/4;
			run("Specify...", "width="+size+" height="+drawingHeightPix+" x=-"+4*spacing+" y=-"+drawingHeightPix/4);
			run("Rotate...", " angle=45");
			for (i = 0; i < 4*drawingWidthPix/spacing; i++) {
				run("Translate... ", "x="+spacing+" y=0");
				setColor(colorHexaPatternRegion);
				run("Fill", "slice");
			}
			run("Select None");
			run("Duplicate...", " ");
			run("Flip Vertically");
			run("Images to Stack", "  title=scales");
			run("Make Montage...", "columns=1 rows=2 scale=1");
			close("Stack");
			
		} else if (patternRegion == patternsTypes[3]) {
			newImage("spots", "RGB black", drawingWidthPix, drawingHeightPix, 1);
			
			// Color background
			Color.setBackground(colorHexaBgRegion);
			run("Select All");
			run("Clear", "slice");	
			
			// Draw and color pattern
			spacing = (drawingWidthPix+drawingHeightPix)/20;
			size = spacing/2;
			for (i = 0; i < drawingWidthPix/spacing; i++) {
				for (j = 0; j < drawingHeightPix/spacing; j++) {
					if(i%2 == 0) {
						run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+j*spacing+" oval");
					} else {
						run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+size+j*spacing+" oval");
					}				
					setColor(colorHexaPatternRegion);
					run("Fill", "slice");									
				}
			}
		}
		
		// Copy and paste pattern on drawing 
		roiManager("select", roiID);
		run("Copy");
		run("Close");
		selectImage(imageID);	
		run("Paste");
		
		setBatchMode(false);	
	}
}

/////////////////////////////////////////
