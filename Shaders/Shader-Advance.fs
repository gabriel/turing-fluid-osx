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
  
  gl_FragColor.y = texture2D(sampler_prev, uv).y + noise.y*1./256.;
  gl_FragColor.y += (texture2D(sampler_prev, uv).y-texture2D(sampler_blur5, uv).y)*1./64.;
  
  vec2 d = pixelSize*8.;
  vec2 gy; // gradient in green
  gy.x = texture2D(sampler_blur2, uv_orig-vec2(1.,0.)*d).y - texture2D(sampler_blur2, uv_orig+vec2(1.,0.)*d).y;
  gy.y = texture2D(sampler_blur2, uv_orig-vec2(0.,1.)*d).y - texture2D(sampler_blur2, uv_orig+vec2(0.,1.)*d).y;
  
  d = pixelSize*4.;
  vec2 gz; // gradient in blue
  gz.x = texture2D(sampler_blur, uv_orig-vec2(1.,0.)*d).z - texture2D(sampler_blur, uv_orig+vec2(1.,0.)*d).z;
  gz.y = texture2D(sampler_blur, uv_orig-vec2(0.,1.)*d).z - texture2D(sampler_blur, uv_orig+vec2(0.,1.)*d).z;
  
  uv = uv_orig - motion + gz.yx*vec2(-1.,1.)*pixelSize*2.0;
  
  gl_FragColor.z = texture2D(sampler_prev, uv).z;
  gl_FragColor.z += (texture2D(sampler_prev, uv).z-texture2D(sampler_blur3, uv).z)*28./256.;
  
  gl_FragColor.z +=  - (gl_FragColor.y-0.255)*1./128.;
  
  vec2 gx; // gradient in blue
  gx.x = texture2D(sampler_blur, uv_orig-vec2(1.,0.)*d).x - texture2D(sampler_blur, uv_orig+vec2(1.,0.)*d).x;
  gx.y = texture2D(sampler_blur, uv_orig-vec2(0.,1.)*d).x - texture2D(sampler_blur, uv_orig+vec2(0.,1.)*d).x;
  
  uv =  uv_orig - motion - gx.yx*vec2(-1.,1.)*pixelSize*2.;
  
  gl_FragColor.x = texture2D(sampler_prev, uv).x;
  gl_FragColor.x += (texture2D(sampler_prev, uv).x-texture2D(sampler_blur3, uv).x)*28./256.; // "reaction-diffusion"
  gl_FragColor.x +=  - (0.745-gl_FragColor.y)*1./128.;
    
	gl_FragColor.a = 1.;
}