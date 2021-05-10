
//////////////////////////////////////////////////////////////
///////////////// ADJUSTABLE VARIABLE ////////////////////////
//////////////////////////////////////////////////////////////

const float sunLightAngle = radians(28.0); // in degrees 0 - 180
const float textureDistanceLod = 0.5; // mip levels
const float saturation = 1.05;
const float exposureMult = 1.2;
const float cloudShadowStart = 0.0;
const float cloudShadowEnd = 0.3;

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
lp vec3 toLinear(vec3 color){ return pow(color, vec3(2.2)); }

vec3 tonemap(vec3 color){
	color *= exposureMult;
	color = color / (0.9813 * color + 0.1511);

	lp float lum = dot(color, vec3(0.2125, 0.7154, 0.0721));
	color = mix(vec3(lum), color, saturation);
	return color;
}

vec3 calcSkyColor(float skyhorizon){
	lp vec3 linfogC = toLinear(FOG_COLOR.rgb);
	lp vec3 zenithColor = vec3(linfogC.r * 0.15, linfogC.g * 0.2, linfogC.b * 0.25);

	lp vec3 horColor = vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8) + vec3(0.1, 0.15, 0.2) * fnight;

		zenithColor = mix(zenithColor, horColor, skyhorizon);
		zenithColor = mix(zenithColor, linfogC * 2.0, wrain);

	if(FOG_CONTROL.x == 0.0) zenithColor = linfogC;

	return zenithColor;
}

vec3 renderSkyColor(vec3 nworldpos, vec3 upposition, lp float miestrength){
	float zenithsky = dot(nworldpos, upposition);

	float horizonline = 1.0 - exp(-0.1 / abs(zenithsky));

	float mies = sqr2x(1.0 - length(nworldpos.zy));
		mies += sqr4x(1.0 - length(nworldpos.zy)) * 1.5;
		mies *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	float skyhorizon = horizonline + (mies * miestrength);
	vec3 skyColor = calcSkyColor(skyhorizon);
	return skyColor;
}

float rand(vec2 coord){
	return fract(sin(dot(coord.xy,vec2(12.9898,78.233))) * 43758.5453);
}
float rand_step(vec3 coord){
	return rand(floor(coord.xz));
}

uniform float TOTAL_REAL_WORLD_TIME;

float drawRandomCube(vec3 wpos){
	float random = rand_step(wpos * 2.0 + TOTAL_REAL_WORLD_TIME * 0.1) * 0.6;
	return floor(random + random);
}

float cloudBorder(vec3 origin, vec3 direction){
	float totalDensity = 0.0;

	for(int i = 0; i < 10; i++){
		float cloudDen = drawRandomCube(origin);
		if(cloudDen > 0.0) totalDensity += 0.1;
		origin += direction * 0.007;
	}
	return max0(1.0 - totalDensity);
}

vec4 calcCloudColor(vec3 origin, vec3 direction){
	float numSteps = 0.0;
	float totalDensity = 0.0;

	for(int i = 0; i < 20; i++){
		float cloudDen = drawRandomCube(origin);
		if(cloudDen > 0.0){
			numSteps = origin.y;
			totalDensity = 1.0;
			break;
		}
		origin += direction * 0.015;
	}

	float cloudShadow = smoothstep(1.0 + cloudShadowStart, 1.0 + cloudShadowEnd, numSteps);
		cloudShadow = pow(cloudShadow, 2.0);
	float cloudb = cloudBorder(origin, direction);

	vec3 cloudColor = calcSkyColor(cloudShadow) + calcSkyColor(cloudb) * 0.3;
	return vec4(cloudColor, totalDensity);
}

vec3 getTangentVector(mp vec3 normalv){
	mp vec3 tangent = vec3(0, 0, 0);
	if(normalv.x > 0.0){ tangent = vec3(0, 0, -1);
	} else if(-normalv.x > 0.0){
		tangent = vec3(0, 0, 1);

	} else if(normalv.y > 0.0){ tangent = vec3(1, 0, 0);
	} else if(-normalv.y > 0.0){
		tangent = vec3(1, 0, 0);

	} else if(normalv.z > 0.0){ tangent = vec3(1, 0, 0);
	} else if(-normalv.z > 0.0){
		tangent = vec3(-1, 0, 0);
	}
	return tangent;
}
