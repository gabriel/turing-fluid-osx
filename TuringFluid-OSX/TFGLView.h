//
//  TFGLView.h
//
//  Created by Gabriel Handford on 1/14/12.
//  Copyright (c) 2012 rel.me. All rights reserved.
//

#import <QuartzCore/CVDisplayLink.h>

#import "TFTuringFluidShader.h"
//#import "TFFluidShader.h"

@interface TFGLView : NSOpenGLView {
  CVDisplayLinkRef _displayLink;
  CGDirectDisplayID	_viewDisplayID;

  CGPoint _mouseKinect[16];
  CGPoint _mouseDKinect[16];
  CGPoint _oldMouseKinect[16];
  
  CGPoint _mouse;
  CGPoint _mouseD;
  CGPoint _oldMouse;
  
  TFTuringFluidShader *_shader;
  //TFFluidShader *_shader;
}

- (void)start;

- (void)stop;

- (CVReturn)drawWithTime:(const CVTimeStamp *)outputTime;

@end
