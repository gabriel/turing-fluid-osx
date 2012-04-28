//
//  TFGLView.h
//
//  Created by Gabriel Handford on 1/14/12.
//  Copyright (c) 2012 rel.me. All rights reserved.
//

#import <QuartzCore/CVDisplayLink.h>

#import "TFShader.h"
//#import "TFFluidShader.h"

@interface TFGLView : NSOpenGLView {
  CVDisplayLinkRef _displayLink;
  CGDirectDisplayID	_viewDisplayID;

  CGPoint _mouse[16];
  CGPoint _mouseD[16];
  CGPoint _oldMouse[16];
  
  TFShader *_shader;
  //TFFluidShader *_shader;
}

- (void)start;

- (void)stop;

- (CVReturn)drawWithTime:(const CVTimeStamp *)outputTime;

@end
