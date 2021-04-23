// __multiversion__
#include "vertexVersionSimple.h"
#include "uniformWorldConstants.h"

attribute mediump vec4 POSITION;

varying highp float isskyhorizon;

void main(){

    vec4 position = POSITION;
        position.y -= length(position.xz) * 0.2;
    gl_Position = WORLDVIEWPROJ * position;

    isskyhorizon = length(POSITION.xz);
}
