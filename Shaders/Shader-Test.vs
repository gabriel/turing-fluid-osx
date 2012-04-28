attribute vec3 aPos;
attribute vec2 aTexCoord;
varying vec2 uv;
varying vec2 uv_orig;

void main(void) {
  
  // #1
  //gl_TexCoord[0] = gl_MultiTexCoord0;
  //gl_Position = ftransform(); 
  
  // #2
  //gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
  
  // #2
  gl_Position = vec4(aPos, 1.);
  uv = aTexCoord;
  uv_orig = uv;
}