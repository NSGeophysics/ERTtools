## INPUT:
# 1) table filename
# 2) name for output figure
# 3) min colorbar value [default: min of apparent resistivitites]
# 4) max colorbar value [default: max of apparent resistivitites]
# 5) Width in cm [default: 17 cm]

## Description of input file
# First column: x positions (centers) of the boxes
# Second column: y positions (centers) of the boxes.
# Third column: Resistivity values
# Fourth column: Box width
# Fifth column: Box height
#
# Comment: Make box height, width, and y position such that the aspect ratios
# of the boxes look nice. 

### The first part is defining variables and using awk et al

## Also, set these variables if you like

if [ -z $5 ]
then
    width=17c
else
    width=$5c
fi

GMT set PS_MEDIA A0

height=5c
#col=polar
#col=jet
col=ColourMapSuite/lajolla/lajolla.cpt
#col=ColourMapSuite/davos/davos.cpt

## Calculating the max and min x and y
# For min x position and max x position, we want tosubtract and add the rectangle width
minX=$(sort -k1 -n $1 | head -n1 | awk '{print $1 - $4}')
maxX=$(sort -k1 -n $1 | tail -1 | awk '{print $1 + $4}')

#minY=$(sort -k2 -n $1 | head -n1 | awk '{print $2 - $5}')
minY=0
# For the max y we add 1 to not cut off the bottom rectangle
maxY=$(sort -k2 -n $1 | tail -1 | awk '{print $2 +1}')

if [ -z $3 ]
then
   minR=$(sort -k3 -n $1 | head -n1 | awk '{print $3}')
   maxR=$(sort -k3 -n $1 | tail -1 | awk '{print $3}')
else
    minR=$3
    maxR=$4
fi

#height=$(echo ${maxY} - ${minY} | bc)c



### Now comes the GMT part
## Make a color scheme.
# The -Q makes a logarithmically interpolated color scheme
gmt makecpt -C$col -I -T${minR}/${maxR}/3 -D -Qo -Z > col.cpt

## Plot the rectangles
gmt psxy $1 -Ccol.cpt -JX$width/-$height -R${minX}/${maxX}/${minY}/${maxY} -Bx1+l"electrode number" -By1 -BN  -Sr -W -K > $2

## Plot the color bar
gmt psscale -Dx0c/-0.5c+w${width}/0.4c+h+e -Bx+l"apparent resistivity [@~W@~m]" -Ccol.cpt -O >> $2 

gmt psconvert -A0.1c -Tf -P $2



## Remove intermediate files
rm col.cpt
rm gmt.history
rm $2
