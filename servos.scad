/**
 * Servo outline library
 * all servos should have their z=0 at the botton and x=y=0 at the turning axis
 * the older ones might have different positions  
 *
 * Authors:
 *   - Eero 'rambo' af Heurlin 2010-
 *   - 2025 klkl added generic servo generator and servo holder generator
 *
 * License: LGPL 2.1
 */

use <triangles.scad>

// Tests:
if(1){
    // generic models
    servo(position=[0,0,0],rotation=[0,0,0],model="sg90",armAngle=90);
    servoHolder(position=[0,0,0],rotation=[0,0,0],model="sg90");

    translate([0,40,0]){
        servo(model="s3003",armAngle=90);
        servoHolder(model="s3003",clipH=20);
    }
    
    //servoArm(armLen=20,armAngle=90);

    // exactly described models kept for older designs
    translate([-30,0,0])alignds420(screws=1);
    translate([-50,0,0])towerprosg90(rotation=[0,0,90]);
    translate([-70+20.1/2,30,0])futabas3003(position=[0,0,0],rotation=[0,0,180]);
}

/**
 * generic servo generator
 *
 * @param string the name of the servo model
 *
 * returns an array with the specific servo dimensions
 * [0] size of the main box
 * [1] size of one ear (for fixing the device)
 * [2] z position lower side of ear
 * [3] x/z of the axis top
 */
function servoDimensions(model)=
    (model == "sg90")   ? [[23, 12.5, 22.5], [4.7, 11.8, 2.5], 15.4, [6,29.6]]:
    (model == "s3003")  ? [[39.9, 20.1, 36.1], [7.6, 18, 2.5], 26.6, [10,41]]:
// new servos could easily been added here
    [undef,[undef,undef,undef],undef,[undef,undef]]; // this is the default
    
/**
 * generic servo generator
 *
 * @param vector position The position vector
 * @param vector rotation The rotation vector
 * @param string the name of the servo model as defined in servoDimensions
 * @param number armAngle generates a servo arm, 180 is showing in servo-direction
 * @param number armlen the length of the servo arm
 */
module servo(position=undef, rotation=undef, model, armAngle=undef, armlen=20){
    dim  = servoDimensions(model)[0];
    ear  = servoDimensions(model)[1];
    earZ = servoDimensions(model)[2];
    axis = servoDimensions(model)[3];
    if(dim!=undef){
        translate(position!=undef?position:[0,0,0]) rotate(rotation!=undef?rotation:[0,0,0]){
            translate([-axis[0],-dim.y/2,0]){
                color("grey"){
                    cube(dim);
                    translate([-ear.x,(dim.y-ear.y)/2,earZ])
                        cube([dim.x+2*ear.x,ear.y,ear.z]);
                }
                translate([axis[0],dim.y/2,0]){
                    color("grey")cylinder(h=dim.z+2,d=10,$fn=30);
                    color("white")cylinder(h=axis[1],d=4,$fn=20);
                }
            }
            if(armAngle!=undef){
                translate([0,0,axis[1]])servoArm(armlen,armAngle);
            }
        }
    }
}

/**
 * generic servo holder generator
 *
 * @param vector position The position vector
 * @param vector rotation The rotation vector
 * @param string the name of the servo model as defined in servoDimensions
 * @param number clipH could be increased to generate more force for holding
 */
