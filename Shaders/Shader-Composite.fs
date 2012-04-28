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
  gl_FragColor = vec4(1.-abs(texture2D(sampler_prev, uv).y*2.-1.));
  
  vec2 d = pixelSize*1.;
  vec2 gy; // green uv gradient vector
  gy.x = texture2D(sampler_prev, uv-vec2(1.,0.)*d).y - texture2D(sampler_prev, uv+vec2(1.,0.)*d).y;
  gy.y = texture2D(sampler_prev, uv-vec2(0.,1.)*d).y - texture2D(sampler_prev, uv+vec2(0.,1.)*d).y;
  
  d = pixelSize*4.;
  
  vec2 gz; // blue blur2 gradient vector
  gz.x += texture2D(sampler_blur2, uv-vec2(1.,0.)*d).z - texture2D(sampler_blur2, uv+vec2(1.,0.)*d).z;
  gz.y += texture2D(sampler_blur2, uv-vec2(0.,1.)*d).z - texture2D(sampler_blur2, uv+vec2(0.,1.)*d).z;
  
  gl_FragColor = vec4(0.);
  
  gl_FragColor.y = texture2D(sampler_prev, uv + gz*pixelSize*64.).y*0.4 - (gz.x + gz.y)*0.4 + 0.4;
  gl_FragColor.z = texture2D(sampler_blur4, uv + 80.*pixelSize*gy - gz ).z*1.75 -0.0;
  
  gl_FragColor.yz *= 1.- texture2D(sampler_blur4, uv).x*2.5;
  gl_FragColor.x = texture2D(sampler_prev, uv).x*1.+0.25;
  
  gl_FragColor.y += gl_FragColor.x;
  
  gl_FragColor.yz *= vec2(0.75,1.)- texture2D(sampler_blur4, uv).z*1.5;
  gl_FragColor.z += texture2D(sampler_prev, uv).z*1.5;
  gl_FragColor.y += gl_FragColor.z*0.5 - 0.1;
  
  
	gl_FragColor.a = 1.;
}