/*
  This is a firmata-based arduinoscope.
  
  (c) 2009 David Konsumer <david.konsumer@gmail.com>
  
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General
  Public License along with this library; if not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330,
  Boston, MA  02111-1307  USA
 */

/*

You need to install firmata on your arduino for this sketch to work.

*/

import arduinoscope.*;
import processing.serial.*;
import cc.arduino.*;

// this example requires controlP5

// http://www.sojamo.de/libraries/controlP5/
import controlP5.*;


// how many scopes, you decide.
Oscilloscope[] scopes = new Oscilloscope[4];
ControlP5 controlP5;
Arduino arduino;

PFont fontLarge;
PFont fontSmall;

void setup() {
  size(1200, 800, P2D);
  background(0);
  
  arduino = new Arduino(this, Arduino.list()[5], 115200);
  
  
  controlP5 = new ControlP5(this);
  
  // set these up under tools/create font, if they are not setup.
  fontLarge = loadFont("TrebuchetMS-20.vlw");
  fontSmall = loadFont("Uni0554-8.vlw");
  
  int[] dimv = new int[2];
  dimv[0] = width-130; // 130 margin for text
  dimv[1] = height/scopes.length;
  
  
  for (int i=0;i<scopes.length;i++){
    arduino.pinMode(i, Arduino.INPUT);
    int[] posv = new int[2];
    posv[0]=0;
    posv[1]=dimv[1]*i;

    // random color, that will look nice and be visible
    scopes[i] = new Oscilloscope(this, posv, dimv);
    scopes[i].setLine_color(color((int)random(255), (int)random(127)+127, 255));
    
    
    controlP5.addButton("pause",1,dimv[0]+10,posv[1]+10,32,20).setId(i);
    controlP5.addButton("logic",1,dimv[0]+52,posv[1]+10,29,20).setId(i+50);
    controlP5.addButton("save",1,dimv[0]+92,posv[1]+10,29,20).setId(i+100);
  }
  
}

void draw()
{
  background(0);
  
  for (int i=0;i<scopes.length;i++){
    // update and draw scopes

    scopes[i].addData(arduino.analogRead(i));
    scopes[i].draw();
    w
    
    // conversion multiplier for voltage
    float multiplier = scopes[i].getMultiplier()/scopes[i].getResolution();
    
    // convert arduino vals to voltage
    float minval = scopes[i].getMinval() * multiplier;
    float maxval = scopes[i].getMaxval() * multiplier;
    int[] values = scopes[i].getValues(); 
    float pinval =  values[values.length-1] * multiplier;
    
    // add lines
    scopes[i].drawBounds();
    stroke(255);
    
    int[] pos = scopes[i].getPos();
    int[] dim = scopes[i].getDim();
    
    line(0, pos[1], width, pos[1]);
    
    // add labels
    fill(255);
    textFont(fontLarge);
    text(pinval, width-60, pos[1] + dim[1] - 10);
    
    textFont(fontSmall);
    text("min: " + minval, dim[0] + 10, pos[1] + 40);
    text("max: " + maxval, dim[0] + 10, pos[1] + 48);
    
    fill(scopes[i].getLine_color());
    text("pin: " + i, dim[0] + 10,pos[1] + dim[1] - 10);
  }
  
  // draw text seperator, based on first scope
  int[] dim = scopes[0].getDim();
  stroke(255);
  line(dim[0], 0, dim[0], height);
  
  // update buttons
  controlP5.draw();
  
}

// handles button clicks
void controlEvent(ControlEvent theEvent) {
  int id = theEvent.controller().id();
  
  // button families are in chunks of 50 to avoid collisions
  if (id < 50){
    scopes[id].setPause(!scopes[id].isPause());
  }else if (id < 100){
    scopes[id-50].setLogicMode(!scopes[id-50].isLogicMode());
  }else if(id < 150){
    String fname = "data"+(id-100)+".csv";
    scopes[id-100].saveData(fname);
    println("Saved as "+fname);
  }
}


//handles data to file
void exportPoints2Text(){
  OUTPUT = createWriter("exportedPoints.txt");
  for(int i = 0; i < pointList.size(); ++i){        
    PVector V = (PVector) pointList.get(i);
    OUTPUT.println(V.x + "" + V.y + "," + V.z);  // here we export the coordinates of the vector using String concatenation!
  }
  OUTPUT.flush();
  OUTPUT.close();
  println("points have been exported");
}





