//
//  TFShaderView.m
//  TuringFluid
//
//  Created by Gabriel Handford on 2/23/12.
//  Copyright (c) 2012 rel.me. All rights reserved.
//

#import "TFShader.h"

#import "GHGLUtils.h"
#import "GHTextureManager.h"

#define SizeX (1024.0f)
#define SizeY (768.0f)
#define SimScale (2.0f)
#define IsFluidEnabled (NO)

@implementation TFShader

@synthesize mouse=_mouse, mouseD=_mouseD, viewSize=_viewSize;

- (id)initWithViewSize:(CGSize)viewSize {
  if ((self = [self init])) {
    _viewSize = viewSize;
  }
  return self;
}

- (void)dealloc {
  [_progCopy release];
  [_progAdvance release];
	[_progComposite release];
	[_progBlurHorizontal release];
	[_progBlurVertical release];
  
	[_progFluidInit release];
	[_progFluidAddMotion release];
	[_progFluidAdvect release];
	[_progFluidP release];
	[_progFluidDiv release];
  
  [super dealloc];
}

- (GHGLProgram *)programForShaderName:(NSString *)shaderName {
  GHGLProgram *program = [[GHGLProgram alloc] init];  
  [program attachShadersWithFragmentShader:[NSString stringWithFormat:@"%@.%@", shaderName, @"fs"] vertexShader:@"Shader.vs" fragmentShaderInclude:@"Include.fs"];
  [program linkProgram];
  [program releaseShaders];
  return [program autorelease];
}

- (void)createAndBindTexture:(GLuint *)texture pixels:(NSMutableData *)pixels scale:(GLfloat)scale fbo:(GLuint)fbo filter:(GLint)filter {
  glGenTextures(1, texture);
  glBindTexture(GL_TEXTURE_2D, *texture);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SizeX/scale, SizeY/scale, 0, GL_RGBA, GL_UNSIGNED_BYTE, [pixels bytes]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *texture, 0);
}

- (void)createAndBindSimulationTexture:(GLuint *)texture pixels:(NSMutableData *)pixels fbo:(GLuint)fbo {
  glGenTextures(1, texture);
  glBindTexture(GL_TEXTURE_2D, *texture);
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, SizeX/SimScale, SizeY/SimScale, 0, GL_RGBA, GL_UNSIGNED_BYTE, [pixels bytes]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *texture, 0);
}

- (void)calculateBlurTexture:(GLuint)sourceTex targetTex:(GLuint)targetTex targetFBO:(GLuint)targetFBO helperTex:(GLuint)helperTex helperFBO:(GLuint)helperFBO scale:(GLfloat)scale {
  // copy source
  glViewport(0, 0, SizeX / scale, SizeY / scale);
  glUseProgram([_progCopy program]);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, sourceTex);
  glBindFramebuffer(GL_FRAMEBUFFER, targetFBO);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
  
  // blur vertically
  glViewport(0, 0, SizeX / scale, SizeY / scale);
  glUseProgram([_progBlurVertical program]);
  glUniform2f(glGetUniformLocation([_progBlurVertical program], "pixelSize"), scale / SizeX, scale / SizeY);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, targetTex);
  glBindFramebuffer(GL_FRAMEBUFFER, helperFBO);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
  
  // blur horizontally
  glViewport(0, 0, SizeX / scale, SizeY / scale);
  glUseProgram([_progBlurHorizontal program]);
  glUniform2f(glGetUniformLocation([_progBlurHorizontal program], "pixelSize"), scale / SizeX, scale / SizeY);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, helperTex);
  glBindFramebuffer(GL_FRAMEBUFFER, targetFBO);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
}

- (void)fluidInit:(GLuint)fbo {
  glViewport(0, 0, SizeX/SimScale, SizeY/SimScale);
  glUseProgram([_progFluidInit program]);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
}

