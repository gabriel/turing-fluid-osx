uniform vec2 texSize;
uniform vec2 pixelSize;
uniform sampler2D sampler_v;
uniform sampler2D sampler_p;

void main(void){
	float p = decode(texture2D(sampler_p, uv).rg);
	vec2 v = decode2(texture2D(sampler_v, uv));
	float p_x = decode(texture2D(sampler_p, uv + vec2(1.,0.)*pixelSize).rg);
	float p_y = decode(texture2D(sampler_p, uv + vec2(0.,1.)*pixelSize).rg);
  
	v -= (vec2(p_x, p_y)-p)*512.;
  
	gl_FragColor = encode2(v);
}