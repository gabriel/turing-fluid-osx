#ifdef GL_ES
precision mediump float;
precision mediump sampler2D;
#endif

// #1
//uniform sampler2D texture0;

// #3
uniform sampler2D source;
varying vec2 uv;
varying vec2 uv_orig;

void main(void) {
  
  // #1
	//gl_FragColor = texture2D(texture0, gl_TexCoord[0].xy);
  
  // #2
  //gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  
  // #3
  gl_FragColor = texture2D(source, uv);
}