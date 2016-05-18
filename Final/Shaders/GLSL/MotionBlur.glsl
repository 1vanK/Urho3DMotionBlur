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

    // Расстояние на экране, которое прошел пиксель с прошлого кадра.
    vec2 offset = (vScreenPos.xy - oldScreenPos);
    // При большой частоте кадров расстояния очень малы и эффект размытия становится незаметен.
    // Поэтому используем промежуток времени с прошлого кадра как коэффициент, чтобы сделать эффект
    // размытия независимым от ФПС.
    // В данном случае эффект рассчитывается как для ФПС = 20 кадров в секунду.
    offset = offset / (cTimeStep * 20.0);

    // ФПС = число кадров / время.
    // Так как нам нужен коэффициент, приводящий текущий ФПС к 20 кадрам в в секунду, то
    // текущий ФПС = 20 * некий коэффициент.
    // Значит некий коэффициент = текущий фпс / 20. Текущий ФПС = также равен 1 / время.
    // Значит коэффициент = 1 / (время * 20).

    int samples = 20;
    
    // Суммируем пиксели в направлении движения на расстояние dist / 2 в каждую сторону
    // от рассматриваемого пикселя.
    vec2 pos = vScreenPos.xy + offset * -0.5;
    vec2 step = offset / (samples - 1);
    vec3 sum = texture2D(sDiffMap, pos).rgb;
    
    for (int i = 1; i < samples; i++)
    {
        pos += step;
        sum += texture2D(sDiffMap, pos).rgb;
    }

    vec3 color = sum / samples;
	
    gl_FragColor = vec4(color, 1);
}
