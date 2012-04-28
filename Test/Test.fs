uniform sampler2D texture0;

void main(void) {
	gl_FragColor = texture2D(texture0, gl_TexCoord[0].xy);
}