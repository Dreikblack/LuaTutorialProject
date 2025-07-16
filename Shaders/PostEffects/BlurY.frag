#version 450
#extension GL_ARB_separate_shader_objects : enable

//Inputs
layout(location = 0) in vec2 texCoords;

//Output
layout(location = 0) out vec4 outColor;

// Uniforms
layout(location = 0, binding = 0) uniform sampler2D ColorBuffer;
layout(location = 2) uniform ivec4 DrawViewport;
layout(location = 3) uniform int BlurRadius = 8;
layout(location = 4) uniform int level = 0;

void main()
{
    vec2 tc = vec2(gl_FragCoord.x / float(DrawViewport.z), gl_FragCoord.y / float(DrawViewport.w));
    float ts = 1.0f / textureSize(ColorBuffer, level + 1).y;
    
    outColor = vec4(0.0);
    for (int n = -BlurRadius; n <= BlurRadius; ++n)
    {
        outColor += textureLod(ColorBuffer, tc + vec2(0.0f, ts * float(n)), level);
    }
    outColor /= float(BlurRadius * 2 + 1);
}