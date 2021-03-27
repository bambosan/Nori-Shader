

const float pi = 3.14159265;
const float sunLightAngle = radians(28.0);

uniform float TOTAL_REAL_WORLD_TIME;

float max0(float x){ return max(0.0, x); }

float saturate(float x){ return clamp(x, 0.0, 1.0); }

float sqr2x(float x){ return x * x; }

float sqr4x(float x){ return x * x * x * x; }

vec3 toLinear(vec3 color){
	return pow(color, vec3(2.2));
}

float luma(vec3 color){
	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

vec3 tonemap(vec3 color){
	const float saturation = 1.0;
	const float exposureMult = 1.0;

	color *= exposureMult;
	color = color / (0.9813 * color + 0.1511);
	return mix(vec3(luma(color)), color, saturation);
}

#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)

vec3 calcSkyColor(float skyDepth, float height, float atten){
	vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.3, FOG_COLOR.g * 0.4, FOG_COLOR.b * 0.55));

	vec3 skyColor = mix(zenithColor, vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8), pow(skyDepth * height, atten));
		skyColor = mix(skyColor, toLinear(FOG_COLOR.rgb), wrain);

	if(FOG_CONTROL.x == 0.0) skyColor = toLinear(FOG_COLOR.rgb);
	return skyColor;
}

vec3 renderSkyColor(vec3 nposition, vec3 upPosition, float mstrength){
	float zenithSky = dot(nposition, upPosition);
	float horizonLine = 0.0;
	if(zenithSky > 0.0){
		horizonLine = 1.0-exp(-0.15 / abs(zenithSky));
	} else {
		horizonLine = 1.0-exp(-0.05 / abs(zenithSky));
	}

	float mies = sqr2x(1.0 - length(nposition.zy));
		mies += sqr4x(1.0 - length(nposition.zy)) * 1.5;
		mies *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	float skyLightFactor = horizonLine + mies * mstrength;
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
		tangentVector = vec3(0.0,0.0,-1.0);
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
