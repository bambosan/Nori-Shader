// __multiversion__
#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"
#include "uniformPerFrameConstants.h"

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
#ifdef FOG
	varying float hFogd;
#endif

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

precision highp float;
varying vec4 vcolor;
varying vec3 nFogC;
varying vec3 sunCol;
varying vec3 moonCol;
varying vec3 szCol;
varying vec3 cPos;
varying vec3 wPos;
varying vec3 nWPos;
varying vec3 lPos;
varying vec3 tlPos;
varying vec3 uPos;
varying float sunVis;
varying float moonVis;

#include "common.glsl"

// vanilla ao hardcoded https://github.com/origin0110/OriginShader/blob/main/shaders/glsl/shaderfunction.lin
float getleaao(vec3 color){
	const vec3 O = vec3(0.682352941176471, 0.643137254901961, 0.164705882352941);
	const vec3 N = vec3(0.195996912842436, 0.978673548072766, -0.061508507207520);
	return length(color) / dot(O, N) * dot(normalize(color), N);
}

float getgraao(vec3 color){
	const vec3 O = vec3(0.745098039215686, 0.713725490196078, 0.329411764705882);
	const vec3 N = vec3(0.161675377098328, 0.970052262589970, 0.181272392504186);
	return length(color) / dot(O, N) * dot(normalize(color), N);
}

vec4 calcVco(vec4 color){
	if(abs(color.x - color.y) < 2e-5 && abs(color.y - color.z) < 2e-5){
		color.a = color.r;
		color.rgb = vec3(1.0);
	} else {
		color.a = color.a < 0.001 ? getleaao(color.rgb) : getgraao(color.rgb);
		color.rgb = color.rgb / color.a;
	}
	return color;
}

vec2 mrCo(vec2 tCoord, vec2 mPos, vec2 oCoord){
	return tCoord - fract(mPos) * 0.015625 + fract(oCoord) * 0.015625;
}

vec2 calcPC(vec2 vVec, vec2 mPos, vec2 tCoord, vec2 nCoord){
	#if defined(ENABLE_PARALLAX) && !defined(ALPHA_TEST)
		vec4 nSamp = textureLod(TEXTURE_0, nCoord, 0.0);
		if((nSamp.r > 0.0 || nSamp.g > 0.0 || nSamp.b > 0.0) && nSamp.a < 1.0){
			vec2 spCoord = mPos + vVec * bayer64(gl_FragCoord.xy) * 0.01;
			for(int i = 0; i < PARALLAX_STEP && texture2D(TEXTURE_0, mrCo(nCoord, mPos, spCoord)).a < 1.0 - float(i) / PARALLAX_RES; i++) spCoord += vVec * PARALLAX_DEPTH;
			return mrCo(tCoord, mPos, spCoord);
		} else return tCoord;
	#endif
	return tCoord;
}

float calcPsha(vec3 tLPos, vec2 pCoord){
	float tLight = 1.0;
	#if defined(ENABLE_PARALLAX_SHADOW) && defined(ENABLE_PARALLAX) && !defined(ALPHA_TEST)
		vec2 npCoord = pCoord + tLPos.xy * bayer64(gl_FragCoord.xy) * 4e-4;
		for(int i = 0; i < PSHADOW_STEP; i++, npCoord += tLPos.xy * PSHADOW_OFFSET){
			float dSample = textureLod(TEXTURE_0, npCoord, 0.0).a - float(i) / PARALLAX_RES;
			if(dSample > textureLod(TEXTURE_0, pCoord, 0.0).a) tLight *= 0.2;
		}
	#endif
	return tLight;
}

float specGGX(vec3 N, float nDotL, float nDotV, float nDotH, float roughness){
	float rs = pow(roughness, 4.0);
	float d = (nDotH * rs - nDotH) * nDotH + 1.0;
	float nd = rs / (pi * d * d);
	float k = (roughness * roughness) * 0.5;
	float v = nDotV * (1.0 - k) + k, l = nDotL * (1.0 - k) + k;
	return max0(nd * (0.25 / (v * l)));
}

#ifdef ENABLE_REFLECTION
vec4 reflection(vec4 albedo, vec3 abl, vec3 N, float met, float ssm, float outD, float nDotV){
	vec3 rVector = reflect(normalize(wPos), N);
	vec3 skyRef = calcSky(rVector, lPos);
		skyRef = mix(skyRef, skyRef * abl, met);
	vec3 F0 = mix(vec3(0.04), abl, met);
	vec3 fSchlick = F0 + (1.0 - F0) * pow(1.0 - nDotV, 5.0);
	albedo.rgb = mix(albedo.rgb, albedo.rgb * 0.03, met * outD);
	albedo = mix(albedo, vec4(skyRef, 1.0), vec4(fSchlick, length(fSchlick)) * max(ssm, wrain * N.y) * outD);
	return albedo;
}
#endif

