// __multiversion__
#include "macro.h"
#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

precision hp float;
varying vec3 worldpos;

#include "util.cs.glsl"

void main(){

	vec3 adjustedpos = vec3(worldpos.x, -worldpos.y + 0.128, -worldpos.z);
	vec3 upposition = normalize(vec3(0.0, abs(adjustedpos.y), 0.0));
	vec3 nworldpos = normalize(adjustedpos);
	vec3 divpos = nworldpos / nworldpos.y;

	vec3 underhorizon = renderSkyColor(nworldpos, upposition, 1.0);
	vec4 cloudcolor = calcCloudColor(divpos, divpos);

	mp float iszenith = dot(nworldpos, upposition);
	vec4 color = mix(vec4(underhorizon, pow(1.0 - iszenith, 6.0)), cloudcolor, cloudcolor.a * smoothstep(1.0, 0.95, length(nworldpos.xz)) * float(iszenith > 0.0));

		color.rgb = tonemap(color.rgb);

	gl_FragColor = color;
}
