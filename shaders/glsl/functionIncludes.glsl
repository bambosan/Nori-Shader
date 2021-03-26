

const float pi = 3.14159265;
const float sunLightAngle = radians(28.0);

const float gamma = 2.2;
const float saturation = 1.0;
const float exposureMult = 1.3;


uniform float TOTAL_REAL_WORLD_TIME;

float max0(float x){ return max(0.0, x); }

float saturate(float x){ return clamp(x, 0.0, 1.0); }

float sqr2x(float x){ return x * x; }

float sqr4x(float x){ return x * x * x * x; }

vec3 toLinear(vec3 color){
	return pow(color, vec3(gamma));
}

float luma(vec3 color){
	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

vec3 colorCorrection(vec3 color){
	color *= exposureMult;
	color = color / (0.981354269 * color + 0.15112856);
	return mix(vec3(luma(color)), color, saturation);
}

float rand(vec2 coord){
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand_step(vec3 coord){ return rand(floor(coord.xz)); }

float drawCubeCloud1(vec3 cloudpos){
	return floor(rand_step(cloudpos * 2.0 + TOTAL_REAL_WORLD_TIME * 0.1) * 0.6 + rand_step(cloudpos * 2.0 + TOTAL_REAL_WORLD_TIME * 0.1) * 0.6);
}

#define isRain smoothstep(0.6, 0.3, FOG_CONTROL.x)

vec3 calcSkyColor(float skyDepth, float height, float atten){
	vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.3, FOG_COLOR.g * 0.4, FOG_COLOR.b * 0.55));

	vec3 skyColor = mix(zenithColor, vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8), pow(skyDepth * height, atten));
		skyColor = mix(skyColor, toLinear(FOG_COLOR.rgb), isRain);

	if(FOG_CONTROL.x == 0.0) skyColor = toLinear(FOG_COLOR.rgb);
	return skyColor;
}

float cloudFadeBorder(vec3 origin, vec3 direction){
	float totalDensity = 0.0;

	for(int i = 0; i < 10; i++){
		float cloudDensity1 = drawCubeCloud1(origin);
		if(cloudDensity1 > 0.0) totalDensity += 0.1;
		origin += direction * 0.008;
	}
	return max0(1.0-totalDensity);
}

vec4 calcCloudColor(vec3 origin, vec3 direction){
	float totalThickness = 0.0;
	float totalDensity = 0.0;

	for(int i = 0; i < 30; i++){
		float cloudDensity1 = drawCubeCloud1(origin);
		if(cloudDensity1 > 0.0){
			totalThickness = origin.y;
			totalDensity = 1.0;
			break;
		}
		origin += direction * 0.007;
	}

	float cloudShadow = smoothstep(1.5, 1.0, totalThickness);
		cloudShadow = pow(cloudShadow, 2.0);
	float cloudb = cloudFadeBorder(origin, direction);
		cloudb = cloudb * totalDensity;

	vec3 cloudColor = mix(FOG_COLOR.rgb, toLinear(FOG_COLOR.rgb * 0.5) + FOG_COLOR.rgb * cloudb, cloudShadow);
return vec4(cloudColor, totalDensity - cloudb);
}

vec3 renderSkyColor(vec3 nposition, vec3 upPosition, float mstrength){
	float zenithSky = dot(nposition, upPosition);
	float horizonLine = 0.0;
	if(zenithSky > 0.0){
		horizonLine = 1.0-exp(-0.15 / abs(zenithSky));
	} else {
		horizonLine = 1.0-exp(-0.05 / abs(zenithSky));
	}

	float mieScatter = sqr2x(1.0 - length(nposition.zy));
		mieScatter += sqr4x(1.0 - length(nposition.zy)) * 1.5;
		mieScatter *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	float skyLightFactor = horizonLine + mieScatter * mstrength;
	vec3 skyColor = calcSkyColor(skyLightFactor, 1.0, 1.0);
	return skyColor;
}

vec3 fresnelSchlick(vec3 f0, float dotproduct){
	return f0 + (1.0 - f0) * pow(1.0 - dotproduct, 5.0);
}

float ditributionGGX(float roughness, float normalDotHalf){
	float roughSquared = sqr4x(roughness);
	float d = (normalDotHalf * roughSquared - normalDotHalf) * normalDotHalf + 1.0;
	return roughSquared / (pi * d * d);
}

float geometrySchlick(float roughness, float normalDotView, float normalDotLight){
	float k = sqr2x(roughness) * 0.5;
	float view = normalDotView * (1.0 - k) + k;
	float light = normalDotLight * (1.0 - k) + k;
	return 0.25 / (view * light);
}

vec3 getTangentVector(vec3 normal){
	vec3 tangentVector;

	if(normal.x > 0.5){
		tangentVector = vec3(0.0,0.0,-1.);
	} else if(normal.x < -0.5){
		tangentVector = vec3(0.0,0.0,1.0);
	} else if(normal.y > 0.5){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(normal.y < -0.5){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(normal.z > 0.5){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(normal.z < -0.5){
		tangentVector = vec3(-1.0,0.0,0.0);
	}

	return tangentVector;
}
