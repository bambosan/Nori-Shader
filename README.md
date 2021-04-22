# Nori-Shaders-BE ALPHA 0.1.0
this is a shader for minecraft be (mobile).

### Features
for the first beta version I released, this shader has the following features.
- Beautiful Fog
- Sun and moon is rounded and looks radiant
- Static direct light
- Underblock shadow
- Bump & Normal map lighting (texture based)
- Sky reflection (texture based)
- GGX lighting / specular (texture based)
- fake sky light bounce
- fake block emission (texture based)
- HDR tonemap
- rain reflection
- rain fog

### Texture Mapping
This shader uses a 1x3 texture mapping so if the texture used is 16px then the size for the shader must be 32px, because minecraft be only read one texture for one block then it's a trick for place 3 different textures in one image (texture)

<img src="https://github.com/Mcbamboo/mbabo_asset/blob/2679374b2cec2a74d84bd7a0b8bdc7444937aade/nori%20asset/mapping.png" width="300" height="300"><br>
Note : the pbr format used is old pbr for java edition

