//////////////////////////////////////////////////////////////
///////////////// ADJUSTABLE VARIABLE ////////////////////////
//////////////////////////////////////////////////////////////

#define DYNAMIC_LIGHT_ANGLE
#define DYNAMIC_L_ANGLE_SPEED 0.008
#define SUN_LIGHT_ANGLE radians(40.0) // will affected when disabling DYNAMIC_LIGHT_ANGLE
#define SUN_PATH_ROTATION radians(-30.0)

#define SKY_COEFF_R 0.03
#define SKY_COEFF_G 0.047
#define SKY_COEFF_B 0.09
#define SKY_NIGHT_SATURATION 0.6
#define SKY_MIE_COEFF 0.004
#define SKY_MIE_G 0.75

#define BLOCK_LIGHT_C_R 1.0
#define BLOCK_LIGHT_C_G 0.45
#define BLOCK_LIGHT_C_B 0.0

#define ENABLE_PRIMARY_FOG
#define ENABLE_SECONDARY_FOG
#define SECONDARY_FOG_DISTANCE 100.0
#define SS_FOG_INTENSITY 0.3
#define NOON_FOG_INTENSITY 0.1
#define RAIN_FOG_INTENSITY 1.0
#define FOG_MIE_COEFF 0.05
#define FOG_MIE_G 0.75

//#define ENABLE_REFLECTION
#define ROUGHNESS_POWER 2.2
#define SMOOTHNESS_TRESHOLD 1.0

//#define ENABLE_PARALLAX
#define PARALLAX_RES 64.0
#define PARALLAX_DEPTH 0.008
#define PARALLAX_STEP 20
//#define ENABLE_PARALLAX_SHADOW
#define PSHADOW_STEP 10
#define PSHADOW_OFFSET 0.00015

#define ADJUST_MIPMAP 0.5
#define SATURATION 1.1
#define EXPOSURE_MULTIPLICATION 1.0

///////////////////////////////////////////////////////////////
////////////// END OF ADJUSTABLE VARIABLE /////////////////////
///////////////////////////////////////////////////////////////

uniform highp float TOTAL_REAL_WORLD_TIME;

const float pi = 3.14159265;
const float hpi = 1.57079633;
const float invpi = 0.31830989;
const float tau = 6.28318531;
const float invtau = 0.15915494;

// debugging
const int showvalue = 0; // 0 off, 1 show linear, 2 show normal, 3 show atlas terrain, 4 show metallic, 5 show emission, 6 show roughness.

#define max0(x) max(0.0, x)
#define saturate(x) clamp(x, 0.0, 1.0)
#define rotate2d(r) mat2(cos(r), sin(r), -sin(r), cos(r))
#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)

float bayer2(vec2 coord){
	coord = floor(coord);
	return fract(dot(coord, vec2(0.5, coord.y * 0.75)));
}

float bayer4(vec2 coord){
	return bayer2(0.5 * coord) * 0.25 + bayer2(coord);
}

float bayer8(vec2 coord){
	return bayer4(0.5 * coord) * 0.25 + bayer2(coord);
}

float bayer64(vec2 coord){
	return bayer8(0.125 * coord) * 0.015625 + bayer8(coord);
}

vec3 toLinear(vec3 color){
	return mix(color / 12.92, pow(0.947867 * color + 0.0521327, vec3(2.4)), step(0.04045, color));
}

vec3 toSrgb(vec3 color){
	return mix(color * 12.92, pow(color, vec3(1.0 / 2.4)) * 1.055 - 0.055, step(0.0031308, color));
}