- (void)calculateBlurTextures {
  GLuint textureSource = (_it < 0) ? _textureMain2L : _textureMainL;
  [self calculateBlurTexture:textureSource targetTex:_textureBlur[0] targetFBO:_blurFrameBuffers[0] helperTex:_textureHelper[0] helperFBO:_helperFrameBuffers[0] scale:1.0f];
  [self calculateBlurTexture:_textureBlur[0] targetTex:_textureBlur[1] targetFBO:_blurFrameBuffers[1] helperTex:_textureHelper[1] helperFBO:_helperFrameBuffers[1] scale:2.0f];
  [self calculateBlurTexture:_textureBlur[1] targetTex:_textureBlur[2] targetFBO:_blurFrameBuffers[2] helperTex:_textureHelper[2] helperFBO:_helperFrameBuffers[2] scale:4.0f];
  [self calculateBlurTexture:_textureBlur[2] targetTex:_textureBlur[3] targetFBO:_blurFrameBuffers[3] helperTex:_textureHelper[3] helperFBO:_helperFrameBuffers[3] scale:8.0f];
  [self calculateBlurTexture:_textureBlur[3] targetTex:_textureBlur[4] targetFBO:_blurFrameBuffers[4] helperTex:_textureHelper[4] helperFBO:_helperFrameBuffers[4] scale:16.0f];
  [self calculateBlurTexture:_textureBlur[4] targetTex:_textureBlur[5] targetFBO:_blurFrameBuffers[5] helperTex:_textureHelper[5] helperFBO:_helperFrameBuffers[5] scale:32.0f];
}

