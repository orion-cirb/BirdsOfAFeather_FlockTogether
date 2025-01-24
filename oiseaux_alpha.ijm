
// Retrieve list of orders
orders_families = Table.open("/Users/thomas/Downloads/orders_families.csv");
orders = split(Table.headings, "\t");
close("orders_families.csv");

// Dialog box to get order
Dialog.create("Select order");
Dialog.addChoice("Order:", orders, orders[0]);
Dialog.show();
order = Dialog.getChoice();

// Retrieve list of families for selected order
orders_families = Table.open("/Users/thomas/Downloads/orders_families.csv");
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


run("Select None");
roiManager("reset");
setOption("Show All",false);

setTool("line");
Dialog.createNonBlocking("");
Dialog.addMessage(" Tracer une ligne de 1 cm ", 20, "black");
Dialog.show();
getLine(x1, y1, x2, y2, lineWidth);
calibration(x1,y1,x2,y2);


setTool("multipoint");
Dialog.createNonBlocking("");
Dialog.addMessage("Placer vos points", 20, "black");
Dialog.show();


getSelectionCoordinates(xpoints, ypoints);


Array.getStatistics(xpoints,x_min,x_max,mean,stdDev);
Array.getStatistics(ypoints,y_min,y_max,mean,stdDev);


makeRectangle(x_min, y_min,(x_max)-(x_min),(y_max)-(y_min));

run("Duplicate...", " ");
close("\\Others");


items = newArray(2);
items[0] = "oui";
items[1] = "non";
sizeX = 50 ;
imageID = getImageID();
height = getHeight();
widthOri = getWidth();
colorMotif = newArray(30);
colorFond = newArray(30);

Dialog.createNonBlocking("");

Dialog.addNumber("nombre de frontière verticales", 0);

Dialog.show();

nbVerti = Dialog.getNumber(); 

type = newArray("Droite","U","U inverse","V","V inverse");
motifs = newArray("barres","ecailles","taches","uniforme");

	Dialog.create("");
	Dialog.addMessage(" type de frontière verticale : ", 20, "black");
for (i = 0; i < nbVerti; i++) {
	if (i == 0) {
		
		Dialog.addChoice(" "+(i+1)+" ère frontière", type)
	} 	else {
			
			Dialog.addChoice(" "+(i+1)+" ème frontière", type)
		}
}

Dialog.show();
choosen = newArray(nbVerti);


height = getHeight();
width = getWidth();

imageID = getImageID();
close("\\Others");

for (j = 0; j < nbVerti; j++) {
choosen[j] = Dialog.getChoice();
}

makeLine(0, 0,0, height);
roiManager("add");

for (k = 0; k < nbVerti; k++) {	

 if (choosen [k] == "Droite") {
  makeLine((sizeX*(k+1)),0,(sizeX*(k+1)),height);
  makeFrontier(k);
 }
 if (choosen [k] == "U" || choosen [k] == "U inverse") {
  makeLine((sizeX*j),0,(sizeX*j+50),(height/3),(sizeX*j+50),(height/1.5),(sizeX*j),height);
   makeFrontier(k);
 }
 if (choosen [k] == "V" || choosen [k] == "V inverse") {
  makeLine((sizeX*j),0,(sizeX*j+50),(height/2),(sizeX*j),height);	
   makeFrontier(k);
 }
}

makeLine(width-1, 0,width-1, height);
roiManager("add");




roiSize = roiManager("count")-1 ;

for (l = 0; l <roiSize ; l++) {
	roiManager("select", l);
	roi = Roi.getCoordinates(xpoints, ypoints);
	sizeY = lengthOf(ypoints);

	if (sizeY == 4) {
		xpoints[1] = xpoints[2];
		xpoints[2] = xpoints[2];
		ypoints[1] = (height/3);
		ypoints[2] = (height/1.5);
	}
	if (sizeY == 3) {
		ypoints[1] = (height/2);
	}
	ypoints[0] = 0;
	ypoints[(sizeY-1)] = height;
	
	
		xpoints [0] = (xpoints[(sizeY-1)] + xpoints[0]) /2;
		xpoints[(sizeY-1)] =  xpoints[0];		
	
	Array.reverse(xpoints);
	Array.reverse(ypoints);
	
	roiManager("select", l+1);

	roi2 = Roi.getCoordinates(xpoints2, ypoints2);
	sizeY2 = lengthOf(ypoints2);
	if (sizeY2 == 4) {
		xpoints2[1] = xpoints2[2];
		xpoints2[2] = xpoints2[2];
		ypoints2[1] = (height/3);
		ypoints2[2] = (height/1.5);
	}
	if (sizeY2 == 3) {
		ypoints2[1] = (height/2);
	}
	ypoints2[0] = 0;
	ypoints2[(sizeY2-1)] = height;	
	
		xpoints2[0] = (xpoints2[(sizeY2-1)] + xpoints2[0])/2;
		xpoints2[(sizeY2-1)] =  xpoints2[0];		
	
	X = Array.concat(xpoints,xpoints2);
	Y = Array.concat(ypoints,ypoints2);
	borderDot(Y,X,l);
	roiManager("select", l);
	roiManager("rename", "region " + (l+1));
}

