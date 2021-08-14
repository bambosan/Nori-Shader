// __multiversion__
#include "fragmentVersionCentroid.h"
#include "uniformShaderConstants.h"

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
varying highp vec2 uv;

void main(){
	vec4 tex = (TEXTURE_DIMENSIONS.xy == vec2(1024, 1024) || TEXTURE_DIMENSIONS.xy == vec2(2048, 2048) || TEXTURE_DIMENSIONS.xy == vec2(4096, 4096)) ? textureLod(TEXTURE_0, uv - fract(uv * 32.0) * 0.015625, 0.0) : texture2D(TEXTURE_0, uv);

#ifdef ALPHA_TEST
	if(tex.a < 0.5) discard;
#endif

	gl_FragColor = CURRENT_COLOR * tex;
}
