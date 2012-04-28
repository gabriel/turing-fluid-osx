uniform sampler2D sampler_prev;
uniform sampler2D sampler_prev_n;
uniform sampler2D sampler_blur;
uniform sampler2D sampler_blur2;
uniform sampler2D sampler_blur3;
uniform sampler2D sampler_blur4;
uniform sampler2D sampler_blur5;
uniform sampler2D sampler_blur6;
uniform sampler2D sampler_noise;
uniform sampler2D sampler_noise_n;
uniform sampler2D sampler_fluid;

uniform vec4 rnd;
uniform vec4 rainbow;
uniform vec2 pixelSize;
uniform vec2 aspect;
uniform vec2 mouse;
uniform vec2 mouseV;
uniform float fps;
uniform float time;

void main(void) {
  vec2 motion = decode2( texture2D(sampler_fluid, uv))*pixelSize*0.75;
  vec2 uv = uv - motion; // add fluid motion
  vec4 noise = texture2D(sampler_noise, uv_orig + rnd.xy)-0.5; 
  
  vec2 d = pixelSize*3.5; // color delta between 2n+1 pixels (from blurred image)
  vec2 gx;
  gx.x = texture2D(sampler_blur3, uv-vec2(1.,0.)*d).x - texture2D(sampler_blur3, uv+vec2(1.,0.)*d).x;
  gx.y = texture2D(sampler_blur3, uv-vec2(0.,1.)*d).x - texture2D(sampler_blur3, uv+vec2(0.,1.)*d).x;

  vec2 uvr = uv + gx*7.*pixelSize; // makes a plane deformation vector to gradually shrink the red color patches at its borders
  
  float r = texture2D(sampler_prev, uvr).r;
  r += (texture2D(sampler_blur, uvr).r - texture2D(sampler_blur4, uv).r)*22.5/256.; // "reaction-diffusion"
  r += 2.25/256.;

  gl_FragColor.r = r;
  gl_FragColor.a = 1.;
}