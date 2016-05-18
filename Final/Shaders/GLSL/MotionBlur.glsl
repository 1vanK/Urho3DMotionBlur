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

    vec2 dist = (vScreenPos.xy - oldScreenPos);
    dist = dist / cTimeStep / 20.0;

    int samples = 20;
    
    // Суммируем пиксели в направлении движения на расстояние dist / 2 в каждую сторону
    // от рассматриваемого пикселя.
    vec2 pos = vScreenPos.xy + dist * -0.5;
    vec2 step = dist / (samples - 1);
    vec3 sum = texture2D(sDiffMap, pos).rgb;
    
    for (int i = 1; i < samples; i++)
    {
        pos += step;
        sum += texture2D(sDiffMap, pos).rgb;
    }

    vec3 color = sum / samples;
	
    gl_FragColor = vec4(color, 1);
}
