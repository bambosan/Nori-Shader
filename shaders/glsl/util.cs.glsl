
//////////////////////////////////////////////////////////////
///////////////// ADJUSTABLE VARIABLE ////////////////////////
//////////////////////////////////////////////////////////////

const float sunLightAngle = radians(28.0); // in degrees. 0 - 180 is daytime && 180 - 360 is nighttime
const float textureDistanceLod = 0.5; // mip levels
const float saturation = 1.05;
const float exposureMult = 1.2;

///////////////////////////////////////////////////////////////
/////////////// END OF ADJUSTABLE VARIABLE ////////////////////
///////////////////////////////////////////////////////////////

const float pi = 3.14159265;
#define max0(x) max(0.0, x)
#define saturate(x) clamp(x, 0.0, 1.0)
#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)
#define fnight pow(saturate(1.0 - FOG_COLOR.r * 1.5), 1.2)

float sqr2x(float x){ return x * x; }
float sqr4x(float x){ return x * x * x * x; }
vec3 toLinear(vec3 color){ return pow(color, vec3(2.2)); }

vec3 tonemap(vec3 color){
	color *= exposureMult;
	color = color / (0.9813 * color + 0.1511);
	float luma = dot(color, vec3(0.2125, 0.7154, 0.0721));
	color = mix(vec3(luma), color, saturation);
	return color;
}

vec3 calcSkyColor(float skyhorizon){
	vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.3, FOG_COLOR.g * 0.4, FOG_COLOR.b * 0.5));

	vec3 skyColor = mix(zenithColor, vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8) + vec3(0.1, 0.15, 0.2) * fnight, skyhorizon);
		skyColor = mix(skyColor, toLinear(FOG_COLOR.rgb) * 2.0, wrain);

	if(FOG_CONTROL.x == 0.0) skyColor = toLinear(FOG_COLOR.rgb);
	return skyColor;
}

vec3 renderSkyColor(vec3 nworldpos, vec3 upposition, float miestrength){
	float zenithsky = dot(nworldpos, upposition);
	float horizonline = 1.0-exp(-0.1 / abs(zenithsky));

	float mies = sqr2x(1.0 - length(nworldpos.zy));
		mies += sqr4x(1.0 - length(nworldpos.zy)) * 1.5;
		mies *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	float skyhorizon = horizonline + (mies * miestrength);
	vec3 skyColor = calcSkyColor(skyhorizon);
	return skyColor;
}

vec3 getTangentVector(vec3 normalv){
	vec3 tangent;
	if(normalv.x > 0.0){ tangent = vec3(0.0,0.0,-1.0);
	} else if(-normalv.x > 0.0){
		tangent = vec3(0.0,0.0,1.0);

	} else if(normalv.y > 0.0){ tangent = vec3(1.0,0.0,0.0);
	} else if(-normalv.y > 0.0){
		tangent = vec3(1.0,0.0,0.0);

	} else if(normalv.z > 0.0){ tangent = vec3(1.0,0.0,0.0);
	} else if(-normalv.z > 0.0){
		tangent = vec3(-1.0,0.0,0.0);
	}
	return tangent;
}