- (BOOL)loadShaders {
  _progCopy = [[self programForShaderName:@"Shader-Copy"] retain];
  _progAdvance = [[self programForShaderName:@"Shader-Advance"] retain];
  _progComposite = [[self programForShaderName:@"Shader-Composite"] retain];
  _progBlurHorizontal = [[self programForShaderName:@"Shader-BlurHorizontal"] retain];
  _progBlurVertical = [[self programForShaderName:@"Shader-BlurVertical"] retain];
  
  if (IsFluidEnabled) {
    _progFluidInit = [[self programForShaderName:@"Shader-FluidInit"] retain];
    _progFluidAddMotion = [[self programForShaderName:@"Shader-FluidAddMotion"] retain];
    _progFluidAdvect = [[self programForShaderName:@"Shader-FluidAdvect"] retain];
    _progFluidP = [[self programForShaderName:@"Shader-FluidP"] retain];
    _progFluidDiv = [[self programForShaderName:@"Shader-FluidDiv"] retain];  
  }
  
  glGenBuffers(1, &_verticesID);
  glBindBuffer(GL_ARRAY_BUFFER, _verticesID);
  
  // two triangles ought to be enough for anyone ;)
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
  
  GLint aPosLoc = glGetAttribLocation([_progAdvance program], "aPos");
  glEnableVertexAttribArray(aPosLoc);
  
  GLint aTexLoc = glGetAttribLocation([_progAdvance program], "aTexCoord");
  glEnableVertexAttribArray(aTexLoc);
  
  glBufferData(GL_ARRAY_BUFFER, sizeof(vertices) + sizeof(texCoords), NULL, GL_STATIC_DRAW);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), &vertices[0]);
  glBufferSubData(GL_ARRAY_BUFFER, sizeof(vertices), sizeof(texCoords), &texCoords[0]);
  
  glVertexAttribPointer(aPosLoc, 3, GL_FLOAT, GL_FALSE, 0, 0);
  glVertexAttribPointer(aTexLoc, 2, GL_FLOAT, GL_FALSE, 0, (void *)sizeof(vertices));
  
  GHGLCheckError();
  
  NSMutableData *noisePixels = [NSMutableData data];
  NSMutableData *pixels = [NSMutableData data];
  NSMutableData *simPixels = [NSMutableData data];
  NSMutableData *pixels2 = [NSMutableData data];
  NSMutableData *pixels3 = [NSMutableData data];
  NSMutableData *pixels4 = [NSMutableData data];
  NSMutableData *pixels5 = [NSMutableData data];
  NSMutableData *pixels6 = [NSMutableData data];
  
  for (int i = 0; i < SizeX; i++) {
    for (int j = 0; j < SizeY; j++) {      
      uint8_t random[4] = { GHGL_RANDOM_INT_0_TO(255), GHGL_RANDOM_INT_0_TO(255), GHGL_RANDOM_INT_0_TO(255), 255 };
      [noisePixels appendBytes:random length:4];
      
      uint8_t empty[4] = { 0, 0, 0, 255 };
      [pixels appendBytes:empty length:4];
      
      if (i < SizeX/SimScale && j < SizeY/SimScale) {
        [simPixels appendBytes:empty length:4];
      }
      if (i < SizeX/2.0f && j < SizeY/2.0f) {
        [pixels2 appendBytes:empty length:4];
      }
      if (i < SizeX/4.0f && j < SizeY/4.0f) {
        [pixels3 appendBytes:empty length:4];
      }
      if (i < SizeX/8.0f && j < SizeY/8.0f) {
        [pixels4 appendBytes:empty length:4];
      }
      if (i < SizeX/16.0f && j < SizeY/16.0f) {
        [pixels5 appendBytes:empty length:4];
      }
      if (i < SizeX/32.0f && j < SizeY/32.0f) {
        [pixels6 appendBytes:empty length:4];
      }
    }
  }
  
  glGenFramebuffers(2, _frameBuffers);
  [self createAndBindTexture:&_textureMainN pixels:noisePixels scale:1.0f fbo:_frameBuffers[0] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureMain2N pixels:noisePixels scale:1.0f fbo:_frameBuffers[1] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureMainL pixels:noisePixels scale:1.0f fbo:_frameBuffers[0] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureMain2L pixels:noisePixels scale:1.0f fbo:_frameBuffers[1] filter:GL_LINEAR];
  
  if (IsFluidEnabled) {
    glGenFramebuffers(1, &_fluidPFrameBuffer);
    glGenFramebuffers(1, &_fluidVFrameBuffer);
    glGenFramebuffers(1, &_fluidStoreFrameBuffer);
    glGenFramebuffers(1, &_fluidBackBuffer);
    
    [self createAndBindSimulationTexture:&_textureFluidV pixels:simPixels fbo:_fluidVFrameBuffer];
    [self createAndBindSimulationTexture:&_textureFluidP pixels:simPixels fbo:_fluidPFrameBuffer];
    [self createAndBindSimulationTexture:&_textureFluidStore pixels:simPixels fbo:_fluidStoreFrameBuffer];
    [self createAndBindSimulationTexture:&_textureFluidBackBuffer pixels:simPixels fbo:_fluidBackBuffer];
  }
  
  glGenFramebuffers(6, _helperFrameBuffers);  
  [self createAndBindTexture:&_textureHelper[0] pixels:pixels scale:1.0f fbo:_helperFrameBuffers[0] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureHelper[1] pixels:pixels2 scale:2.0f fbo:_helperFrameBuffers[1] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureHelper[2] pixels:pixels3 scale:4.0f fbo:_helperFrameBuffers[2] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureHelper[3] pixels:pixels4 scale:8.0f fbo:_helperFrameBuffers[3] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureHelper[4] pixels:pixels5 scale:16.0f fbo:_helperFrameBuffers[4] filter:GL_NEAREST];
  [self createAndBindTexture:&_textureHelper[5] pixels:pixels6 scale:32.0f fbo:_helperFrameBuffers[5] filter:GL_NEAREST];
  
  glGenFramebuffers(6, _blurFrameBuffers);  
  [self createAndBindTexture:&_textureBlur[0] pixels:pixels scale:1.0f fbo:_blurFrameBuffers[0] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureBlur[1] pixels:pixels2 scale:2.0f fbo:_blurFrameBuffers[1] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureBlur[2] pixels:pixels3 scale:4.0f fbo:_blurFrameBuffers[2] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureBlur[3] pixels:pixels4 scale:8.0f fbo:_blurFrameBuffers[3] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureBlur[4] pixels:pixels5 scale:16.0f fbo:_blurFrameBuffers[4] filter:GL_LINEAR];
  [self createAndBindTexture:&_textureBlur[5] pixels:pixels6 scale:32.0f fbo:_blurFrameBuffers[5] filter:GL_LINEAR];
  
  glGenFramebuffers(1, &_noiseFrameBuffer);
  [self createAndBindTexture:&_textureNoiseN pixels:noisePixels scale:1.0f fbo:_noiseFrameBuffer filter:GL_NEAREST];
  [self createAndBindTexture:&_textureNoise1 pixels:noisePixels scale:1.0f fbo:_noiseFrameBuffer filter:GL_LINEAR];
  
  glActiveTexture(GL_TEXTURE2); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[0]);
  glActiveTexture(GL_TEXTURE3); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[1]);
  glActiveTexture(GL_TEXTURE4); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[2]);
  glActiveTexture(GL_TEXTURE5); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[3]);
  glActiveTexture(GL_TEXTURE6); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[4]);
  glActiveTexture(GL_TEXTURE7); 
  glBindTexture(GL_TEXTURE_2D, _textureBlur[5]);
  glActiveTexture(GL_TEXTURE8); 
  glBindTexture(GL_TEXTURE_2D, _textureNoise1);
  glActiveTexture(GL_TEXTURE9); 
  glBindTexture(GL_TEXTURE_2D, _textureNoiseN);
  
  if (IsFluidEnabled) {
    glActiveTexture(GL_TEXTURE10); 
    glBindTexture(GL_TEXTURE_2D, _textureFluidV);
    glActiveTexture(GL_TEXTURE11); 
    glBindTexture(GL_TEXTURE_2D, _textureFluidP);
  }
  
  _it = 1;
  _fps = 0;
  _mouse = CGPointMake(0.5, 0.5);
  _mouseD = CGPointZero;
  _rainbowR = M_PI * 2 / 3;
  _rainbowG = M_PI * 2 / 3;
  _rainbowB = M_PI * 2 / 3;
  _w = M_PI * 2 / 3;
  _time = [[NSDate date] timeIntervalSince1970] * 1000;
  _frameCounter = 0;
  _frameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_timer) userInfo:nil repeats:YES];
  
  [self calculateBlurTextures];
  
  if (IsFluidEnabled) {
    [self fluidInit:_fluidVFrameBuffer];
    [self fluidInit:_fluidPFrameBuffer];
    [self fluidInit:_fluidStoreFrameBuffer];
    [self fluidInit:_fluidBackBuffer];
  }
  
  [self anim];
  
  return YES;
}


