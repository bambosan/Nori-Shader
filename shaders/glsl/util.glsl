precision highp float;

const float pi = 3.14159265;
const float sunLightAngle = radians(28.0); // in degrees
const float textureDistanceLod = 0.5; // mip levels


uniform float TOTAL_REAL_WORLD_TIME;

float max0(float x){ return max(0.0, x); }

float saturate(float x){ return clamp(x, 0.0, 1.0); }

float sqr2x(float x){ return x * x; }

float sqr4x(float x){ return x * x * x * x; }

struct fmaterials {
	float metallic;
	float emissive;
	float roughness;
	float surfacesmooth;
	float shadowm;
	float skyhorizon;
	float miestrength;
	float normaldotlight;
	float normaldothalf;
	float normaldotview;
} materials;

struct posvector {
	vec3 lworldpos;
	vec3 nworldpos;
	vec3 lightpos;
	vec3 upposition;
	vec3 normal;
	vec3 normalv;
	vec3 albedolinear;
} posvec;

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
	color = mix(vec3(luma(color)), color, saturation);

	return color;
}

#define wrain smoothstep(0.6, 0.3, FOG_CONTROL.x)
#define fnight pow(saturate(1.0 - FOG_COLOR.r * 1.5), 1.2)

vec3 calcSkyColor(in fmaterials materials){
	vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.3, FOG_COLOR.g * 0.4, FOG_COLOR.b * 0.55));

	vec3 skyColor = mix(zenithColor, vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8) + vec3(0.1, 0.15, 0.2) * fnight, materials.skyhorizon);

		skyColor = mix(skyColor, toLinear(FOG_COLOR.rgb) * 2.0, wrain);

	if(FOG_CONTROL.x == 0.0) skyColor = toLinear(FOG_COLOR.rgb);
	return skyColor;
}

vec3 renderSkyColor(in posvector posvec, in fmaterials materials){
	float zenithSky = dot(posvec.nworldpos, posvec.upposition);
	float horizonLine = 1.0-exp(-0.1 / abs(zenithSky));

	float mies = sqr2x(1.0 - length(posvec.nworldpos.zy));
		mies += sqr4x(1.0 - length(posvec.nworldpos.zy)) * 1.5;
		mies *= saturate((FOG_COLOR.r - 0.15) * 1.25) * (1.0 - FOG_COLOR.b);

	materials.skyhorizon = horizonLine + mies * materials.miestrength;
	vec3 skyColor = calcSkyColor(materials);
	return skyColor;
}

vec3 fresnelSchlick(vec3 f0, in fmaterials materials){
	return f0 + (1.0 - f0) * pow(1.0 - materials.normaldotview, 5.0);
}

float ditributionGGX(in fmaterials materials){
	float roughSquared = sqr4x(materials.roughness);
	float d = (materials.normaldothalf * roughSquared - materials.normaldothalf) * materials.normaldothalf + 1.0;
	return roughSquared / (pi * d * d);
}

float geometrySchlick(in fmaterials materials){
	float k = sqr2x(materials.roughness) * 0.5;
	float view = materials.normaldotview * (1.0 - k) + k;
	float light = materials.normaldotlight * (1.0 - k) + k;
	return 0.25 / (view * light);
}

vec3 getTangentVector(in posvector posvec){
	vec3 tangentVector;

	if(posvec.normalv.x > 0.0){
		tangentVector = vec3(0.0,0.0,-1.0);
	} else if(-posvec.normalv.x > 0.0){
		tangentVector = vec3(0.0,0.0,1.0);
	} else if(posvec.normalv.y > 0.0){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(-posvec.normalv.y > 0.0){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(posvec.normalv.z > 0.0){
		tangentVector = vec3(1.0,0.0,0.0);
	} else if(-posvec.normalv.z > 0.0){
		tangentVector = vec3(-1.0,0.0,0.0);
	}

	return tangentVector;
}
