uniform sampler2D src_tex;
uniform vec2 pixelSize;

void main(void) // fragment
{
	float v = pixelSize.y;
	vec4 sum = vec4(0.0);
	sum += texture2D(src_tex, vec2(uv.x, - 4.0*v + uv.y) ) * 0.05;
	sum += texture2D(src_tex, vec2(uv.x, - 3.0*v + uv.y) ) * 0.09;
	sum += texture2D(src_tex, vec2(uv.x, - 2.0*v + uv.y) ) * 0.12;
	sum += texture2D(src_tex, vec2(uv.x, - 1.0*v + uv.y) ) * 0.15;
	sum += texture2D(src_tex, vec2(uv.x, + 0.0*v + uv.y) ) * 0.16;
	sum += texture2D(src_tex, vec2(uv.x, + 1.0*v + uv.y) ) * 0.15;
	sum += texture2D(src_tex, vec2(uv.x, + 2.0*v + uv.y) ) * 0.12;
	sum += texture2D(src_tex, vec2(uv.x, + 3.0*v + uv.y) ) * 0.09;
	sum += texture2D(src_tex, vec2(uv.x, + 4.0*v + uv.y) ) * 0.05;
  gl_FragColor.xyz = sum.xyz/0.98;
	gl_FragColor.a = 1.;
}