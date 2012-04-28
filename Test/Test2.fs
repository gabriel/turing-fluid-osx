#ifdef GL_ES
precision mediump float;
#endif

varying vec2 uv;
varying vec2 uv_orig;

vec2 encode(float v){
	vec2 c = vec2(0.);
  
	int signum = (v >= 0.) ? 128 : 0;
	v = abs(v);
	int exponent = 15;
	float limit = 64.; // considering the bias from 2^-9 to 2^6 (==64)
	for(int exp = 15; exp > 0; exp--){
		if( v < limit){
			limit /= 2.;
			exponent--;
		}
	}
  
	float rest;
	if(exponent == 0){
		rest = v / limit / 2.;		// "subnormalize" implicite preceding 0. 
	}else{
		rest = (v - limit)/limit;		// normalize accordingly to implicite preceding 1.
	}
  
	int mantissa = int(rest * 2048.);	// 2048 = 2^11 for the (split) 11 bit mantissa
	int msb = mantissa / 256;			// the most significant 3 bits go into the lower part of the first byte
	int lsb = mantissa - msb * 256;		// there go the other 8 bit of the lower significance
  
	c.x = float(signum + exponent * 8 + msb) / 255.;	// yeah, the '+1)/255.' seems a little bit odd, but it turned out necessary on my AMD Radeon HD series
	c.y = float(lsb) / 255.;							// ^^ ...same weird color normalization for texture2D here
  
	if(v >= 2048.){
		//c.x = float( 128. + float(signum)) / 256.;
		c.y = 1.;
	}
  
	return c;
}

float decode(vec2 c){
	float v = 0.;
  
	int ix = int(c.x*255.); // 1st byte: 1 bit signum, 4 bits exponent, 3 bits mantissa (MSB)
	int iy = int(c.y*255.);	// 2nd byte: 8 bit mantissa (LSB)
  
	int s = (c.x >= 0.5) ? 1 : -1;
	ix = (s > 0) ? ix - 128 : ix; // remove the signum bit from exponent
	int iexp = ix / 8; // cut off the last 3 bits of the mantissa to select the 4 exponent bits
	int msb = ix - iexp * 8;	// subtract the exponent bits to select the 3 most significant bits of the mantissa
  
	int norm = (iexp == 0) ? 0 : 2048; // distinguish between normalized and subnormalized numbers
	int mantissa = norm + msb * 256 + iy; // implicite preceding 1 or 0 added here
	norm = (iexp == 0) ? 1 : 0; // normalization toggle
	float exponent = pow( 2., float(iexp + norm) - 20.); // -9 for the the exponent bias from 2^-9 to 2^6 plus another -11 for the normalized 12 bit mantissa 
	v = float( s * mantissa ) * exponent;
  
	return v;
}

vec4 encode2(vec2 v){
	return vec4( encode(v.x), encode(v.y) );
}

vec2 decode2(vec4 c){
	return vec2( decode(c.rg), decode(c.ba) );
}

bool is_onscreen(vec2 uv){
	return (uv.x < 1.) && (uv.x > 0.) && (uv.y < 1.) && (uv.y > 0.);
}

float border(vec2 uv, float border, vec2 texSize){
	uv*=texSize;
	return (uv.x<border || uv.x>texSize.x-border || uv.y<border || uv.y >texSize.y-border) ? 1.:.0;
}

uniform sampler2D sampler_prev;
uniform sampler2D sampler_prev_n;
uniform sampler2D sampler_blur;
uniform sampler2D sampler_blur2;
uniform sampler2D sampler_blur3;
uniform sampler2D sampler_blur4;
uniform sampler2D sampler_blur5;
uniform sampler2D sampler_blur6;
uniform sampler2D sampler_noise;
uniform sampler2D sampler_noise_n;
uniform sampler2D sampler_fluid;

uniform vec4 rnd;
uniform vec4 rainbow;
uniform vec2 pixelSize;
uniform vec2 aspect;
uniform vec2 mouse;
uniform vec2 mouseV;
uniform float fps;
uniform float time;

void main(void) {
  vec2 motion = decode2( texture2D(sampler_fluid, uv))*pixelSize*0.75;
  
  vec2 uv = uv - motion; // add fluid motion
  vec4 noise = texture2D(sampler_noise, uv_orig + rnd.xy)-0.5; 
  
  gl_FragColor.y = texture2D(sampler_prev, uv).y + noise.y*1./256.;
  gl_FragColor.y += (texture2D(sampler_prev, uv).y-texture2D(sampler_blur5, uv).y)*1./64.;
  
  vec2 d = pixelSize*8.;
  vec2 gy; // gradient in green
  gy.x = texture2D(sampler_blur2, uv_orig-vec2(1.,0.)*d).y - texture2D(sampler_blur2, uv_orig+vec2(1.,0.)*d).y;
  gy.y = texture2D(sampler_blur2, uv_orig-vec2(0.,1.)*d).y - texture2D(sampler_blur2, uv_orig+vec2(0.,1.)*d).y;
  
  d = pixelSize*4.;
  vec2 gz; // gradient in blue
  gz.x = texture2D(sampler_blur, uv_orig-vec2(1.,0.)*d).z - texture2D(sampler_blur, uv_orig+vec2(1.,0.)*d).z;
  gz.y = texture2D(sampler_blur, uv_orig-vec2(0.,1.)*d).z - texture2D(sampler_blur, uv_orig+vec2(0.,1.)*d).z;
  
  uv = uv_orig - motion + gz.yx*vec2(-1.,1.)*pixelSize*2.0;
  
  gl_FragColor.z = texture2D(sampler_prev, uv).z;
  gl_FragColor.z += (texture2D(sampler_prev, uv).z-texture2D(sampler_blur3, uv).z)*28./256.;
  
  gl_FragColor.z +=  - (gl_FragColor.y-0.255)*1./128.;
  
  vec2 gx; // gradient in blue
  gx.x = texture2D(sampler_blur, uv_orig-vec2(1.,0.)*d).x - texture2D(sampler_blur, uv_orig+vec2(1.,0.)*d).x;
  gx.y = texture2D(sampler_blur, uv_orig-vec2(0.,1.)*d).x - texture2D(sampler_blur, uv_orig+vec2(0.,1.)*d).x;
  
  uv =  uv_orig - motion - gx.yx*vec2(-1.,1.)*pixelSize*2.;
  
  gl_FragColor.x = texture2D(sampler_prev, uv).x;
  gl_FragColor.x += (texture2D(sampler_prev, uv).x-texture2D(sampler_blur3, uv).x)*28./256.; // "reaction-diffusion"
  gl_FragColor.x +=  - (0.745-gl_FragColor.y)*1./128.;
    
	gl_FragColor.a = 1.;
}
