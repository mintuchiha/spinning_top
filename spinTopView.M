#import "spinTopView.h"

@implementation spinTopView


-(void)awakeFromNib
{
    coneTopRadius = 1.83;
    coneHeight = 2.74;
    
    phi = 0.0 / DEG_RAD;
    theta = 5.0 / DEG_RAD;
    psi = 0.0 / DEG_RAD;
    
    phi_ = 0.0 / DEG_RAD;
    theta_ = 0.0 / DEG_RAD;
    psi_ = 300.0 / DEG_RAD;
    
    dTime = 0.0001;
    g= 1.0;
    
    animationRate = 40000;
    fieldOfViewAngle = 100;
    depth = -10;
    
    [phiText setFloatValue:(phi * DEG_RAD)];
    [thetaText setFloatValue:(theta * DEG_RAD)];
    [psiText setFloatValue:(psi * DEG_RAD)];
    
    [phi_Text setFloatValue:(phi_ * DEG_RAD)];
    [theta_Text setFloatValue:(theta_ * DEG_RAD)];
    [psi_Text setFloatValue:(psi_ * DEG_RAD)];
    
    [coneHeightText setFloatValue:coneHeight];
    [coneTopRadiusText setFloatValue:coneTopRadius];
    
    [dTimeText setDoubleValue:dTime];
    [gText setDoubleValue:g];
    
    [fieldOfViewSlider setDoubleValue: fieldOfViewAngle];
    [animationRateSlider setIntValue:animationRate];
    [zoomSlider setDoubleValue: depth];
    
    [NSThread detachNewThreadSelector:@selector(evolve:) toTarget:self withObject:nil]; //multithreading
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES]; // so user can control opacity
    
    [[self openGLContext] makeCurrentContext];
    [self ShapeGLContext];
    [self reset:self];
}
-(IBAction)reset:(id)sender
{
    phi = [phiText floatValue] / DEG_RAD;
    theta = [thetaText floatValue] / DEG_RAD;
    psi = [psiText floatValue] / DEG_RAD;
    
    phi_ = [phiText floatValue] / DEG_RAD;
    theta_ = [thetaText floatValue] / DEG_RAD;
    psi_ = [psiText floatValue] / DEG_RAD;
    
    coneTopRadius = [coneTopRadiusText floatValue];
    coneHeight = [coneHeightText floatValue];
    
    g = [gText doubleValue];
    dTime = [dTimeText doubleValue];
        
    Ix = 2;
    Iz = 3;
}


- (void)drawRect:(NSRect)dirtyRect
{
    [self reshape];
    [self render];
    [[self openGLContext]   flushBuffer];
}

-(void)ShapeGLContext
{
    glClearColor(0, 0, 0, 0);
    float ambient[4] = {1,1,1,1};
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT, ambient);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0); glEnable(GL_LIGHT1);
    glColorMaterial(GL_FRONT_AND_BACK, GL_DIFFUSE);
    glEnable(GL_COLOR_MATERIAL);
    glShadeModel(GL_FLAT);
    glEnable(GL_DEPTH_TEST);
}

-(void)reshape
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_PROJECTION);
    {
        fieldOfViewAngle =[fieldOfViewSlider doubleValue];
        
        glLoadIdentity();
        gluPerspective(fieldOfViewAngle,
                       [self bounds].size.width / [self bounds].size.height,
                       1, 200);
    }
    
    glMatrixMode(GL_MODELVIEW);
    {
        glLoadIdentity();
        glTranslatef(0, 0, depth);
        
        glRotatef(trackCylinderAngle * DEG_RAD, 1, 0, 0);
        glRotatef(trackCylinderAngleX * DEG_RAD, 0, 1, 0);
        
        float lightPosition1[4] = {-1, -3, 3, FALSE};
        float lightPosition2[4] = {-1, 3, -3, FALSE};
        glLightfv(GL_LIGHT0, GL_POSITION, lightPosition1);
        glLightfv(GL_LIGHT1, GL_POSITION, lightPosition2);
    }
}

