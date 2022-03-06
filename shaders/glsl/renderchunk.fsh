#version 300 es

uniform sampler2D TEXTURE_0;
uniform sampler2D TEXTURE_2;

precision highp float;
#ifndef BYPASS_PIXEL_SHADER
in vec4 vcolor;
in vec3 fogc;
in vec3 sunc;
in vec3 moonc;
in vec3 zcol;
in vec3 cpos;
in vec3 wpos;
in vec3 lpos;
in vec3 tlpos;
centroid in vec2 uv0;
centroid in vec2 uv1;
#endif
#ifdef FOG
in float fogd;
#endif

#include "shader_settings.txt"
#include "pbr_set.txt"
#include "common.glsl"

vec2 ruv(vec2 uv, vec2 ouv){ return uv - mod(uv, vec2(0.015625)) + mod(uv + ouv, vec2(0.015625)); }
vec2 cpuv(vec3 vvec, vec2 uv, vec2 nuv){
#if defined(ENABLE_PARALLAX) && !defined(ALPHA_TEST)
	if(textureLod(TEXTURE_0, nuv, 0.0).a < 1.0){
		vec2 suv = vec2(0.0);
		vvec.xy = vvec.xy / (-vvec.z) * PARALLAX_DEPTH;
		for(int i = 0; i < PARALLAX_STEP && textureLod(TEXTURE_0, ruv(nuv, suv), 0.0).a < 1.0 - float(i) * invtres; i++) suv += vvec.xy;
		return ruv(uv, suv);
	} else { return uv; }
#endif
	return uv;
}

float cpsh(vec3 alp, vec2 puv){
	float lo = 1.0;
#if defined(ENABLE_PARALLAX_SHADOW) && defined(ENABLE_PARALLAX) && !defined(ALPHA_TEST)
	vec2 sof = vec2(0.0);
	for(int i = 0; i < PSHADOW_STEP; i++, sof += alp.xy * PSHADOW_OFFSET) lo *= step(textureLod(TEXTURE_0, ruv(puv, sof), 0.0).a - float(i) * invtres, textureLod(TEXTURE_0, puv, 0.0).a);
#endif
	return lo;
}

void ellp(in vec4 stex, inout float met, inout float ems, inout float rough, inout float ssm, inout float por){
	met = saturate(stex.g);
	ems = (stex.a * 255.0) < 254.5 ? saturate(stex.a) : 0.0;
	rough = saturate(pow(1.0 - stex.r, 2.0) * ROUGHNESS_STRENGTH);
	ssm = saturate(stex.r * SMOOTHNESS_STRENGTH);
	if(!((stex.g * 255.0) > 229.5)) por = (stex.b * 255.0) > 64.0 ? 0.0 : saturate(stex.b);
}

void eolp(in vec3 stex, inout float met, inout float ems, inout float rough, inout float ssm){
	met = saturate(stex.g);
	ems = saturate(stex.b);
	ssm = saturate(stex.r * SMOOTHNESS_STRENGTH);
	rough = saturate(pow(1.0 - stex.r, 2.0) * ROUGHNESS_STRENGTH);
}

//http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
float gv(float ndv, float k){ return 1.0 / (ndv * (1.0 - k) + k); }
float sggx(vec3 hdir, float ndl, float ndv, float ndh, float rough, float met){
	float a = rough * rough;
	float asqr = a * a;
	float dm = ndh * ndh * (asqr - 1.0) + 1.0;
	float d = asqr / (pi * dm * dm);
	float dlhs = pow(1.0 - saturate(dot(tlpos, hdir)), 5.0);
	float fre = met + (1.0 - met) * (dlhs);
	float k = a * 0.5;
	float vis = gv(ndl, k) * gv(ndv, k);
	return ndl * d * fre * vis;
}

#ifdef ENABLE_REFLECTION
vec4 refl(vec4 tex, vec3 n, vec3 abl, float met, float ssm, float por, float oud, float ndv){
	vec3 rv = reflect(normalize(wpos), n);
	vec3 skyr = csky(rv, lpos, sunc, moonc);
	vec4 vc = ccv(rv, tlpos, sunc, moonc, zcol, bayer8(gl_FragCoord.xy));
		skyr = skyr * vc.a + vc.rgb;
		skyr = mix(skyr, skyr * abl, met);
	vec3 f0 = mix(vec3(0.04), abl, met);
	vec3 fsch = f0 + (1.0 - f0) * pow(1.0 - ndv, 5.0);
	tex.rgb = mix(tex.rgb, tex.rgb * vec3(0.03), met * oud);
	tex = mix(tex, vec4(skyr, 1.0), vec4(fsch, length(fsch)) * max(ssm, wrain * n.y * por) * oud);
	return tex;
}
#endif

