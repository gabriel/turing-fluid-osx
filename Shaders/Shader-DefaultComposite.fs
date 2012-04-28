
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
  gl_FragColor = texture2D(sampler_prev, uv);
}