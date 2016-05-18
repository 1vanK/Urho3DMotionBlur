#include "Uniforms.glsl"
#include "Samplers.glsl"
#include "Transform.glsl"
#include "ScreenPos.glsl"

#ifdef COMPILEPS
uniform mat4 cOldViewProj;
uniform float cTimeStep;
#endif

varying vec3 vFarRay;
varying vec4 vScreenPos;
varying vec4 vGBufferOffsets;

void VS()
{
    mat4 modelMatrix = iModelMatrix;
    vec3 worldPos = GetWorldPos(modelMatrix);
    gl_Position = GetClipPos(worldPos);
    vScreenPos = GetScreenPos(gl_Position);
    vFarRay = GetFarRay(gl_Position) * gl_Position.w;
    vGBufferOffsets = cGBufferOffsets;
}

#line 0
void PS()
{
    // HWDEPTH
    float depth = ReconstructDepth(texture2DProj(sDepthBuffer, vScreenPos).r);

    vec3 worldPos = vFarRay * depth / vScreenPos.w;
    worldPos += cCameraPosPS;

    vec4 oldClipPos = vec4(worldPos, 1.0) * cOldViewProj;
    oldClipPos /= oldClipPos.w;

    vec2 oldScreenPos = vec2(oldClipPos.x * vGBufferOffsets.z + vGBufferOffsets.x * oldClipPos.w,
                        oldClipPos.y * vGBufferOffsets.w + vGBufferOffsets.y * oldClipPos.w);

    vec2 delta = (vScreenPos.xy - oldScreenPos);
    delta = delta / cTimeStep / 20.0;

    vec3 sum = vec3(0.0);
    float samples = 20;
    
    for (float i = 0.0; i < samples; i++)
    {
        vec2 pos = vScreenPos.xy + delta * ( (i / (samples - 1)) - 0.5 );
        sum += texture2D(sDiffMap, pos).rgb;
	}

	vec3 color = sum / samples;
	
    gl_FragColor = vec4(color, 1);
}
