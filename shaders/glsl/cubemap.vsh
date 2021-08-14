// __multiversion__
#include "vertexVersionSimple.h"
#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"

attribute POS4 POSITION;
varying vec3 cPos;

void main(){
	gl_Position = WORLDVIEWPROJ * POSITION;
	cPos = POSITION.xyz;
}
