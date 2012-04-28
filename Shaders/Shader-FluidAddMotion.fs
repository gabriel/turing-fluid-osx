uniform sampler2D sampler_fluid;

uniform vec2 aspect;
uniform vec2 mouse; // mouse coordinate
uniform vec2 mouseV; // mouse velocity
uniform vec2 pixelSize;
uniform vec2 texSize;

float mouseFilter(vec2 uv){
	return clamp( 1.-length((uv-mouse)*texSize)/8., 0. , 1.);
}

void main(void){
	vec2 v = decode2(texture2D(sampler_fluid, uv));
  
	if(length(mouseV) > 0.)
  v = mix(v, mouseV*2., mouseFilter(uv)*0.85);
  
	gl_FragColor = encode2(v);
}