//
//  TFFluidShader.h
//  TuringFluid
//
//  Created by Gabriel Handford on 2/23/12.
//  Copyright (c) 2012 rel.me. All rights reserved.
//

#import "GHGLCommon.h"
#import "GHGLProgram.h"
#import "GHGLTexture.h"


@interface TFFluidShader : NSObject {
  
  GHGLProgram *_prog;
  GHGLProgram *_progCopy;
  GHGLProgram *_progComposite;
  
	GHGLProgram *_progFluidInit;
	GHGLProgram *_progFluidAddMotion;
	GHGLProgram *_progFluidAdvect;
	GHGLProgram *_progFluidP;
	GHGLProgram *_progFluidDiv;
  
  GHGLProgram *_progBlurHorizontal;
	GHGLProgram *_progBlurVertical;
  
  GLuint _frameBuffers[2];
  GLuint _fluidPFrameBuffer;
  GLuint _fluidVFrameBuffer;
  GLuint _fluidStoreFrameBuffer;
  GLuint _fluidBackBuffer;
  
  GLuint _helperFrameBuffers[6];
  GLuint _blurFrameBuffers[6];
  
  GLuint _textureMainN;
  GLuint _textureMain2N;
  GLuint _textureMainL;
  GLuint _textureMain2L;

  GLuint _textureFluidV;
  GLuint _textureFluidP;
  GLuint _textureFluidStore;
  GLuint _textureFluidBackBuffer;
  
  GLuint _textureHelper[6];
  GLuint _textureBlur[6];
  
  GLuint _verticesID;
  
  CGPoint _mouse;
  CGPoint _mouseD;
  
  BOOL _loaded;
  
  int _frameCounter;
  NSTimer *_frameTimer;
  
  float _fps;
  GLfloat _time;
  
  NSInteger _it;
  
  CGSize _viewSize;
}

@property (assign, nonatomic) CGPoint mouse;
@property (assign, nonatomic) CGPoint mouseD;
@property (assign, nonatomic) CGSize viewSize;


- (id)initWithViewSize:(CGSize)viewSize;

- (void)prepareOpenGL;

- (void)draw;

@end
