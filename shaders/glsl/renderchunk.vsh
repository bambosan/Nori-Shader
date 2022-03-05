#version 300 es
#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"
#include "uniformShaderConstants.h"
#include "uniformRenderChunkConstants.h"

precision highp float;
#ifndef BYPASS_PIXEL_SHADER
out vec4 vcolor;
out vec3 fogc;
out vec3 sunc;
out vec3 moonc;
out vec3 zcol;
out vec3 cpos;
out vec3 wpos;
out vec3 lpos;
out vec3 tlpos;
out vec2 uv0;
out vec2 uv1;
#endif
#ifdef FOG
out float fogd;
#endif

#include "shader_settings.txt"
#include "common.glsl"

in vec4 POSITION;
in vec4 COLOR;
in vec2 TEXCOORD_0;
in vec2 TEXCOORD_1;

void main(){
	vec4 worldPos, pos;
#ifdef AS_ENTITY_RENDERER
	pos = WORLDVIEWPROJ * POSITION;
	worldPos = pos;
#else
	worldPos.xyz = (POSITION.xyz * CHUNK_ORIGIN_AND_SCALE.w) + CHUNK_ORIGIN_AND_SCALE.xyz;
	pos = PROJ * WORLDVIEW * vec4(worldPos.xyz, 1.0);
#endif
	gl_Position = pos;
#ifndef BYPASS_PIXEL_SHADER
	uv0 = TEXCOORD_0;
	uv1 = TEXCOORD_1;
	vcolor = COLOR;
	// thanks @GFPCoder for ao separator
	vec3 ncol = normalize(COLOR.rgb);
	float ao = dot(vcolor.rgb, vec3(0.3333));
	vcolor.rgb /= ao;
		ao = max(ao, saturate((ncol.r + ncol.g + ncol.b) / 3.0 + float(ncol.r < 0.59 && ncol.g < 0.59 && ncol.b < 0.59)));
	vcolor.rgb = vcolor.rgb / (dot(vcolor.rgb, vec3(0.3333)) / ao);
	cpos = POSITION.xyz;
	wpos = worldPos.xyz;
	clpos(tlpos, lpos);
	fogc = catm(normalize(wpos), lpos);
	clig(lpos, sunc, moonc, zcol);
#endif
#ifdef FOG
#ifdef FANCY
	float camDepth = length(-worldPos.xyz);
#else
	float camDepth = pos.z;
#endif
	float len = camDepth / RENDER_DISTANCE;
#ifdef ALLOW_FADE
	len += RENDER_CHUNK_FOG_ALPHA;
#endif
	fogd = saturate((len - FOG_CONTROL.x) / (FOG_CONTROL.y - FOG_CONTROL.x));
#endif
}
