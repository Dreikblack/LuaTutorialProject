#version 450
#extension GL_ARB_separate_shader_objects : enable
//#extension GL_EXT_multiview : enable
#extension GL_ARB_bindless_texture : enable

#include "../Base/Fragment.glsl"
#include "../Utilities/DepthFunctions.glsl"

void main()
{    
    Material mtl = materials[materialID];
    vec4 basecolor = mtl.diffuseColor * color;

    outColor[0] = basecolor;
    
    // Base texture color
    if (mtl.textureHandle[0] != uvec2(0)) outColor[0] *= textureLod(sampler2D(mtl.textureHandle[0]), texcoords.xy, mtl.emissiveColor.r);

    if ((RenderFlags & RENDERFLAGS_TRANSPARENCY) != 0) outColor[0].rgb *= outColor[0].a;
}