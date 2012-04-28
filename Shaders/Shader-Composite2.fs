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
uniform sampler2D sampler_fluid_p;

uniform vec4 rnd;
uniform vec4 rainbow;
uniform vec2 pixelSize;
uniform vec2 aspect;
uniform vec2 mouse;
uniform vec2 mouseV;
uniform float fps;
uniform float time;

void main(void) {

  vec2 d = pixelSize*2.;
  vec2 gx;
  gx.x = texture2D(sampler_blur, uv-vec2(1.,0.)*d).x - texture2D(sampler_blur, uv+vec2(1.,0.)*d).x;
  gx.y = texture2D(sampler_blur, uv-vec2(0.,1.)*d).x - texture2D(sampler_blur, uv+vec2(0.,1.)*d).x;

  gl_FragColor.r = (0.18-texture2D(sampler_blur3, uv).r)*4. + texture2D(sampler_prev, uv).r;

  gl_FragColor = vec4(texture2D(sampler_blur, uv - gx*pixelSize*8.).x)*vec4(1.5,0.75,0.,1.);
  
  //gl_FragColor = texture2D(sampler_prev, uv); // bypass
  
  gl_FragColor.a = 1.;
  
}