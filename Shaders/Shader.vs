attribute vec3 aPos;
attribute vec2 aTexCoord;
varying vec2 uv;
varying vec2 uv_orig;

void main(void) {
  gl_Position = vec4(aPos, 1.);
  uv = aTexCoord;
  uv_orig = uv;
}