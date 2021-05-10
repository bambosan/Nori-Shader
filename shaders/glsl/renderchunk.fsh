// __multiversion__

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300
	#ifndef BYPASS_PIXEL_SHADER
		_centroid in highp vec2 uv0;
		_centroid in highp vec2 uv1;
	#endif
#else
	#ifndef BYPASS_PIXEL_SHADER
		varying highp vec2 uv0;
		varying highp vec2 uv1;
	#endif
#endif

varying vec4 vcolor;

#ifdef FOG
	varying float fogalpha;
#endif

#include "uniformShaderConstants.h"
#include "uniformPerFrameConstants.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

precision highp float;

varying vec3 perchunkpos;
varying vec3 worldpos;

#include "util.cs.glsl"

float ditributionGGX(float normaldothalf, float roughness){
	float roughSquared = sqr4x(roughness);

	float d = (normaldothalf * roughSquared - normaldothalf) * normaldothalf + 1.0;
	return roughSquared / (pi * d * d);
}

float geometrySchlick(float normaldotview, float normaldotlight, float roughness){
	float k = sqr2x(roughness) * 0.5;

	float view = normaldotview * (1.0 - k) + k;
	float light = normaldotlight * (1.0 - k) + k;

	return 0.25 / (view * light);
}

vec4 illummination(lowp vec4 albedoot, lowp vec3 albedonoem, float roughness, float normaldotview, float normaldotlight, float normaldothalf, float emission){
	float lightmapbrightness = texture2D(TEXTURE_1, vec2(0, 1)).r;

	lowp vec3 ambientcolor = vec3(0.3, 0.3, 0.3) * mix(1.0, 0.0, (wrain * 0.4) + (fnight * 0.6));
		ambientcolor *= uv1.y;

	lowp float adaptivebls = smoothstep(lightmapbrightness * uv1.y, 1.0, uv1.x);
	lowp float blocklightsource = mix(mix(0.0, uv1.x, adaptivebls), uv1.x, wrain);

		ambientcolor += vec3(1.0, 0.5, 0.2) * blocklightsource + pow(blocklightsource * 1.15, 5.0);

	lowp float difflightr = FOG_COLOR.r * max0(1.0 - fnight * 0.4);
	lowp float difflightg = FOG_COLOR.g * max0(0.9 - fnight * 0.1);
	lowp float difflightb = FOG_COLOR.b * (0.8 + fnight * 0.2);

	vec3 diffuselightcolor = vec3(difflightr, difflightg, difflightb) * 3.0 * normaldotlight;
	float shadowm = smoothstep(0.845, 0.87, uv1.y);
		ambientcolor += diffuselightcolor * shadowm * (1.0 - wrain);

	albedoot.rgb = albedoot.rgb * ambientcolor;
	albedoot.rgb += emission * albedonoem * 5.0;

	float normaldistribution = ditributionGGX(normaldothalf, roughness);
	float geometylight = geometrySchlick(normaldotview, normaldotlight, roughness);
	float attenuation = max0(1.0 - roughness) * geometylight * normaldistribution;

	albedoot += attenuation * normaldotlight * vec4(FOG_COLOR.r * 2.0, FOG_COLOR.g * 1.8, FOG_COLOR.b * 1.6, 1.0) * shadowm * (1.0 - wrain);
	return albedoot;
}

vec3 skylightb(lowp vec3 albedoot, vec3 normalv, float normaldotview, float normaldotlight, float roughness, float metallic){
	lowp vec3 zenithColor = toLinear(vec3(FOG_COLOR.r * 0.4, FOG_COLOR.g * 0.5, FOG_COLOR.b * 0.6));

	float rim = mix(0.5, 1.0, 1.0-normaldotview);
	float skylightbounce = rim * max0(1.0 - normaldotlight) * pow(uv1.y, 3.0);
		skylightbounce *= max0(1.0-(-normalv.y));

	albedoot = mix(albedoot, zenithColor, skylightbounce * roughness * 0.13 * (1.0-metallic));
	return albedoot;
}

vec3 fresnelSchlick(vec3 f0, float normaldotview){
	return f0 + (1.0 - f0) * pow(1.0 - normaldotview, 5.0);
}

vec4 reflection(lowp vec4 albedoot, vec3 normal, vec3 normalv, vec3 upposition, lowp vec3 albedonoem, float normaldotview, float metallic, float roughness, float surfacesmooth){

	vec3 nworldpos = normalize(worldpos);
	vec3 reflectedvector = reflect(nworldpos, normal);
	vec3 skyCloudReflection = renderSkyColor(reflectedvector, upposition, 1.5);

	float iszenith = dot(reflectedvector, upposition);
	float cloudF = smoothstep(1.0, 0.95, length(nworldpos.xz)) * float(iszenith > 0.0);

		reflectedvector /= reflectedvector.y;

	vec4 cloudColorReflection = calcCloudColor(reflectedvector, reflectedvector);
		skyCloudReflection = mix(skyCloudReflection, cloudColorReflection.rgb, cloudColorReflection.a * cloudF);
		skyCloudReflection = mix(skyCloudReflection, skyCloudReflection * albedonoem, metallic);

	vec3 f0 = vec3(0.04);
		f0 = mix(f0, albedonoem, metallic);
	vec3 viewFresnel = fresnelSchlick(f0, normaldotview);

	albedoot.rgb = mix(albedoot.rgb, albedoot.rgb * vec3(0.03), metallic);

	float reflectivity = max(surfacesmooth, wrain * normalv.y) * smoothstep(0.845, 0.87, uv1.y);
	albedoot.rgb = mix(albedoot.rgb, skyCloudReflection, viewFresnel * reflectivity);

	#ifdef BLEND
		albedoot.a *= max(vcolor.a, length(viewFresnel));
	#endif

	return albedoot;
}

