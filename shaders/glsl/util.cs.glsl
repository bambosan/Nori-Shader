

//////////////////////////////////////////////////////////////
///////////////// ADJUSTABLE VARIABLE ////////////////////////
//////////////////////////////////////////////////////////////

//#define ENABLE_CLOUD
#define CLOUD_SHADOW_START 0.0 // from bottom
#define CLOUD_SHADOW_END 0.2 // to top
#define CLOUD_STEP 20
#define CLOUD_THICNESS 0.016 // layer space

//#define ENABLE_REFLECTION

////// wip
#define ENABLE_PARALLAX
#define PARALLAX_RES 64.0
#define PARALLAX_DEPTH 0.008
#define PARALLAX_STEP 25

#define ENABLE_PARALLAX_SHADOW
#define PSHADOW_STEP 10
#define PSHADOW_OFFSET 0.00015

////// terrain texture
#define ADJUST_MIPMAP 0.5

////// lighting
#define SUN_LIGHT_ANGLE radians(28.0) // all lighting angle (bump map, parallax shadow and diffuse lighting) set value in degrees 0 - 180

#define SATURATION 1.05
#define EXPOSURE_MULTIPLICATION 1.2

/// debugging section
//#define LOOK_NORMALS
//#define LOOK_ATLAS_TERRAIN
//#define LOOK_METALLIC
//#define LOOK_EMISSION
//#define LOOK_ROUGHNESS

///////////////////////////////////////////////////////////////
////////////// END OF ADJUSTABLE VARIABLE /////////////////////
///////////////////////////////////////////////////////////////

#define pi 3.14159265
#define max0(x) max(0.0, x)
#define saturate(x) clamp(x, 0.0, 1.0)
#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)
#define fnight pow(saturate(1.0 - FOG_COLOR.r * 1.5), 1.2)

float sqr2x(float x){ return x * x; }
float sqr4x(float x){ return x * x * x * x; }
vec3 toLinear(vec3 color){ return pow(color, vec3(2.2)); }

vec3 colorCorrection(vec3 color){
	color *= EXPOSURE_MULTIPLICATION;
	color = color / (0.9813 * color + 0.1511);

	float lum = dot(color, vec3(0.2125, 0.7154, 0.0721));
	color = mix(vec3(lum), color, SATURATION);
	return color;
}

vec3 calcSkyColor(float skyhorizon){

	vec3 linfogC = toLinear(FOG_COLOR.rgb);
	vec3 zenithColor = vec3(linfogC.r * 0.15, linfogC.g * 0.2, linfogC.b * 0.25);

	vec3 horColor = vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8) + vec3(0.1, 0.15, 0.2) * fnight;

		zenithColor = mix(zenithColor, horColor, skyhorizon);
		zenithColor = mix(zenithColor, linfogC * 2.0, wrain);

	if(FOG_CONTROL.x == 0.0) zenithColor = linfogC;

	return zenithColor;
}

vec3 renderSkyColor(vec3 nworldpos, vec3 upPosition, float miestrength){

	float horizonLine = 1.0 - exp(-0.1 / abs(dot(nworldpos, upPosition)));

	float mies = sqr2x(1.0 - length(nworldpos.zy));
		mies += sqr4x(1.0 - length(nworldpos.zy)) * 1.5;
		mies *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	float skyHor = horizonLine + (mies * miestrength);
	vec3 skyColor = calcSkyColor(skyHor);

	return skyColor;
}

#ifdef ENABLE_CLOUD
float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(12.9898,78.233))) * 43758.5453);
}
float srand(vec2 coord){ return rand(floor(coord)); }

uniform float TOTAL_REAL_WORLD_TIME;

float randomStep(vec3 pos){
	float rands = srand(pos.xz * 2.0 + TOTAL_REAL_WORLD_TIME * 0.1) * 0.6;
	return floor(rands + rands);
}

vec4 calcCloudColor(vec3 origin, vec3 direction){
	float numSteps = 0.0;
	float totalDensity = 0.0;

	for(int i = 0; i < CLOUD_STEP; i++){
		float cloudDen = randomStep(origin);
		if(cloudDen > 0.0){
			numSteps = origin.y;
			totalDensity = 1.0;
			break;
		}
		origin += direction * CLOUD_THICNESS;
	}

	float cloudShadow = smoothstep(1.0 + CLOUD_SHADOW_START, 1.0 + CLOUD_SHADOW_END, numSteps);
		cloudShadow = pow(cloudShadow, 2.0);
	vec3 cloudColor = calcSkyColor(cloudShadow);

	return vec4(cloudColor, totalDensity);
}
#endif

vec3 getTangent(vec3 normal){
	vec3 tangent = vec3(0, 0, 0);
	if(normal.x > 0.0){ tangent = vec3(0, 0, -1);
	} else if(-normal.x > 0.0){ tangent = vec3(0, 0, 1);

	} else if(normal.y > 0.0){ tangent = vec3(1, 0, 0);
	} else if(-normal.y > 0.0){ tangent = vec3(1, 0, 0);

	} else if(normal.z > 0.0){ tangent = vec3(1, 0, 0);
	} else if(-normal.z > 0.0){ tangent = vec3(-1, 0, 0);
	}
	return tangent;
}
