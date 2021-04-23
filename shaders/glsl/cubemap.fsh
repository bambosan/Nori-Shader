// __multiversion__
#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
varying vec3 worldpos;

#include "util.cs.glsl"

void main(){

	vec3 adjustedpos = vec3(worldpos.x, -worldpos.y + 0.128, -worldpos.z);
	vec3 upposition = normalize(vec3(0.0, abs(adjustedpos.y), 0.0));
	vec3 nworldpos = normalize(adjustedpos);

	vec3 underscatter = renderSkyColor(nworldpos, upposition, 1.0);

	float iszenith = dot(nworldpos, upposition);
	vec4 color = vec4(underscatter, pow(1.0 - iszenith, 6.0));
		color.rgb = tonemap(color.rgb);

	gl_FragColor = color;
}
