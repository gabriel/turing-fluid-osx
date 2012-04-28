#ifdef GL_ES
precision mediump float;
precision mediump sampler2D;
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

