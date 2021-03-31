#version 300 es
#include "uniformPerFrameConstants.h"
#include "uniformShaderConstants.h"

precision highp float;

in float isskyhorizon;

#include "util.glsl"

out vec4 fragcolor;
void main(){

	materials.skyhorizon = pow(isskyhorizon * 2.0, 2.0);

	vec3 color = calcSkyColor(materials);
 		color = tonemap(color);

	fragcolor = vec4(color, 1.0);
}