roiArray = newArray(roiSize);
for (m = 0; m < (roiSize+1); m++) {
	roiArray [m] = m;
}

roiManager("select",roiArray);
roiManager("delete");

choosenLong = newArray(nbVerti+1);
renameROI(choosenLong,roiSize);


setOption("Show All",true);
Dialog.createNonBlocking("");
Dialog.addMessage("frontière longitudinale : ", 20, "black");
for (i = 0; i < (nbVerti+1); i++) {
	if (i == 0) {
		
		Dialog.addRadioButtonGroup(" "+(i+1)+" ère région", items,1,2,"non")
	} 	else {
			
			Dialog.addRadioButtonGroup(" "+(i+1)+" ème région", items,1,2,"non")
		}
}
Dialog.show();

for (j = 0; j < nbVerti+1; j++) {
choosenLong[j] = Dialog.getRadioButton();
}
for (k= 0; k < nbVerti+1; k++){
	if (choosenLong[k] == "oui") {
		longi(k);
	}
}

regionOfInterest(choosenLong,roiSize);

run("Select None");
run("Scale...", "x=- y=- width=500 height=250 interpolation=Bilinear average create");
RoiManager.scale(500/width,250/height,false)
close("\\Others");
imageID = getImageID();
height = getHeight();
width = getWidth();
run("RGB Color");
roiManager("sort");

motifRegion = newArray(roiManager("count")-1);
couleurMotif = newArray(roiManager("count")-1);
couleurFond = newArray(roiManager("count")-1);
	array = newArray(7*6);
colorArray(array);

	
for (i = 0; i <= (roiManager("count")-1); i++) {

		
	if (i == 0) {
		roiManager("select", i);
		roiName = Roi.getName;
		Dialog.createNonBlocking("");
		Dialog.addMessage("motif de la "+roiName+":                                         ", 20, "black");	
		
		Dialog.addRadioButtonGroup("motif :", motifs,1,4,"uniforme");
		Dialog.addRadioButtonGroup("couleur motif:", array, 6 , 7,0);
		Dialog.addToSameRow();
		Dialog.addRadioButtonGroup("couleur fond:", array, 6 , 7,0);
		Dialog.show();
		motifRegion[i] = Dialog.getRadioButton();
		couleurMotif[i] = Dialog.getRadioButton();
		couleurFond[i] = Dialog.getRadioButton();
		
		
	} 	else {
		roiManager("select", i);	
		roiName = Roi.getName;
		Dialog.createNonBlocking("");
		Dialog.addMessage("motif de la "+ roiName +"                                         ", 20, "black");	
		
		Dialog.addRadioButtonGroup("motif :", motifs,1,4,"uniforme")
		Dialog.addRadioButtonGroup("couleur motif :", array, 6 , 7,0);
		Dialog.addToSameRow();
		Dialog.addRadioButtonGroup("couleur fond :", array, 6 , 7,0);
		
		Dialog.show();
		motifRegion[i] = Dialog.getRadioButton();
		couleurMotif[i] = Dialog.getRadioButton();
		couleurFond[i] = Dialog.getRadioButton();
		
		}	
}


couleurArray = newArray("#de8f88","#e1d9d6","#f5dbca","#f3f3f1","#0196b4","#e48831","#68c9b6","#dfrc370","#d3ddd4","#e0c099","#e7e5e5","#ce64a6","#5369b4","#9293c3","#8bc08a","#dbdadf","#cfa573","#c3c5c2","#fdda0c","#d56776","#916950","#5bb2c6","#584c4c","#9f7251","#9a9a98","#c63949","#6e4d7c","#668aac","#7fa4d0","#49534b","5a4b44","#777976","#11a253","#aecb4d","#d3a492","#cc89aa","#4c4e5a","#4b4b4d","#4f4f4f","#3449a2","#f3ad33","#815d4d");


motif(motifRegion,imageID,width,height,array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond);


//Colormap(array,couleurMotif,couleurFond,couleurArray);

  /////////////////////////////////
  ////////////////////////////////
  ///////// Functions ///////////
  //////////////////////////////
  /////////////////////////////
 
 
 function calibration (x1,y1,x2,y2) {
 	length = abs(x1-x2);
 	run("Set Scale...", "distance="+length+" known=10 unit=mm");
 }  
 
function makeFrontier(k) { 
	roiManager("add");
	Dialog.createNonBlocking("");
	Dialog.addMessage(" Déplacer les points", 20, "black");
	Dialog.show();
	roiManager("add");
	roiManager("Select",(roiManager("count")-1));
	roiManager("select", k+1);
	roiManager("delete");
}

