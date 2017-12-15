#pragma once

#include "ofxiOS.h"

//#define WIDTH 320
//#define HEIGHT 568
#define WIDTH 640
#define HEIGHT 1136

#define NEIGHBOURS_COUNT 8
#define DEFAULT_COLORS_COUNT 14
#define NUM_LAYERS 10000
#define NUM_TOUCHES 5

class ofApp : public ofxiOSApp {
    
public:
    void setup();
    void update();
    void draw();
    void exit();

    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);

    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    struct neighbour hasNeighbours(int x, int y);
    void wakeNeighbours(int x, int y);
    void wakeNeighbours(int x, int y, bool force);
    void dryNeighbours(int x, int y);
    void addSpec(int x, int y, int layer, int force);
    void reset();
    
    int neighbours[NEIGHBOURS_COUNT][2] = {
        {0,-1},
        {-1,0},
        {1,0},
        {0,1},
        {-1,-1},
        {1,-1},
        {-1,1},
        {1,1}
    };
    
    float neighbourStrength[NEIGHBOURS_COUNT];
    
    ofImage img;
    int wipeTimer;
    bool waitForWipe;
    
    // color layers
    bool phistory[WIDTH][HEIGHT];
    bool pawake[WIDTH][HEIGHT];
    int pcolors[WIDTH][HEIGHT];
    uint16_t pforce[WIDTH][HEIGHT];
    int currentLayer = 0;
    int layerCount = 0;
    
    int touchLayers[NUM_TOUCHES];
    
    ofColor ugly;
    ofColor layers[NUM_LAYERS];
    ofColor defaultColors[DEFAULT_COLORS_COUNT];
    
    bool odd;
};

struct neighbour {
    int force=0;
    int layer=0;
    
    neighbour(int f, int l){
        force = f;
        layer = l;
    }
    
    neighbour(){
        neighbour(0,0);
    }
};


