
uniform sampler2D sampler;
uniform sampler2D sampler_fluid;

uniform vec4 rnd;
uniform vec2 pixelSize;
uniform vec2 aspect;
uniform vec2 mouse;
uniform vec2 mouseV;
uniform float fps;
uniform float time;

void main(void) {
  vec2 motion = decode2(texture2D(sampler_fluid, uv))*pixelSize*0.75;
  
  vec2 uv = uv - motion; // add fluid motion
  
  gl_FragColor = texture2D(sampler, uv);
  //gl_FragColor.a = 1.;

}