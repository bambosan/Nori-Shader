// __multiversion__
#include "vertexVersionSimple.h"
#include "uniformWorldConstants.h"

attribute POS4 POSITION;

varying highp vec3 worldpos;

void main()
{

    gl_Position = WORLDVIEWPROJ * POSITION;

    worldpos = POSITION.xyz;

}
