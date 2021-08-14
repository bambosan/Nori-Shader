// __multiversion__
#include "vertexVersionSimple.h"
#include "uniformWorldConstants.h"

attribute mediump vec4 POSITION;
varying vec4 color;

void main(){
 	gl_Position = WORLDVIEWPROJ * POSITION;
 	color.a *= 0.0;
}
