uniform sampler2D source;
void main(void) {
	gl_FragColor = texture2D(source, uv);
}