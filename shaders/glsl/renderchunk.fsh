#version 300 es

in mediump vec4 vcolor;

precision highp float;

uniform sampler2D TEXTURE_0;
uniform sampler2D TEXTURE_1;
uniform sampler2D TEXTURE_2;

#ifdef FOG
	in float fogalpha;
#endif

in vec3 perchunkpos;
in vec3 worldpos;
in vec2 uv0;
in vec2 uv1;

#include "util.cs.glsl"

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

vec3 illummination(in vec3 albedoot, in posvector posvec, in fmaterials materials){
	float lightmapbrightness = texture(TEXTURE_1, vec2(0, 1)).r;

	vec3 ambientcolor = vec3(0.3, 0.3, 0.3) * (1.0 - (wrain * 0.4 + fnight * 0.6));
		ambientcolor *= uv1.y;

	float adaptivebls = smoothstep(lightmapbrightness * uv1.y, 1.0, uv1.x);
	float blocklightsource;
		blocklightsource = mix(mix(blocklightsource, uv1.x, adaptivebls), uv1.x, wrain);

		ambientcolor += vec3(1.0, 0.5, 0.2) * blocklightsource + pow(blocklightsource * 1.15, 5.0);

	float difflightr = FOG_COLOR.r * max0(1.0 - fnight * 0.4);
	float difflightg = FOG_COLOR.g * max0(0.9 - fnight * 0.1);
	float difflightb = FOG_COLOR.b * (0.8 + fnight * 0.2);

	vec3 diffuselightcolor = vec3(difflightr, difflightg, difflightb) * 3.0 * materials.normaldotlight;
		ambientcolor += diffuselightcolor * materials.shadowm * (1.0 - wrain);

	albedoot = albedoot * ambientcolor;
	albedoot += saturate(materials.emissive) * posvec.albedolinear * 5.0;

	vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.4, FOG_COLOR.g * 0.5, FOG_COLOR.b * 0.6));

	float rim = mix(0.5, 1.0, 1.0-materials.normaldotview);
	float skylightbounce = rim * max0(1.0 - materials.normaldotlight) * pow(uv1.y, 3.0);
		skylightbounce *= max0(1.0-(-posvec.normalv.y));

	albedoot = mix(albedoot, zenithColor, skylightbounce * materials.roughness * 0.15 * (1.0-materials.metallic));
	return albedoot;
}

vec4 reflection(in vec4 albedoot, in posvector posvec, in fmaterials materials){
	materials.miestrength = 1.5;
	posvec.nworldpos = reflect(posvec.nworldpos, posvec.normal);
	vec3 skyColorReflection = renderSkyColor(posvec, materials);
		skyColorReflection = mix(skyColorReflection, skyColorReflection * posvec.albedolinear, materials.metallic);

	vec3 f0 = vec3(0.04);
		f0 = mix(f0, posvec.albedolinear, materials.metallic);
	vec3 viewFresnel = fresnelSchlick(f0, materials);

	albedoot.rgb = mix(albedoot.rgb, albedoot.rgb * vec3(0.03), materials.metallic);

	float reflectionplacement = max(max(materials.metallic, materials.surfacesmooth), wrain * posvec.normalv.y) * materials.shadowm;
	albedoot.rgb = mix(albedoot.rgb, skyColorReflection, viewFresnel * reflectionplacement);

	#ifdef BLEND
		albedoot.a *= max(vcolor.a, length(viewFresnel));
	#endif

	float normaldistribution = ditributionGGX(materials);
	float geometylight = geometrySchlick(materials);
	float attenuation = max0(1.0 - materials.roughness) * geometylight * normaldistribution;

	albedoot += attenuation * materials.normaldotlight * vec4(vec3(FOG_COLOR.r, FOG_COLOR.g * 0.9, FOG_COLOR.b * 0.8) * 2.0, 1.0) * materials.shadowm * (1.0 - wrain);
	return albedoot;
}

