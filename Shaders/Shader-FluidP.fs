uniform vec2 pixelSize;
uniform vec2 texSize;
uniform sampler2D sampler_v;
uniform sampler2D sampler_p;
const float h = 1./1024.;

void main(void){
  
	vec2 v = decode2(texture2D(sampler_v, uv));
	float v_x = decode(texture2D(sampler_v, uv - vec2(1.,0.)*pixelSize).rg);
	float v_y = decode(texture2D(sampler_v, uv - vec2(0.,1.)*pixelSize).ba);
  
	float n = decode(texture2D(sampler_p, uv- pixelSize*vec2(0.,1.)).rg);
	float w = decode(texture2D(sampler_p, uv + pixelSize*vec2(1.,0.)).rg);
	float s = decode(texture2D(sampler_p, uv + pixelSize*vec2(0.,1.)).rg);
	float e = decode(texture2D(sampler_p, uv - pixelSize*vec2(1.,0.)).rg);
  
	float p = ( n + w + s + e - (v.x - v_x + v.y - v_y)*h ) * .25;
  
	gl_FragColor.rg = encode(p);
	gl_FragColor.ba = vec2(0.); // unused
}