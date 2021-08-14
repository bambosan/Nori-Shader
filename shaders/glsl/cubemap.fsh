// __multiversion__
#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"
precision highp float;
#include "common.glsl"

varying vec3 cPos;

void main(){
	vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
	vec3 ajPos = normalize(vec3(cPos.x, -cPos.y + 0.128, -cPos.z));
	vec3 lPos = vec3(0.0), tlPos = vec3(0.0);
	calcLpos(tlPos, lPos);
		color.rgb = calcSky(ajPos, lPos);
		color.rgb = colorCorrection(color.rgb);
	gl_FragColor = color;
}
