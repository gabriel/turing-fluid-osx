uniform vec2 texSize;
uniform vec2 pixelSize;

uniform sampler2D sampler_fluid;

const float dt = .001;

void main(void){
	vec2 v = decode2(texture2D(sampler_fluid, uv));
  
	vec2 D = -texSize*vec2(v.x, v.y)*dt;
  
  vec2 Df = floor(D),   Dd = D - Df;
  vec2 uv = uv + Df*pixelSize;
  
	vec2 uv0, uv1, uv2, uv3;
  
	uv0 = uv + pixelSize*vec2(0.,0.);
	uv1 = uv + pixelSize*vec2(1.,0.);
	uv2 = uv + pixelSize*vec2(0.,1.);
	uv3 = uv + pixelSize*vec2(1.,1.);
  
	vec2 v0 = decode2( texture2D(sampler_fluid, uv0));
	vec2 v1 = decode2( texture2D(sampler_fluid, uv1));
	vec2 v2 = decode2( texture2D(sampler_fluid, uv2));
	vec2 v3 = decode2( texture2D(sampler_fluid, uv3));
  
	v = mix( mix( v0, v1, Dd.x), mix( v2, v3, Dd.x), Dd.y);
  
	gl_FragColor = encode2(v*(1.-border(uv, 1., texSize)));
}