//
//  spinTopView.h
//  spinningTop2.0
//
//  Created by Prakrit Shrestha on 4/10/13.
//  Copyright (c) 2013 Prakrit Shrestha. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GLUT/GLUT.h>
#import <OpenGL/OpenGL.h>

const double DEG_RAD = 180.0 / M_PI;

@interface spinTopView : NSOpenGLView
{
    IBOutlet id phiText, thetaText, psiText;
    float phi, theta, psi;
    
    IBOutlet id phi_Text, theta_Text, psi_Text;
    float phi_, theta_, psi_;
    
    float phi__, theta__, psi__;
    
    IBOutlet id gText, dTimeText;
    double g, dTime;
        
    IBOutlet id coneTopRadiusText, coneHeightText;
    float coneTopRadius, coneHeight;
    
    int slices, stacks;
    
    double trackCylinderAngle, trackCylinderAngleX;
    
    double Ix, Iz;
        
    IBOutlet id pauseButton;
    
    IBOutlet id fieldOfViewSlider, zoomSlider, animationRateSlider;
    int animationRate;
    float fieldOfViewAngle, depth;
    
    IBOutlet id topColor, base1Color;

    NSPoint oldMousePoint;
}

-(void)awakeFromNib;

-(void)ShapeGLContext;
-(void)reshape;
-(void)render;

-(void)mouseDown:(NSEvent *)theEvent;
-(void)mouseDragged:(NSEvent *)theEvent;

-(void)toggleEvolveStep;
-(void)evolve:(id)anObject;

-(IBAction)redraw:(id)sender;
-(IBAction)reset:(id)sender;

@end