vec3 nttang(vec3 n){
	vec3 t = vec3(0, 0, 0);
	if(n.x > 0.0){ t = vec3(0, 0, -1); } else if(n.x < -0.5){ t = vec3(0, 0, 1);
	} else if(n.y > 0.0){ t = vec3(1, 0, 0); } else if(n.y < -0.5){ t = vec3(1, 0, 0);
	} else if(n.z > 0.0){ t = vec3(1, 0, 0); } else if(n.z < -0.5){ t = vec3(-1, 0, 0); }
	return t;
}

out vec4 fragcol;
void main(){
#ifdef BYPASS_PIXEL_SHADER
	fragcol = vec4(0.0,0.0,0.0,0.0);
	return;
#else
	vec3 dx = normalize(dFdx(cpos)), dy = normalize(dFdy(cpos));
	vec3 n = normalize(cross(dx, dy));
	vec3 t = nttang(n);
	vec3 b = normalize(cross(t, n));
	mat3 tbn = transpose(mat3(t, b, n));
	vec3 vvec = normalize(tbn * wpos);
	vec2 nuv = uv0 + vec2(0.015625, 0.0);
	vec2 lcd = vec2(dFdx(uv1.x), dFdy(uv1.x)) / length(fwidth(cpos));
	vec3 tl = normalize(vec3(dx * lcd.x + n * 0.07 + dy * lcd.y));
	float met = 0.0, ems = 0.0, rough = 1.0, ssm = 0.0, por = 0.0;
#ifdef PBR
	vec4 stex = textureLod(TEXTURE_0, cpuv(vvec, uv0 + vec2(0.03125, 0.0), nuv), 0.0);
#if PBR_FORMAT == 1
	ellp(stex, met, ems, rough, ssm, por);
#else
	eolp(stex.rgb, met, ems, rough, ssm);
#endif
	vec3 ntex = textureGrad(TEXTURE_0, cpuv(vvec, nuv, nuv), dFdx(uv0), dFdy(uv0)).rgb;
		n.xy = ntex.rg * 2.0 - 1.0;
		n.z = sqrt(1.0 - dot(n.xy, n.xy));
		n.xy *= NORMAL_MAP_STRENGTH;
		n = normalize(n * tbn);
#endif
	vec3 vdir = normalize(-wpos), hdir = normalize(vdir + tlpos);
	float ndl = saturate(dot(tlpos, n)), ndv = saturate(dot(n, vdir)), ndh = saturate(dot(n, hdir));
	fragcol = textureGrad(TEXTURE_0, cpuv(vvec, uv0, nuv), dFdx(uv0), dFdy(uv0));
#ifdef SEASONS_FAR
	fragcol.a = 1.0;
#endif
#ifdef ALPHA_TEST
#ifdef ALPHA_TO_COVERAGE
	if(fragcol.a < 0.05) discard;
#else
	if(fragcol.a < 0.5) discard;
#endif
#endif
#ifndef SEASONS
#if !defined(ALPHA_TEST) && !defined(BLEND)
	fragcol.a = vcolor.a;
#endif
	fragcol.rgb *= vcolor.rgb;
#else
	fragcol.rgb *= mix(vec3(1.0), texture(TEXTURE_2, vcolor.rg).rgb * 2.0, vcolor.b);
#endif
	fragcol.rgb = pow(fragcol.rgb, vec3(2.2));
	if(vcolor.a > 0.54 && vcolor.a < 0.67){ fragcol.a *= 0.5; met = 0.3, rough = 0.04, ssm = 1.0, por = 1.0; }
	float alm = uv1.x * max(smoothstep(saturate(lpos.y) * uv1.y, 1.0, uv1.x), wrain * uv1.y), oud = smoothstep(0.845, 0.87, uv1.y);
	float bl = saturate(dot(tl, n)) * alm + pow(alm, 5.0) * 2.0;
	vec3 ambc = zcol * uv1.y + vec3(BLOCK_LIGHT_C_R, BLOCK_LIGHT_C_G, BLOCK_LIGHT_C_B) * bl, abl = fragcol.rgb;
	float psh = cpsh(tbn * tlpos, cpuv(vvec, nuv, nuv));
		psh *= ndl;
		ambc += (sunc + moonc) * psh * oud * (1.0 - wrain);
	fragcol.rgb = (fragcol.rgb * ambc) + (ems * abl * 6.0);
#ifdef ENABLE_REFLECTION
	fragcol = refl(fragcol, n, abl, met, ssm, por, oud, ndv);
#endif
	float spl = sggx(hdir, psh, ndv, ndh, rough, met);
	fragcol += vec4(sunc + moonc, 1.0) * spl * oud * (1.0 - wrain);
#ifdef FOG
	fragcol.rgb = mix(fragcol.rgb, fogc, fogd);
#endif
	fragcol.rgb = colc(fragcol.rgb);
#endif
}
