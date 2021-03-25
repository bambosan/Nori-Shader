#ifndef _UNIFORM_UI_TEXT_PS_CONSTANTS_H
#define _UNIFORM_UI_TEXT_PS_CONSTANTS_H

#include "uniformMacro.h"

#ifdef MCPE_PLATFORM_NX
#extension GL_ARB_enhanced_layouts : enable
layout(binding = 3) uniform UITextPSConstants {
#endif
// BEGIN_UNIFORM_BLOCK(UITextPSConstants) - unfortunately this macro does not work on old Amazon platforms so using above 3 lines instead
UNIFORM float BITMAP;
END_UNIFORM_BLOCK

#endif
