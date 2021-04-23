// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300

#if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
_centroid in highp vec2 uv;
#else
_centroid in highp vec2 uv;
#endif

#else

varying highp vec2 uv;

#endif

#include "uniformShaderConstants.h"
#include "util.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;

void main()
{
	highp vec2 topleftmcoord = fract(uv * 32.0) * (1.0 / 64.0);
	vec4 diffuse;
	if(
		TEXTURE_DIMENSIONS.xy == vec2(1024, 1024) ||
		TEXTURE_DIMENSIONS.xy == vec2(2048, 2048) ||
		TEXTURE_DIMENSIONS.xy == vec2(4096, 4096)
	){
		diffuse = textureLod(TEXTURE_0, uv - topleftmcoord, 0.0);
	} else {
		diffuse = texture2D(TEXTURE_0, uv);
	}

#ifdef ALPHA_TEST
	if(diffuse.a < 0.5) discard;
#endif

	gl_FragColor = CURRENT_COLOR * diffuse;
}
