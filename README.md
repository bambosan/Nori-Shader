# Nori-Shaders-BE
this is a shader for minecraft be (mobile) for opengl es 3.0 or above, this shader has a unique feature which not all shaders have and physical texture-based rendering (PBR) is its own uniqueness but other than that all the coloring on the shader is only based on color minecraft's built-in fog so the resulting color is uncertain.

The pbr format used is really adapted from the old java edition pbr

### Texture Mapping
This shader uses a 1x3 texture mapping so if the texture used is 16px then the size for the shader must be 32px, this is necessary because for the placement of the mer and normal map textures.
<img src="https://github.com/Mcbamboo/mbabo_asset/blob/ba5f5deb37cee6878137f3707b2337ede505f52f/nori%20asset/mapping.png" width="100" height="100">
### Metallic