module servoHolder(position=undef, rotation=undef, model, clipH=15.5){
    dim  = servoDimensions(model)[0];
    ear  = servoDimensions(model)[1];
    earZ = servoDimensions(model)[2];
    axis = servoDimensions(model)[3];
    space = .3;
    t = 3;              // thickness of back and springs
    height = dim.z;     // the holder should be as high as the servo
    noseY = 3.3;        // a little bit of tension, was 3.5
    translate(position!=undef?position:[0,0,0]) rotate(rotation!=undef?rotation:[0,0,0]){
        translate([axis[0]-space,0,0])difference(){
            union(){
                // long side
                translate([-dim.x/2-space,dim.y/2+space,0])
                    cube([dim.x+2*space,t,height]);
                // short sides (the gap comes later)
                seiteY = dim.y+t+space+noseY-1; // a little shorter to get some tension
                for(x=[-dim.x/2-t-space, dim.x/2+space]){
                    translate([x,-dim.y/2-noseY+1,dim.z-clipH]) cube([t,seiteY,clipH]);
                }
                // the holding noses
                t2=t*.9;   // was 1.1
                for(x=[dim.x/2+space,-dim.x/2-space]){
                    //Y jetzt 1mm kuerzer (+1)
                    translate([x,-dim.y/2-noseY+1,dim.z-clipH])
                        rotate([0,0,45]) cube([t2,t2,clipH]);
                }
            }
            // the gap for holding the ears of the servo
            gapZ = ear.z+space;
            gapY = dim.y+noseY+.1;
            totalX = dim.x+2*space+2*t;
            translate([-totalX/2-.1,-gapY+dim.y/2,earZ])
                cube([totalX+.2,gapY,gapZ]);
        }
    }
}

module servoArm(armLen,armAngle){
    armD = 3;
    dhFix = 2;  // the part sitting over the servo axis
    rAchse = 4;
    rEnde = 2;
    drehachseR = 2.35;
    translate([0,0,0])rotate([0,0,armAngle]){
        difference(){
            color("white")union(){
                translate([0,0,-dhFix]) cylinder(r=rAchse, h=armD+dhFix, $fn=25);
                linear_extrude(height = armD, convexity = 10)
                    polygon(points=[[0,rAchse],[0,-rAchse],[armLen,rEnde],[armLen,-rEnde]]
                        , paths=[[0,1,3,2]]);
                translate([armLen,0,0]) cylinder(r=rEnde, h=armD, $fn=20);
            }
            // the axis
            translate([0,0,-dhFix-.1]) cylinder(r=drehachseR, h=dhFix, $fn=20);
            translate([0,0,-.2]) cylinder(d=2.5, h=armD+.3, $fn=20);
            // the hole for ataching the lever rod
            translate([armLen,0,-.1]) cylinder(d=1.5, h=armD+.2, $fn=20);
        }
    }
}

/**
 * TowerPro SG90 servo
 *
 * @param vector position The position vector
 * @param vector rotation The rotation vector
 * @param boolean screws If defined then "screws" will be added and when the module is differenced() from something if will have holes for the screws
 * @param boolean cables If defined then "cables" output will be added and when the module is differenced() from something if will have holes for the cables output
 * @param number axle_length If defined this will draw a red indicator for the main axle
 */
module towerprosg90(position=undef, rotation=undef, screws = 0, axle_length = 0, cables=0)
{
    translate(position!=undef?position:[0,0,0]) rotate(rotation!=undef?rotation:[0,0,0]){
        difference(){
            union(){
                translate([-5.9,-11.8/2,0]) cube([22.5,11.8,22.7]);
                translate([0,0,22.7-0.1]){
                    cylinder(d=11.8,h=4+0.1);
                    hull(){
                        translate([8.8-5/2,0,0]) cylinder(d=5,h=4+0.1);
                        cylinder(d=5,h=4+0.1);
                    }
                    translate([0,0,4]) cylinder(d=4.6,h=3.2);
                }
                translate([-4.7-5.9,-11.8/2,15.9]) cube([22.5+4.7*2, 11.8, 2.5]); 
            }
            //screw holes
            translate([-2.3-5.9,0,15.9+1.25]) cylinder(d=2,h=5, center=true);
            translate([-2.3-5.9-2,0,15.9+1.25]) cube([3,1.3,5], center=true);
            translate([2.3+22.5-5.9,0,15.9+1.25]) cylinder(d=2,h=5, center=true);
            translate([2.3+22.5-5.9+2,0,15.9+1.25]) cube([3,1.3,5], center=true);
        }
        if (axle_length > 0) {
            color("red", 0.3) translate([0,0,29.9/2]) cylinder(r=1, h=29.9+axle_length, center=true);
        }
        if (cables > 0) color("red", 0.3) translate([-12.4,-1.8,4.5]) cube([10,3.6,1.2]);
        if(screws > 0) color("red", 0.3) {
            translate([-2.3-5.9,0,15.9+1.25]) cylinder(d=2,h=10, center=true);
            translate([2.3+22.5-5.9,0,15.9+1.25]) cylinder(d=2,h=10, center=true);
        }
    }
    
}

