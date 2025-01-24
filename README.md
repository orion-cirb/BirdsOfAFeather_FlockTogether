# BirdsOfAFeather_FlockTogether

* **Developed by:** Thomas & Héloïse
* **Developed for:** Manceau Lab
* **Team:** Manceau
* **Date:** January 2025
* **Software:** Fiji


### Images description

Flat birds RGB images, a ruler is needed on the image for calibration.

     
### Macro description

* Open a .csv table with birds Order as the column header and the associated families below
* Dialog box pops up and user selects Order, Families, Genus, Species, Subspecies, Sex and Experimenter
* User must draw a line to calibrate the image, make 6 points on the bird, specify the number of vertical boundaries
* A bounding box is created with the 6 points selected, and the user selects the type of boundaries (U,V,line)
* Create ROIs based on the boundaries, ask the user if there is a longitudinal bondary and where it is located
* Ask the user the pattern inside the ROI (Uniform, Scales, Bars, Spots) and the color of the pattern and background 


### Dependencies
csv file with Orders and Families

### Version history

Version 0.1 released on January 24, 2025.
