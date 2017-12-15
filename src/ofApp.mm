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
    img.setColor(ofColor::black);
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
void ofApp::update(){
    acc3d.set(ofxAccelerometer.getForce());
    acc2d.set(acc3d);
    
    // Tilt direction
    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        neighbourStrength[i] = acc2d.angle(ofVec2f(-neighbours[i][1], -neighbours[i][0])) / 360 * acc2d.lengthSquared();
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
            neighbour nb = hasNeighbours(x, y);
            if(pcolors[x][y] < nb.layer){
                phistory[x][y] = odd;
                if(ofRandom(10)>3){
                    pcolors[x][y] = nb.layer;
                    if(nb.force > 0){
                        pforce[x][y] = MAX(0, nb.force - (int)ofRandom(2));
                    }
                    pawake[x][y] = false;
                    col.setBrightness(nb.force);
                    col = img.getColor(x,y).getLerped(layers[nb.layer % NUM_LAYERS], nb.force/255.0);
                    img.setColor(x, y, col);
                    wakeNeighbours(x, y);
                }
            }
        }
    }
    
    img.update();
    
    odd = !odd;
}

struct neighbour ofApp::hasNeighbours(int x, int y){
    int dx, dy;
    int layer, force;
    float strength = 0;
    
    dx = dy = layer = force = 0;

    for(int i=0; i < NEIGHBOURS_COUNT; i++){
        dx = neighbours[i][0];
        dy = neighbours[i][1];
        if(x+dx >= 0 && x+dx < WIDTH && y+dy >= 0 && y+dy < HEIGHT){
            if(phistory[x+dx][y+dy] != odd && pforce[x+dx][y+dy] > 0){
                if(ofRandom(100) > 95 || (/*pcolors[x+dx][y+dy] > pcolors[x][y] &&*/ neighbourStrength[i] > 0.05)){
                    force = pforce[x+dx][y+dy];
                    layer = pcolors[x+dx][y+dy];
                }
            }
        }
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

void ofApp::addSpec(int x, int y, int layer, int force){
    pcolors[x][y] = layer;
    pforce[x][y] = force;
    pawake[x][y] = false;
    wakeNeighbours(x,y, true);
    img.setColor(x,y,layers[layer % NUM_LAYERS]);
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
    
    addSpec(x, y, currentLayer, 255);
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    addSpec((int)touch.x, (int)touch.y, touchLayers[touch.id], 255);
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