/**
 * Align DS420 digital servo
 * https://servodatabase.com/servo/align/ds420#google_vignette
 *
 * @param vector position The position vector
 * @param vector rotation The rotation vector
 * @param boolean screws If defined then "screws" will be added and when the module is differenced() from something if will have holes for the screws
 * @param number axle_lenght If defined this will draw "backgound" indicator for the main axle
 */
module alignds420(position, rotation, screws = 0, axle_lenght = 0)
{
	translate(position!=undef?position:[0,0,0]) rotate(rotation!=undef?rotation:[0,0,0]){
        union(){
            // Main axle
            translate([0,0,17]){
                cylinder(r=6, h=8, $fn=30);
                cylinder(r=2.5, h=10.5, $fn=20);
            }
            // Box and ears
            translate([-6,-6,0]){
                cube([12, 22.8,19.5]);
                translate([0,-5, 17]){
                    cube([12, 7, 2.5]);
                }
                translate([0, 20.8, 17]){
                    cube([12, 7, 2.5]);
                }
            }
            if (screws > 0){
                translate([0,(-10.2 + 1.8),11.5]){
                    #cylinder(r=1.8/2, h=6, $fn=6);
                }
                translate([0,(21.0 - 1.8),11.5]){
                    #cylinder(r=1.8/2, h=6, $fn=6);
                }

            }
            // The large slope
            translate([-6,0,19])rotate([90,0,90]){
                triangle(4, 18, 12);
            }

            /**
             * This seems to get too complex fast
            // Small additional axes
            translate([0,6,17]){
                cylinder(r=2.5, h=6, $fn=10);
                cylinder(r=1.25, h=8, $fn=10);
            }
            // Small slope
            difference(){
                translate([-6,-6,19.0]){
                    cube([12,6.5,4]);
                }
                translate([7,-7,24.0]){
                    rotate([-90,0,90]){
                        triangle(3, 8, 14);
                    }
                }
            }
            */
            // So we render a cube instead of the small slope on a cube
            translate([-6,-6,19.0]){
                cube([12,6.5,4]);
            }
        }
        if (axle_lenght > 0){
            % cylinder(r=0.9, h=axle_lenght, center=true, $fn=8);
        }
    }
}
module test_alignds420(){alignds420(screws=1);}

/**
 * Futaba S3003 servo
 * https://servodatabase.com/servo/futaba/s3003
 *
 * @param vector position The position vector
 * @param vector rotation The rotation vector
 */
module futabas3003(position=undef, rotation=undef)
{
    translate(position!=undef?position:[0,0,0]) rotate(rotation!=undef?rotation:[0,0,0]){
        mainBox = [20.1, 39.9, 36.1];
        union(){
            // Box and ears
            cube(mainBox);
            oneEar = [18, 7.6, 2.5];
            translate([(mainBox.x-oneEar.x)/2, 0, 26.6]){
                difference(){
                    translate([0,-oneEar.y,0])cube([oneEar.x, mainBox.y+2*oneEar.y, oneEar.z]);
                    // mounting holes
                    for(pos=[[4, 3.5-oneEar.y],[14,3.5-oneEar.y]
                        ,[4,mainBox.y+oneEar.y-3],[14,mainBox.y+oneEar.y-3]])
                    {
                        translate([pos.x, pos.y, -.1]) cylinder(h=oneEar.z+.2, r=2, $fn=20);
                    }
                }
            }
            // Main axle
            translate([10, 30, 36.1]){
                cylinder(r=6, h=0.4, $fn=30);
                cylinder(r=2.5, h=4.9, $fn=20);
            }
        }
	}
}