void main(){
#ifdef BYPASS_PIXEL_SHADER
	gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
	return;
#else

	vec3 N = normalize(cross(dFdx(cPos.xyz), dFdy(cPos.xyz)));
	vec3 T = toTangent(N), B = normalize(cross(T, N));
	mat3 TBN = transpose(mat3(T, B, N));
	vec3 vVec = normalize(TBN * wPos), mPos = TBN * cPos;

	vec2 frUV = fract(uv0 * 32.0) * 0.015625;
	vec2 aUV = uv0 - frUV, mUV = uv0 - (frUV - vec2(0.015625, 0.0)), nUV = uv0 - (frUV - vec2(0.0, 0.015625));

	vec4 stex = textureLod(TEXTURE_0, calcPC(vVec.xy, mPos.xy, mUV, nUV), 0.0);
	float met = 0.0, rough = 0.0, ems = 0.0, ssm = 0.0;
	if((stex.r > 0.0 || stex.g > 0.0 || stex.b > 0.0) && stex.a > 0.0){
		met = saturate(stex.g);
		ems = saturate(stex.b);
		rough = saturate(pow(1.0 - stex.r, (2.0 + ROUGHNESS_TRESHOLD)));
		ssm = saturate(1.0 - rough * (2.0 + SMOOTHNESS_TRESHOLD));
	}

	vec3 nTex = textureGrad(TEXTURE_0, calcPC(vVec.xy, mPos.xy, nUV, nUV), dFdx(uv0 * ADJUST_MIPMAP), dFdy(uv0 * ADJUST_MIPMAP)).rgb;
	if(nTex.r > 0.0 || nTex.g > 0.0 || nTex.b > 0.0){
		N = nTex * 2.0 - 1.0;
		N.rg *= max0(1.2 - wrain * 0.5);
		N = normalize(N * TBN);
	}

	vec3 vDir = normalize(-wPos), hDir = normalize(vDir + tlPos);
	float nDotL = max0(dot(N, tlPos)), nDotV = max(0.001, dot(N, vDir)), nDotU = max0(dot(N, uPos)), nDotH = max(0.001, dot(N, hDir));

	vec4 albedo = textureGrad(TEXTURE_0, calcPC(vVec.xy, mPos.xy, aUV, nUV), dFdx(uv0 * ADJUST_MIPMAP), dFdy(uv0 * ADJUST_MIPMAP));
	#ifdef SEASONS_FAR
		albedo.a = 1.0;
	#endif
	#ifdef ALPHA_TEST
		#ifdef ALPHA_TO_COVERAGE
			if(albedo.a < 0.05) discard;
		#else
			if(albedo.a < 0.5) discard;
		#endif
	#endif
	#ifndef SEASONS
		#if !defined(ALPHA_TEST) && !defined(BLEND)
			albedo.a = vcolor.a;
		#endif
		albedo.rgb *= calcVco(vcolor).rgb;
	#else
		albedo.rgb *= mix(vec3(1.0), texture2D(TEXTURE_2, vcolor.rg).rgb * 2.0, vcolor.b);
		albedo.rgb *= vcolor.aaa;
		albedo.a = 1.0;
	#endif
		albedo.rgb = toLinear(albedo.rgb);

	float blSource = uv1.x * max(smoothstep(sunVis * uv1.y, 1.0, uv1.x), wrain * uv1.y), outD = smoothstep(0.845, 0.87, uv1.y);
	vec3 ambCol = szCol * uv1.y + vec3(BLOCK_LIGHT_C_R, BLOCK_LIGHT_C_G, BLOCK_LIGHT_C_B) * blSource + pow(blSource, 5.0) * 1.2, abl = albedo.rgb;

	float pShadow = calcPsha(TBN * tlPos, calcPC(vVec.xy, mPos.xy, nUV, nUV)) * nDotL;
		ambCol += (sunCol + moonCol) * pShadow * outD * (1.0 - wrain);
		albedo.rgb = (albedo.rgb * ambCol) + (ems * abl * tau);

	#ifdef ENABLE_REFLECTION
		albedo = reflection(albedo, abl, N, met, ssm, outD, nDotV);
	#endif

	float specL = specGGX(N, nDotL, nDotV, nDotH, rough), fdist = max0(length(wPos) / SECONDARY_FOG_DISTANCE);
		albedo += vec4(sunCol + moonCol, 1.0) * specL * pShadow * outD * (1.0 - wrain);

	#ifdef ENABLE_SECONDARY_FOG
		albedo.rgb = mix(albedo.rgb, szCol, fdist * mix(mix(SS_FOG_INTENSITY, NOON_FOG_INTENSITY, sunVis), RAIN_FOG_INTENSITY, wrain));
		albedo.rgb += sunCol * mPhase(max0(1.0 - distance(nWPos, lPos)), FOG_MIE_G) * fdist * FOG_MIE_COEFF;
	#endif

	#ifdef ENABLE_PRIMARY_FOG
		#ifdef FOG
			albedo.rgb = mix(albedo.rgb, nFogC, hFogd);
		#endif
	#endif

		albedo.rgb = colorCorrection(albedo.rgb);

	switch(showvalue){
		case 2: albedo = vec4(N, 1.0); break;
		case 3: albedo = texture2D(TEXTURE_0, cPos.xz * 0.125); break;
		case 4: albedo = vec4(met); break;
		case 5: albedo = vec4(ems); break;
		case 6: albedo = vec4(rough); break;
	}

	gl_FragColor = albedo;

#endif
}
