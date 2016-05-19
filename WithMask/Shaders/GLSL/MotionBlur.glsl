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

void PS()
{
    vec3 mask = texture2DProj(sNormalMap, vScreenPos).rgb;
    if (mask.r > 0)
    {
        gl_FragColor = texture2DProj(sDiffMap, vScreenPos).rgba;
        return;
    }

    // HWDEPTH
    float depth = ReconstructDepth(texture2DProj(sDepthBuffer, vScreenPos).r);
    
    

    vec3 worldPos = vFarRay * depth / vScreenPos.w;
    worldPos += cCameraPosPS;

    vec4 oldClipPos = vec4(worldPos, 1.0) * cOldViewProj;
    oldClipPos /= oldClipPos.w;

    vec4 oldScreenPos = vec4(oldClipPos.x * vGBufferOffsets.z + vGBufferOffsets.x * oldClipPos.w,
                        oldClipPos.y * vGBufferOffsets.w + vGBufferOffsets.y * oldClipPos.w,
                        0.0, oldClipPos.w);

    // Расстояние на экране, которое прошел пиксель с прошлого кадра.
    vec4 offset = (vScreenPos - oldScreenPos);
    // При большой частоте кадров расстояния очень малы и эффект размытия становится незаметен.
    // Поэтому используем промежуток времени с прошлого кадра как коэффициент, чтобы сделать эффект
    // размытия независимым от ФПС.
    // В данном случае эффект рассчитывается как для ФПС = 20 кадров в секунду.
    offset = offset / (cTimeStep * 20.0);

    // Скорость пикселя = путь / время = offset / cTimeStep.
    // Так как мы хотим привести поведение эффекта к ФПС = 20, то нам нужно расстояние, которое пройдет пиксель за 1 / 20 секунды.
    // Итоговый путь = скорость * время = (offset / cTimeStep) * (1 / 20) = offset / (cTimeStep * 20).

    int samples = 20;
    
#line 0
    // Суммируем пиксели в направлении движения на расстояние dist / 2 в каждую сторону
    // от рассматриваемого пикселя.
    vec4 startPos = vScreenPos + offset * -0.5;
    vec4 step = offset / (samples - 1);
    //vec3 sum = texture2DProj(sDiffMap, pos).rgb;
    
    vec3 sum = vec3(0.0);
    
    float goodSamples = 0;
    
    for (float i = 0; i < samples; i++)
    {
        //vec4 pos = vScreenPos + offset * ( ( i / ( samples - 1 ) ) - 0.5 );
        vec4 pos = startPos + step * i;
        vec4 mask = texture2DProj(sNormalMap, pos).rgba;
        if (mask.r > 0)
            continue;
        sum += texture2DProj(sDiffMap, pos).rgb * (1 - mask.r);
        goodSamples += (1 - mask.r);
    }

    vec3 color = sum / goodSamples;
    
	
    gl_FragColor = vec4(color, 1);
}