-(void)render
{
    float coneBaseRadius = 0.0;
    
    coneTopRadius = [coneTopRadiusText floatValue];
    coneHeight = [coneHeightText floatValue];
    
    slices = 24;
    stacks = 4;
    
    glPushMatrix();     //draw top
    {
        glRotatef(phi * DEG_RAD, 0, 0, 1);
        glRotatef(theta * DEG_RAD, 1, 0, 0);
        glRotatef(psi * DEG_RAD, 0, 0, 1);
        
        NSColor *coneColor =[topColor color];
        glColor4f([coneColor redComponent], [coneColor greenComponent], [coneColor blueComponent], [coneColor alphaComponent]);
        
        GLUquadric *invertedCone = gluNewQuadric();
        {
            gluCylinder(invertedCone, coneBaseRadius, coneTopRadius, coneHeight, slices, stacks);
        }
        gluDeleteQuadric(invertedCone);
        
        glTranslatef(0, 0, coneHeight);
        
        GLUquadric *disc = gluNewQuadric();
        {
            gluDisk(disc,0, coneTopRadius, slices, stacks);
        }
        gluDeleteQuadric(disc);
    }
    
    glPopMatrix();
    
    int b = 4;
    
    glPushMatrix(); //draw plane
    {
        NSColor *baseColor =[base1Color color];
        glColor4f([baseColor redComponent], [baseColor greenComponent], [baseColor blueComponent], [baseColor alphaComponent]);
        
        glBegin(GL_QUADS);
        {
            glNormal3f(0, 0, 1);
            
            glVertex3f(b, b, 0);
            glVertex3f(-b, b, 0);
            glVertex3f(-b, -b, 0);
            glVertex3f(b, -b, 0);
        }
        glEnd();
    }
    glPopMatrix();
}

-(void)mouseDown:(NSEvent *)theEvent
{
    oldMousePoint = [theEvent locationInWindow];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    double trackCylinderRadius = 40.0;
    
    NSPoint mousePoint = [theEvent locationInWindow];
    
    trackCylinderAngle -= (mousePoint.y - oldMousePoint.y) / trackCylinderRadius;
    trackCylinderAngleX -= (mousePoint.x - oldMousePoint.x) / trackCylinderRadius;
    
    oldMousePoint = mousePoint;
    
    [self display];
}

-(void)toggleEvolveStep //euler-cromer
{
    double mgh = g;
    
    theta__ = (sinf(theta) * (mgh + (Ix - Iz) * cosf(theta) * (phi_) * (phi_) - (Iz * phi_ * psi_))) / Ix;
    phi__ = - ((1 / sinf(theta)) * theta_ * ((2 * Ix - Iz) * cosf(theta) * phi_ - Iz * psi_)) / Ix;
    psi__ = ((1 / sinf(theta)) * theta_ * ((3 * Ix - Iz + (Ix - Iz) * cosf(2 * theta) * phi_ - 2 * Iz * cosf(theta) * psi_))) / (2 * Ix);
    
    phi_ += phi__ * dTime;
    theta_ += theta__ * dTime;
    psi_ += psi__ * dTime;
    
    phi += phi_ * dTime;
    theta += theta_ * dTime;
    psi += psi_ * dTime;
}

-(void)evolve:(id)anObject
{
    while (YES)
    {
        animationRate = [animationRateSlider intValue];
        
        if (not [pauseButton state])
        {
            [self toggleEvolveStep];
            [self setNeedsDisplay:YES];
        }
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0 / (animationRate)]];
    }
}

- (IBAction)redraw:(id)sender
{
    fieldOfViewAngle =[fieldOfViewSlider doubleValue] ;
    depth = [zoomSlider doubleValue];
	
	[self setNeedsDisplay:YES];					// invokes drawRect:
}

@end
