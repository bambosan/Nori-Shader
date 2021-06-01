// __multiversion__

#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

precision highp float;

varying vec3 cubepos;

#include "util.cs.glsl"

void main(){

	vec3 adjustpos = vec3(cubepos.x, -cubepos.y + 0.128, -cubepos.z);
	vec3 upPos = normalize(vec3(0.0, abs(adjustpos.y), 0.0));
	vec3 nPos = normalize(adjustpos);

	vec3 underHorizon = renderSkyColor(nPos, upPos, 1.0);
	float zenith = max0(dot(nPos, upPos));

	vec4 color = vec4(underHorizon, pow(1.0 - zenith, 6.0));

	#ifdef ENABLE_CLOUD
		vec3 dPos = nPos / nPos.y;
		vec4 cloud = calcCloudColor(dPos, dPos);
		color = mix(color, cloud, cloud.a * smoothstep(1.0, 0.95, length(nPos.xz)) * float(zenith > 0.0));
	#endif

		color.rgb = colorCorrection(color.rgb);

	gl_FragColor = color;
}