function borderDot (Y,X,l) {
	makeSelection("polygon", X, Y);
	roiManager("add");		
}

function renameROI (choosenLong,roiSize) {
	for (o = 0; o < roiSize ; o++) {
		roiManager("select", o);
		roiManager("rename", "region " + o+1);
	}
}

function regionOfInterest (choosenLong,roiSize){
	for (o = 0; o < roiSize ; o++) {
		if (choosenLong[o] == "oui") {	
			name = RoiManager.getIndex("region " +(o+1));
			longName = RoiManager.getIndex("region " + (o+1)+ " longitudinale");
			cross = newArray(2);
			cross [0] = name;
			cross [1] = longName;
			roiManager("Select",(roiManager("count")-1));
			
		
			roiManager("Select",cross);
			roiManager("AND");
			//roiManager("Select",(roiManager("count")-1));
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




function longi(k){
	

	setTool("Rectangle");
	run("Select None");
	Dialog.createNonBlocking("");
	Dialog.addMessage(" Tracer le rectangle longitudinale", 20, "black");
	Dialog.show();
	roiManager("add");
	roiManager("Select",(roiManager("count")-1));
	roiManager("rename", "region " + (k+1)+" longitudinale");
	
}

function Colormap(array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond) {
	for (a = 0; a < roiManager("count"); a++) {

		
		for (b = 0; b < 42; b++) {
		
			if (array [b] == couleurMotif [a]){
				
				colorMotif [a] = couleurArray [b];
					
				
			}
			if (array [b] == couleurFond [a]){
				colorFond [a] = couleurArray [b];
			}
		
		}
	}
}

function motif(motifRegion,imageID,width,height,array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond) {
	for (o = 0; o <= (roiManager("count")-1) ; o++) {
		roiManager("select", o);
		Colormap(array,couleurMotif,couleurFond,couleurArray,colorMotif,colorFond);
		if (motifRegion[o] == "uniforme") {
			setColor(colorMotif[o]);
			run("Fill", "slice");
			continue;
		}
		
		if (motifRegion[o] == "barres") {
			roiManager("add");
			
			
			setBatchMode(true);
			spacing = 500/15;
			size = spacing/3;
			newImage("bars", "RGB black", 500, 250, 1);
			Color.setBackground(colorFond [o]);
			run("Select All");
			run("Clear", "slice");
			for (i = 0; i < spacing; i++) {
				run("Specify...", "width="+size+" height="+500+" x="+size+i*spacing+" y=0");
				setColor(colorMotif[o]);
				run("Fill", "slice");
			}
			applyMotif(imageID);
			
			setBatchMode(false);	
		}
		
		if (motifRegion[o] == "ecailles") {
			roiManager("add");
			setBatchMode(true);
			spacing = 500/15;
			size = spacing/4;
			newImage("scales", "RGB black", width, height/2, 1);
			Color.setBackground(colorFond [o]);
			run("Select All");
			run("Clear", "slice");
			run("Specify...", "width="+size+" height="+height+" x=-"+4*spacing+" y=-"+height/4);
			run("Rotate...", " angle=45");
			for (i = 0; i < 4*width/spacing; i++) {
				run("Translate... ", "x="+spacing+" y=0");
				setColor(colorMotif[o]);
				run("Fill", "slice");
			}
			run("Select None");
			run("Duplicate...", " ");
			run("Flip Vertically");
			run("Images to Stack", "  title=scales");
			run("Make Montage...", "columns=1 rows=2 scale=1");
			rename("scales");
			close("Stack");
			run("Tile");
			applyMotif(imageID);
			setBatchMode(false);
			
		}
		
		if (motifRegion[o] == "taches") {
			
			roiManager("add");
			setBatchMode(true);
			spacing = (width+height)/20;
			size = spacing/2;
			newImage("spots", "RGB black", width, height, 1);
			Color.setBackground(colorFond [o]);
			run("Select All");
			run("Clear", "slice");
			
			for (i = 0; i < width/spacing; i++) {
				for (j = 0; j < height/spacing; j++) {
					if(i%2 == 0) {
						run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+j*spacing+" oval");
					} else {
						run("Specify...", "width="+size+" height="+size+" x="+i*spacing+" y="+size+j*spacing+" oval");
					}				
					setColor(colorMotif[o]);
					run("Fill", "slice");									
				}
			}
			applyMotif(imageID);
			setBatchMode(false);	
			
		}
	}
}

function colorArray (array) {

	index =0;
	letters = "ABCDFGH"
	for (j = 1; j <= 6; j++) {
		
		for (i = 0; i < 7; i++) {
			letter = substring(letters, i, i+1);	
			array[index] = letter + (j);
			index++;
			
		}	
	}	
}
	


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

