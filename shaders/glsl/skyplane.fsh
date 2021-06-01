// __multiversion__
#include "fragmentVersionSimple.h"
#include "uniformPerFrameConstants.h"

varying highp float isskyhorizon;

#include "util.cs.glsl"

void main(){

	vec3 color = calcSkyColor(pow(isskyhorizon * 2.0, 2.0));
 		color = colorCorrection(color);

	gl_FragColor = vec4(color, 1.0);
}
