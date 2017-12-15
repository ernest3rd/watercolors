#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    cout << ofGetWidth() << ", " << ofGetHeight() << endl;
    
    // Enable accelerometer
    ofxAccelerometer.setup();
    
    img.allocate(WIDTH, HEIGHT, OF_IMAGE_COLOR);
    
    defaultColors[0].set(0);
    defaultColors[1].set(255);
    defaultColors[2].set(255,255,2);
    defaultColors[3].set(128,212,26);
    defaultColors[4].set(1,169,51);
    defaultColors[5].set(21,131,102);
    defaultColors[6].set(42,95,153);
    defaultColors[7].set(85,49,141);
    defaultColors[8].set(128,0,127);
    defaultColors[9].set(191,0,65);
    defaultColors[10].set(255,0,0);
    defaultColors[11].set(255,64,0);
    defaultColors[12].set(255,128,0);
    defaultColors[13].set(255,191,0);
    
    reset();
}

void ofApp::reset(){
    img.setColor(ofColor::white);
    currentLayer = 0;
    layers[currentLayer] = defaultColors[0];
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            pcolors[x][y] = currentLayer;
            pforce[x][y] = 0;
            pawake[x][y] = false;
        }
    }
}
    
//--------------------------------------------------------------
ofColor col;
ofVec3f acc3d;
ofVec2f acc2d;
float maxStrength;
void ofApp::update(){
    acc3d.set(ofxAccelerometer.getForce());
    acc2d.set(acc3d);
    
    maxStrength = 0;
    
    // Tilt direction
    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        neighbourStrength[i] = acc2d.angle(ofVec2f(neighbours[i][0], -neighbours[i][1])) / 360 * acc2d.length();
        
        neighbourStrength[i] = std::pow(neighbourStrength[i], 10);
        
        if(neighbourStrength[i] < 0){
            neighbourStrength[i] *= -1;
        }
        if(maxStrength < neighbourStrength[i]){
            maxStrength = neighbourStrength[i];
        }
    }
    
    // Wipe action
    if(acc3d.z > 0.9){
        if(!waitForWipe){
            waitForWipe = true;
            wipeTimer = 10;
        }
    }
    else if(waitForWipe){
        waitForWipe = false;
    }
    if(waitForWipe){
        wipeTimer--;
        if(wipeTimer == 0){
            ofxiOSAppDelegate * delegate = ofxiOSGetAppDelegate();
            ofxiOSScreenGrab(delegate);
            reset();
        }
    }
    
    // Pixel logic
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            if(!pawake[x][y]) {
                //img.setColor(x, y, defaultColors[0]);
                continue;
            }
            dryNeighbours(x, y);
            neighbour nb = hasNeighbours(x, y);
            if(pcolors[x][y] < nb.layer){
                phistory[x][y] = odd;
                pawake[x][y] = false;
                if(nb.force > 0 && nb.force < 2550){
                    pcolors[x][y] = nb.layer;
                    pforce[x][y] = nb.force;
                    col.setBrightness(nb.force);
                    col = img.getColor(x,y).getLerped(layers[nb.layer % NUM_LAYERS], nb.force/2550.0);
                    img.setColor(x, y, col);
                    wakeNeighbours(x, y);
                }
                else{
                    pforce[x][y] = 0;
                }
            }
        }
    }
    
    img.update();
    
    odd = !odd;
}

struct neighbour ofApp::hasNeighbours(int x, int y){
    int dx, dy, wx, wy;
    int layer, force;
    float strength = ofRandom(maxStrength) / acc2d.length();
    
    dx = dy = wx = wy = layer = force = 0;

    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        dx = neighbours[i][0];
        dy = neighbours[i][1];
        if(x+dx >= 0 && x+dx < WIDTH && y+dy >= 0 && y+dy < HEIGHT){
            if(phistory[x+dx][y+dy] != odd && pforce[x+dx][y+dy] > 0){
                if(ofRandom(100) > 97 || (pcolors[x+dx][y+dy] > pcolors[x][y] && neighbourStrength[i] > strength)){
                    force = pforce[x+dx][y+dy];
                    layer = pcolors[x+dx][y+dy];
                    wx = x+dx;
                    wy = y+dy;
                }
            }
        }
    }
    
    if(force > 0 && force < 2550){
        force += (int)ofRandom(4);
    }

    return neighbour {force, layer};
}

void ofApp::wakeNeighbours(int x, int y){
    wakeNeighbours(x, y, false);
}
void ofApp::wakeNeighbours(int x, int y, bool force){
    int dx, dy;
    int layer = pcolors[x][y];
    
    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        dx = neighbours[i][0];
        dy = neighbours[i][1];
        if(x+dx >= 0 && x+dx < WIDTH && y+dy >= 0 && y+dy < HEIGHT){
            if(pcolors[x+dx][y+dy] != layer){
                pawake[x+dx][y+dy] = true;
            }
        }
    }
}

void ofApp::dryNeighbours(int x, int y){
    int dx, dy;
    
    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        dx = neighbours[i][0];
        dy = neighbours[i][1];
        if(x+dx >= 0 && x+dx < WIDTH && y+dy >= 0 && y+dy < HEIGHT){
            if(pforce[x+dx][y+dy] > 0){
                //pforce[x+dx][y+dy] = int(pforce[x+dx][y+dy] * 0.999);
                pforce[x+dx][y+dy] -= 1.0/float(pforce[x+dx][y+dy]) * ofRandom(20);
                if(pforce[x+dx][y+dy] < 0){
                    pforce[x+dx][y+dy] = 0;
                };
            }
        }
    }
}

void ofApp::addSpec(int x, int y, int layer, int force){
    int vx, vy;
    for(int dy=0; dy<20; dy++){
        for(int dx=0; dx<20; dx++){
            vx = x+dx;
            vy = y+dy;
            if(vx >= 0 && vx < WIDTH && vy >= 0 && vy < HEIGHT){
                if( (dx*dx)+(dy*dy) < 100 ) {
                    pcolors[vx][vy] = layer;
                    pforce[vx][vy] = force;
                    pawake[vx][vy] = false;
                    wakeNeighbours(vx,vy, true);
                    img.setColor(vx,vy,layers[layer % NUM_LAYERS]);
                }
            }
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    img.draw(0,0);
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    int x = (int)touch.x;
    int y = (int)touch.y;
    currentLayer++;
    ofColor newColor;
    do {
        newColor = defaultColors[(int)ofRandom(DEFAULT_COLORS_COUNT)];
    } while(newColor == layers[pcolors[x][y] % NUM_LAYERS]);
    newColor.setBrightness(255);
    layers[currentLayer % NUM_LAYERS] = newColor;
    
    touchLayers[touch.id] = currentLayer;
    
    addSpec(x, y, currentLayer, 2550);
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    addSpec((int)touch.x, (int)touch.y, touchLayers[touch.id], 2550);
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}