void main()
{
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor = vec4(0, 0, 0, 0);
	return;
#else

	vec2 topleftmcoord = fract(uv0 * 32.0) * 0.015625;
	vec2 toprightmcoord = topleftmcoord - vec2(0.015625, 0.0);
	vec3 mertex = textureLod(TEXTURE_0, uv0 - toprightmcoord, 0.0).rgb;

	float getopaquenomipmap = textureLod(TEXTURE_0, uv0 - topleftmcoord, 0.0).a;
	if( (mertex.r > 0.0 || mertex.g > 0.0 || mertex.b > 0.0) && getopaquenomipmap > 0.0){
		mertex = mertex;
	} else {
		mertex = vec3(0.05, 0, 0);
	}

	mediump float metallic = saturate(mertex.g);
	mediump float emission = saturate(mertex.b);
	mediump float roughness = saturate(pow(1.0 - mertex.r, 2.0));
	mediump float surfacesmooth = saturate(1.0 - roughness * 3.0);

	vec2 bottomleftmcoord = topleftmcoord - vec2(0.0, 0.015625);
	vec3 normal = textureGrad(TEXTURE_0, uv0 - bottomleftmcoord, dFdx(uv0 * textureDistanceLod), dFdy(uv0 * textureDistanceLod)).rgb;
	if(normal.r > 0.0 || normal.g > 0.0 || normal.b > 0.0){ normal = normal; } else { normal = vec3(0, 0, 1) * 0.5 + 0.5; }
		normal = normal * 2.0 - 1.0;

	vec3 normalv = normalize(cross(dFdx(perchunkpos.xyz), dFdy(perchunkpos.xyz)));
	vec3 tangent = getTangentVector(normalv);
		tangent = normalize(tangent);
	vec3 binormal = normalize(cross(tangent, normalv));
	mat3 tbnmatrix = mat3(tangent.x, binormal.x, normalv.x, tangent.y, binormal.y, normalv.y, tangent.z, binormal.z, normalv.z);

		normal.rg *= max0(1.0 - wrain * 0.5);
		normal.rgb = normalize(normal * tbnmatrix);

	vec3 lightpos = normalize(vec3(cos(sunLightAngle), sin(sunLightAngle), 0.0));
	vec3 upposition = normalize(vec3(0.0, abs(worldpos.y), 0.0));
	vec3 viewdirection = normalize(-worldpos);
	vec3 halfwaydir = normalize(viewdirection + lightpos);

	float normaldotlight = max0(dot(normal, lightpos));
	float normaldothalf = max(0.001, dot(normal, halfwaydir));
	float normaldotview = max(0.001, dot(normal, viewdirection));

	lowp vec4 albedo = textureGrad(TEXTURE_0, uv0 - topleftmcoord, dFdx(uv0 * textureDistanceLod), dFdy(uv0 * textureDistanceLod));

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
		if(normalizedvcolor.g > normalizedvcolor.b && vcolor.a != 0.0){
			albedo.rgb *= mix(normalizedvcolor, vcolor.rgb, 0.5);
		} else {
			albedo.rgb *= vcolor.a == 0.0 ? vcolor.rgb : sqrt(vcolor.rgb);
		}
	#else
		albedo.rgb *= mix(vec3(1.0,1.0,1.0), texture2D(TEXTURE_2, vcolor.rg).rgb * 2.0, vcolor.b);
		albedo.rgb *= vcolor.aaa;
		albedo.a = 1.0;
	#endif
		albedo.rgb = toLinear(albedo.rgb);
	lowp vec3 albedonoem = albedo.rgb;

		albedo = illummination(albedo, albedonoem, roughness, normaldotview, normaldotlight, normaldothalf, emission);
		albedo.rgb = skylightb(albedo.rgb, normalv, normaldotview, normaldotlight, roughness, metallic);
		albedo = reflection(albedo, normal, normalv, upposition, albedonoem, normaldotview, metallic, roughness, surfacesmooth);

	vec3 nworldpos = normalize(worldpos);
	vec3 newfogcolor = renderSkyColor(nworldpos, upposition, 1.0);

	if(FOG_CONTROL.x > 0.5){
		albedo.rgb = mix(albedo.rgb, newfogcolor * vec3(0.4, 0.7, 1.0), max0(length(worldpos) / 200.0) * 0.3);
	}
		albedo.rgb = mix(albedo.rgb, newfogcolor, max0(length(worldpos) / 100.0) * wrain);
	#ifdef FOG
		albedo.rgb = mix(albedo.rgb, newfogcolor, fogalpha);
	#endif
		albedo.rgb = tonemap(albedo.rgb);

	gl_FragColor = albedo;
#endif
}
