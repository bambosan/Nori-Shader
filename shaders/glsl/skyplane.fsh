// __multiversion__
// This signals the loading code to prepend either #version 100 or #version 300 es as apropriate.
#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

varying highp float isskyhorizon;

#include "util.cs.glsl"

void main(){

	vec3 color = calcSkyColor(pow(isskyhorizon * 2.0, 2.0));
 		color = tonemap(color);

	gl_FragColor = vec4(color, 1.0);
}