float luma(vec3 color){
	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

vec2 pDens(vec3 pos){
	float d = -2.0 * dot(pos, vec3(0, 900, 0));
	return vec2(sqrt(365e3 + d * d - 36e4) + d, sqrt(375e3 + d * d - 36e4) + d);
}

float rPhase(float cosT){
	return 0.375 * (cosT * cosT + 1.0);
}

float mPhase(float cosT, float g){
	float g2 = g * g;
	return (1.0 / 4.0 * pi) * ((1.0 - g2) / pow(1.0 + g2 - 2.0 * g * cosT, 1.5));
}

// aces approxmiation https://github.com/TheRealMJP/BakingLab/blob/master/LICENSE
vec3 RRTandODTFit(vec3 color){
	vec3 a = color * (color + 0.0245786) - 0.000090537;
	vec3 b = color * (0.983729 * color + 0.4329510) + 0.238081;
	return a / b;
}

vec3 ACESFitted(vec3 color){
	color *= mat3(0.59719, 0.35458, 0.04823, 0.07600, 0.90834, 0.01566, 0.02840, 0.13383, 0.83777);
	color = RRTandODTFit(color);
	color *= mat3(1.60475, -0.53108, -0.07367, -0.10208,  1.10813, -0.00605, -0.00327, -0.07276,  1.07602);
	color = saturate(color);
	return color;
}

vec3 colorCorrection(vec3 color){
	color *= EXPOSURE_MULTIPLICATION;
	if(showvalue == 1){ color = color;
	} else {
		color = ACESFitted(color);
		color = toSrgb(color);
	}
	color = mix(vec3(luma(color)), color, SATURATION);
	return color;
}

// atmospheric scattering https://www.shadertoy.com/view/4llfDS
vec3 calcAtmospScatter(vec3 nWPos, vec3 sunPos, out vec3 sabsorb, out vec3 mabsorb, out vec3 vabsorb){
	const vec3 rCoeff = vec3(SKY_COEFF_R, SKY_COEFF_G, SKY_COEFF_B);
	float mCoeff = mix(SKY_MIE_COEFF, 0.5, wrain);
	float mieg = mix(SKY_MIE_G, 0.3, wrain);
	float scdist = max0(1.0 - distance(nWPos, sunPos)), mcdist = max0(1.0 - distance(nWPos, sunPos));
	float vOD = pDens(nWPos).x;
	float suOD = pDens(sunPos).y;
	float moOD = pDens(-sunPos).y;

#define sc(coeff, coeff2, d) (coeff * d + coeff2 * d)
	float dRPhase = rPhase(scdist), dMPhase = mPhase(scdist, 0.0 + mieg * exp2(-vOD * 0.005));
	vec3 dPhase = sc(rCoeff * dRPhase, mCoeff * dMPhase, vOD);

	float nRPhase = rPhase(mcdist), nMPhase = mPhase(mcdist, 0.0 + mieg * exp2(-vOD * 0.005));
	vec3 nPhase = sc(rCoeff * nRPhase, mCoeff * nMPhase, vOD);

#define ab(coeff, coeff2, d) exp2(-sc(coeff, coeff2, d))
	sabsorb = ab(rCoeff, mCoeff, suOD);
	mabsorb = ab(rCoeff, mCoeff, moOD);
	vabsorb = ab(rCoeff, mCoeff, vOD);
#undef ab

#define tsc(a, a2, s, s2, p) (abs(a - a2) / abs(s - s2)) * p
	vec3 dscatter = tsc(sabsorb, vabsorb, sc(rCoeff, mCoeff, suOD), sc(rCoeff, mCoeff, vOD), dPhase) * (2.0 + tau * exp2(-vOD * 0.01));
	vec3 nscatter = tsc(mabsorb, vabsorb, sc(rCoeff, mCoeff, moOD), sc(rCoeff, mCoeff, vOD), nPhase) * (0.0 + 1.0 * exp2(-vOD * 0.01));
#undef tsc
		nscatter = mix(vec3(luma(nscatter)), nscatter, SKY_NIGHT_SATURATION) * invpi;
	return dscatter + nscatter;
#undef sc
}

float getdisk(vec3 spos, vec3 dpos, float size){
	float angle = saturate((1.0 - dot(spos, dpos)) * size);
	return cos(angle * hpi);
}

vec3 calcSky(vec3 nWPos, vec3 sunPos){
	vec3 useless = vec3(0.0), absorbc = vec3(0.0);
	vec3 totalSky = calcAtmospScatter(nWPos, sunPos, useless, useless, absorbc);

	float vOD = pDens(nWPos).x;
		absorbc = mix(vec3(0.0), absorbc, exp2(-vOD * 0.1));
		totalSky += absorbc * 1e3 * getdisk(nWPos, sunPos, 3e3);
		totalSky += absorbc * 5e2 * getdisk(nWPos, -sunPos, 6e3);
	return totalSky;
}

void lirradiance(vec3 sunPos, out vec3 sunC, out vec3 moonC, out vec3 szColor){
	sunC = vec3(0.0), moonC = vec3(0.0);
	vec3 useless = vec3(0.0);
	szColor = calcAtmospScatter(vec3(0, 1, 0), sunPos, sunC, moonC, useless);
	sunC *= pi, moonC = vec3(luma(moonC)) * invpi, szColor *= pi;
}

void calcLpos(out vec3 tlPos, out vec3 lPos){
	#ifdef DYNAMIC_LIGHT_ANGLE
		highp float ang = TOTAL_REAL_WORLD_TIME * DYNAMIC_L_ANGLE_SPEED;
		lPos = normalize(vec3(cos(ang), sin(ang), 0.0));
	#else
		lPos = normalize(vec3(cos(SUN_LIGHT_ANGLE), sin(SUN_LIGHT_ANGLE), 0.0));
	#endif
	lPos.yz *= rotate2d(SUN_PATH_ROTATION);
	tlPos = lPos.y >= 0.0 ? lPos : -lPos;
}

vec3 toTangent(vec3 n){
	vec3 t = vec3(0, 0, 0);
	if(n.x > 0.0){ t = vec3(0, 0, -1); } else if(n.x < -0.5){ t = vec3(0, 0, 1);
	} else if(n.y > 0.0){ t = vec3(1, 0, 0); } else if(n.y < -0.5){ t = vec3(1, 0, 0);
	} else if(n.z > 0.0){ t = vec3(1, 0, 0); } else if(n.z < -0.5){ t = vec3(-1, 0, 0); }
	return t;
}