- (void)addMouseMotion {
  glViewport(0, 0, (SizeX/SimScale), (SizeY/SimScale));
  glUseProgram([_progFluidAddMotion program]);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _textureFluidV);
  glUniform2f(glGetUniformLocation([_progFluidAddMotion program], "aspect"), MAX(1.0f, _viewSize.width / _viewSize.height), MAX(1.0f, _viewSize.height / _viewSize.width));
  glUniform2f(glGetUniformLocation([_progFluidAddMotion program], "mouse"), _mouse.x, _mouse.y);
  glUniform2f(glGetUniformLocation([_progFluidAddMotion program], "mouseV"), _mouseD.x, _mouseD.y);
  glUniform2f(glGetUniformLocation([_progFluidAddMotion program], "pixelSize"), 1.0f / (SizeX/SimScale), 1.0f / (SizeY/SimScale));
  glUniform2f(glGetUniformLocation([_progFluidAddMotion program], "texSize"), (SizeX/SimScale), (SizeY/SimScale));
  glBindFramebuffer(GL_FRAMEBUFFER, _fluidBackBuffer);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
}

- (void)advect {
  glViewport(0, 0, (SizeX/SimScale), (SizeY/SimScale));
  glUseProgram([_progFluidAdvect program]);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _textureFluidBackBuffer);
  glUniform2f(glGetUniformLocation([_progFluidAdvect program], "pixelSize"), 1.0f / (SizeX/SimScale), 1.0f / (SizeY/SimScale));
  glUniform2f(glGetUniformLocation([_progFluidAdvect program], "texSize"), (SizeX/SimScale), (SizeY/SimScale));
  glBindFramebuffer(GL_FRAMEBUFFER, _fluidVFrameBuffer);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
}

- (void)diffuse {
  for (int i = 0; i < 8; i++) {
    glViewport(0, 0, (SizeX/SimScale), (SizeY/SimScale));
    glUseProgram([_progFluidP program]);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureFluidV);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureFluidP);
    glUniform2f(glGetUniformLocation([_progFluidP program], "texSize"), (SizeX/SimScale), (SizeY/SimScale));
    glUniform2f(glGetUniformLocation([_progFluidP program], "pixelSize"), 1.0f / (SizeX/SimScale), 1.0f / (SizeY/SimScale));
    glUniform1i(glGetUniformLocation([_progFluidP program], "sampler_v"), 0);
    glUniform1i(glGetUniformLocation([_progFluidP program], "sampler_p"), 1);
    glBindFramebuffer(GL_FRAMEBUFFER, _fluidBackBuffer);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
    
    glViewport(0, 0, (SizeX/SimScale), (SizeY/SimScale));
    glUseProgram([_progFluidP program]);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureFluidV);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureFluidBackBuffer);
    glUniform2f(glGetUniformLocation([_progFluidP program], "texSize"), (SizeX/SimScale), (SizeY/SimScale));
    glUniform2f(glGetUniformLocation([_progFluidP program], "pixelSize"), 1.0f / (SizeX/SimScale), 1.0f / (SizeY/SimScale));
    glUniform1i(glGetUniformLocation([_progFluidP program], "sampler_v"), 0);
    glUniform1i(glGetUniformLocation([_progFluidP program], "sampler_p"), 1);
    glBindFramebuffer(GL_FRAMEBUFFER, _fluidPFrameBuffer);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFlush();
  }
  
  glViewport(0, 0, (SizeX/SimScale), (SizeY/SimScale));
  glUseProgram([_progFluidDiv program]);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, _textureFluidV);
  glActiveTexture(GL_TEXTURE1);
  glBindTexture(GL_TEXTURE_2D, _textureFluidP);
  glUniform2f(glGetUniformLocation([_progFluidDiv program], "texSize"), (SizeX/SimScale), (SizeY/SimScale));
  glUniform2f(glGetUniformLocation([_progFluidDiv program], "pixelSize"), 1.0f / (SizeX/SimScale), 1.0f / (SizeY/SimScale));
  glUniform1i(glGetUniformLocation([_progFluidDiv program], "sampler_v"), 0.);
  glUniform1i(glGetUniformLocation([_progFluidDiv program], "sampler_p"), 1);
  glBindFramebuffer(GL_FRAMEBUFFER, _fluidVFrameBuffer);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
  
}