out vec4 fragcolor;
void main()
{

#ifdef BYPASS_PIXEL_SHADER
	discard;
#else

	vec2 topleftmcoord = fract(uv0 * 32.0) * (1.0 / 64.0);

	vec2 toprightmcoord = topleftmcoord - vec2(1.0 / 64.0, 0.0);
	vec4 mertexture = textureLod(TEXTURE_0, uv0 - toprightmcoord, 0.0);

	float getopaquesamplernomipmap = textureLod(TEXTURE_0, uv0 - topleftmcoord, 0.0).a;
	if( (mertexture.r > 0.0 ||
		mertexture.g > 0.0 ||
		mertexture.b > 0.0) && getopaquesamplernomipmap > 0.0
	){
		mertexture = mertexture;
	} else {
		mertexture = vec4(0.05, 0, 0, 0);
	}

	materials.metallic = saturate(mertexture.g);
	materials.emissive = saturate(mertexture.b);
 	materials.roughness = saturate(pow(1.0 - mertexture.r, 2.0));
	materials.surfacesmooth = saturate(1.0 - materials.roughness * 3.0);


	vec2 bottomleftmcoord = topleftmcoord - vec2(0.0, 1.0 / 64.0);
	vec4 normaltexture = textureGrad(TEXTURE_0, uv0 - bottomleftmcoord, dFdx(uv0 * textureDistanceLod), dFdy(uv0 * textureDistanceLod));

	if(normaltexture.r > 0.0 || normaltexture.g > 0.0 || normaltexture.b > 0.0){
		normaltexture = normaltexture;
	} else {
		normaltexture = vec4(vec3(0, 0, 1) * 0.5 + 0.5, 1.0);
	}
		normaltexture.rgb = normaltexture.rgb * 2.0 - 1.0;

	posvec.normalv = normalize(cross(dFdx(perchunkpos.xyz), dFdy(perchunkpos.xyz)));;

	vec3 tangent = getTangentVector(posvec);
		tangent = normalize(tangent);
	vec3 binormal = normalize(cross(tangent, posvec.normalv));

	mat3 tbnmatrix = mat3(tangent.x, binormal.x, posvec.normalv.x,
		tangent.y, binormal.y, posvec.normalv.y,
		tangent.z, binormal.z, posvec.normalv.z);

		normaltexture.rg *= max0(1.0 - wrain * 0.5);
		normaltexture.rgb = normalize(normaltexture.rgb * tbnmatrix);


	posvec.normal = normaltexture.rgb;
	posvec.lightpos = normalize(vec3(cos(sunLightAngle), sin(sunLightAngle), 0.0));
	posvec.upposition = normalize(vec3(0.0, abs(worldpos.y), 0.0));
	posvec.nworldpos = normalize(worldpos);

	vec3 viewdirection = normalize(-worldpos);
	vec3 halfwaydir = normalize(viewdirection + posvec.lightpos);

	materials.normaldotlight = max0(dot(normalmap, posvec.lightpos));
	materials.normaldothalf = max(0.001, dot(normalmap, halfwaydir));
	materials.normaldotview = max(0.001, dot(normalmap, viewdirection));
	materials.shadowm = smoothstep(0.845, 0.87, uv1.y);


	vec4 albedo = textureGrad(TEXTURE_0, uv0 - topleftmcoord, dFdx(uv0 * textureDistanceLod), dFdy(uv0 * textureDistanceLod));

	#ifdef SEASONS_FAR
		albedo.a = 1.0;
	#endif

	#ifdef ALPHA_TEST
		#ifdef ALPHA_TO_COVERAGE
			#define ALPHA_THRESHOLD 0.05
		#else
			#define ALPHA_THRESHOLD 0.5
		#endif
		if(albedo.a < ALPHA_THRESHOLD) discard;
	#endif

	#ifndef SEASONS
		#if !defined(ALPHA_TEST) && !defined(BLEND)
			albedo.a = vcolor.a;
		#endif

		vec3 normalizedvcolor = normalize(vcolor.rgb);
		if(normalizedvcolor.g > normalizedvcolor.b && vcolor.a == 1.0){
			albedo.rgb *= mix(normalizedvcolor, vcolor.rgb, 0.5);
		} else {
			albedo.rgb *= vcolor.a == 0.0 ? vcolor.rgb : sqrt(vcolor.rgb);
		}
	#else
		albedo.rgb *= mix(vec3(1.0,1.0,1.0), texture(TEXTURE_2, vcolor.rg).rgb * 2.0, vcolor.b);
		albedo.rgb *= vcolor.aaa;
		albedo.a = 1.0;
	#endif

		albedo.rgb = toLinear(albedo.rgb);

	posvec.albedolinear = albedo.rgb;

		albedo.rgb = illummination(albedo.rgb, posvec, materials);
		albedo = reflection(albedo, posvec, materials);

	materials.miestrength = 1.0;
	vec3 newfogcolor = renderSkyColor(posvec, materials);

	if(FOG_CONTROL.x > 0.5){
		albedo.rgb = mix(albedo.rgb, newfogcolor * vec3(0.4, 0.7, 1.0), max0(length(worldpos) / RENDER_DISTANCE) * 0.5);
	}
		albedo.rgb = mix(albedo.rgb, newfogcolor, max0(length(worldpos) / 100.0) * wrain);

	#ifdef FOG
		albedo.rgb = mix(albedo.rgb, newfogcolor, fogalpha);
	#endif

		albedo.rgb = tonemap(albedo.rgb);

	fragcolor = albedo;
#endif
}
