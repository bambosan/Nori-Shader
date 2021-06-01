// __multiversion__

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300
#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
_centroid in highp vec2 uv;
#else
_centroid in vec2 uv;
#endif
#else
varying vec2 uv;
#endif

#include "uniformShaderConstants.h"
#include "util.h"
#include "uniformPerFrameConstants.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;

varying highp vec3 worldpos;

#include "util.cs.glsl"

void main(){

#if !defined(TEXEL_AA) || !defined(TEXEL_AA_FEATURE)
	vec4 diffuse = texture2D( TEXTURE_0, uv );
#else
	vec4 diffuse = texture2D_AA(TEXTURE_0, uv );
#endif

	vec3 color = vec3(FOG_COLOR.r, FOG_COLOR.g * 0.7, FOG_COLOR.b * 0.5) + vec3(0.8, 0.9, 1.0) * fnight;

	float centerr = length(worldpos.xz);
		color += max0(0.01 / pow(centerr * (18.0 - fnight * 12.0), 8.0));
 		color *= exp(0.9 - centerr) / 5.0;

	diffuse.rgb = color;

	gl_FragColor = diffuse * CURRENT_COLOR;

}