- (void)fluidSimulationStep {
  [self addMouseMotion];
  [self advect];
  [self diffuse];
}

- (void)setUniforms:(GLuint)program {
  glUniform4f(glGetUniformLocation(program, "rnd"), GHGL_RANDOM_0_TO_1(), GHGL_RANDOM_0_TO_1(), GHGL_RANDOM_0_TO_1(), GHGL_RANDOM_0_TO_1());
  glUniform4f(glGetUniformLocation(program, "rainbow"), _rainbowR, _rainbowG, _rainbowB, 1.0f);
  glUniform2f(glGetUniformLocation(program, "texSize"), SizeX, SizeY);
  glUniform2f(glGetUniformLocation(program, "pixelSize"), 1.0f / SizeX, 1.0f / SizeY);
  glUniform2f(glGetUniformLocation(program, "aspect"), MAX(1, _viewSize.width / _viewSize.height), MAX(1.0f, _viewSize.height / _viewSize.width));
  glUniform2f(glGetUniformLocation(program, "mouse"), _mouse.x, _mouse.y);
  glUniform2f(glGetUniformLocation(program, "mouseV"), _mouseD.x, _mouseD.y);
  glUniform1f(glGetUniformLocation(program, "fps"), _fps);
  glUniform1f(glGetUniformLocation(program, "time"), _time);
  
  glUniform1i(glGetUniformLocation(program, "sampler_prev"), 0);
  glUniform1i(glGetUniformLocation(program, "sampler_prev_n"), 1);
  glUniform1i(glGetUniformLocation(program, "sampler_blur"), 2);
  glUniform1i(glGetUniformLocation(program, "sampler_blur2"), 3);
  glUniform1i(glGetUniformLocation(program, "sampler_blur3"), 4);
  glUniform1i(glGetUniformLocation(program, "sampler_blur4"), 5);
  glUniform1i(glGetUniformLocation(program, "sampler_blur5"), 6);
  glUniform1i(glGetUniformLocation(program, "sampler_blur6"), 7);
  glUniform1i(glGetUniformLocation(program, "sampler_noise"), 8);
  glUniform1i(glGetUniformLocation(program, "sampler_noise_n"), 9);
  glUniform1i(glGetUniformLocation(program, "sampler_fluid"), 10);
  glUniform1i(glGetUniformLocation(program, "sampler_fluid_p"), 11);
}

- (void)advance {
  if (IsFluidEnabled) {
    [self fluidSimulationStep];
  }
  
  // Texture warp step  
  glViewport(0, 0, SizeX, SizeY);
  glUseProgram([_progAdvance program]);
  [self setUniforms:[_progAdvance program]];
  if (_it > 0) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureMainL); // interpolated input
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureMainN); // "nearest" input
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffers[1]); // write to buffer
  } else {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureMain2L); // interpolated
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureMain2N); // "nearest"
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffers[0]); // write to buffer
  }
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
  
  [self calculateBlurTextures];
  
  _it = -_it;
}

- (void)composite {
  glViewport(0, 0, _viewSize.width, _viewSize.height);
  glUseProgram([_progComposite program]);
  [self setUniforms:[_progComposite program]];
  if (_it < 0) {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureMainL);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureMainN);
  } else {
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _textureMain2L);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _textureMain2N);
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
  glFlush();
}

- (void)anim {
  
  _time = [[NSDate date] timeIntervalSince1970] * 1000;
  double t = _time / 150.0;
  
  _rainbowR = 0.5 + 0.5 * sin(t);
  _rainbowG = 0.5 + 0.5 * sin(t + _w);
  _rainbowB = 0.5 + 0.5 * sin(t - _w);
  
  [self advance];
  
  [self composite];
  
  _frameCounter++;
  
  glFlush();
}

- (void)_timer {
  GHGLDebug(@"FPS: %d", _frameCounter);
  _fps = _frameCounter;
  _frameCounter = 0;
}

- (void)prepareOpenGL {
  [self loadShaders];
}

- (void)draw {
  [self anim];
}

@end
