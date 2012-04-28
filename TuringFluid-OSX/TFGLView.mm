//
//  TFGLView.m
//
//  Created by Gabriel Handford on 1/14/12.
//  Copyright (c) 2012 rel.me. All rights reserved.
//

#import "TFGLView.h"
#import <OpenGL/gl.h>
#import <QuartzCore/CVDisplayLink.h>
#import <OpenGL/OpenGL.h>

#import "GHGLUtils.h"
#import "GHTextureManager.h"
#import "CocoaOpenNI.h"

#define IsOpenNIEnabled (NO)

@interface TFGLView ()
- (BOOL)_openNI;
@end

@implementation TFGLView

static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
  return [(TFGLView *)displayLinkContext drawWithTime:inOutputTime];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  CVDisplayLinkRelease(_displayLink);
  [_shader release];
  [super dealloc];
}

- (void)windowChangedScreen:(NSNotification *)notification {
	// If the video moves to a different screen, synchronize to the timing of that screen.
  NSWindow *window = [notification object]; 
  CGDirectDisplayID displayID = (CGDirectDisplayID)[[[[window screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
  
  if ((displayID != 0) && (_viewDisplayID != displayID)) {
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
		_viewDisplayID = displayID;
  }
}

- (void)start {
  NSAssert(!_displayLink, @"Already have display link");
  
  NSOpenGLPixelFormatAttribute attributes[] = {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		0
  };
	
  NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
  [self setPixelFormat:pixelFormat];
  [pixelFormat release];
  
  CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowChangedScreen:) name:NSWindowDidMoveNotification object:nil];
  
  // Set up callbacks for the display link.
	CVDisplayLinkSetOutputCallback(_displayLink, DisplayLinkCallback, self);
  
  CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
  CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
  NSAssert(cglPixelFormat, @"No pixel format");
  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(_displayLink, cglContext, cglPixelFormat);
  
  CVReturn started = CVDisplayLinkStart(_displayLink);
  NSLog(@"Started: %d", started);
}

- (void)stop {
  if (_displayLink != NULL) {
    CVDisplayLinkStop(_displayLink);  
    CVDisplayLinkRelease(_displayLink);
    _displayLink = NULL;
  }
}

- (void)prepareOpenGL {
  _shader = [[TFShader alloc] initWithViewSize:self.frame.size];
  [_shader prepareOpenGL];
  
  [self _openNI];
}

- (void)reshape {
  [_shader setViewSize:self.frame.size];
}

- (CVReturn)drawWithTime:(const CVTimeStamp *)outputTime {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  CGLContextObj contextObj = (CGLContextObj)[[self openGLContext] CGLContextObj];
  CGLLockContext(contextObj);
	
	[[self openGLContext] makeCurrentContext];
    
  [self _openNI];
  
  Vector2D mouseToUse = {0, 0};
  Vector2D mouseDToUse = {0, 0};

  for (int i = 0; i < 16; i++) {
    Vector2D mouse = { _mouse[i].x, _mouse[i].y };
    Vector2D mouseD = { _mouseD[i].x, _mouseD[i].y };
    Vector2D oldMouse = { _oldMouse[i].x, _oldMouse[i].y };

    if (oldMouse.x != 0 && oldMouse.y != 0) {
      mouseD.x = (mouse.x - oldMouse.x) * self.frame.size.width;
      mouseD.y = (mouse.y - oldMouse.y) * self.frame.size.height;
    }
    
    if (Vector2DDistance(mouseD, mouse) > Vector2DDistance(mouseDToUse, mouseToUse)) {
      mouseToUse = mouse;
      mouseDToUse = mouseD;
    }
  }
  _shader.mouse = CGPointMake(mouseToUse.x, mouseToUse.y);
  _shader.mouseD = CGPointMake(mouseDToUse.x, mouseDToUse.y);
  
  [_shader draw];
  
  [[self openGLContext] flushBuffer];
	
	CGLUnlockContext(contextObj);
  
	[pool release];
  return kCVReturnSuccess;
}

- (void)mouseDragged:(NSEvent *)event {
  NSPoint p = [event locationInWindow];
  _oldMouse[0] = _mouse[0];
  _mouse[0] = CGPointMake(p.x / self.frame.size.width, p.y / self.frame.size.height);
}

- (void)mouseUp:(NSEvent *)event {
  _oldMouse[0] = _mouse[0];
}

- (BOOL)_openNI {
  CocoaOpenNI *openNI = [CocoaOpenNI sharedOpenNI];
  
  if (!openNI.isStarted && IsOpenNIEnabled) {
    [openNI startWithConfigPath:[[NSBundle mainBundle] pathForResource:@"Config" ofType:@"xml"] skeletonProfile:XN_SKEL_PROFILE_NONE handsProfile:NO];
  }
  
  //BOOL hasUser = NO;
  if (openNI.isStarted) {
    
    xn::SceneMetaData sceneMD;
    xn::DepthMetaData depthMD;
    openNI.depthGenerator.GetMetaData(depthMD);
    
    // Read next available data
    // If we skip this, the view will appear paused
    [openNI context].WaitNoneUpdateAll();
    
    
    // Process the data
    [openNI depthGenerator].GetMetaData(depthMD);
    [openNI userGenerator].GetUserPixels(0, sceneMD);
    
    XnUserID aUsers[15];
    XnUInt16 nUsers = 15;
    [openNI userGenerator].GetUsers(aUsers, nUsers);
    
    //hasUser = HasUser(aUsers, nUsers);
    XnPoint3D locations[16];
    UserLocations(depthMD, sceneMD, locations, UserLocationTypeCenter);
    
    for (int i = 0; i < 16; i++) {
      if (locations[i].X != -1) {
        _oldMouse[i] = _mouse[i];
        
        // Translate
        locations[i].Y = (-locations[i].Y + 480);
        locations[i].Y *= 2;
        
        _mouse[i] = CGPointMake(locations[i].X / 640, locations[i].Y / 480);
      } else {
        _oldMouse[i] = _mouse[i];
        _mouse[i] = CGPointZero;
      }
    }
  }
  return NO;
}

#pragma mark Testing

/*
- (void)loadTest {
  _progTest = [[GHGLProgram compileAndLinkWithFragmentShader:@"Shader-Test.fs" vertexShader:@"Shader-Test.vs"] retain];
  glGenFramebuffers(1, &_frameBufferTest);  
  //[self createAndBindTexture:&_textureTest pixels:testPixels scale:1.0f fbo:_frameBufferTest filter:GL_LINEAR];  
  _textureTestObj = [[GHGLTexture alloc] initWithName:@"particle-test2.png"];
  
  glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferTest);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [_textureTestObj textureId], 0);
}

- (void)test {
  //glViewport(0, 0, SizeX, SizeY);
  glUseProgram([_progTest program]);
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  
  
  const GLfloat vertices[] = {
    0.0f, 0.0f,
    64.0f, 0.0f,
    0.0f, 64.0f,
    64.0f, 64.0f,
	};
	
	const GLfloat texCoords[] = {
		0.0, 1.0,
		1.0, 1.0,
		0.0, 0.0,
		1.0, 0.0
	};
  
  glEnable(GL_TEXTURE_2D);
  
  [_textureTestObj bind];
  
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  glDisable(GL_BLEND);
  glDisableClientState(GL_VERTEX_ARRAY);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
  glDisable(GL_TEXTURE);
  glFlush();
}

- (void)loadTest2 {
  _progTest = [[GHGLProgram compileAndLinkWithFragmentShader:@"Shader-Test.fs" vertexShader:@"Shader-Test.vs"] retain];
  glGenFramebuffers(1, &_frameBufferTest);  
  
  //_textureTestObj = [[GHGLTexture alloc] initWithName:@"particle-test2.png"];  
  //glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferTest);
  //glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, [_textureTestObj textureId], 0);
  
  glGenBuffers(1, &_verticesID);
  glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
  
  //glEnableClientState(GL_VERTEX_ARRAY);
  //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  const GLfloat vertices[] = { 
    -1.0f, -1.0f, 0.0f, 
    1.0f, -1.0f, 0.0f, 
    -1.0f, 1.0f, 0.0f, 
    1.0f, 1.0f, 0.0f
  };
  
  const GLfloat texCoords[] = {
    0.0f, 0.0f, 
    1.0f, 0.0f, 
    0.0f, 1.0f, 
    1.0f, 1.0f
  };
  
  GLint aPosLoc = glGetAttribLocation([_progTest program], "aPos");
  glEnableVertexAttribArray(aPosLoc);
  
  GLint aTexLoc = glGetAttribLocation([_progTest program], "aTexCoord");
  glEnableVertexAttribArray(aTexLoc);
  
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices) + sizeof(texCoords), NULL, GL_STATIC_DRAW);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), &vertices[0]);
  glBufferSubData(GL_ARRAY_BUFFER, sizeof(vertices), sizeof(texCoords), &texCoords[0]);
  
  glVertexAttribPointer(aPosLoc, 3, GL_FLOAT, GL_FALSE, 0, 0);
  glVertexAttribPointer(aTexLoc, 2, GL_FLOAT, GL_FALSE, 0, (void *)sizeof(vertices));
  
  NSMutableData *noisePixels = [NSMutableData data];
  
  for (int i = 0; i < SizeX; i++) {
    for (int j = 0; j < SizeY; j++) {      
      uint8_t random[4] = { GHGL_RANDOM_INT_0_TO(255), GHGL_RANDOM_INT_0_TO(255), GHGL_RANDOM_INT_0_TO(255), 255 };
      [noisePixels appendBytes:random length:4];
    }
  }
  
  [self createAndBindTexture:&_textureTest pixels:noisePixels scale:1.0f fbo:_frameBufferTest filter:GL_NEAREST];
}

- (void)test2 {
  glViewport(0, 0, self.frame.size.width, self.frame.size.height);
  glUseProgram([_progTest program]);
  
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);  
  
  //[_textureTestObj bind];
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _textureTest);
  
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  
  glFlush();
}
 */

@end
