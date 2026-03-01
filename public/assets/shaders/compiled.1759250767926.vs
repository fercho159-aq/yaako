{@}CTVRHand.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uStatic;
uniform float uContrastMix;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;

#!SHADER: Vertex
varying vec3 vPos;

#require(skinning.glsl)
#require(matcap.vs)

void main() {
    vNormal = normalize(normalMatrix * normal);
    vUv = uv;
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    vec3 pos = position;

    if (uStatic < 0.5) {
        applySkin(pos, vNormal);
    }

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vPos = pos;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));
}

#!SHADER: Fragment

#require(fresnel.glsl)
#require(range.glsl)

void main() {
    float fresnel =  getFresnel(vNormal, vViewDir, 1.0);
    float c = 0.0;

    float matcap = texture2D(tMatcap, vMuv * vec2(0.5, 1.0) + vec2(0.5 * uColor.r, 0.0)).r;

    matcap = crange(
        matcap,
        0.0,
        crange(uColor.r, 0.0, 0.1, 1.0, 0.6),
        crange(uColor.r, 0.0, 0.1, 0.05, 0.4),
        crange(uColor.r, 0.0, 0.1, 0.95, 1.0)
    );
    matcap += fresnel * crange(uColor.r, 0.0, 0.1, 0.0, 0.2);
    matcap += crange(
        fresnel,
        0.2,
        1.0,
        0.0,
        crange(uColor.r, 0.0, 0.1, 0.5, 0.0)
    );

    c += matcap;
    c = clamp(c, 0.0, 1.0);
    vec3 color = texture2D(tRamp, vec2(c, 0.0)).rgb;
    gl_FragColor.rgb = color;
    gl_FragColor.a = uAlpha;
}{@}AntimatterCopy.fs{@}uniform sampler2D tDiffuse;

varying vec2 vUv;

void main() {
    gl_FragColor = texture2D(tDiffuse, vUv);
}{@}AntimatterCopy.vs{@}varying vec2 vUv;
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}{@}AntimatterPass.vs{@}varying vec2 vUv;

void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}{@}AntimatterPosition.vs{@}uniform sampler2D tPos;

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;

    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    gl_PointSize = 0.02 * (1000.0 / length(mvPosition.xyz));
    gl_Position = projectionMatrix * mvPosition;
}{@}AntimatterBasicFrag.fs{@}void main() {
    gl_FragColor = vec4(1.0);
}{@}antimatter.glsl{@}vec3 getData(sampler2D tex, vec2 uv) {
    return texture2D(tex, uv).xyz;
}

vec4 getData4(sampler2D tex, vec2 uv) {
    return texture2D(tex, uv);
}

{@}blendmodes.glsl{@}float blendColorDodge(float base, float blend) {
    return (blend == 1.0)?blend:min(base/(1.0-blend), 1.0);
}
vec3 blendColorDodge(vec3 base, vec3 blend) {
    return vec3(blendColorDodge(base.r, blend.r), blendColorDodge(base.g, blend.g), blendColorDodge(base.b, blend.b));
}
vec3 blendColorDodge(vec3 base, vec3 blend, float opacity) {
    return (blendColorDodge(base, blend) * opacity + base * (1.0 - opacity));
}
float blendColorBurn(float base, float blend) {
    return (blend == 0.0)?blend:max((1.0-((1.0-base)/blend)), 0.0);
}
vec3 blendColorBurn(vec3 base, vec3 blend) {
    return vec3(blendColorBurn(base.r, blend.r), blendColorBurn(base.g, blend.g), blendColorBurn(base.b, blend.b));
}
vec3 blendColorBurn(vec3 base, vec3 blend, float opacity) {
    return (blendColorBurn(base, blend) * opacity + base * (1.0 - opacity));
}
float blendVividLight(float base, float blend) {
    return (blend<0.5)?blendColorBurn(base, (2.0*blend)):blendColorDodge(base, (2.0*(blend-0.5)));
}
vec3 blendVividLight(vec3 base, vec3 blend) {
    return vec3(blendVividLight(base.r, blend.r), blendVividLight(base.g, blend.g), blendVividLight(base.b, blend.b));
}
vec3 blendVividLight(vec3 base, vec3 blend, float opacity) {
    return (blendVividLight(base, blend) * opacity + base * (1.0 - opacity));
}
float blendHardMix(float base, float blend) {
    return (blendVividLight(base, blend)<0.5)?0.0:1.0;
}
vec3 blendHardMix(vec3 base, vec3 blend) {
    return vec3(blendHardMix(base.r, blend.r), blendHardMix(base.g, blend.g), blendHardMix(base.b, blend.b));
}
vec3 blendHardMix(vec3 base, vec3 blend, float opacity) {
    return (blendHardMix(base, blend) * opacity + base * (1.0 - opacity));
}
float blendLinearDodge(float base, float blend) {
    return min(base+blend, 1.0);
}
vec3 blendLinearDodge(vec3 base, vec3 blend) {
    return min(base+blend, vec3(1.0));
}
vec3 blendLinearDodge(vec3 base, vec3 blend, float opacity) {
    return (blendLinearDodge(base, blend) * opacity + base * (1.0 - opacity));
}
float blendLinearBurn(float base, float blend) {
    return max(base+blend-1.0, 0.0);
}
vec3 blendLinearBurn(vec3 base, vec3 blend) {
    return max(base+blend-vec3(1.0), vec3(0.0));
}
vec3 blendLinearBurn(vec3 base, vec3 blend, float opacity) {
    return (blendLinearBurn(base, blend) * opacity + base * (1.0 - opacity));
}
float blendLinearLight(float base, float blend) {
    return blend<0.5?blendLinearBurn(base, (2.0*blend)):blendLinearDodge(base, (2.0*(blend-0.5)));
}
vec3 blendLinearLight(vec3 base, vec3 blend) {
    return vec3(blendLinearLight(base.r, blend.r), blendLinearLight(base.g, blend.g), blendLinearLight(base.b, blend.b));
}
vec3 blendLinearLight(vec3 base, vec3 blend, float opacity) {
    return (blendLinearLight(base, blend) * opacity + base * (1.0 - opacity));
}
float blendLighten(float base, float blend) {
    return max(blend, base);
}
vec3 blendLighten(vec3 base, vec3 blend) {
    return vec3(blendLighten(base.r, blend.r), blendLighten(base.g, blend.g), blendLighten(base.b, blend.b));
}
vec3 blendLighten(vec3 base, vec3 blend, float opacity) {
    return (blendLighten(base, blend) * opacity + base * (1.0 - opacity));
}
float blendDarken(float base, float blend) {
    return min(blend, base);
}
vec3 blendDarken(vec3 base, vec3 blend) {
    return vec3(blendDarken(base.r, blend.r), blendDarken(base.g, blend.g), blendDarken(base.b, blend.b));
}
vec3 blendDarken(vec3 base, vec3 blend, float opacity) {
    return (blendDarken(base, blend) * opacity + base * (1.0 - opacity));
}
float blendPinLight(float base, float blend) {
    return (blend<0.5)?blendDarken(base, (2.0*blend)):blendLighten(base, (2.0*(blend-0.5)));
}
vec3 blendPinLight(vec3 base, vec3 blend) {
    return vec3(blendPinLight(base.r, blend.r), blendPinLight(base.g, blend.g), blendPinLight(base.b, blend.b));
}
vec3 blendPinLight(vec3 base, vec3 blend, float opacity) {
    return (blendPinLight(base, blend) * opacity + base * (1.0 - opacity));
}
float blendReflect(float base, float blend) {
    return (blend == 1.0)?blend:min(base*base/(1.0-blend), 1.0);
}
vec3 blendReflect(vec3 base, vec3 blend) {
    return vec3(blendReflect(base.r, blend.r), blendReflect(base.g, blend.g), blendReflect(base.b, blend.b));
}
vec3 blendReflect(vec3 base, vec3 blend, float opacity) {
    return (blendReflect(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendGlow(vec3 base, vec3 blend) {
    return blendReflect(blend, base);
}
vec3 blendGlow(vec3 base, vec3 blend, float opacity) {
    return (blendGlow(base, blend) * opacity + base * (1.0 - opacity));
}
float blendOverlay(float base, float blend) {
    return base<0.5?(2.0*base*blend):(1.0-2.0*(1.0-base)*(1.0-blend));
}
vec3 blendOverlay(vec3 base, vec3 blend) {
    return vec3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
}
vec3 blendOverlay(vec3 base, vec3 blend, float opacity) {
    return (blendOverlay(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendHardLight(vec3 base, vec3 blend) {
    return blendOverlay(blend, base);
}
vec3 blendHardLight(vec3 base, vec3 blend, float opacity) {
    return (blendHardLight(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendPhoenix(vec3 base, vec3 blend) {
    return min(base, blend)-max(base, blend)+vec3(1.0);
}
vec3 blendPhoenix(vec3 base, vec3 blend, float opacity) {
    return (blendPhoenix(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendNormal(vec3 base, vec3 blend) {
    return blend;
}
vec3 blendNormal(vec3 base, vec3 blend, float opacity) {
    return (blendNormal(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendNegation(vec3 base, vec3 blend) {
    return vec3(1.0)-abs(vec3(1.0)-base-blend);
}
vec3 blendNegation(vec3 base, vec3 blend, float opacity) {
    return (blendNegation(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendMultiply(vec3 base, vec3 blend) {
    return base*blend;
}
vec3 blendMultiply(vec3 base, vec3 blend, float opacity) {
    return (blendMultiply(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendAverage(vec3 base, vec3 blend) {
    return (base+blend)/2.0;
}
vec3 blendAverage(vec3 base, vec3 blend, float opacity) {
    return (blendAverage(base, blend) * opacity + base * (1.0 - opacity));
}
float blendScreen(float base, float blend) {
    return 1.0-((1.0-base)*(1.0-blend));
}
vec3 blendScreen(vec3 base, vec3 blend) {
    return vec3(blendScreen(base.r, blend.r), blendScreen(base.g, blend.g), blendScreen(base.b, blend.b));
}
vec3 blendScreen(vec3 base, vec3 blend, float opacity) {
    return (blendScreen(base, blend) * opacity + base * (1.0 - opacity));
}
float blendSoftLight(float base, float blend) {
    return (blend<0.5)?(2.0*base*blend+base*base*(1.0-2.0*blend)):(sqrt(base)*(2.0*blend-1.0)+2.0*base*(1.0-blend));
}
vec3 blendSoftLight(vec3 base, vec3 blend) {
    return vec3(blendSoftLight(base.r, blend.r), blendSoftLight(base.g, blend.g), blendSoftLight(base.b, blend.b));
}
vec3 blendSoftLight(vec3 base, vec3 blend, float opacity) {
    return (blendSoftLight(base, blend) * opacity + base * (1.0 - opacity));
}
float blendSubtract(float base, float blend) {
    return max(base+blend-1.0, 0.0);
}
vec3 blendSubtract(vec3 base, vec3 blend) {
    return max(base+blend-vec3(1.0), vec3(0.0));
}
vec3 blendSubtract(vec3 base, vec3 blend, float opacity) {
    return (blendSubtract(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendExclusion(vec3 base, vec3 blend) {
    return base+blend-2.0*base*blend;
}
vec3 blendExclusion(vec3 base, vec3 blend, float opacity) {
    return (blendExclusion(base, blend) * opacity + base * (1.0 - opacity));
}
vec3 blendDifference(vec3 base, vec3 blend) {
    return abs(base-blend);
}
vec3 blendDifference(vec3 base, vec3 blend, float opacity) {
    return (blendDifference(base, blend) * opacity + base * (1.0 - opacity));
}
float blendAdd(float base, float blend) {
    return min(base+blend, 1.0);
}
vec3 blendAdd(vec3 base, vec3 blend) {
    return min(base+blend, vec3(1.0));
}
vec3 blendAdd(vec3 base, vec3 blend, float opacity) {
    return (blendAdd(base, blend) * opacity + base * (1.0 - opacity));
}{@}conditionals.glsl{@}vec4 when_eq(vec4 x, vec4 y) {
  return 1.0 - abs(sign(x - y));
}

vec4 when_neq(vec4 x, vec4 y) {
  return abs(sign(x - y));
}

vec4 when_gt(vec4 x, vec4 y) {
  return max(sign(x - y), 0.0);
}

vec4 when_lt(vec4 x, vec4 y) {
  return max(sign(y - x), 0.0);
}

vec4 when_ge(vec4 x, vec4 y) {
  return 1.0 - when_lt(x, y);
}

vec4 when_le(vec4 x, vec4 y) {
  return 1.0 - when_gt(x, y);
}

vec3 when_eq(vec3 x, vec3 y) {
  return 1.0 - abs(sign(x - y));
}

vec3 when_neq(vec3 x, vec3 y) {
  return abs(sign(x - y));
}

vec3 when_gt(vec3 x, vec3 y) {
  return max(sign(x - y), 0.0);
}

vec3 when_lt(vec3 x, vec3 y) {
  return max(sign(y - x), 0.0);
}

vec3 when_ge(vec3 x, vec3 y) {
  return 1.0 - when_lt(x, y);
}

vec3 when_le(vec3 x, vec3 y) {
  return 1.0 - when_gt(x, y);
}

vec2 when_eq(vec2 x, vec2 y) {
  return 1.0 - abs(sign(x - y));
}

vec2 when_neq(vec2 x, vec2 y) {
  return abs(sign(x - y));
}

vec2 when_gt(vec2 x, vec2 y) {
  return max(sign(x - y), 0.0);
}

vec2 when_lt(vec2 x, vec2 y) {
  return max(sign(y - x), 0.0);
}

vec2 when_ge(vec2 x, vec2 y) {
  return 1.0 - when_lt(x, y);
}

vec2 when_le(vec2 x, vec2 y) {
  return 1.0 - when_gt(x, y);
}

float when_eq(float x, float y) {
  return 1.0 - abs(sign(x - y));
}

float when_neq(float x, float y) {
  return abs(sign(x - y));
}

float when_gt(float x, float y) {
  return max(sign(x - y), 0.0);
}

float when_lt(float x, float y) {
  return max(sign(y - x), 0.0);
}

float when_ge(float x, float y) {
  return 1.0 - when_lt(x, y);
}

float when_le(float x, float y) {
  return 1.0 - when_gt(x, y);
}

vec4 and(vec4 a, vec4 b) {
  return a * b;
}

vec4 or(vec4 a, vec4 b) {
  return min(a + b, 1.0);
}

vec4 Not(vec4 a) {
  return 1.0 - a;
}

vec3 and(vec3 a, vec3 b) {
  return a * b;
}

vec3 or(vec3 a, vec3 b) {
  return min(a + b, 1.0);
}

vec3 Not(vec3 a) {
  return 1.0 - a;
}

vec2 and(vec2 a, vec2 b) {
  return a * b;
}

vec2 or(vec2 a, vec2 b) {
  return min(a + b, 1.0);
}


vec2 Not(vec2 a) {
  return 1.0 - a;
}

float and(float a, float b) {
  return a * b;
}

float or(float a, float b) {
  return min(a + b, 1.0);
}

float Not(float a) {
  return 1.0 - a;
}{@}contrast.glsl{@}vec3 adjustContrast(vec3 color, float c, float m) {
	float t = 0.5 - c * 0.5;
	color.rgb = color.rgb * c + t;
	return color * m;
}{@}curl.glsl{@}#test Device.mobile
float sinf2(float x) {
    x*=0.159155;
    x-=floor(x);
    float xx=x*x;
    float y=-6.87897;
    y=y*xx+33.7755;
    y=y*xx-72.5257;
    y=y*xx+80.5874;
    y=y*xx-41.2408;
    y=y*xx+6.28077;
    return x*y;
}

float cosf2(float x) {
    return sinf2(x+1.5708);
}
#endtest

#test !Device.mobile
    #define sinf2 sin
    #define cosf2 cos
#endtest

float potential1(vec3 v) {
    float noise = 0.0;
    noise += sinf2(v.x * 1.8 + v.z * 3.) + sinf2(v.x * 4.8 + v.z * 4.5) + sinf2(v.x * -7.0 + v.z * 1.2) + sinf2(v.x * -5.0 + v.z * 2.13);
    noise += sinf2(v.y * -0.48 + v.z * 5.4) + sinf2(v.y * 2.56 + v.z * 5.4) + sinf2(v.y * 4.16 + v.z * 2.4) + sinf2(v.y * -4.16 + v.z * 1.35);
    return noise;
}

float potential2(vec3 v) {
    float noise = 0.0;
    noise += sinf2(v.y * 1.8 + v.x * 3. - 2.82) + sinf2(v.y * 4.8 + v.x * 4.5 + 74.37) + sinf2(v.y * -7.0 + v.x * 1.2 - 256.72) + sinf2(v.y * -5.0 + v.x * 2.13 - 207.683);
    noise += sinf2(v.z * -0.48 + v.x * 5.4 -125.796) + sinf2(v.z * 2.56 + v.x * 5.4 + 17.692) + sinf2(v.z * 4.16 + v.x * 2.4 + 150.512) + sinf2(v.z * -4.16 + v.x * 1.35 - 222.137);
    return noise;
}

float potential3(vec3 v) {
    float noise = 0.0;
    noise += sinf2(v.z * 1.8 + v.y * 3. - 194.58) + sinf2(v.z * 4.8 + v.y * 4.5 - 83.13) + sinf2(v.z * -7.0 + v.y * 1.2 -845.2) + sinf2(v.z * -5.0 + v.y * 2.13 - 762.185);
    noise += sinf2(v.x * -0.48 + v.y * 5.4 - 707.916) + sinf2(v.x * 2.56 + v.y * 5.4 + -482.348) + sinf2(v.x * 4.16 + v.y * 2.4 + 9.872) + sinf2(v.x * -4.16 + v.y * 1.35 - 476.747);
    return noise;
}

vec3 snoiseVec3( vec3 x ) {
    float s  = potential1(x);
    float s1 = potential2(x);
    float s2 = potential3(x);
    return vec3( s , s1 , s2 );
}

//Analitic derivatives of the potentials for the curl noise, based on: http://weber.itn.liu.se/~stegu/TNM084-2019/bridson-siggraph2007-curlnoise.pdf

float dP3dY(vec3 v) {
    float noise = 0.0;
    noise += 3. * cosf2(v.z * 1.8 + v.y * 3. - 194.58) + 4.5 * cosf2(v.z * 4.8 + v.y * 4.5 - 83.13) + 1.2 * cosf2(v.z * -7.0 + v.y * 1.2 -845.2) + 2.13 * cosf2(v.z * -5.0 + v.y * 2.13 - 762.185);
    noise += 5.4 * cosf2(v.x * -0.48 + v.y * 5.4 - 707.916) + 5.4 * cosf2(v.x * 2.56 + v.y * 5.4 + -482.348) + 2.4 * cosf2(v.x * 4.16 + v.y * 2.4 + 9.872) + 1.35 * cosf2(v.x * -4.16 + v.y * 1.35 - 476.747);
    return noise;
}

float dP2dZ(vec3 v) {
    return -0.48 * cosf2(v.z * -0.48 + v.x * 5.4 -125.796) + 2.56 * cosf2(v.z * 2.56 + v.x * 5.4 + 17.692) + 4.16 * cosf2(v.z * 4.16 + v.x * 2.4 + 150.512) -4.16 * cosf2(v.z * -4.16 + v.x * 1.35 - 222.137);
}

float dP1dZ(vec3 v) {
    float noise = 0.0;
    noise += 3. * cosf2(v.x * 1.8 + v.z * 3.) + 4.5 * cosf2(v.x * 4.8 + v.z * 4.5) + 1.2 * cosf2(v.x * -7.0 + v.z * 1.2) + 2.13 * cosf2(v.x * -5.0 + v.z * 2.13);
    noise += 5.4 * cosf2(v.y * -0.48 + v.z * 5.4) + 5.4 * cosf2(v.y * 2.56 + v.z * 5.4) + 2.4 * cosf2(v.y * 4.16 + v.z * 2.4) + 1.35 * cosf2(v.y * -4.16 + v.z * 1.35);
    return noise;
}

float dP3dX(vec3 v) {
    return -0.48 * cosf2(v.x * -0.48 + v.y * 5.4 - 707.916) + 2.56 * cosf2(v.x * 2.56 + v.y * 5.4 + -482.348) + 4.16 * cosf2(v.x * 4.16 + v.y * 2.4 + 9.872) -4.16 * cosf2(v.x * -4.16 + v.y * 1.35 - 476.747);
}

float dP2dX(vec3 v) {
    float noise = 0.0;
    noise += 3. * cosf2(v.y * 1.8 + v.x * 3. - 2.82) + 4.5 * cosf2(v.y * 4.8 + v.x * 4.5 + 74.37) + 1.2 * cosf2(v.y * -7.0 + v.x * 1.2 - 256.72) + 2.13 * cosf2(v.y * -5.0 + v.x * 2.13 - 207.683);
    noise += 5.4 * cosf2(v.z * -0.48 + v.x * 5.4 -125.796) + 5.4 * cosf2(v.z * 2.56 + v.x * 5.4 + 17.692) + 2.4 * cosf2(v.z * 4.16 + v.x * 2.4 + 150.512) + 1.35 * cosf2(v.z * -4.16 + v.x * 1.35 - 222.137);
    return noise;
}

float dP1dY(vec3 v) {
    return -0.48 * cosf2(v.y * -0.48 + v.z * 5.4) + 2.56 * cosf2(v.y * 2.56 + v.z * 5.4) +  4.16 * cosf2(v.y * 4.16 + v.z * 2.4) -4.16 * cosf2(v.y * -4.16 + v.z * 1.35);
}


vec3 curlNoise( vec3 p ) {

    //A sinf2 or cosf2 call is a trigonometric function, these functions are expensive in the GPU
    //the partial derivatives with approximations require to calculate the snoiseVec3 function 4 times.
    //The previous function evaluate the potentials that include 8 trigonometric functions each.
    //
    //This means that the potentials are evaluated 12 times (4 calls to snoiseVec3 that make 3 potential calls).
    //The whole process call 12 * 8 trigonometric functions, a total of 96 times.


    /*
    const float e = 1e-1;
    vec3 dx = vec3( e   , 0.0 , 0.0 );
    vec3 dy = vec3( 0.0 , e   , 0.0 );
    vec3 dz = vec3( 0.0 , 0.0 , e   );
    vec3 p0 = snoiseVec3(p);
    vec3 p_x1 = snoiseVec3( p + dx );
    vec3 p_y1 = snoiseVec3( p + dy );
    vec3 p_z1 = snoiseVec3( p + dz );
    float x = p_y1.z - p0.z - p_z1.y + p0.y;
    float y = p_z1.x - p0.x - p_x1.z + p0.z;
    float z = p_x1.y - p0.y - p_y1.x + p0.x;
    return normalize( vec3( x , y , z ));
    */


    //The noise that is used to define the potentials is based on analitic functions that are easy to derivate,
    //meaning that the analitic solution would provide a much faster approach with the same visual results.
    //
    //Usinf2g the analitic derivatives the algorithm does not require to evaluate snoiseVec3, instead it uses the
    //analitic partial derivatives from each potential on the corresponding axis, providing a total of
    //36 calls to trigonometric functions, making the analytic evaluation almost 3 times faster than the aproximation method.


    float x = dP3dY(p) - dP2dZ(p);
    float y = dP1dZ(p) - dP3dX(p);
    float z = dP2dX(p) - dP1dY(p);


    return normalize( vec3( x , y , z ));



}{@}depthvalue.fs{@}float getDepthValue(sampler2D tDepth, vec2 uv, float n, float f) {
    vec4 depth = texture2D(tDepth, uv);
    return (2.0 * n) / (f + n - depth.x * (f - n));
}{@}desaturate.fs{@}vec3 desaturate(vec3 color, float amount) {
    vec3 gray = vec3(dot(vec3(0.2126,0.7152,0.0722), color));
    return vec3(mix(color, gray, amount));
}{@}eases.glsl{@}#ifndef PI
#define PI 3.141592653589793
#endif

#ifndef HALF_PI
#define HALF_PI 1.5707963267948966
#endif

float backInOut(float t) {
  float f = t < 0.5
    ? 2.0 * t
    : 1.0 - (2.0 * t - 1.0);

  float g = pow(f, 3.0) - f * sin(f * PI);

  return t < 0.5
    ? 0.5 * g
    : 0.5 * (1.0 - g) + 0.5;
}

float backIn(float t) {
  return pow(t, 3.0) - t * sin(t * PI);
}

float backOut(float t) {
  float f = 1.0 - t;
  return 1.0 - (pow(f, 3.0) - f * sin(f * PI));
}

float bounceOut(float t) {
  const float a = 4.0 / 11.0;
  const float b = 8.0 / 11.0;
  const float c = 9.0 / 10.0;

  const float ca = 4356.0 / 361.0;
  const float cb = 35442.0 / 1805.0;
  const float cc = 16061.0 / 1805.0;

  float t2 = t * t;

  return t < a
    ? 7.5625 * t2
    : t < b
      ? 9.075 * t2 - 9.9 * t + 3.4
      : t < c
        ? ca * t2 - cb * t + cc
        : 10.8 * t * t - 20.52 * t + 10.72;
}

float bounceIn(float t) {
  return 1.0 - bounceOut(1.0 - t);
}

float bounceInOut(float t) {
  return t < 0.5
    ? 0.5 * (1.0 - bounceOut(1.0 - t * 2.0))
    : 0.5 * bounceOut(t * 2.0 - 1.0) + 0.5;
}

float circularInOut(float t) {
  return t < 0.5
    ? 0.5 * (1.0 - sqrt(1.0 - 4.0 * t * t))
    : 0.5 * (sqrt((3.0 - 2.0 * t) * (2.0 * t - 1.0)) + 1.0);
}

float circularIn(float t) {
  return 1.0 - sqrt(1.0 - t * t);
}

float circularOut(float t) {
  return sqrt((2.0 - t) * t);
}

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

float cubicIn(float t) {
  return t * t * t;
}

float cubicOut(float t) {
  float f = t - 1.0;
  return f * f * f + 1.0;
}

float elasticInOut(float t) {
  return t < 0.5
    ? 0.5 * sin(+13.0 * HALF_PI * 2.0 * t) * pow(2.0, 10.0 * (2.0 * t - 1.0))
    : 0.5 * sin(-13.0 * HALF_PI * ((2.0 * t - 1.0) + 1.0)) * pow(2.0, -10.0 * (2.0 * t - 1.0)) + 1.0;
}

float elasticIn(float t) {
  return sin(13.0 * t * HALF_PI) * pow(2.0, 10.0 * (t - 1.0));
}

float elasticOut(float t) {
  return sin(-13.0 * (t + 1.0) * HALF_PI) * pow(2.0, -10.0 * t) + 1.0;
}

float expoInOut(float t) {
  return t == 0.0 || t == 1.0
    ? t
    : t < 0.5
      ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
      : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}

float expoIn(float t) {
  return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0));
}

float expoOut(float t) {
  return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

float linear(float t) {
  return t;
}

float quadraticInOut(float t) {
  float p = 2.0 * t * t;
  return t < 0.5 ? p : -p + (4.0 * t) - 1.0;
}

float quadraticIn(float t) {
  return t * t;
}

float quadraticOut(float t) {
  return -t * (t - 2.0);
}

float quarticInOut(float t) {
  return t < 0.5
    ? +8.0 * pow(t, 4.0)
    : -8.0 * pow(t - 1.0, 4.0) + 1.0;
}

float quarticIn(float t) {
  return pow(t, 4.0);
}

float quarticOut(float t) {
  return pow(t - 1.0, 3.0) * (1.0 - t) + 1.0;
}

float qinticInOut(float t) {
  return t < 0.5
    ? +16.0 * pow(t, 5.0)
    : -0.5 * pow(2.0 * t - 2.0, 5.0) + 1.0;
}

float qinticIn(float t) {
  return pow(t, 5.0);
}

float qinticOut(float t) {
  return 1.0 - (pow(t - 1.0, 5.0));
}

float sineInOut(float t) {
  return -0.5 * (cos(PI * t) - 1.0);
}

float sineIn(float t) {
  return sin((t - 1.0) * HALF_PI) + 1.0;
}

float sineOut(float t) {
  return sin(t * HALF_PI);
}
{@}ColorMaterial.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 color;

#!VARYINGS

#!SHADER: ColorMaterial.vs
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: ColorMaterial.fs
void main() {
    gl_FragColor = vec4(color, 1.0);
}{@}DebugCamera.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;

#!VARYINGS
varying vec3 vColor;

#!SHADER: DebugCamera.vs
void main() {
    vColor = mix(uColor, vec3(1.0, 0.0, 0.0), step(position.z, -0.1));
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: DebugCamera.fs
void main() {
    gl_FragColor = vec4(vColor, 1.0);
}{@}ScreenQuad.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: ScreenQuad.vs
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: ScreenQuad.fs
void main() {
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.a = 1.0;
}{@}TestMaterial.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float alpha;

#!VARYINGS
varying vec3 vNormal;

#!SHADER: TestMaterial.vs
void main() {
    vec3 pos = position;
    vNormal = normalMatrix * normal;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: TestMaterial.fs
void main() {
    gl_FragColor = vec4(vNormal, 1.0);
}{@}TextureMaterial.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: TextureMaterial.vs
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: TextureMaterial.fs
void main() {
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.rgb /= gl_FragColor.a;
}{@}BlitPass.fs{@}void main() {
    gl_FragColor = texture2D(tDiffuse, vUv);
    gl_FragColor.a = 1.0;
}{@}NukePass.vs{@}varying vec2 vUv;

void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}{@}ShadowDepth.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS

#!SHADER: ShadowDepth.vs
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: ShadowDepth.fs
void main() {
    gl_FragColor = vec4(vec3(gl_FragCoord.x), 1.0);
}{@}instance.vs{@}vec3 transformNormal(vec3 n, vec4 orientation) {
    vec3 nn = n + 2.0 * cross(orientation.xyz, cross(orientation.xyz, n) + orientation.w * n);
    return nn;
}

vec3 transformPosition(vec3 position, vec3 offset, vec3 scale, vec4 orientation) {
    vec3 _pos = position;
    _pos *= scale;

    _pos = _pos + 2.0 * cross(orientation.xyz, cross(orientation.xyz, _pos) + orientation.w * _pos);
    _pos += offset;
    return _pos;
}

vec3 transformPosition(vec3 position, vec3 offset, vec4 orientation) {
    vec3 _pos = position;

    _pos = _pos + 2.0 * cross(orientation.xyz, cross(orientation.xyz, _pos) + orientation.w * _pos);
    _pos += offset;
    return _pos;
}

vec3 transformPosition(vec3 position, vec3 offset, float scale, vec4 orientation) {
    return transformPosition(position, offset, vec3(scale), orientation);
}

vec3 transformPosition(vec3 position, vec3 offset) {
    return position + offset;
}

vec3 transformPosition(vec3 position, vec3 offset, float scale) {
    vec3 pos = position * scale;
    return pos + offset;
}

vec3 transformPosition(vec3 position, vec3 offset, vec3 scale) {
    vec3 pos = position * scale;
    return pos + offset;
}{@}lights.fs{@}vec3 worldLight(vec3 pos, vec3 vpos) {
    vec4 mvPos = modelViewMatrix * vec4(vpos, 1.0);
    vec4 worldPosition = viewMatrix * vec4(pos, 1.0);
    return worldPosition.xyz - mvPos.xyz;
}{@}lights.vs{@}vec3 worldLight(vec3 pos) {
    vec4 mvPos = modelViewMatrix * vec4(position, 1.0);
    vec4 worldPosition = viewMatrix * vec4(pos, 1.0);
    return worldPosition.xyz - mvPos.xyz;
}

vec3 worldLight(vec3 lightPos, vec3 localPos) {
    vec4 mvPos = modelViewMatrix * vec4(localPos, 1.0);
    vec4 worldPosition = viewMatrix * vec4(lightPos, 1.0);
    return worldPosition.xyz - mvPos.xyz;
}{@}shadows.fs{@}float shadowCompare(sampler2D map, vec2 coords, float compare) {
    return step(compare, texture2D(map, coords).r);
}

float shadowLerp(sampler2D map, vec2 coords, float compare, float size) {
    const vec2 offset = vec2(0.0, 1.0);

    vec2 texelSize = vec2(1.0) / size;
    vec2 centroidUV = floor(coords * size + 0.5) / size;

    float lb = shadowCompare(map, centroidUV + texelSize * offset.xx, compare);
    float lt = shadowCompare(map, centroidUV + texelSize * offset.xy, compare);
    float rb = shadowCompare(map, centroidUV + texelSize * offset.yx, compare);
    float rt = shadowCompare(map, centroidUV + texelSize * offset.yy, compare);

    vec2 f = fract( coords * size + 0.5 );

    float a = mix( lb, lt, f.y );
    float b = mix( rb, rt, f.y );
    float c = mix( a, b, f.x );

    return c;
}

float srange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    float oldRange = oldMax - oldMin;
    float newRange = newMax - newMin;
    return (((oldValue - oldMin) * newRange) / oldRange) + newMin;
}

float shadowrandom(vec3 vin) {
    vec3 v = vin * 0.1;
    float t = v.z * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += srange(sin(v.x * 0.9 / s + t * 10.0) + sin(v.x * 2.4 / s + t * 15.0) + sin(v.x * -3.5 / s + t * 4.0) + sin(v.x * -2.5 / s + t * 7.1), -1.0, 1.0, -0.3, 0.3);
    noise += srange(sin(v.y * -0.3 / s + t * 18.0) + sin(v.y * 1.6 / s + t * 18.0) + sin(v.y * 2.6 / s + t * 8.0) + sin(v.y * -2.6 / s + t * 4.5), -1.0, 1.0, -0.3, 0.3);
    return noise;
}

float shadowLookup(sampler2D map, vec3 coords, float size, float compare, vec3 wpos) {
    float shadow = 1.0;

    #if defined(SHADOW_MAPS)
    bool frustumTest = coords.x >= 0.0 && coords.x <= 1.0 && coords.y >= 0.0 && coords.y <= 1.0 && coords.z <= 1.0;
    if (frustumTest) {
        vec2 texelSize = vec2(1.0) / size;

        float dx0 = -texelSize.x;
        float dy0 = -texelSize.y;
        float dx1 = +texelSize.x;
        float dy1 = +texelSize.y;

        float rnoise = shadowrandom(wpos) * 0.00015;
        dx0 += rnoise;
        dy0 -= rnoise;
        dx1 += rnoise;
        dy1 -= rnoise;

        #if defined(SHADOWS_MED)
        shadow += shadowCompare(map, coords.xy + vec2(0.0, dy0), compare);
        //        shadow += shadowCompare(map, coords.xy + vec2(dx1, dy0), compare);
        shadow += shadowCompare(map, coords.xy + vec2(dx0, 0.0), compare);
        shadow += shadowCompare(map, coords.xy, compare);
        shadow += shadowCompare(map, coords.xy + vec2(dx1, 0.0), compare);
        //        shadow += shadowCompare(map, coords.xy + vec2(dx0, dy1), compare);
        shadow += shadowCompare(map, coords.xy + vec2(0.0, dy1), compare);
        shadow /= 5.0;

        #elif defined(SHADOWS_HIGH)
        shadow = shadowLerp(map, coords.xy + vec2(dx0, dy0), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(0.0, dy0), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(dx1, dy0), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(dx0, 0.0), compare, size);
        shadow += shadowLerp(map, coords.xy, compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(dx1, 0.0), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(dx0, dy1), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(0.0, dy1), compare, size);
        shadow += shadowLerp(map, coords.xy + vec2(dx1, dy1), compare, size);
        shadow /= 9.0;

        #else
        shadow = shadowCompare(map, coords.xy, compare);
        #endif
    }

        #endif

    return clamp(shadow, 0.0, 1.0);
}

#test !!window.Metal
vec3 transformShadowLight(vec3 pos, vec3 vpos, mat4 mvMatrix, mat4 viewMatrix) {
    vec4 mvPos = mvMatrix * vec4(vpos, 1.0);
    vec4 worldPosition = viewMatrix * vec4(pos, 1.0);
    return normalize(worldPosition.xyz - mvPos.xyz);
}

float getShadow(vec3 pos, vec3 normal, float bias, Uniforms uniforms, GlobalUniforms globalUniforms, sampler2D shadowMap) {
    float shadow = 1.0;
    #if defined(SHADOW_MAPS)

    vec4 shadowMapCoords;
    vec3 coords;
    float lookup;

    for (int i = 0; i < SHADOW_COUNT; i++) {
        shadowMapCoords = uniforms.shadowMatrix[i] * vec4(pos, 1.0);
        coords = (shadowMapCoords.xyz / shadowMapCoords.w) * vec3(0.5) + vec3(0.5);

        lookup = shadowLookup(shadowMap, coords, uniforms.shadowSize[i], coords.z - bias, pos);
        lookup += mix(1.0 - step(0.002, dot(transformShadowLight(uniforms.shadowLightPos[i], pos, uniforms.modelViewMatrix, globalUniforms.viewMatrix), normal)), 0.0, step(999.0, normal.x));
        shadow *= clamp(lookup, 0.0, 1.0);
    }

    #endif
    return shadow;
}

float getShadow(vec3 pos, vec3 normal, Uniforms uniforms, GlobalUniforms globalUniforms, sampler2D shadowMap) {
    return getShadow(pos, normal, 0.0, uniforms, globalUniforms, shadowMap);
}

float getShadow(vec3 pos, float bias, Uniforms uniforms, GlobalUniforms globalUniforms, sampler2D shadowMap) {
    return getShadow(pos, vec3(99999.0), bias, uniforms, globalUniforms, shadowMap);
}

float getShadow(vec3 pos, Uniforms uniforms, GlobalUniforms globalUniforms, sampler2D shadowMap) {
    return getShadow(pos, vec3(99999.0), 0.0, uniforms, globalUniforms, shadowMap);
}

float getShadow(vec3 pos, vec3 normal) {
    return 1.0;
}

float getShadow(vec3 pos, float bias) {
    return 1.0;
}

float getShadow(vec3 pos) {
    return 1.0;
}
#endtest

#test !window.Metal
vec3 transformShadowLight(vec3 pos, vec3 vpos) {
    vec4 mvPos = modelViewMatrix * vec4(vpos, 1.0);
    vec4 worldPosition = viewMatrix * vec4(pos, 1.0);
    return normalize(worldPosition.xyz - mvPos.xyz);
}

float getShadow(vec3 pos, vec3 normal, float bias) {
    float shadow = 1.0;
    #if defined(SHADOW_MAPS)

    vec4 shadowMapCoords;
    vec3 coords;
    float lookup;

    #pragma unroll_loop
    for (int i = 0; i < SHADOW_COUNT; i++) {
        shadowMapCoords = shadowMatrix[i] * vec4(pos, 1.0);
        coords = (shadowMapCoords.xyz / shadowMapCoords.w) * vec3(0.5) + vec3(0.5);

        lookup = shadowLookup(shadowMap[i], coords, shadowSize[i], coords.z - bias, pos);
        lookup += mix(1.0 - step(0.002, dot(transformShadowLight(shadowLightPos[i], pos), normal)), 0.0, step(999.0, normal.x));
        shadow *= clamp(lookup, 0.0, 1.0);
    }

    #endif
    return shadow;
}

float getShadow(vec3 pos, vec3 normal) {
    return getShadow(pos, normal, 0.0);
}

float getShadow(vec3 pos, float bias) {
    return getShadow(pos, vec3(99999.0), bias);
}

float getShadow(vec3 pos) {
    return getShadow(pos, vec3(99999.0), 0.0);
}
#endtest{@}fresnel.glsl{@}float getFresnel(vec3 normal, vec3 viewDir, float power) {
    float d = dot(normalize(normal), normalize(viewDir));
    return 1.0 - pow(abs(d), power);
}

float getFresnel(float inIOR, float outIOR, vec3 normal, vec3 viewDir) {
    float ro = (inIOR - outIOR) / (inIOR + outIOR);
    float d = dot(normalize(normal), normalize(viewDir));
    return ro + (1. - ro) * pow((1. - d), 5.);
}


//viewDir = -vec3(modelViewMatrix * vec4(position, 1.0));{@}FXAA.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMask;

#!VARYINGS
varying vec2 v_rgbNW;
varying vec2 v_rgbNE;
varying vec2 v_rgbSW;
varying vec2 v_rgbSE;
varying vec2 v_rgbM;

#!SHADER: FXAA.vs

varying vec2 vUv;

void main() {
    vUv = uv;

    vec2 fragCoord = uv * resolution;
    vec2 inverseVP = 1.0 / resolution.xy;
    v_rgbNW = (fragCoord + vec2(-1.0, -1.0)) * inverseVP;
    v_rgbNE = (fragCoord + vec2(1.0, -1.0)) * inverseVP;
    v_rgbSW = (fragCoord + vec2(-1.0, 1.0)) * inverseVP;
    v_rgbSE = (fragCoord + vec2(1.0, 1.0)) * inverseVP;
    v_rgbM = vec2(fragCoord * inverseVP);

    gl_Position = vec4(position, 1.0);
}

#!SHADER: FXAA.fs

#require(conditionals.glsl)

#ifndef FXAA_REDUCE_MIN
    #define FXAA_REDUCE_MIN   (1.0/ 128.0)
#endif
#ifndef FXAA_REDUCE_MUL
    #define FXAA_REDUCE_MUL   (1.0 / 8.0)
#endif
#ifndef FXAA_SPAN_MAX
    #define FXAA_SPAN_MAX     8.0
#endif

vec4 fxaa(sampler2D tex, vec2 fragCoord, vec2 resolution,
            vec2 v_rgbNW, vec2 v_rgbNE,
            vec2 v_rgbSW, vec2 v_rgbSE,
            vec2 v_rgbM) {
    vec4 color;
    mediump vec2 inverseVP = vec2(1.0 / resolution.x, 1.0 / resolution.y);
    vec3 rgbNW = texture2D(tex, v_rgbNW).xyz;
    vec3 rgbNE = texture2D(tex, v_rgbNE).xyz;
    vec3 rgbSW = texture2D(tex, v_rgbSW).xyz;
    vec3 rgbSE = texture2D(tex, v_rgbSE).xyz;
    vec4 texColor = texture2D(tex, v_rgbM);
    vec3 rgbM  = texColor.xyz;
    vec3 luma = vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);
    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    mediump vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max((lumaNW + lumaNE + lumaSW + lumaSE) *
                          (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = min(vec2(FXAA_SPAN_MAX, FXAA_SPAN_MAX),
              max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
              dir * rcpDirMin)) * inverseVP;

    vec3 rgbA = 0.5 * (
        texture2D(tex, fragCoord * inverseVP + dir * (1.0 / 3.0 - 0.5)).xyz +
        texture2D(tex, fragCoord * inverseVP + dir * (2.0 / 3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * 0.5 + 0.25 * (
        texture2D(tex, fragCoord * inverseVP + dir * -0.5).xyz +
        texture2D(tex, fragCoord * inverseVP + dir * 0.5).xyz);

    float lumaB = dot(rgbB, luma);

    color = vec4(rgbB, texColor.a);
    color = mix(color, vec4(rgbA, texColor.a), when_lt(lumaB, lumaMin));
    color = mix(color, vec4(rgbA, texColor.a), when_gt(lumaB, lumaMax));

    return color;
}

void main() {
    vec2 fragCoord = vUv * resolution;
    float mask = texture2D(tMask, vUv).r;
    if (mask < 0.5) {
        gl_FragColor = fxaa(tDiffuse, fragCoord, resolution, v_rgbNW, v_rgbNE, v_rgbSW, v_rgbSE, v_rgbM);
    } else {
        gl_FragColor = texture2D(tDiffuse, vUv);
    }
    gl_FragColor.a = 1.0;
}
{@}gaussianblur.fs{@}vec4 blur13(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(1.411764705882353) * direction;
  vec2 off2 = vec2(3.2941176470588234) * direction;
  vec2 off3 = vec2(5.176470588235294) * direction;
  color += texture2D(image, uv) * 0.1964825501511404;
  color += texture2D(image, uv + (off1 / resolution)) * 0.2969069646728344;
  color += texture2D(image, uv - (off1 / resolution)) * 0.2969069646728344;
  color += texture2D(image, uv + (off2 / resolution)) * 0.09447039785044732;
  color += texture2D(image, uv - (off2 / resolution)) * 0.09447039785044732;
  color += texture2D(image, uv + (off3 / resolution)) * 0.010381362401148057;
  color += texture2D(image, uv - (off3 / resolution)) * 0.010381362401148057;
  return color;
}

vec4 blur5(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(1.3333333333333333) * direction;
  color += texture2D(image, uv) * 0.29411764705882354;
  color += texture2D(image, uv + (off1 / resolution)) * 0.35294117647058826;
  color += texture2D(image, uv - (off1 / resolution)) * 0.35294117647058826;
  return color;
}

vec4 blur9(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(1.3846153846) * direction;
  vec2 off2 = vec2(3.2307692308) * direction;
  color += texture2D(image, uv) * 0.2270270270;
  color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
  color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
  color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
  color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
  return color;
}

vec4 gaussianblur(sampler2D image, vec2 uv, float steps, vec2 resolution, vec2 direction) {

  vec4 blend = vec4(0.);
  float sum = 1.;
  float m = 1.;
  float n = steps;

  for (float i = 0.; i < 100.; i += 1.) {
      if(i >= 2. * steps) break;
      float k = i;
      float j = i - 0.5 * steps;
      blend += m * texture2D(image, uv + j * direction / resolution);
      m *= (n - k) / (k + 1.);
      sum += m;
  }

  return blend / sum;

}{@}glscreenprojection.glsl{@}vec2 frag_coord(vec4 glPos) {
    return ((glPos.xyz / glPos.w) * 0.5 + 0.5).xy;
}

vec2 getProjection(vec3 pos, mat4 projMatrix) {
    vec4 mvpPos = projMatrix * vec4(pos, 1.0);
    return frag_coord(mvpPos);
}

void applyNormal(inout vec3 pos, mat4 projNormalMatrix) {
    vec3 transformed = vec3(projNormalMatrix * vec4(pos, 0.0));
    pos = transformed;
}{@}DefaultText.glsl{@}#!ATTRIBUTES

#!UNIFORMS

uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS

varying vec2 vUv;

#!SHADER: DefaultText.vs

void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: DefaultText.fs

#require(msdf.glsl)

void main() {
    float alpha = msdf(tMap, vUv);

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha;
}
{@}msdf.glsl{@}float msdf(vec3 tex, vec2 uv) {
    // TODO: fallback for fwidth for webgl1 (need to enable ext)
    float signedDist = max(min(tex.r, tex.g), min(max(tex.r, tex.g), tex.b)) - 0.5;
    float d = fwidth(signedDist);
    float alpha = smoothstep(-d, d, signedDist);
    if (alpha < 0.01) discard;
    return alpha;
}

float msdf(sampler2D tMap, vec2 uv) {
    vec3 tex = texture2D(tMap, uv).rgb;
    return msdf( tex, uv );
}

float strokemsdf(sampler2D tMap, vec2 uv, float stroke, float padding) {
    vec3 tex = texture2D(tMap, uv).rgb;
    float signedDist = max(min(tex.r, tex.g), min(max(tex.r, tex.g), tex.b)) - 0.5;
    float t = stroke;
    float alpha = smoothstep(-t, -t + padding, signedDist) * smoothstep(t, t - padding, signedDist);
    return alpha;
}{@}GLUIBatch.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec2 scale;
attribute float rotation;
//attributes

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
//varyings

#!SHADER: Vertex

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0);
}

void main() {
    vUv = uv;
    //vdefines

    vec3 pos = vec3(rotationMatrix(vec3(0.0, 0.0, 1.0), rotation) * vec4(position, 1.0));
    pos.xy *= scale;
    pos.xyz += offset;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(1.0);
}{@}GLUIBatchText.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec2 scale;
attribute float rotation;
//attributes

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
//varyings

#!SHADER: Vertex

mat4 lrotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0);
}

void main() {
    vUv = uv;
    //vdefines

    vec3 pos = vec3(lrotationMatrix(vec3(0.0, 0.0, 1.0), rotation) * vec4(position, 1.0));

    //custommain

    pos.xy *= scale;
    pos += offset;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(msdf.glsl)

void main() {
    float alpha = msdf(tMap, vUv);

    gl_FragColor.rgb = v_uColor;
    gl_FragColor.a = alpha * v_uAlpha;
}
{@}GLUIColor.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: GLUIColor.vs
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: GLUIColor.fs
void main() {
    vec2 uv = vUv;
    vec3 uvColor = vec3(uv, 1.0);
    gl_FragColor = vec4(mix(uColor, uvColor, 0.0), uAlpha);
}{@}GLUIObject.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: GLUIObject.vs
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: GLUIObject.fs
void main() {
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.a *= uAlpha;
}{@}gluimask.fs{@}uniform vec4 uMaskValues;

#require(range.glsl)

vec2 getMaskUV() {
    vec2 ores = gl_FragCoord.xy / resolution;
    vec2 uv;
    uv.x = range(ores.x, uMaskValues.x, uMaskValues.z, 0.0, 1.0);
    uv.y = 1.0 - range(1.0 - ores.y, uMaskValues.y, uMaskValues.w, 0.0, 1.0);
    return uv;
}{@}levelmask.glsl{@}float levelChannel(float inPixel, float inBlack, float inGamma, float inWhite, float outBlack, float outWhite) {
    return (pow(((inPixel * 255.0) - inBlack) / (inWhite - inBlack), inGamma) * (outWhite - outBlack) + outBlack) / 255.0;
}

vec3 levels(vec3 inPixel, float inBlack, float inGamma, float inWhite, float outBlack, float outWhite) {
    vec3 o = vec3(1.0);
    o.r = levelChannel(inPixel.r, inBlack, inGamma, inWhite, outBlack, outWhite);
    o.g = levelChannel(inPixel.g, inBlack, inGamma, inWhite, outBlack, outWhite);
    o.b = levelChannel(inPixel.b, inBlack, inGamma, inWhite, outBlack, outWhite);
    return o;
}

float animateLevels(float inp, float t) {
    float inBlack = 0.0;
    float inGamma = range(t, 0.0, 1.0, 0.0, 3.0);
    float inWhite = range(t, 0.0, 1.0, 20.0, 255.0);
    float outBlack = 0.0;
    float outWhite = 255.0;

    float mask = 1.0 - levels(vec3(inp), inBlack, inGamma, inWhite, outBlack, outWhite).r;
    mask = max(0.0, min(1.0, mask));
    return mask;
}{@}levels.glsl{@}vec3 gammaCorrect(vec3 color, float gamma){
    return pow(color, vec3(1.0/gamma));
}

vec3 levelRange(vec3 color, float minInput, float maxInput){
    return min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0));
}

vec3 getLevels(vec3 color, float minInput, float gamma, float maxInput){
    return gammaCorrect(levelRange(color, minInput, maxInput), gamma);
}{@}LightVolume.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec4 attribs;

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMask;

uniform float uScale;
uniform float uSeparation;
uniform float uAlpha;
uniform float uMaskScale;
uniform float uRotateSpeed;
uniform float uRotateTexture;
uniform float uNoiseScale;
uniform float uNoiseSpeed;
uniform float uNoiseRange;
uniform float uOffset;
uniform float uScrollX;
uniform float uScrollY;
uniform float uHueShift;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec4 vAttribs;
varying float vOffset;

#!SHADER: LightVolume.vs

#require(instance.vs)
#require(rotation.glsl)

void main() {
    vec3 pos = transformPosition(position, offset * uSeparation, uScale);
    pos = vec3(vec4(pos, 1.0) * rotationMatrix(vec3(0.0, 0.0, 1.0), radians(360.0 * 0.1 * offset.z * uOffset)));

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vPos = pos;
    vAttribs = attribs;
    vOffset = offset.z * 10.0;
}

#!SHADER: LightVolume.fs

#require(rgb2hsv.fs)
#require(range.glsl)
#require(transformUV.glsl)
#require(simplenoise.glsl)

void main() {
    vec3 color = rgb2hsv(uColor);
    color += vOffset * uHueShift * 0.01;
    color = hsv2rgb(color);

    float alpha = texture2D(tMap, rotateUV(vUv, time * uRotateTexture * 0.1)).r;

    vec2 uv = scaleUV(vUv, vec2(uMaskScale));

    float noise = cnoise(vPos * uNoiseScale + (time * uNoiseSpeed));
    uv += noise * uNoiseRange * 0.1;
    uv = scaleUV(uv, vec2(range(noise, -1.0, 0.0, 0.96, 1.02)));
    uv.x += sin(time * 0.04) * 0.3;

    uv = rotateUV(uv, uRotateSpeed * time * range(vAttribs.x, 0.0, 1.0, 0.5, 1.5));
    uv.x += time * uScrollX * 0.1 * range(vAttribs.y, 0.0, 1.0, 0.5, 1.5);
    uv.y += time * uScrollY * 0.1 * range(vAttribs.z, 0.0, 1.0, 0.5, 1.5);

    float mask = texture2D(tMask, uv).r;
    alpha *= mask;

    gl_FragColor = vec4(color, alpha * uAlpha);
}
{@}luma.fs{@}float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}{@}matcap.vs{@}vec2 reflectMatcap(vec3 position, mat4 modelViewMatrix, mat3 normalMatrix, vec3 normal) {
    vec4 p = vec4(position, 1.0);
    
    vec3 e = normalize(vec3(modelViewMatrix * p));
    vec3 n = normalize(normalMatrix * normal);
    vec3 r = reflect(e, n);
    float m = 2.0 * sqrt(
        pow(r.x, 2.0) +
        pow(r.y, 2.0) +
        pow(r.z + 1.0, 2.0)
    );
    
    vec2 uv = r.xy / m + .5;
    
    return uv;
}

vec2 reflectMatcap(vec3 position, mat4 modelViewMatrix, vec3 normal) {
    vec4 p = vec4(position, 1.0);
    
    vec3 e = normalize(vec3(modelViewMatrix * p));
    vec3 n = normalize(normal);
    vec3 r = reflect(e, n);
    float m = 2.0 * sqrt(
                         pow(r.x, 2.0) +
                         pow(r.y, 2.0) +
                         pow(r.z + 1.0, 2.0)
                         );
    
    vec2 uv = r.xy / m + .5;
    
    return uv;
}

vec2 reflectMatcap(vec4 mvPos, vec3 normal) {
    vec3 e = normalize(vec3(mvPos));
    vec3 n = normalize(normal);
    vec3 r = reflect(e, n);
    float m = 2.0 * sqrt(
                         pow(r.x, 2.0) +
                         pow(r.y, 2.0) +
                         pow(r.z + 1.0, 2.0)
                         );

    vec2 uv = r.xy / m + .5;

    return uv;
}{@}phong.fs{@}#define saturate(a) clamp( a, 0.0, 1.0 )

float dPhong(float shininess, float dotNH) {
    return (shininess * 0.5 + 1.0) * pow(dotNH, shininess);
}

vec3 schlick(vec3 specularColor, float dotLH) {
    float fresnel = exp2((-5.55437 * dotLH - 6.98316) * dotLH);
    return (1.0 - specularColor) * fresnel + specularColor;
}

vec3 calcBlinnPhong(vec3 specularColor, float shininess, vec3 normal, vec3 lightDir, vec3 viewDir) {
    vec3 halfDir = normalize(lightDir + viewDir);
    
    float dotNH = saturate(dot(normal, halfDir));
    float dotLH = saturate(dot(lightDir, halfDir));

    vec3 F = schlick(specularColor, dotLH);
    float G = 0.85;
    float D = dPhong(shininess, dotNH);
    
    return F * G * D;
}

vec3 calcBlinnPhong(vec3 specularColor, float shininess, vec3 normal, vec3 lightDir, vec3 viewDir, float minTreshold) {
    vec3 halfDir = normalize(lightDir + viewDir);

    float dotNH = saturate(dot(normal, halfDir));
    float dotLH = saturate(dot(lightDir, halfDir));

    dotNH = range(dotNH, 0.0, 1.0, minTreshold, 1.0);
    dotLH = range(dotLH, 0.0, 1.0, minTreshold, 1.0);

    vec3 F = schlick(specularColor, dotLH);
    float G = 0.85;
    float D = dPhong(shininess, dotNH);

    return F * G * D;
}

vec3 phong(float amount, vec3 diffuse, vec3 specular, float shininess, float attenuation, vec3 normal, vec3 lightDir, vec3 viewDir) {
    float cosineTerm = saturate(dot(normal, lightDir));
    vec3 brdf = calcBlinnPhong(specular, shininess, normal, lightDir, viewDir);
    return brdf * amount * diffuse * attenuation * cosineTerm;
}

vec3 phong(float amount, vec3 diffuse, vec3 specular, float shininess, float attenuation, vec3 normal, vec3 lightDir, vec3 viewDir, float minThreshold) {
    float cosineTerm = saturate(range(dot(normal, lightDir), 0.0, 1.0, minThreshold, 1.0));
    vec3 brdf = calcBlinnPhong(specular, shininess, normal, lightDir, viewDir, minThreshold);
    return brdf * amount * diffuse * attenuation * cosineTerm;
}

//viewDir = -mvPosition.xyz
//lightDir = normalize(lightPos){@}radialblur.fs{@}vec3 radialBlur( sampler2D map, vec2 uv, float size, vec2 resolution, float quality ) {
    vec3 color = vec3(0.);

    const float pi2 = 3.141596 * 2.0;
    const float direction = 8.0;

    vec2 radius = size / resolution;
    float test = 1.0;

    for ( float d = 0.0; d < pi2 ; d += pi2 / direction ) {
        vec2 t = radius * vec2( cos(d), sin(d));
        for ( float i = 1.0; i <= 100.0; i += 1.0 ) {
            if (i >= quality) break;
            color += texture2D( map, uv + t * i / quality ).rgb ;
        }
    }

    return color / ( quality * direction);
}

vec3 radialBlur( sampler2D map, vec2 uv, float size, float quality ) {
    vec3 color = vec3(0.);

    const float pi2 = 3.141596 * 2.0;
    const float direction = 8.0;

    vec2 radius = size / vec2(1024.0);
    float test = 1.0;

    for ( float d = 0.0; d < pi2 ; d += pi2 / direction ) {
        vec2 t = radius * vec2( cos(d), sin(d));
        for ( float i = 1.0; i <= 100.0; i += 1.0 ) {
            if (i >= quality) break;
            color += texture2D( map, uv + t * i / quality ).rgb ;
        }
    }

    return color / ( quality * direction);
}
{@}range.glsl{@}

float range(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    vec3 sub = vec3(oldValue, newMax, oldMax) - vec3(oldMin, newMin, oldMin);
    return sub.x * sub.y / sub.z + newMin;
}

vec2 range(vec2 oldValue, vec2 oldMin, vec2 oldMax, vec2 newMin, vec2 newMax) {
    vec2 oldRange = oldMax - oldMin;
    vec2 newRange = newMax - newMin;
    vec2 val = oldValue - oldMin;
    return val * newRange / oldRange + newMin;
}

vec3 range(vec3 oldValue, vec3 oldMin, vec3 oldMax, vec3 newMin, vec3 newMax) {
    vec3 oldRange = oldMax - oldMin;
    vec3 newRange = newMax - newMin;
    vec3 val = oldValue - oldMin;
    return val * newRange / oldRange + newMin;
}

float crange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}

vec2 crange(vec2 oldValue, vec2 oldMin, vec2 oldMax, vec2 newMin, vec2 newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}

vec3 crange(vec3 oldValue, vec3 oldMin, vec3 oldMax, vec3 newMin, vec3 newMax) {
    return clamp(range(oldValue, oldMin, oldMax, newMin, newMax), min(newMin, newMax), max(newMin, newMax));
}

float rangeTransition(float t, float x, float padding) {
    float transition = crange(t, 0.0, 1.0, -padding, 1.0 + padding);
    return crange(x, transition - padding, transition + padding, 1.0, 0.0);
}
{@}refl.fs{@}vec3 reflection(vec3 worldPosition, vec3 normal) {
    vec3 cameraToVertex = normalize(worldPosition - cameraPosition);
    
    return reflect(cameraToVertex, normal);
}

vec3 refraction(vec3 worldPosition, vec3 normal, float rRatio) {
    vec3 cameraToVertex = normalize(worldPosition - cameraPosition);
    
    return refract(cameraToVertex, normal, rRatio);
}

vec4 envColor(samplerCube map, vec3 vec) {
    float flipNormal = 1.0;
    return textureCube(map, flipNormal * vec3(-1.0 * vec.x, vec.yz));
}

vec4 envColorEqui(sampler2D map, vec3 direction) {
    vec2 uv;
    uv.y = asin( clamp( direction.y, - 1.0, 1.0 ) ) * 0.31830988618 + 0.5;
    uv.x = atan( direction.z, direction.x ) * 0.15915494 + 0.5;
    return texture2D(map, uv);
}{@}refl.vs{@}vec3 inverseTransformDirection(in vec3 normal, in mat4 matrix) {
    return normalize((matrix * vec4(normal, 0.0) * matrix).xyz);
}

vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
    return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}

vec3 reflection(vec4 worldPosition) {
    vec3 transformedNormal = normalMatrix * normal;
    vec3 cameraToVertex = normalize(worldPosition.xyz - cameraPosition);
    vec3 worldNormal = inverseTransformDirection(transformedNormal, viewMatrix);
    
    return reflect(cameraToVertex, worldNormal);
}

vec3 refraction(vec4 worldPosition, float refractionRatio) {
    vec3 transformedNormal = normalMatrix * normal;
    vec3 cameraToVertex = normalize(worldPosition.xyz - cameraPosition);
    vec3 worldNormal = inverseTransformDirection(transformedNormal, viewMatrix);
    
    return refract(cameraToVertex, worldNormal, refractionRatio);
}{@}rgb2hsv.fs{@}vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}{@}rgbshift.fs{@}vec4 getRGB(sampler2D tDiffuse, vec2 uv, float angle, float amount) {
    vec2 offset = vec2(cos(angle), sin(angle)) * amount;
    vec4 r = texture2D(tDiffuse, uv + offset);
    vec4 g = texture2D(tDiffuse, uv);
    vec4 b = texture2D(tDiffuse, uv - offset);
    return vec4(r.r, g.g, b.b, g.a);
}{@}rotation.glsl{@}mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}


mat2 rotationMatrix(float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return mat2(c, -s, s, c);
}{@}roundedBorder.glsl{@}float roundedBorder(float thickness, float radius, vec2 uv, vec2 resolution, out float inside) {
    // Get square-pixel coordinates in range -1.0 .. 1.0
    float multiplier = max(resolution.x, resolution.y);
    vec2 ratio = resolution / multiplier;
    vec2 squareUv = (2.0 * uv - 1.0) * ratio; // -1.0 .. 1.0

    float squareThickness = (thickness / multiplier);
    float squareRadius = 2.0 * (radius / multiplier);
    vec2 size = ratio - vec2(squareRadius + squareThickness);


    vec2 q = abs(squareUv) - size;
    float d = min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - squareRadius;
    float dist = abs(d);
    float delta = fwidth(dist);
    float border = 1.0 - smoothstep(-delta, delta, dist - squareThickness);

    delta = fwidth(d);
    float limit = squareThickness * 0.5;
    inside = 1.0 - smoothstep(-delta, delta, d - limit);

    return border;
}

float roundedBorder(float thickness, float radius, vec2 uv, vec2 resolution) {
    float inside;
    return roundedBorder(thickness, radius, uv, resolution, inside);
}
{@}simplenoise.glsl{@}float getNoise(vec2 uv, float time) {
    float x = uv.x * uv.y * time * 1000.0;
    x = mod(x, 13.0) * mod(x, 123.0);
    float dx = mod(x, 0.01);
    float amount = clamp(0.1 + dx * 100.0, 0.0, 1.0);
    return amount;
}

#test Device.mobile
float sinf(float x) {
    x*=0.159155;
    x-=floor(x);
    float xx=x*x;
    float y=-6.87897;
    y=y*xx+33.7755;
    y=y*xx-72.5257;
    y=y*xx+80.5874;
    y=y*xx-41.2408;
    y=y*xx+6.28077;
    return x*y;
}
#endtest

#test !Device.mobile
    #define sinf sin
#endtest

highp float getRandom(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt = dot(co.xy, vec2(a, b));
    highp float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

float cnoise(vec3 v) {
    float t = v.z * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += (sinf(v.x * 0.9 / s + t * 10.0) + sinf(v.x * 2.4 / s + t * 15.0) + sinf(v.x * -3.5 / s + t * 4.0) + sinf(v.x * -2.5 / s + t * 7.1)) * 0.3;
    noise += (sinf(v.y * -0.3 / s + t * 18.0) + sinf(v.y * 1.6 / s + t * 18.0) + sinf(v.y * 2.6 / s + t * 8.0) + sinf(v.y * -2.6 / s + t * 4.5)) * 0.3;
    return noise;
}

float cnoise(vec2 v) {
    float t = v.x * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += (sinf(v.x * 0.9 / s + t * 10.0) + sinf(v.x * 2.4 / s + t * 15.0) + sinf(v.x * -3.5 / s + t * 4.0) + sinf(v.x * -2.5 / s + t * 7.1)) * 0.3;
    noise += (sinf(v.y * -0.3 / s + t * 18.0) + sinf(v.y * 1.6 / s + t * 18.0) + sinf(v.y * 2.6 / s + t * 8.0) + sinf(v.y * -2.6 / s + t * 4.5)) * 0.3;
    return noise;
}{@}skinning.glsl{@}attribute vec4 skinIndex;
attribute vec4 skinWeight;

uniform sampler2D boneTexture;
uniform float boneTextureSize;

mat4 getBoneMatrix(const in float i) {
    float j = i * 4.0;
    float x = mod(j, boneTextureSize);
    float y = floor(j / boneTextureSize);

    float dx = 1.0 / boneTextureSize;
    float dy = 1.0 / boneTextureSize;

    y = dy * (y + 0.5);

    vec4 v1 = texture2D(boneTexture, vec2(dx * (x + 0.5), y));
    vec4 v2 = texture2D(boneTexture, vec2(dx * (x + 1.5), y));
    vec4 v3 = texture2D(boneTexture, vec2(dx * (x + 2.5), y));
    vec4 v4 = texture2D(boneTexture, vec2(dx * (x + 3.5), y));

    return mat4(v1, v2, v3, v4);
}

void applySkin(inout vec3 pos, inout vec3 normal) {
    mat4 boneMatX = getBoneMatrix(skinIndex.x);
    mat4 boneMatY = getBoneMatrix(skinIndex.y);
    mat4 boneMatZ = getBoneMatrix(skinIndex.z);
    mat4 boneMatW = getBoneMatrix(skinIndex.w);

    mat4 skinMatrix = mat4(0.0);
    skinMatrix += skinWeight.x * boneMatX;
    skinMatrix += skinWeight.y * boneMatY;
    skinMatrix += skinWeight.z * boneMatZ;
    skinMatrix += skinWeight.w * boneMatW;
    normal = vec4(skinMatrix * vec4(normal, 0.0)).xyz;

    vec4 bindPos = vec4(pos, 1.0);
    vec4 transformed = vec4(0.0);
    
    transformed += boneMatX * bindPos * skinWeight.x;
    transformed += boneMatY * bindPos * skinWeight.y;
    transformed += boneMatZ * bindPos * skinWeight.z;
    transformed += boneMatW * bindPos * skinWeight.w;

    pos = transformed.xyz;
}

void applySkin(inout vec3 pos) {
    vec3 normal = vec3(0.0, 1.0, 0.0);
    applySkin(pos, normal);
}{@}transformUV.glsl{@}vec2 translateUV(vec2 uv, vec2 translate) {
    return uv - translate;
}

vec2 rotateUV(vec2 uv, float r, vec2 origin) {
    float c = cos(r);
    float s = sin(r);
    mat2 m = mat2(c, -s,
                  s, c);
    vec2 st = uv - origin;
    st = m * st;
    return st + origin;
}

vec2 scaleUV(vec2 uv, vec2 scale, vec2 origin) {
    vec2 st = uv - origin;
    st /= scale;
    return st + origin;
}

vec2 rotateUV(vec2 uv, float r) {
    return rotateUV(uv, r, vec2(0.5));
}

vec2 scaleUV(vec2 uv, vec2 scale) {
    return scaleUV(uv, scale, vec2(0.5));
}

vec2 skewUV(vec2 st, vec2 skew) {
    return st + st.gr * skew;
}

vec2 transformUV(vec2 uv, float a[9]) {

    // Array consists of the following
    // 0 translate.x
    // 1 translate.y
    // 2 skew.x
    // 3 skew.y
    // 4 rotate
    // 5 scale.x
    // 6 scale.y
    // 7 origin.x
    // 8 origin.y

    vec2 st = uv;

    //Translate
    st -= vec2(a[0], a[1]);

    //Skew
    st = st + st.gr * vec2(a[2], a[3]);

    //Rotate
    st = rotateUV(st, a[4], vec2(a[7], a[8]));

    //Scale
    st = scaleUV(st, vec2(a[5], a[6]), vec2(a[7], a[8]));

    return st;
}{@}VRInputControllerBeam.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: VRInputControllerBeam.vs
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: VRInputControllerBeam.fs

#require(range.glsl)

void main() {
    vec4 vColor = vec4( uColor, length( vUv.y ));
    gl_FragColor = vColor;
}{@}VRInputControllerBody.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS

#!SHADER: VRInputControllerBody.vs
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: VRInputControllerBody.fs
void main() {
    gl_FragColor = vec4(1.0);
}{@}VRInputControllerPoint.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform vec3 uBorderColor;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: VRInputControllerPoint.vs
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: VRInputControllerPoint.fs

const float borderWidth = 0.08;

void main() {
    vec2 uv = vUv * (2. + borderWidth * 4.) - (1. + borderWidth * 2.); // -1.0 ... 1.0
    float r = length(uv);

    // border
    float dist = abs(r-(1. - borderWidth));
    float delta = fwidth(dist);
    float alpha = 1.0 - smoothstep(-delta, delta, dist - borderWidth);
    vec4 border = vec4(uBorderColor, alpha);

    // fill
    dist = r-(1. - borderWidth);
    delta = fwidth(dist);
    float limit = borderWidth * 0.5;
    alpha = 1.0 - smoothstep(-delta, delta, dist - limit);
    vec4 fill = vec4(uColor, alpha);

    alpha = border.a + fill.a * (1. - border.a);

    gl_FragColor = vec4((border.rgb * border.a + fill.rgb * fill.a * (1. - border.a)) / alpha, uAlpha * alpha);
}{@}UICaptionShader.glsl{@}#!ATTRIBUTES
attribute vec3 animation;
#!UNIFORMS
uniform sampler2D tMap;
uniform vec2 uRange;
uniform float uTransition;
uniform float uAlpha;
uniform float uTransparency;
uniform float uLetterCount;
uniform vec3 uColor;
#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying float vId;
#!SHADER: Vertex
void main() {

    vec3 pos = position;
    vPos = pos;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vId = animation.x;
}

#!SHADER: Fragment

#require(msdf.glsl)
#require(range.glsl)
void main() {
    float alpha = msdf(tMap, vUv);

    float transition = smoothstep(uTransition - .2, uTransition, vId/uLetterCount);

    transition *= mix(1.0, 0.5+sin(time*20.0-vPos.x*0.5)*0.5, smoothstep(0.0, 0.5, transition) * smoothstep(1.0, 0.5, transition));

    alpha *= 1. - transition;

    alpha *= uTransparency * uAlpha;
    alpha *= 1.0;// + sin(time+vPos.x*2.0) * 0.2;

    gl_FragColor = vec4(uColor, alpha);
}{@}UIHintShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    float a = texture2D(tMap, vUv).r;
    gl_FragColor = vec4(vec3(1.), a * uAlpha);
}
{@}HudGlass.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS

#!SHADER: Vertex

#require(glass.vs)

void main() {
    setupGlass(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(glass.fs)

void main() {
    gl_FragColor = getGlass(vNormal);
}{@}PodUIShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.rgb /= gl_FragColor.a;
    gl_FragColor.a *= uAlpha;
}{@}AirmanCurlParticles.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tPos;
uniform sampler2D tLife;
uniform sampler2D tMask;

uniform vec3 uColor1;
uniform vec3 uColor2;

uniform float uScale;
uniform float uAlpha;
uniform float uVRScale;
uniform float uIsVR;

#!VARYINGS
varying vec2 vUv;
varying float vDepth;
varying float vBottomFade;
varying float vLife;

#require(rgb2hsv.fs)

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    float life = texture2D(tLife, position.xy).r;
    life = crange(life, 0.0, 0.5, 0.0, 1.0) * crange(life, 0.5, 1.0, 1.0, 0.0);
    float scale = uScale * life * sin(life * 5.0);

    vec4 mvPosition = modelViewMatrix * decodedPos;
    gl_Position = projectionMatrix * mvPosition;
    gl_PointSize = 0.02 * scale * (1000.0 / length(mvPosition.xyz));

    vLife = life;

}
#!SHADER: Fragment

void main() {
    float mask = texture2D(tMask, vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y)).g;
    vec3 color = mix(uColor2, uColor1, vLife);
    gl_FragColor.rgb = color;
    gl_FragColor.a = uAlpha * vLife * mask;
}{@}AirmanHologramShader.glsl{@}#!ATTRIBUTES
attribute vec4 random;
attribute vec4 vRandom;

#!UNIFORMS
uniform samplerExternalOES tMap;
uniform sampler2D tPos;
uniform sampler2D tOrigin;
uniform sampler2D tMask;
uniform float uTransition;
uniform float uTransitionPadding;

uniform vec3 uColorHigh;
uniform vec3 uColorLow;
uniform float uBrightDepthMix;

uniform float uScale;
uniform float uVRScale;
uniform float uAlpha;

uniform vec2 uFadeRange;
uniform vec2 uDepthRange;
uniform vec2 uDepthScale;

uniform float uContrast;
uniform float uBrightness;
uniform float uVidColorMix;

#!VARYINGS
varying vec2 vUv;
varying float vDepth;
varying float vBottomFade;
varying float vAlpha;
varying vec4 vRandom2;

#require(rgb2hsv.fs)

#!SHADER: Vertex
#require(range.glsl)
#require(luma.fs)
#require(simplenoise.glsl)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec2 st = texture2D(tOrigin, position.xy).xy * vec2(1.0, 0.5);

    vec4 map = texture2D(tMap, st);
    float depth = rgb2hsv(map.rgb).x;
    float zDepth = crange(depth, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    float bottomfade = crange(st.y, uFadeRange.x, uFadeRange.y, 0.0, 1.0);

    vRandom2 = random;

    #ifdef AURA
    bottomfade = smoothstep(0.1, 0.2, 1.0 - st.y);
    #endif

    vec4 mvPosition = modelViewMatrix * decodedPos;
    gl_Position = projectionMatrix * mvPosition;

    float scale = uScale * crange(uTransition, 0.0, 1.0, 0.3, 1.0);
    scale *= crange(zDepth, uDepthScale.x, uDepthScale.y, 1.0, 0.5);
    scale *= 1.0+sin(time+vRandom2.x*20.0)*0.08;
    gl_PointSize = 0.02 * scale * (1000.0 / length(mvPosition.xyz));

    vUv = st;
    vDepth = zDepth;
    vBottomFade = bottomfade;
    vAlpha = rangeTransition(uTransition, random.w, uTransitionPadding);
}

#!SHADER: Fragment
#require(range.glsl)
#require(contrast.glsl)
#require(blendmodes.glsl)

void main() {
    float particle = texture2D(tMask, gl_PointCoord).g;

    vec2 uv = vUv;
    uv += vec2(0.0, 0.5);

    #ifdef AURA
    uv -= vec2(0.0, 1.0);
    #endif

    vec3 vidTex = texture2D(tMap, uv).rgb;

    //discard by color
    if(vidTex.r < 0.01) discard;

    // Colorize by brighness
    float brightness = (vidTex.r + vidTex.g + vidTex.b) / 3.0;
    vec3 colorBright = mix(uColorLow, uColorHigh, brightness);
    colorBright = mix(colorBright, blendScreen(colorBright, vidTex), uVidColorMix);
    // Colorize by depth
    vec3 colorDepth = mix(uColorHigh, uColorLow, vDepth);
//    colorDepth = blendOverlay(colorDepth, vidTex);
    vec3 finalColor = mix(colorBright, colorDepth, uBrightDepthMix);

    finalColor = mix(uColorLow, finalColor, pow(vUv.y / 0.5, .3));

    float scanLines = fract(uv.y*8.0+time*0.25);
    scanLines = smoothstep(0.0, 0.1, scanLines) * smoothstep(1.0, 0.1, scanLines);
    scanLines *= 0.7 + sin(time*10.0) * 0.05 + sin(time*30.0) * 0.05 + sin(time*50.0) * 0.05;
    finalColor *= 1.0 + scanLines*0.5 * smoothstep(0.0, 0.5, uv.y);

    float alpha = uAlpha;
    float flicker = 0.5 + sin(time+vRandom2.y*20.0)*0.5;
    alpha *= mix(1.0, flicker, 0.1 + smoothstep(1.0, 0.4, uAlpha)*0.9);

    gl_FragColor.rgb = finalColor;
    gl_FragColor.a = clamp(alpha * vBottomFade * vAlpha * particle, 0.0, 1.0);
}{@}AirmanPlanesShader.glsl{@}#!ATTRIBUTES
#!UNIFORMS
uniform samplerExternalOES tMap;
uniform sampler2D tPos;
uniform float uAlpha;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform float uColorMix;
uniform vec2 uFadeRange;
uniform float uDepth;

uniform vec3 uNoiseScale;
uniform float uNoiseSpeed;
uniform float uNoiseStrength;
uniform vec2 uNoiseRange;
uniform float uNoiseOffset;

#!VARYINGS
varying vec2 vUv;
varying float vDepth;
varying float vAlpha;
varying vec3 vMap;
varying float vLuma;

#require(rgb2hsv.fs)

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;
    vec2 st = uv * vec2(1.0, 0.5);

    vec4 map = texture2D(tMap, vec2(st.x, st.y));
    float depth = rgb2hsv(map.rgb).x;
    depth += crange(depth, 0.01, 0.1, 1.0, 0.0);

    vec4 decodedPos = vec4(pos + vec3(0.0, 0.0, -depth * uDepth), 1.0);

    vec4 mvPosition = modelViewMatrix * decodedPos;
    gl_Position = projectionMatrix * mvPosition;
    gl_PointSize = 0.02 * (1000.0 / length(mvPosition.xyz)) * 0.5;

    vDepth = depth;
    vUv = uv;
}
#!SHADER: Fragment
#require(range.glsl)
#require(luma.fs)

void main() {
    if (vDepth < 0.01) discard;
    vec2 uv = vUv;

    vec4 map = texture2D(tMap, uv * vec2(1.0, 0.5) + vec2(0.0, 0.5));
    // float d = rgb2hsv(map.rgb).x;

    gl_FragColor.rgb = vec3(map.r);
    gl_FragColor.a = uAlpha * (1.0 - vDepth) * crange(vUv.y, uFadeRange.x, uFadeRange.y, 0.0, 1.0);
}{@}LandingLogo.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;
uniform float uTransition;
uniform float uOutline;
uniform float uFlipClamp;
uniform float uInvertAnim;
uniform vec2 uClamp;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

void main() {
    vUv = uv;
    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)
#require(mousefluid.fs)

float random (in float x) {
    return fract(sin(x)*1e4);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float pattern(vec2 st, vec2 v, float t) {
    vec2 p = floor(st+v);
    return step(t, random(100.+p*.000001)+random(p.x)*0.5 );
}

void main() {
    float mixFluid = 0.0;

    #test Tests.renderMouseFluid()
    vec2 fluidUV = gl_FragCoord.xy / resolution;

    float fluidMask = smoothstep(0.0, 0.1, texture2D(tFluidMask, fluidUV).r);
    float fluidOutline = smoothstep(0.0, 0.2, fluidMask) * smoothstep(1.0, 0.2, fluidMask);
    vec2 fluid = texture2D(tFluid, vUv).xy * fluidMask;

    mixFluid = smoothstep(0.0, 0.0005, fluid.x*fluid.y);//+smoothstep(0.0, 0.002, fluid.y);
    mixFluid = mix(mixFluid, 0.0, 0.3);
    fluidMask = mix(fluidMask, 1.0, smoothstep(0.5, 0.0, uTransition));
    mixFluid = max(fluidMask, mixFluid);
    #endtest

    vec2 uv = vUv;
    float noise = cnoise(vUv*3.0-time*0.15);

    vec3 color = vec3(1.0);
    vec4 tex = texture2D(tMap, uv);

    float outline = tex.r; // resolution
    //outline *= 0.7 + sin(time*3.0) * 0.1 + sin(time*5.0) * 0.1 + sin(time*7.0) * 0.1;

    outline = mix(outline*mixFluid, outline, uOutline);

    float fill = tex.b;

    vec2 st = vUv;
    vec2 grid = mix(vec2(140.0,200.0), vec2(250.0,3000.0), uInvertAnim);
    st *= grid;
    vec2 ipos = floor(st);  // integer
    vec2 fpos = fract(st);  // fraction
    vec2 vel = vec2(((time*mix(0.1, 0.07, uInvertAnim))/2.*max(grid.x,grid.y))); // time

    vec2 horizontal = vec2(-1.,0.0) * random(1.0+ipos.y);
    vec2 vertical = vec2(0.,-1.0) * random(1.0+ipos.x);
    vel *= mix(horizontal, vertical, uInvertAnim); // direction

    vec2 offset = mix(vec2(0.1,-0.5), vec2(-0.5, 0.1), uInvertAnim);
    float c = clamp(pattern(st+offset,vel,0.7), 0., 1.);
    float a = step(.6,mix(fpos.y, fpos.x, uInvertAnim));
    outline += c * a * fill * (1.0-uOutline);
    fill = mix(fill, outline, mixFluid);

    float alpha = mix(fill, outline, uOutline);

    //float mid = 0.5;
    //alpha = smoothstep(mid-0.001, mid+0.001, alpha);

    float transition = 1.0-uTransition;
    float fade = smoothstep(transition-0.5, transition, 1.0-vUv.y) * smoothstep(0.0, 0.2, uTransition);

    //fade *= mix(1.0, getNoise(vUv, time), smoothstep(0.0, 0.5, fade) * smoothstep(1.0, 0.7, fade));
    alpha *= fade;
    alpha *= 0.85 + noise * 0.2;


    float clampAlpha = smoothstep(uClamp.x-0.001, uClamp.x+0.001, 1.0-vUv.y) * smoothstep(uClamp.y+0.001, uClamp.y-0.001, 1.0-vUv.y);
    alpha *= mix(clampAlpha, 1.0-clampAlpha, uFlipClamp);
    alpha = mix(alpha, outline*alpha, smoothstep(0.8, 0.0, alpha));

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha;

    gl_FragColor = mix(gl_FragColor, vec4(1.0), (1.0-c)*a*fill*mixFluid*uTransition);
}{@}HexTunnel.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform vec3 uColor;
uniform float uNoiseScale;
uniform float uNoiseTime;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

void main() {
    vUv = uv;
    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
#require(range.glsl)
    #require(simplenoise.glsl)
void main() {
    vec3 color = uColor;

    float alpha = uAlpha;

    float noise1 = cnoise(vPos*uNoiseScale+time*uNoiseTime-uAlpha);
    float noise2 = cnoise(vec2(vPos.y*1.5)*uNoiseScale+time*uNoiseTime-uAlpha);
    noise1 = mix(noise1, noise2, 0.6);
    alpha *= 0.5 + noise1 * 0.5;
    alpha *= smoothstep(-0.5, 0.8, vPos.y);

    gl_FragColor.rgb = color;
    gl_FragColor.a = alpha;
}{@}PodShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tLightmap;
uniform sampler2D tBaseMatcap;
uniform sampler2D tRamp;
uniform vec3 uTintColor;
uniform float uNoiseMin;
uniform float uScreenAlpha;
uniform float uAlpha;

#!VARYINGS
varying vec2 mUV;
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

#require(matcap.vs)

void main() {
    vUv = uv;
    mUV = reflectMatcap(position, viewMatrix, normal);
    vPos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)

void main() {
    vec3 color;
    float alpha = uAlpha;

    if (vUv.x > 0.7 && vUv.y < 0.25) {
        color = texture2D(tBaseMatcap, mUV).rgb * uTintColor;
    } else if (vUv.x < 0.05) {
        color = texture2D(tRamp, vec2(0.0, vUv.y)).rgb;
        color *= crange(getNoise(vUv, time), 0.0, 1.0, uNoiseMin, 1.0);
        alpha *= mix(1.0, uScreenAlpha, sineOut(crange(vUv.y, 0.0, 0.5, 0.0, 1.0)));
    } else {
        color = texture2D(tLightmap, vUv).rgb;
    }

    alpha *= crange(vPos.y, 0.1, 0.5, 1.0, 0.0);

    gl_FragColor = vec4(color, alpha);
}
{@}ConeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uTimeOffset;
uniform float uAlpha;
uniform vec3 uColor1;
uniform vec3 uColor2;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vNormal = normal;
    vUv = uv;
    vPos = position;
}

#!SHADER: Fragment

#require(range.glsl)

void main() {
    vec2 st = vUv;

    float t = time + uTimeOffset;
    float dist = 1.0 - distance(vUv, vec2(0.5));
    dist = crange(dist, 0.5, 1.0, 0.0, 1.0);
    vec4 sunbeamTexture = texture2D(tMap, st * vec2(2.0, 0.05) + vec2(t * -0.22, 0.15));
    vec4 sunbeamTexture2 = texture2D(tMap, st * vec2(1.0, 0.3) + vec2(t * 0.14, 0.25));
    sunbeamTexture *= sunbeamTexture2.r;
    sunbeamTexture *= dist;
    sunbeamTexture.r = crange(sunbeamTexture.r, 0.0, 0.7, 0.0, 1.0);
    sunbeamTexture.rgb = uColor2 * sunbeamTexture.r;

    gl_FragColor.rgb = sunbeamTexture.rgb;
    gl_FragColor.a = 1.0 * uAlpha;
}{@}SplineSurfaceShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uSpeed;
uniform float uThreshold;
uniform float uFreq;
uniform float uMaskStep;
uniform float uAlpha;
uniform float uTransition;
uniform float uTransitionPadding;
uniform vec3 uColor;
uniform float uColorNScale;
uniform float uScale;
uniform vec3 uHSL;
uniform vec4 uDamage;
uniform vec3 uDamageColor;
uniform vec2 uFog;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vWorldPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position * uScale;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
    vWorldPos = vec3(modelMatrix * vec4(pos, 1.0));
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)
#require(rgb2hsv.fs)

void main() {
    vec4 tex = texture2D(tMap, vUv);
    float mask = step(uMaskStep, tex.g);
    if (mask < uThreshold) discard;

    float curveu = tex.r;
    float animatedline = sin(curveu * uFreq + time * uSpeed);
    float transition = rangeTransition(uTransition, tex.r, uTransitionPadding);

    vec3 color = rgb2hsv(uColor);
    float n = cnoise(vPos * uColorNScale);
    color += n * uHSL * 0.1;
    color = hsv2rgb(color);

    gl_FragColor.rgb = color;
    gl_FragColor.a = animatedline * 0.8 * transition * uAlpha;

    float damage = crange(length(uDamage.xyz - vWorldPos), 0.0, uDamage.w, 1.0, 0.0);
    gl_FragColor.rgb *= mix(vec3(1.0), uDamageColor, damage);
    gl_FragColor.a *= sineOut(crange(length(cameraPosition - vWorldPos), uFog.x, uFog.x + uFog.y, 1.0, 0.0));
}{@}StyleTestLines.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;

#!VARYINGS

#!SHADER: Vertex
void main() {

}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(vec3(1.0), alpha * uAlpha);
}
{@}StyleTestParticles.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tPos;
uniform sampler2D tNormal;
uniform float uAlpha;
uniform float uLightMin;

#!VARYINGS
varying float vVolume;

#!SHADER: Vertex

#require(lights.vs)
#require(range.glsl)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;

    vec3 n = normalMatrix * texture2D(tNormal, position.xy).rgb;
    vec3 light = worldLight(vec3(0.0));
    vVolume = crange(dot(n, light), 0.0, 1.0, uLightMin, 1.0);

    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    gl_PointSize = 0.02 * (1000.0 / length(mvPosition.xyz));
    gl_Position = projectionMatrix * mvPosition;
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(vec3(1.0), vVolume * uAlpha);
}
{@}VideoTestShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform samplerExternalOES tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    vec2 uv = vUv;

    #ifdef AURA
    uv.y = 1.0 - uv.y;
    #endif

    gl_FragColor = texture2D(tMap, uv);
}{@}WireframeGroundShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uScale;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = texture2D(tMap, vUv * uScale);
}{@}WireframeTeleportCylinder.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(eases.glsl)

void main() {
    gl_FragColor = vec4(uColor, sineIn(1.0 - vUv.y));
}{@}WireframeTruckShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform float uFresnelPow;
uniform float uFresnelMin;

#!VARYINGS
varying vec3 vViewDir;
varying vec3 vNormal;

#!SHADER: Vertex
void main() {
    vNormal = normalMatrix * normal;
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(fresnel.glsl)

void main() {
    gl_FragColor = vec4(1.0);
    gl_FragColor.a *= uAlpha;
    gl_FragColor.a *= range(getFresnel(vNormal, vViewDir, uFresnelPow), 0.0, 1.0, uFresnelMin, 1.0);
}{@}WireframeWall.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(uColor, uAlpha);
}{@}AntimatterSpawn.fs{@}uniform float uMaxCount;
uniform float uSetup;
uniform float decay;
uniform vec2 decayRandom;
uniform sampler2D tLife;
uniform sampler2D tAttribs;
uniform float HZ;

#require(range.glsl)

void main() {
    vec2 uv = vUv;
    #test !window.Metal
    uv = gl_FragCoord.xy / fSize;
    #endtest

    vec4 data = texture2D(tInput, uv);

    if (vUv.x + vUv.y * fSize > uMaxCount) {
        gl_FragColor = vec4(9999.0);
        return;
    }

    vec4 life = texture2D(tLife, uv);
    vec4 random = texture2D(tAttribs, uv);
    if (life.x > 0.5) {
        data.xyz = life.yzw;
        data.x -= 999.0;
    } else {
        if (data.x < -500.0) {
            data.x = 1.0;
        } else {
            data.x -= 0.005 * decay * crange(random.w, 0.0, 1.0, decayRandom.x, decayRandom.y) * HZ;
        }
    }

    if (uSetup > 0.5) {
        data = vec4(0.0);
    }

    gl_FragColor = data;
}{@}CloudFogShader.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec4 orientation;
attribute vec4 random;

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uScale;
uniform float uAlpha;
uniform float uCullDistance;
uniform float uSpeed;
uniform float uNoiseScale;
uniform float uNoiseStrength;
uniform float uNoiseTime;
uniform float uBillboard;
uniform vec2 uFadeDist;

#!VARYINGS
varying vec2 vUv;
varying float vAlpha;
varying vec3 vPos;


#!SHADER: Vertex

#require(instance.vs)
#require(range.glsl)
#require(rotation.glsl)

void main() {
    vUv = uv;
    vAlpha = uAlpha * crange(random.y, 0.0, 1.0, 0.5, 1.0) * 0.1;

    vec3 inPos = position;
    float rotation = radians((360.0 * random.z) + time*crange(random.w, 0.0, 1.0, -1.0, 1.0)*10.0*uSpeed);
    inPos = vec3(rotationMatrix(vec3(0.0, 0.0, 1.0), rotation) * vec4(inPos, 1.0));

    float scale = uScale * crange(random.x, 0.0, 1.0, 0.5, 1.5);
    vec4 quat;
    // This used to pass `uBillboard > 0.5 ? cameraQuaternion : orientation`
    // directly to transformPosition() but that causes this error on iOS:
    //   Internal error compiling shader with Metal backend.
    //   Please submit this shader, or website as a bug to https://bugs.webkit.org
    // So does using the ?: to initialize `quat`. The if-else works.
    if (uBillboard > 0.5) {
        quat = cameraQuaternion;
    } else {
        quat = orientation;
    }
    vec3 pos = transformPosition(inPos, offset, scale, quat);
    float mDist = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));

    vAlpha *= crange(mDist, uCullDistance*0.8, uCullDistance, 1.0, 0.0);
    vPos = pos;
    vAlpha *= crange(mDist, uFadeDist.x, uFadeDist.x + uFadeDist.y, 0.0, 1.0);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(transformUV.glsl)
#require(simplenoise.glsl)

vec2 getUV() {
    float noise = cnoise((vPos * uNoiseScale) + time*uNoiseTime);
    float scale = 1.0 + (noise * uNoiseStrength * 0.1);

    return scaleUV(vUv, vec2(scale));
}

void main() {
    if (vAlpha < 0.01) {
        discard;
        return;
    }
    vec2 uv = uNoiseStrength > 0.0 ? getUV() : vUv;
    float mask = texture2D(tMap, uv).r;
    float padding = 0.3;
    mask *= crange(vUv.x, 0.0, padding, 0.0, 1.0) * crange(vUv.x, 1.0 - padding, 1.0, 1.0, 0.0);
    mask *= crange(vUv.y, 0.0, padding, 0.0, 1.0) * crange(vUv.y, 1.0 - padding, 1.0, 1.0, 0.0);

    gl_FragColor = vec4(uColor, mask * vAlpha);
}
{@}curve3d.vs{@}uniform sampler2D tCurve;
uniform float uCurveSize;

vec2 getCurveUVFromIndex(float index) {
    float size = uCurveSize;
    vec2 ruv = vec2(0.0);
    float p0 = index / size;
    float y = floor(p0);
    float x = p0 - y;
    ruv.x = x;
    ruv.y = y / size;
    return ruv;
}

vec3 transformAlongCurve(vec3 pos, float idx) {
    vec3 offset = texture2D(tCurve, getCurveUVFromIndex(idx * (uCurveSize * uCurveSize))).xyz;
    vec3 p = pos;
    p.xz += offset.xz;
    return p;
}
{@}DesktopStreamShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = texture2D(tMap, vUv);
}{@}fbr.fs{@}uniform sampler2D tMRO;
uniform sampler2D tMatcap;
uniform sampler2D tNormal;
uniform vec4 uLight;
uniform vec3 uColor;
uniform float uNormalStrength;

varying vec3 vNormal;
varying vec3 vPos;
varying vec3 vEyePos;
varying vec2 vUv;
varying vec3 vMPos;

const float PI = 3.14159265359;
const float PI2 = 6.28318530718;
const float RECIPROCAL_PI = 0.31830988618;
const float RECIPROCAL_PI2 = 0.15915494;
const float LOG2 = 1.442695;
const float EPSILON = 1e-6;
const float LN2 = 0.6931472;

vec2 reflectMatcapFBR(vec3 position, mat4 modelViewMatrix, vec3 normal) {
    vec4 p = vec4(position, 1.0);

    vec3 e = normalize(vec3(modelViewMatrix * p));
    vec3 n = normalize(normal);
    vec3 r = reflect(e, n);
    float m = 2.0 * sqrt(
    pow(r.x, 2.0) +
    pow(r.y, 2.0) +
    pow(r.z + 1.0, 2.0)
    );

    vec2 uv = r.xy / m + .5;

    return uv;
}

float prange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    float oldRange = oldMax - oldMin;
    float newRange = newMax - newMin;
    return (((oldValue - oldMin) * newRange) / oldRange) + newMin;
}

float pcrange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    return clamp(prange(oldValue, oldMin, oldMax, newMin, newMax), min(newMax, newMin), max(newMin, newMax));
}

vec3 unpackNormalFBR( vec3 eye_pos, vec3 surf_norm, sampler2D normal_map, float intensity, float scale, vec2 uv ) {
    surf_norm = normalize(surf_norm);

    vec3 q0 = dFdx( eye_pos.xyz );
    vec3 q1 = dFdy( eye_pos.xyz );
    vec2 st0 = dFdx( uv.st );
    vec2 st1 = dFdy( uv.st );

    vec3 S = normalize( q0 * st1.t - q1 * st0.t );
    vec3 T = normalize( -q0 * st1.s + q1 * st0.s );
    vec3 N = normalize( surf_norm );

    vec3 mapN = texture2D( normal_map, uv * scale ).xyz * 2.0 - 1.0;
    mapN.xy *= intensity;
    mat3 tsn = mat3( S, T, N );
    return normalize( tsn * mapN );
}

float geometricOcclusion(float NdL, float NdV, float roughness) {
    float r = roughness;
    float attenuationL = 2.0 * NdL / (NdL + sqrt(r * r + (1.0 - r * r) * (NdL * NdL)));
    float attenuationV = 2.0 * NdV / (NdV + sqrt(r * r + (1.0 - r * r) * (NdV * NdV)));
    return attenuationL * attenuationV;
}

float microfacetDistribution(float roughness, float NdH) {
    float roughnessSq = roughness * roughness;
    float f = (NdH * roughnessSq - NdH) * NdH + 1.0;
    return roughnessSq / (PI * f * f);
}

vec3 getFBR(vec3 baseColor, vec2 uv, vec2 normalUV) {
    vec3 mro = texture2D(tMRO, uv).rgb;
    float roughness = mro.g;

    vec3 normal = unpackNormalFBR(vEyePos, vNormal, tNormal, uNormalStrength, 1.0, normalUV);
    vec2 aUV = reflectMatcapFBR(vPos, projectionMatrix, normal);
    vec2 bUV = reflectMatcapFBR(vPos, modelMatrix, normal);
    vec2 mUV = mix(aUV, bUV, roughness);

    vec3 V = normalize(cameraPosition - vMPos);
    vec3 L = normalize(uLight.xyz);
    vec3 H = normalize(L + V);
    vec3 reflection = -normalize(reflect(V, normal));

    float NdL = pcrange(clamp(dot(normal, L), 0.001, 1.0), 0.0, 1.0, 0.4, 1.0);
    float NdV = pcrange(clamp(abs(dot(normal, V)), 0.001, 1.0), 0.0, 1.0, 0.4, 1.0);
    float NdH = clamp(dot(normal, H), 0.0, 1.0);
    float VdH = clamp(dot(V, H), 0.0, 1.0);

    float G = geometricOcclusion(NdL, NdV, roughness);
    float D = microfacetDistribution(roughness, NdH);

    vec3 specContrib = G * D / (4.0 * NdL * NdV) * uColor;
    vec3 color = NdL * specContrib * uLight.w;

    return ((baseColor * texture2D(tMatcap, mUV).rgb) + color) * mro.b;
}

vec3 getFBR(vec3 baseColor, vec2 uv) {
    return getFBR(baseColor, uv, uv);
}

vec3 getFBR(vec3 baseColor) {
    return getFBR(baseColor, vUv, vUv);
}

vec3 getFBR() {
    float roughness = texture2D(tMRO, vUv).g;

    vec3 normal = unpackNormalFBR(vEyePos, vNormal, tNormal, 1.0, 1.0, vUv);
    vec2 aUV = reflectMatcapFBR(vPos, projectionMatrix, normal);
    vec2 bUV = reflectMatcapFBR(vPos, modelMatrix, normal);
    vec2 mUV = mix(aUV, bUV, roughness);

    return texture2D(tMatcap, mUV).rgb;
}

vec3 getFBRSimplified() {
    vec2 mUV = reflectMatcapFBR(vPos, modelViewMatrix, vNormal);
    return texture2D(tMatcap, mUV).rgb;
}
{@}fbr.vs{@}varying vec3 vNormal;
varying vec3 vPos;
varying vec3 vEyePos;
varying vec2 vUv;
varying vec3 vMPos;

void setupFBR(vec3 p0) { //inlinemain
    vNormal = normalMatrix * normal;
    vUv = uv;
    vPos = p0;
    vec4 mPos = modelMatrix * vec4(p0, 1.0);
    vMPos = mPos.xyz / mPos.w;
    vEyePos = vec3(modelViewMatrix * vec4(p0, 1.0));
}{@}advectionManualFilteringShader.fs{@}varying vec2 vUv;
uniform sampler2D uVelocity;
uniform sampler2D uSource;
uniform vec2 texelSize;
uniform vec2 dyeTexelSize;
uniform float dt;
uniform float dissipation;
vec4 bilerp (sampler2D sam, vec2 uv, vec2 tsize) {
    vec2 st = uv / tsize - 0.5;
    vec2 iuv = floor(st);
    vec2 fuv = fract(st);
    vec4 a = texture2D(sam, (iuv + vec2(0.5, 0.5)) * tsize);
    vec4 b = texture2D(sam, (iuv + vec2(1.5, 0.5)) * tsize);
    vec4 c = texture2D(sam, (iuv + vec2(0.5, 1.5)) * tsize);
    vec4 d = texture2D(sam, (iuv + vec2(1.5, 1.5)) * tsize);
    return mix(mix(a, b, fuv.x), mix(c, d, fuv.x), fuv.y);
}
void main () {
    vec2 coord = vUv - dt * bilerp(uVelocity, vUv, texelSize).xy * texelSize;
    gl_FragColor = dissipation * bilerp(uSource, coord, dyeTexelSize);
    gl_FragColor.a = 1.0;
}{@}advectionShader.fs{@}varying vec2 vUv;
uniform sampler2D uVelocity;
uniform sampler2D uSource;
uniform vec2 texelSize;
uniform float dt;
uniform float dissipation;
void main () {
    vec2 coord = vUv - dt * texture2D(uVelocity, vUv).xy * texelSize;
    gl_FragColor = dissipation * texture2D(uSource, coord);
    gl_FragColor.a = 1.0;
}{@}backgroundShader.fs{@}varying vec2 vUv;
uniform sampler2D uTexture;
uniform float aspectRatio;
#define SCALE 25.0
void main () {
    vec2 uv = floor(vUv * SCALE * vec2(aspectRatio, 1.0));
    float v = mod(uv.x + uv.y, 2.0);
    v = v * 0.1 + 0.8;
    gl_FragColor = vec4(vec3(v), 1.0);
}{@}clearShader.fs{@}varying vec2 vUv;
uniform sampler2D uTexture;
uniform float value;
void main () {
    gl_FragColor = value * texture2D(uTexture, vUv);
}{@}colorShader.fs{@}uniform vec4 color;
void main () {
    gl_FragColor = color;
}{@}curlShader.fs{@}varying highp vec2 vUv;
varying highp vec2 vL;
varying highp vec2 vR;
varying highp vec2 vT;
varying highp vec2 vB;
uniform sampler2D uVelocity;
void main () {
    float L = texture2D(uVelocity, vL).y;
    float R = texture2D(uVelocity, vR).y;
    float T = texture2D(uVelocity, vT).x;
    float B = texture2D(uVelocity, vB).x;
    float vorticity = R - L - T + B;
    gl_FragColor = vec4(0.5 * vorticity, 0.0, 0.0, 1.0);
}{@}displayShader.fs{@}varying vec2 vUv;
uniform sampler2D uTexture;
void main () {
    vec3 C = texture2D(uTexture, vUv).rgb;
    float a = max(C.r, max(C.g, C.b));
    gl_FragColor = vec4(C, a);
}{@}divergenceShader.fs{@}varying highp vec2 vUv;
varying highp vec2 vL;
varying highp vec2 vR;
varying highp vec2 vT;
varying highp vec2 vB;
uniform sampler2D uVelocity;
void main () {
    float L = texture2D(uVelocity, vL).x;
    float R = texture2D(uVelocity, vR).x;
    float T = texture2D(uVelocity, vT).y;
    float B = texture2D(uVelocity, vB).y;
    vec2 C = texture2D(uVelocity, vUv).xy;
//    if (vL.x < 0.0) { L = -C.x; }
//    if (vR.x > 1.0) { R = -C.x; }
//    if (vT.y > 1.0) { T = -C.y; }
//    if (vB.y < 0.0) { B = -C.y; }
    float div = 0.5 * (R - L + T - B);
    gl_FragColor = vec4(div, 0.0, 0.0, 1.0);
}{@}fluidBase.vs{@}varying vec2 vUv;
varying vec2 vL;
varying vec2 vR;
varying vec2 vT;
varying vec2 vB;
uniform vec2 texelSize;

void main () {
    vUv = uv;
    vL = vUv - vec2(texelSize.x, 0.0);
    vR = vUv + vec2(texelSize.x, 0.0);
    vT = vUv + vec2(0.0, texelSize.y);
    vB = vUv - vec2(0.0, texelSize.y);
    gl_Position = vec4(position, 1.0);
}{@}gradientSubtractShader.fs{@}varying highp vec2 vUv;
varying highp vec2 vL;
varying highp vec2 vR;
varying highp vec2 vT;
varying highp vec2 vB;
uniform sampler2D uPressure;
uniform sampler2D uVelocity;
vec2 boundary (vec2 uv) {
    return uv;
    // uv = min(max(uv, 0.0), 1.0);
    // return uv;
}
void main () {
    float L = texture2D(uPressure, boundary(vL)).x;
    float R = texture2D(uPressure, boundary(vR)).x;
    float T = texture2D(uPressure, boundary(vT)).x;
    float B = texture2D(uPressure, boundary(vB)).x;
    vec2 velocity = texture2D(uVelocity, vUv).xy;
    velocity.xy -= vec2(R - L, T - B);
    gl_FragColor = vec4(velocity, 0.0, 1.0);
}{@}pressureShader.fs{@}varying highp vec2 vUv;
varying highp vec2 vL;
varying highp vec2 vR;
varying highp vec2 vT;
varying highp vec2 vB;
uniform sampler2D uPressure;
uniform sampler2D uDivergence;
vec2 boundary (vec2 uv) {
    return uv;
    // uncomment if you use wrap or repeat texture mode
    // uv = min(max(uv, 0.0), 1.0);
    // return uv;
}
void main () {
    float L = texture2D(uPressure, boundary(vL)).x;
    float R = texture2D(uPressure, boundary(vR)).x;
    float T = texture2D(uPressure, boundary(vT)).x;
    float B = texture2D(uPressure, boundary(vB)).x;
    float C = texture2D(uPressure, vUv).x;
    float divergence = texture2D(uDivergence, vUv).x;
    float pressure = (L + R + B + T - divergence) * 0.25;
    gl_FragColor = vec4(pressure, 0.0, 0.0, 1.0);
}{@}splatShader.fs{@}varying vec2 vUv;
uniform sampler2D uTarget;
uniform float aspectRatio;
uniform vec3 color;
uniform vec3 bgColor;
uniform vec2 point;
uniform vec2 prevPoint;
uniform float radius;
uniform float canRender;
uniform float uAdd;

float blendScreen(float base, float blend) {
    return 1.0-((1.0-base)*(1.0-blend));
}

vec3 blendScreen(vec3 base, vec3 blend) {
    return vec3(blendScreen(base.r, blend.r), blendScreen(base.g, blend.g), blendScreen(base.b, blend.b));
}

float l(vec2 uv, vec2 point1, vec2 point2) {
    vec2 pa = uv - point1, ba = point2 - point1;
    pa.x *= aspectRatio;
    ba.x *= aspectRatio;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float cubicOut(float t) {
    float f = t - 1.0;
    return f * f * f + 1.0;
}

void main () {
    vec3 splat = (1.0 - cubicOut(clamp(l(vUv, prevPoint.xy, point.xy) / radius, 0.0, 1.0))) * color;
    vec3 base = texture2D(uTarget, vUv).xyz;
    base *= canRender;

    vec3 outColor = mix(blendScreen(base, splat), base + splat, uAdd);
    gl_FragColor = vec4(outColor, 1.0);
}{@}vorticityShader.fs{@}varying vec2 vUv;
varying vec2 vL;
varying vec2 vR;
varying vec2 vT;
varying vec2 vB;
uniform sampler2D uVelocity;
uniform sampler2D uCurl;
uniform float curl;
uniform float dt;
void main () {
    float L = texture2D(uCurl, vL).x;
    float R = texture2D(uCurl, vR).x;
    float T = texture2D(uCurl, vT).x;
    float B = texture2D(uCurl, vB).x;
    float C = texture2D(uCurl, vUv).x;
    vec2 force = 0.5 * vec2(abs(T) - abs(B), abs(R) - abs(L));
    force /= length(force) + 0.0001;
    force *= curl * C;
    force.y *= -1.0;
//    force.y += 400.3;
    vec2 vel = texture2D(uVelocity, vUv).xy;
    gl_FragColor = vec4(vel + force * dt, 0.0, 1.0);
}{@}GlassShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tInside;
uniform float uTransparent;
uniform float uDistortStrength;

#!VARYINGS

#!SHADER: Vertex

#require(glass.vs)

void main() {
    setupGlass(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(glass.fs)

void main() {
    vec3 normal = normalMatrix * (gl_FrontFacing == false ? -vNormal : vNormal);

    gl_FragColor = getGlass(normal);

    if (uTransparent < 0.5) {
        vec2 uv = gl_FragCoord.xy / resolution;
        uv += 0.1 * vNormal.xy * gFresnel * uDistortStrength;
        vec3 color = texture2D(tInside, uv).rgb;
        gl_FragColor.rgb = mix(gl_FragColor.rgb, color, 1.0 - gl_FragColor.a);
    }
}{@}glass.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tEnv;
uniform float uRefractionRatio;
uniform float uReflectScale;
uniform float uRatio;
uniform float uAttenuation;
uniform float uAlpha;
uniform float uShininess;
uniform float uFresnelPow;
uniform float uFresnelAlpha;
uniform float uEnvBlend;
uniform vec2 uSpecAdd;
uniform vec3 uPhongColor;
uniform vec3 uFresnelColor;
uniform vec3 uLightDir;

#!VARYINGS
varying vec3 vReflect;
varying vec3 vRefract;
varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec3 vLightDir;

#!SHADER: Vertex

#require(refl.vs)
#require(lights.vs)

void setupGlass(vec3 pos) {
    vec4 worldPos = modelMatrix * vec4(pos * uReflectScale, 1.0);
    vWorldPos = worldPos.xyz;
    vNormal = normal;
    vViewDir = -vec3(modelViewMatrix * vec4(pos, 1.0));
    vReflect = reflection(worldPos);
    vRefract = refraction(worldPos, uRefractionRatio);
    vLightDir = normalize(worldLight(uLightDir));
}

#!SHADER: Fragment

#require(refl.fs)
#require(range.glsl)
#require(phong.fs)
#require(fresnel.glsl)

float gFresnel;

vec4 getGlass(vec3 normal) {
    vec3 specLight = phong(1.0, vec3(1.0), uPhongColor, uShininess, uAttenuation, normal, vLightDir, vViewDir);
    gFresnel = getFresnel(normal, vViewDir, uFresnelPow);

    vec3 reflected = envColorEqui(tEnv, vReflect).rgb;
    vec3 refracted = envColorEqui(tEnv, vRefract).rgb;
    vec4 color = vec4(mix(reflected, refracted, uRatio) * uEnvBlend, uAlpha);
    color.rgb += specLight * uSpecAdd.x;
    color.rgb *= mix(vec3(1.0), uFresnelColor, gFresnel);
    color.a += specLight.r * uSpecAdd.y;
    color.a += uFresnelAlpha * gFresnel;

    return color;
}{@}AreaLights.glsl{@}mat3 transposeMat3(  mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}

// Real-Time Polygonal-Light Shading with Linearly Transformed Cosines
// by Eric Heitz, Jonathan Dupuy, Stephen Hill and David Neubelt
// code: https://github.com/selfshadow/ltc_code/
vec2 LTC_Uv(  vec3 N,  vec3 V,  float roughness ) {
	float LUT_SIZE  = 64.0;
	float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	float LUT_BIAS  = 0.5 / LUT_SIZE;
	float dotNV = clamp( dot( N, V ), 0.0, 1.0 );
	// texture parameterized by sqrt( GGX alpha ) and sqrt( 1 - cos( theta ) )
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}

float LTC_ClippedSphereFormFactor(  vec3 f ) {
	// Real-Time Area Lighting: a Journey from Research to Production (p.102)
	// An approximation of the form factor of a horizon-clipped rectangle.
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}

vec3 LTC_EdgeVectorFormFactor(  vec3 v1,  vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	// rational polynomial approximation to theta / sin( theta ) / 2PI
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}

vec3 LTC_Evaluate(  vec3 N,  vec3 V,  vec3 P,  mat3 mInv,  vec3 rectCoords[ 4 ] ) {
	// bail if point is on back side of plane of light
	// assumes ccw winding order of light vertices
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	// construct orthonormal basis around N
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 ); // negated from paper; possibly due to a different handedness of world coordinate system
	// compute transform
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	// transform rect
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	// project rect onto sphere
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	// calculate vector form factor
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	// adjust for horizon clipping
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );

	return vec3( result );
}{@}Lighting.glsl{@}#!ATTRIBUTES

#!UNIFORMS
struct LightConfig {
    vec3 normal;
    bool phong;
    bool areaToPoint;
    float phongAttenuation;
    float phongShininess;
    vec3 phongColor;
    vec3 lightColor;
    bool overrideColor;
};

uniform sampler2D tLTC1;
uniform sampler2D tLTC2;

#!VARYINGS
varying vec3 vPos;
varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec3 vViewDir;

#!SHADER: lighting.vs

void setupLight(vec3 p0, vec3 p1) { //inlinemain
    vPos = p0;
    vNormal = normalize(normalMatrix * p1);
    vWorldPos = vec3(modelMatrix * vec4(p0, 1.0));
    vViewDir = -vec3(modelViewMatrix * vec4(p0, 1.0));
}

#test !window.Metal
void setupLight(vec3 p0) {
    setupLight(p0, normal);
}
#endtest

#!SHADER: lighting.fs

#require(LightingCommon.glsl)

void setupLight() {

}
vec3 getCombinedColor(LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix, sampler2D tLTC1, sampler2D tLTC2) {
    vec3 color = vec3(0.0);

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        if (lProps.w < 1.0) continue;

        if (lProps.w < 1.1) {
            color += lightDirectional(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        } else if (lProps.w < 2.1) {
            color += lightPoint(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        } else if (lProps.w < 3.1) {
            color += lightCone(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        } else if (lProps.w < 4.1) {
            color += lightArea(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
        }
    }

    return lclamp(color);
}

vec3 getCombinedColor(LightConfig config) {
    #test !window.Metal
    return getCombinedColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
    #endtest
    return vec3(0.0);
}

vec3 getCombinedColor() {
    LightConfig config;
    config.normal = vNormal;
    return getCombinedColor(config);
}

vec3 getCombinedColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getCombinedColor(config);
}

vec3 getCombinedColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix, sampler2D tLTC1, sampler2D tLTC2) {
    LightConfig config;
    config.normal = normal;
    return getCombinedColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
}

vec3 getPointLightColor(LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec3 color = vec3(0.0);

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        if (lProps.w > 1.9 && lProps.w < 2.1) {
            color += lightPoint(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        }
    }

    return lclamp(color);
}

vec3 getPointLightColor(LightConfig config) {
    #test !window.Metal
    return getPointLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
    #endtest
    return vec3(0.0);
}

vec3 getPointLightColor() {
    LightConfig config;
    config.normal = vNormal;
    return getPointLightColor(config);
}

vec3 getPointLightColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getPointLightColor(config);
}

vec3 getPointLightColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    LightConfig config;
    config.normal = normal;
    return getPointLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
}

vec3 getAreaLightColor(float roughness, LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix, sampler2D tLTC1, sampler2D tLTC2) {
    vec3 color = vec3(0.0);

    #test Lighting.fallbackAreaToPointTest()
    config.areaToPoint = true;
    #endtest

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        lData.w *= roughness;

        if (lProps.w > 3.9 && lProps.w < 4.1) {
            if (config.areaToPoint) {
                color += lightPoint(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
            } else {
                color += lightArea(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
            }
        }
    }

    return lclamp(color);
}

vec3 getAreaLightColor(float roughness, LightConfig config) {
    #test !window.Metal
    return getAreaLightColor(roughness, config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
    #endtest
    return vec3(0.0);
}


vec3 getAreaLightColor(float roughness) {
    LightConfig config;
    config.normal = vNormal;
    return getAreaLightColor(roughness, config);
}

vec3 getAreaLightColor() {
    LightConfig config;
    config.normal = vNormal;
    return getAreaLightColor(1.0, config);
}

vec3 getAreaLightColor(LightConfig config) {
    return getAreaLightColor(1.0, config);
}

vec3 getAreaLightColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getAreaLightColor(1.0, config);
}

vec3 getAreaLightColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix, sampler2D tLTC1, sampler2D tLTC2) {
    LightConfig config;
    config.normal = normal;
    return getAreaLightColor(1.0, config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix, tLTC1, tLTC2);
}


vec3 getSpotLightColor(LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec3 color = vec3(0.0);

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        if (lProps.w > 2.9 && lProps.w < 3.1) {
            color += lightCone(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        }
    }

    return lclamp(color);
}

vec3 getSpotLightColor(LightConfig config) {
    #test !window.Metal
    return getSpotLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
    #endtest
    return vec3(0.0);
}

vec3 getSpotLightColor() {
    LightConfig config;
    config.normal = vNormal;
    return getSpotLightColor(config);
}

vec3 getSpotLightColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getSpotLightColor(config);
}

vec3 getSpotLightColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    LightConfig config;
    config.normal = normal;
    return getSpotLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
}


vec3 getDirectionalLightColor(LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec3 color = vec3(0.0);

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        if (lProps.w > 0.9 && lProps.w < 1.1) {
            color += lightDirectional(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        }
    }

    return lclamp(color);
}

vec3 getDirectionalLightColor(LightConfig config) {
    #test !window.Metal
    return getDirectionalLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
    #endtest
    return vec3(0.0);
}

vec3 getDirectionalLightColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getDirectionalLightColor(config);
}

vec3 getDirectionalLightColor() {
    LightConfig config;
    config.normal = vNormal;
    return getDirectionalLightColor(config);
}

vec3 getDirectionalLightColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    LightConfig config;
    config.normal = vNormal;
    return getDirectionalLightColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
}

vec3 getStandardColor(LightConfig config, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec3 color = vec3(0.0);

    #pragma unroll_loop
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lColor = config.overrideColor ? config.lightColor : lightColor[i].rgb;
        vec3 lPos = lightPos[i].rgb;
        vec4 lData = lightData[i];
        vec4 lData2 = lightData2[i];
        vec4 lData3 = lightData3[i];
        vec4 lProps = lightProperties[i];

        if (lProps.w < 1.0) continue;

        if (lProps.w < 1.1) {
            color += lightDirectional(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        } else if (lProps.w < 2.1) {
            color += lightPoint(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
        }
    }

    return lclamp(color);
}

vec3 getStandardColor(LightConfig config) {
    #test !window.Metal
    return getStandardColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
    #endtest
    return vec3(0.0);
}

vec3 getStandardColor() {
    LightConfig config;
    config.normal = vNormal;
    return getStandardColor(config);
}

vec3 getStandardColor(vec3 normal) {
    LightConfig config;
    config.normal = normal;
    return getStandardColor(config);
}

vec3 getStandardColor(vec3 normal, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    LightConfig config;
    config.normal = normal;
    return getStandardColor(config, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);
}{@}LightingCommon.glsl{@}#require(AreaLights.glsl)

vec3 lworldLight(vec3 lightPos, vec3 localPos, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec4 mvPos = modelViewMatrix * vec4(localPos, 1.0);
    vec4 worldPosition = viewMatrix * vec4(lightPos, 1.0);
    return worldPosition.xyz - mvPos.xyz;
}

float lrange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    vec3 sub = vec3(oldValue, newMax, oldMax) - vec3(oldMin, newMin, oldMin);
    return sub.x * sub.y / sub.z + newMin;
}

vec3 lclamp(vec3 v) {
    return clamp(v, vec3(0.0), vec3(1.0));
}

float lcrange(float oldValue, float oldMin, float oldMax, float newMin, float newMax) {
    return clamp(lrange(oldValue, oldMin, oldMax, newMin, newMax), min(newMax, newMin), max(newMin, newMax));
}

#require(Phong.glsl)

vec3 lightDirectional(LightConfig config, vec3 lColor, vec3 lPos, vec4 lData, vec4 lData2, vec4 lData3, vec4 lProps, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    vec3 lDir = lworldLight(lPos, vPos, modelViewMatrix, viewMatrix);
    float volume = dot(normalize(lDir), config.normal);

    return lColor * lcrange(volume, 0.0, 1.0, lProps.z, 1.0);
}

vec3 lightPoint(LightConfig config, vec3 lColor, vec3 lPos, vec4 lData, vec4 lData2, vec4 lData3, vec4 lProps, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    float dist = length(vWorldPos - lPos);
    if (dist > lProps.y) return vec3(0.0);

    vec3 color = vec3(0.0);

    vec3 lDir = lworldLight(lPos, vPos, modelViewMatrix, viewMatrix);
    float falloff = pow(lcrange(dist, 0.0, lProps.y, 1.0, 0.0), 2.0);

    if (config.phong) {
        color += falloff * phong(lProps.x, lColor, config.phongColor, config.phongShininess, config.phongAttenuation, config.normal, normalize(lDir), vViewDir, lProps.z);
    } else {
        float volume = dot(normalize(lDir), config.normal);
        volume = lcrange(volume, 0.0, 1.0, lProps.z, 1.0);
        color += lColor * volume * lProps.x * falloff;
    }

    return color;
}

vec3 lightCone(LightConfig config, vec3 lColor, vec3 lPos, vec4 lData, vec4 lData2, vec4 lData3, vec4 lProps, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix) {
    float dist = length(vWorldPos - lPos);
    if (dist > lProps.y) return vec3(0.0);

    vec3 lDir = lworldLight(lPos, vPos, modelViewMatrix, viewMatrix);
    vec3 sDir = degrees(-lData.xyz);
    float radius = lData.w;
    vec3 surfacePos = vWorldPos;
    vec3 surfaceToLight = normalize(lPos - surfacePos);
    float lightToSurfaceAngle = degrees(acos(dot(-surfaceToLight, normalize(sDir))));
    float attenuation = 1.0;

    vec3 nColor = lightPoint(config, lColor, lPos, lData, lData2, lData3, lProps, vPos, vWorldPos, vViewDir, modelViewMatrix, viewMatrix);

    float featherMin = 1.0 - lData2.x*0.1;
    float featherMax = 1.0 + lData2.x*0.1;

    attenuation *= smoothstep(lightToSurfaceAngle*featherMin, lightToSurfaceAngle*featherMax, radius);

    nColor *= attenuation;
    return nColor;
}

vec3 lightArea(LightConfig config, vec3 lColor, vec3 lPos, vec4 lData, vec4 lData2, vec4 lData3, vec4 lProps, vec3 vPos, vec3 vWorldPos, vec3 vViewDir, mat4 modelViewMatrix, mat4 viewMatrix, sampler2D tLTC1, sampler2D tLTC2) {
    float dist = length(vWorldPos - lPos);
    if (dist > lProps.y) return vec3(0.0);

    vec3 color = vec3(0.0);

    vec3 normal = config.normal;
    vec3 viewDir = normalize(vViewDir);
    vec3 position = -vViewDir;
    float roughness = lData.w;
    vec3 mPos = lData.xyz;
    vec3 halfWidth = lData2.xyz;
    vec3 halfHeight = lData3.xyz;

    float falloff = pow(lcrange(dist, 0.0, lProps.y, 1.0, 0.0), 2.0);

    vec3 rectCoords[ 4 ];
    rectCoords[ 0 ] = mPos + halfWidth - halfHeight;
    rectCoords[ 1 ] = mPos - halfWidth - halfHeight;
    rectCoords[ 2 ] = mPos - halfWidth + halfHeight;
    rectCoords[ 3 ] = mPos + halfWidth + halfHeight;

    vec2 uv = LTC_Uv( normal, viewDir, roughness );

    #test !!window.Metal
    uv.y = 1.0 - uv.y;
    #endtest

    vec4 t1 = texture2D(tLTC1, uv);
    vec4 t2 = texture2D(tLTC2, uv);

    mat3 mInv = mat3(
    vec3( t1.x, 0, t1.y ),
    vec3(    0, 1,    0 ),
    vec3( t1.z, 0, t1.w )
    );

    vec3 fresnel = ( lColor * t2.x + ( vec3( 1.0 ) - lColor ) * t2.y );
    color += lColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords ) * falloff * lProps.x;
    color += lColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords ) * falloff * lProps.x;

    return color;
}{@}LitMaterial.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

#require(lighting.vs)

void main() {
    vUv = uv;
    vPos = position;
    setupLight(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(lighting.fs)
#require(shadows.fs)

void main() {
    setupLight();

    vec3 color = texture2D(tMap, vUv).rgb;
    color *= getShadow(vPos);

    color += getCombinedColor();

    gl_FragColor = vec4(color, 1.0);
}{@}Phong.glsl{@}float pclamp(float v) {
    return clamp(v, 0.0, 1.0);
}

float dPhong(float shininess, float dotNH) {
    return (shininess * 0.5 + 1.0) * pow(dotNH, shininess);
}

vec3 schlick(vec3 specularColor, float dotLH) {
    float fresnel = exp2((-5.55437 * dotLH - 6.98316) * dotLH);
    return (1.0 - specularColor) * fresnel + specularColor;
}

vec3 calcBlinnPhong(vec3 specularColor, float shininess, vec3 normal, vec3 lightDir, vec3 viewDir) {
    vec3 halfDir = normalize(lightDir + viewDir);
    
    float dotNH = pclamp(dot(normal, halfDir));
    float dotLH = pclamp(dot(lightDir, halfDir));

    vec3 F = schlick(specularColor, dotLH);
    float G = 0.85;
    float D = dPhong(shininess, dotNH);
    
    return F * G * D;
}

vec3 calcBlinnPhong(vec3 specularColor, float shininess, vec3 normal, vec3 lightDir, vec3 viewDir, float minTreshold) {
    vec3 halfDir = normalize(lightDir + viewDir);

    float dotNH = pclamp(dot(normal, halfDir));
    float dotLH = pclamp(dot(lightDir, halfDir));

    dotNH = lrange(dotNH, 0.0, 1.0, minTreshold, 1.0);
    dotLH = lrange(dotLH, 0.0, 1.0, minTreshold, 1.0);

    vec3 F = schlick(specularColor, dotLH);
    float G = 0.85;
    float D = dPhong(shininess, dotNH);

    return F * G * D;
}

vec3 phong(float amount, vec3 diffuse, vec3 specular, float shininess, float attenuation, vec3 normal, vec3 lightDir, vec3 viewDir, float minThreshold) {
    float cosineTerm = pclamp(lrange(dot(normal, lightDir), 0.0, 1.0, minThreshold, 1.0));
    vec3 brdf = calcBlinnPhong(specular, shininess, normal, lightDir, viewDir, minThreshold);
    return brdf * amount * diffuse * attenuation * cosineTerm;
}{@}Line.glsl{@}#!ATTRIBUTES
attribute vec3 previous;
attribute vec3 next;
attribute float side;
attribute float width;
attribute float lineIndex;
attribute vec2 uv2;

#!UNIFORMS
uniform float uLineWidth;
uniform float uBaseWidth;
uniform float uOpacity;
uniform vec3 uColor;

#!VARYINGS
varying float vLineIndex;
varying vec2 vUv;
varying vec2 vUv2;
varying vec3 vColor;
varying float vOpacity;
varying float vWidth;
varying float vDist;
varying float vFeather;


#!SHADER: Vertex

//params

vec2 fix(vec4 i, float aspect) {
    vec2 res = i.xy / i.w;
    res.x *= aspect;
    return res;
}

void main() {
#test RenderManager.type == RenderManager.VR
    float aspect = (resolution.x / 2.0) / resolution.y;
#endtest
#test RenderManager.type != RenderManager.VR
    float aspect = resolution.x / resolution.y;
#endtest

    vUv = uv;
    vUv2 = uv2;
    vLineIndex = lineIndex;
    vColor = uColor;
    vOpacity = uOpacity;
    vFeather = 0.1;

    vec3 pos = position;
    vec3 prevPos = previous;
    vec3 nextPos = next;
    float lineWidth = 1.0;
    //main

    //startMatrix
    mat4 m = projectionMatrix * modelViewMatrix;
    vec4 finalPosition = m * vec4(pos, 1.0);
    vec4 pPos = m * vec4(prevPos, 1.0);
    vec4 nPos = m * vec4(nextPos, 1.0);
    //endMatrix

    vec2 currentP = fix(finalPosition, aspect);
    vec2 prevP = fix(pPos, aspect);
    vec2 nextP = fix(nPos, aspect);

    float w = uBaseWidth * uLineWidth * width * lineWidth;
    vWidth = w;

    vec2 dirNC = currentP - prevP;
    vec2 dirPC = nextP - currentP;
    if (length(dirNC) >= 0.0001) dirNC = normalize(dirNC);
    if (length(dirPC) >= 0.0001) dirPC = normalize(dirPC);
    vec2 dir = normalize(dirNC + dirPC);

    //direction
    vec2 normal = vec2(-dir.y, dir.x);
    normal.x /= aspect;
    normal *= 0.5 * w;

    vDist = finalPosition.z / 10.0;

    finalPosition.xy += normal * side;
    gl_Position = finalPosition;
}

#!SHADER: Fragment

//fsparams

void main() {
    float d = (1.0 / (5.0 * vWidth + 1.0)) * vFeather * (vDist * 5.0 + 0.5);
    vec2 uvButt = vec2(0.0, vUv.y);
    float buttLength = 0.5 * vWidth;
    uvButt.x = min(0.5, vUv2.x / buttLength) + (0.5 - min(0.5, (vUv2.y - vUv2.x) / buttLength));
    float round = length(uvButt - 0.5);
    float alpha = 1.0 - smoothstep(0.45, 0.5, round);

    /*
        If you're having antialiasing problems try:
        Remove line 93 to 98 and replace with
        `
            float signedDist = tri(vUv.y) - 0.5;
            float alpha = clamp(signedDist/fwidth(signedDist) + 0.5, 0.0, 1.0);

            if (w <= 0.3) {
                discard;
                return;
            }

            where tri function is

            float tri(float v) {
                return mix(v, 1.0 - v, step(0.5, v)) * 2.0;
            }
        `

        Then, make sure your line has transparency and remove the last line
        if (gl_FragColor.a < 0.1) discard;
    */

    vec3 color = vColor;

    gl_FragColor.rgb = color;
    gl_FragColor.a = alpha;
    gl_FragColor.a *= vOpacity;

    //fsmain

    if (gl_FragColor.a < 0.1) discard;
}
{@}mousefluid.fs{@}uniform sampler2D tFluid;
uniform sampler2D tFluidMask;

vec2 getFluidVelocity() {
    float fluidMask = smoothstep(0.1, 0.7, texture2D(tFluidMask, vUv).r);
    return texture2D(tFluid, vUv).xy * fluidMask;
}

vec3 getFluidVelocityMask() {
    float fluidMask = smoothstep(0.1, 0.7, texture2D(tFluidMask, vUv).r);
    return vec3(texture2D(tFluid, vUv).xy * fluidMask, fluidMask);
}{@}OculusHand.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;

#!SHADER: Vertex

#require(skinning.glsl)

void main() {
    vNormal = normalize(normalMatrix * normal);
    vUv = uv;
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    vec3 pos = position;
    applySkin(pos, vNormal);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(fresnel.glsl)

void main() {
    gl_FragColor = vec4(uColor * (1.0 - getFresnel(vNormal, vViewDir, 5.0)), 1.0);
}{@}hierarchyparticles.glsl{@}#require(instance.vs)

uniform sampler2D tHPos;
uniform sampler2D tHQuat;
uniform float uHTexSize;
uniform float uHCount;

float hround(float i) {
    return floor(i + 0.5);
}

vec2 getHLookupUV(float r) {
    float pixel = hround(crange(r, 0.0, 1.0, 0.0, uHCount-1.0));

    float size = uHTexSize;
    float p0 = pixel / size;
    float y = floor(p0);
    float x = p0 - y;

    vec2 uv = vec2(0.0);
    uv.x = x;
    uv.y = y / size;
    return uv;
}{@}particleskin.glsl{@}uniform sampler2D tSkinWeight;
uniform sampler2D tSkinIndex;
uniform sampler2D boneTexture;
uniform float boneTextureSize;

mat4 getBoneMatrix(const in float i) {
    float j = i * 4.0;
    float x = mod(j, boneTextureSize);
    float y = floor(j / boneTextureSize);

    float dx = 1.0 / boneTextureSize;
    float dy = 1.0 / boneTextureSize;

    y = dy * (y + 0.5);

    vec4 v1 = texture2D(boneTexture, vec2(dx * (x + 0.5), y));
    vec4 v2 = texture2D(boneTexture, vec2(dx * (x + 1.5), y));
    vec4 v3 = texture2D(boneTexture, vec2(dx * (x + 2.5), y));
    vec4 v4 = texture2D(boneTexture, vec2(dx * (x + 3.5), y));

    return mat4(v1, v2, v3, v4);
}

vec3 applySkin(vec3 pos, vec4 skinIndex, vec4 skinWeight) {
    mat4 boneMatX = getBoneMatrix(skinIndex.x);
    mat4 boneMatY = getBoneMatrix(skinIndex.y);
    mat4 boneMatZ = getBoneMatrix(skinIndex.z);
    mat4 boneMatW = getBoneMatrix(skinIndex.w);

    mat4 skinMatrix = mat4(0.0);
    skinMatrix += skinWeight.x * boneMatX;
    skinMatrix += skinWeight.y * boneMatY;
    skinMatrix += skinWeight.z * boneMatZ;
    skinMatrix += skinWeight.w * boneMatW;

    vec4 bindPos = vec4(pos, 1.0);
    vec4 transformed = vec4(0.0);

    transformed += boneMatX * bindPos * skinWeight.x;
    transformed += boneMatY * bindPos * skinWeight.y;
    transformed += boneMatZ * bindPos * skinWeight.z;
    transformed += boneMatW * bindPos * skinWeight.w;

    return transformed.xyz;
}{@}textureparticleanimation.glsl{@}uniform float uTexAnimSpeed;
uniform float uTexFrameCount;
uniform sampler2D tTexAnimation;
uniform sampler2D tUV;

vec3 getAnimationPos(vec2 uv, float offset) {
    float t = (time * uTexAnimSpeed) + offset;

    vec2 frameOffset = vec2(1.0 / uTexFrameCount, 0.0) * floor(fract(t) * uTexFrameCount);
    vec2 nextFrameOffset;
    nextFrameOffset.x = mod(frameOffset.x + (1.0 / uTexFrameCount), 1.0);
    nextFrameOffset.y = 0.0;

    vec3 frame = texture2D(tTexAnimation, vec2(uv.x / uTexFrameCount, uv.y) + frameOffset).rgb;
    vec3 nextFrame = texture2D(tTexAnimation, vec2(uv.x / uTexFrameCount, uv.y) + nextFrameOffset).rgb;

    frame = mix(frame, nextFrame, fract(t * uTexFrameCount));

    vec3 res = vec3(0.0);

    res.x += crange(frame.r, 0.0, 1.0, -1.0, 1.0);
    res.y += crange(frame.g, 0.0, 1.0, -1.0, 1.0);
    res.z += crange(frame.b, 0.0, 1.0, -1.0, 1.0);

    return res;
}{@}ProtonAntimatter.fs{@}uniform sampler2D tOrigin;
uniform sampler2D tAttribs;
uniform float uMaxCount;
//uniforms

#require(range.glsl)
//requires

void main() {
    vec2 uv = vUv;
    #test !window.Metal
    uv = gl_FragCoord.xy / fSize;
    #endtest

    vec3 origin = texture2D(tOrigin, uv).xyz;
    vec4 inputData = texture2D(tInput, uv);
    vec3 pos = inputData.xyz;
    vec4 random = texture2D(tAttribs, uv);
    float data = inputData.w;

    if (vUv.x + vUv.y * fSize > uMaxCount) {
        gl_FragColor = vec4(9999.0);
        return;
    }

    //code

    gl_FragColor = vec4(pos, data);
}{@}ProtonAntimatterLifecycle.fs{@}uniform sampler2D tOrigin;
uniform sampler2D tAttribs;
uniform sampler2D tSpawn;
uniform float uMaxCount;
//uniforms

#require(range.glsl)
//requires

void main() {
    vec3 origin = texture2D(tOrigin, vUv).rgb;
    vec4 inputData = texture2D(tInput, vUv);
    vec3 pos = inputData.xyz;
    vec4 random = texture2D(tAttribs, vUv);
    float data = inputData.w;

    if (vUv.x + vUv.y * fSize > uMaxCount) {
        gl_FragColor = vec4(9999.0);
        return;
    }

    vec4 spawn = texture2D(tSpawn, vUv);
    float life = spawn.x;

    if (spawn.x < -500.0) {
        pos = spawn.xyz;
        pos.x += 999.0;
        spawn.x = 1.0;
        gl_FragColor = vec4(pos, data);
        return;
    }

    //abovespawn
    if (spawn.x <= 0.0) {
        pos.x = 9999.0;
        gl_FragColor = vec4(pos, data);
        return;
    }

    //abovecode
    //code

    gl_FragColor = vec4(pos, data);
}{@}ProtonNeutrino.fs{@}//uniforms

#require(range.glsl)
//requires

void main() {
    //code
}{@}ProtonTube.glsl{@}#!ATTRIBUTES
attribute float angle;
attribute vec2 tuv;
attribute float cIndex;
attribute float cNumber;

#!UNIFORMS
uniform sampler2D tPos;
uniform sampler2D tLife;
uniform float radialSegments;
uniform float thickness;
uniform float taper;

#!VARYINGS
varying float vLength;
varying vec3 vNormal;
varying vec3 vViewPosition;
varying vec3 vPos;
varying vec2 vUv;
varying vec2 vUv2;
varying float vIndex;
varying float vLife;
varying vec3 vDiscard;

#!SHADER: Vertex

//neutrinoparams

#require(ProtonTubesUniforms.fs)
#require(range.glsl)
#require(conditionals.glsl)

void main() {
    float headIndex = getIndex(cNumber, 0.0, lineSegments);
    vec2 iuv = getUVFromIndex(headIndex, textureSize);
    vUv2 = iuv;
    float life = texture2D(tLife, iuv).x;
    vLife = life;

    float scale = 1.0;
    //neutrinovs
    vec2 volume = vec2(thickness * 0.065 * scale);

    vec3 transformed;
    vec3 objectNormal;

    //extrude tube
    float posIndex = getIndex(cNumber, cIndex, lineSegments);
    float nextIndex = getIndex(cNumber, cIndex + 1.0, lineSegments);

    vLength = cIndex / (lineSegments - 2.0);
    vIndex = cIndex;

    vec3 current = texture2D(tPos, getUVFromIndex(posIndex, textureSize)).xyz;
    vec3 next = texture2D(tPos, getUVFromIndex(nextIndex, textureSize)).xyz;

    vDiscard = next - current;
    vec3 T = normalize(next - current);
    vec3 B = normalize(cross(T, next + current));
    vec3 N = -normalize(cross(B, T));

    float tubeAngle = angle;
    float circX = cos(tubeAngle);
    float circY = sin(tubeAngle);

    volume *= mix(crange(vLength, 1.0 - taper, 1.0, 1.0, 0.0) * crange(vLength, 0.0, taper, 0.0, 1.0), 1.0, when_eq(taper, 0.0));

    objectNormal.xyz = normalize(B * circX + N * circY);
    transformed.xyz = current + B * volume.x * circX + N * volume.y * circY;
    //extrude tube

    vec3 transformedNormal = normalMatrix * objectNormal;
    vNormal = normalize(transformedNormal);
    vUv = tuv.yx;

    vec3 pos = transformed;
    vec4 mvPosition = modelViewMatrix * vec4(transformed, 1.0);
    vViewPosition = -mvPosition.xyz;
    vPos = pos;
    gl_Position = projectionMatrix * mvPosition;

    //neutrinovspost
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(1.0);
}{@}ProtonTubesMain.fs{@}void main() {
    vec3 index = getData(tIndices, vUv);

    float CHAIN = index.x;
    float LINE = index.y;
    float HEAD = index.z;

    if (HEAD > 0.9) {

        //main

    } else {

        float followIndex = getIndex(LINE, CHAIN-1.0, lineSegments);
        float headIndex = getIndex(LINE, 0.0, lineSegments);
        vec3 followPos = texture2D(tInput, getUVFromIndex(followIndex, textureSize)).xyz;
        vec4 followSpawn = texture2D(tSpawn, getUVFromIndex(headIndex, textureSize));

        if (followSpawn.x <= 0.0) {
            pos.x = 9999.0;
            gl_FragColor = vec4(pos, data);
            return;
        }

        if (length(followPos - pos) > uResetDelta) {
            followPos = texture2D(tInput, getUVFromIndex(headIndex, textureSize)).xyz;
            pos = followPos;
        }

        pos += (followPos - pos) * (uLerp * timeScale * HZ);
    }
}{@}ProtonTubesUniforms.fs{@}uniform sampler2D tIndices;
uniform float textureSize;
uniform float lineSegments;
uniform float uLerp;
uniform float uResetDelta;

vec2 getUVFromIndex(float index, float textureSize) {
    float size = textureSize;
    vec2 ruv = vec2(0.0);
    float p0 = index / size;
    float y = floor(p0);
    float x = p0 - y;
    ruv.x = x;
    ruv.y = y / size;
    return ruv;
}

float getIndex(float line, float chain, float lineSegments) {
    return (line * lineSegments) + chain;
}{@}SceneLayout.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vec3 pos = position;
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.a *= uAlpha;
    gl_FragColor.rgb /= gl_FragColor.a;
}{@}ShadowInspector.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(depthvalue.fs)

void main() {
    gl_FragColor = vec4(vec3(getDepthValue(tMap, vUv, 10.0, 51.0)), 1.0);
}{@}GLUIShape.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(uColor, uAlpha);
}{@}GLUIShapeBitmap.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMask;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = texture2D(tMap, vUv) * texture2D(tMask, vUv).a;
    gl_FragColor.a *= uAlpha;
}{@}SplineParticleInstance.glsl{@}#!ATTRIBUTES
attribute vec2 lookup;

#!UNIFORMS
uniform sampler2D tPos;

#!VARYINGS

#!SHADER: Vertex

#require(instance.vs)
#require(rotation.glsl)

void main() {
    vec3 offset = texture2D(tPos, lookup).xyz;
    vec3 p = vec3(rotationMatrix(vec3(0.0, 0.0, 1.0), radians(time*10000000.0)) * vec4(position, 1.0));
    vec3 pos = transformPosition(p, offset);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(1.0);
}{@}SplineParticleLife.fs{@}uniform sampler2D tAttribs;
uniform sampler2D tPos;
uniform sampler2D tOrigin;
uniform float uMaxCount;
uniform float uSplineCount;
uniform float uSetup;
uniform float uDecayRate;
uniform float uTimeMultiplier;
uniform float uIHold;
uniform vec2 uDecayRange;
uniform vec2 uRelease;
uniform float uStartOffset;
uniform vec2 uFlowRange;
uniform vec2 uSplineSpeed;
uniform float uInfinite;
uniform float uDelayStart;
uniform float uMaxDelay;
uniform float uMaxSDelay;
uniform float uHoldBack;
uniform float uHoldBack2;
uniform float uStartSpacing;
uniform vec4 uLifeSlow;
uniform float HZ;

#require(range.glsl)
#require(conditionals.glsl)
#require(simplenoise.glsl)

float sround(float i) {
    return floor(i + 0.5);
}

float randomSeed(float seed) {
    float n = sin(seed) * 10.0;
    return n - floor(n);
}

float srand(float seed, float min, float max) {
    return (min + randomSeed(seed) * (max - min));
}

void main() {
    vec2 uv = vUv;

    if (vUv.x + vUv.y * fSize > uMaxCount) {
        gl_FragColor = vec4(9999.0);
        return;
    }

    vec4 inputData = getData4(tInput, uv);
    vec4 random = getData4(tAttribs, uv);
    vec4 random2 = (getData4(tOrigin, uv) / 2.0) + 0.5;
    vec4 pos = getData4(tPos, uv);

    vec4 outputData;
    outputData.x = sround(crange(random.x, 0.0, 1.0, 0.0, uSplineCount-1.0));

//    float decay = crange(random.w, 0.0, 1.0, uDecayRange.x, uDecayRange.y);
//
//    outputData.y = inputData.y + mix(0.02 * uDecaySpeed.x * decay, 0.002 * uDecaySpeed.y * decay, when_gt(inputData.y, 0.999));
//    outputData.y = clamp(outputData.y, 0.0, 2.0);

    outputData.y = inputData.y - (0.01 * uDecayRate * mix(uDecayRange.x, uDecayRange.y, random2.y) * timeScale * HZ);
    outputData.y = clamp(outputData.y, 0.0, 1.0);

    if (uSetup > 0.5) {
        outputData.z = crange(random.w, 0.0, 1.0, 0.0, uStartOffset);
        outputData.z += srand(outputData.x, 0.0, uStartSpacing);
    } else {
        float delayed = 1.0;
        float delayedSpline = 1.0;

        float sRandom = crange(cnoise(vec2(random.x)), -1.0, 1.0, 0.0, 1.0);

        bool isStarting = inputData.z == 0.0;

        if (uDelayStart > 0.0) {
            delayed = time - uDelayStart > uMaxDelay * random2.y ? 1.0 : 0.0;
            delayedSpline = time - uDelayStart > uMaxSDelay * random.x ? 1.0 : 0.0;
        }

        float lifeSlow = crange(inputData.z, uLifeSlow.x, uLifeSlow.y, uLifeSlow.z, uLifeSlow.w);
        outputData.z = inputData.z + (0.001 * timeScale * uTimeMultiplier * lifeSlow * HZ * crange(random2.z, 0.0, 1.0, uFlowRange.x, uFlowRange.y) * crange(sRandom, 0.0, 1.0, uSplineSpeed.x, uSplineSpeed.y));

        if (uRelease.y > 1.0) {
            if (inputData.z < 0.001 || inputData.z > 1.0) {
                float minR = uRelease.x / uRelease.y;
                float maxR = (uRelease.x+1.0) / uRelease.y;
                if (random.w < minR || random.w > maxR) {
                    outputData.z = 0.0;
                }
            }
        }
//
        if (isStarting) outputData.z *= delayed * delayedSpline * step(1.0 - ((1.0 - uHoldBack) * (1.0 - uHoldBack2)), random2.x);

        if (outputData.z > 1.0) {
            outputData.w = 0.0;
            if (uInfinite > 0.5) outputData.z = 0.0;
        } else if (outputData.z < 0.01) {
            outputData.y = 1.0;
        }

        if (uIHold > 0.5) outputData.z = 0.0;
    }

    gl_FragColor = outputData;
}{@}SplineParticlePreset.fs{@}void main() {
sRandom = random;
sOrigin = origin;

float travel = texture2D(tLife, vUv).z;
vec3 target = getSplinePos(travel);

if (uSetup > 0.5 || travel < 0.001) {
    pos = target;
}

pos += (target - pos) * 0.07 * HZ;
}{@}splineparticles.fs{@}uniform sampler2D tSpline;
uniform sampler2D tLife;
uniform float uSplineTexSize;
uniform float uPerSpline;
uniform float uSplineCount;
uniform float uInfinite;
uniform float uSetup;

vec4 sRandom;
vec3 sOrigin;

float splinenoise(vec3 v) {
    float t = v.z * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += range(sin(v.x * 0.9 / s + t * 10.0) + sin(v.x * 2.4 / s + t * 15.0) + sin(v.x * -3.5 / s + t * 4.0) + sin(v.x * -2.5 / s + t * 7.1), -1.0, 1.0, -0.3, 0.3);
    noise += range(sin(v.y * -0.3 / s + t * 18.0) + sin(v.y * 1.6 / s + t * 18.0) + sin(v.y * 2.6 / s + t * 8.0) + sin(v.y * -2.6 / s + t * 4.5), -1.0, 1.0, -0.3, 0.3);
    return noise;
}

float sround(float i) {
    return floor(i + 0.5);
}

float randomSeed(float seed) {
    float n = sin(seed) * 10000000.0;
    return n - floor(n);
}

float srand(float seed, float min, float max) {
    return sround((min + randomSeed(seed) * (max - min)));
}

float getSplineIndex() {
    return sround(crange(sRandom.x, 0.0, 1.0, 0.0, uSplineCount-1.0));
}

vec2 getSplineLookupUV(float index, float time) {
    float pixel = uPerSpline * (index + time);
    return vec2(mod(pixel, uSplineTexSize), floor(pixel / uSplineTexSize)) / uSplineTexSize;
}

float ssineOut(float t) {
    return sin(t * 1.5707963267948966);
}

float scnoise(vec3 v) {
    float t = v.z * 0.3;
    v.y *= 0.8;
    float noise = 0.0;
    float s = 0.5;
    noise += range(sin(v.x * 0.9 / s + t * 10.0) + sin(v.x * 2.4 / s + t * 15.0) + sin(v.x * -3.5 / s + t * 4.0) + sin(v.x * -2.5 / s + t * 7.1), -1.0, 1.0, -0.3, 0.3);
    noise += range(sin(v.y * -0.3 / s + t * 18.0) + sin(v.y * 1.6 / s + t * 18.0) + sin(v.y * 2.6 / s + t * 8.0) + sin(v.y * -2.6 / s + t * 4.5), -1.0, 1.0, -0.3, 0.3);
    return noise;
}

vec3 getSplineThickness(vec3 pos, float time) {
    float angle = radians(360.0 * sRandom.z);

    float gamma = ssineOut(crange(scnoise(sOrigin.xyz * uDistribution), -1.0, 1.0, 0.0, 1.0));
    float fizzy = pow(mix(uDistributionRange.x, uDistributionRange.y, gamma), 3.0);

    float splineRandom = 0.0;//srand(getSplineIndex() * 10000.0, 0.0, 1000.0) / 1000.0;
    float splineRandomStep = step(uThicknessStep.x, splineRandom);
    float distribution = mix(uThicknessStep.y, 1.0, 1.0 - splineRandomStep);

    float radius = 0.5 * uSplineThickness * distribution * fizzy;

    radius *= crange(splinenoise((pos * uRangeScale) + time*uThicknessSpeed), -1.0, 1.0, 1.0 - uRangeThickness, 1.0 + uRangeThickness);
    radius *= mix(1.0, uExtrudeRandom, sRandom.y);

    return normalize(sOrigin) * radius;
}

vec3 getSplinePosRaw(float time) {
    float step = 1.0 / uPerSpline;
    float index = getSplineIndex();

    float next = time + step;
    vec2 uv0 = vec2(0.);
    vec2 uv1 = vec2(1.);

    if(next <= 1.) {
        uv0 = getSplineLookupUV(index, time);
        uv1 = getSplineLookupUV(index, next);
    } else {
        uv0 = getSplineLookupUV(index, 1.);
        uv1 = getSplineLookupUV(index, time - step);
    }
    
    float interpolate = mod(time, step) * uPerSpline;

    vec3 cpos = texture2D(tSpline, uv0).xyz;
    vec3 npos = texture2D(tSpline, uv1).xyz;
    vec3 pos = mix(cpos, npos, interpolate);

    if (uSCurlNoiseSpeed > 0.0) {
        pos += curlNoise((pos * uSCurlNoiseScale*0.1) + (time * uSCurlTimeScale*0.1)) * uSCurlNoiseSpeed * 0.01 * HZ;
    }

    return pos;
}

vec3 getSplinePos(float time) {
    vec3 pos = getSplinePosRaw(time);
    pos += getSplineThickness(pos, time);
    return pos;
}{@}splineshader.glsl{@}uniform sampler2D tSpline;
uniform float uSplineTexSize;
uniform float uPerSpline;

#require(conditionals.glsl)

float sround(float i) {
    return floor(i + 0.5);
}

vec2 getSplineLookupUV(float index, float time) {
    float pixel = (index * uPerSpline) + (time * uPerSpline);

    float size = uSplineTexSize;
    float p0 = pixel / size;
    float y = floor(p0);
    float x = p0 - y;

    vec2 uv = vec2(0.0);
    uv.x = x;
    uv.y = y / size;
    return uv;
}

vec3 getSplinePos(float index, float time) {
    vec2 uv = getSplineLookupUV(index, time);
    vec3 pos = texture2D(tSpline, uv).xyz;
    return pos;
}

float isMoving(float index, float time) {
    vec3 cpos = getSplinePos(index, time);
    vec3 npos = getSplinePos(index, time + (1.0 / uPerSpline));

    float moving = when_gt(length(cpos - npos), 0.001);
    moving = mix(moving, 1.0, when_gt(time, 0.5));

    return moving;
}{@}Text3D.glsl{@}#!ATTRIBUTES
attribute vec3 animation;

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uOpacity;
uniform vec3 uTranslate;
uniform vec3 uRotate;
uniform float uTransition;
uniform float uWordCount;
uniform float uLineCount;
uniform float uLetterCount;
uniform float uByWord;
uniform float uByLine;
uniform float uPadding;
uniform float uFlicker;
uniform vec3 uBoundingMin;
uniform vec3 uBoundingMax;

#!VARYINGS
varying float vTrans;
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

#require(range.glsl)
#require(eases.glsl)
#require(rotation.glsl)
#require(conditionals.glsl)

void main() {
    vUv = uv;
    vTrans = 1.0;

    vec3 pos = position;

    if (uTransition > 0.0 && uTransition < 1.0) {
        float padding = uPadding;
        float letter = (animation.x + 1.0) / uLetterCount;
        float word = (animation.y + 1.0) / uWordCount;
        float line = (animation.z + 1.0) / uLineCount;

        float letterTrans = rangeTransition(uTransition, letter, padding);
        float wordTrans = rangeTransition(uTransition, word, padding);
        float lineTrans = rangeTransition(uTransition, line, padding);

        vTrans = mix(cubicOut(letterTrans), cubicOut(wordTrans), uByWord);
        vTrans = mix(vTrans, cubicOut(lineTrans), uByLine);

        float invTrans = (1.0 - vTrans);
        vec3 nRotate = normalize(uRotate);
        vec3 axisX = vec3(1.0, 0.0, 0.0);
        vec3 axisY = vec3(0.0, 1.0, 0.0);
        vec3 axisZ = vec3(0.0, 0.0, 1.0);
        vec3 axis = mix(axisX, axisY, when_gt(nRotate.y, nRotate.x));
        axis = mix(axis, axisZ, when_gt(nRotate.z, nRotate.x));
        pos = vec3(vec4(position, 1.0) * rotationMatrix(axis, radians(max(max(uRotate.x, uRotate.y), uRotate.z) * invTrans)));
        pos += uTranslate * invTrans;
    }

    vPos = pos;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(msdf.glsl)
#require(simplenoise.glsl)

vec2 getBoundingUV() {
    vec2 uv;
    uv.x = crange(vPos.x, uBoundingMin.x, uBoundingMax.x, 0.0, 1.0);
    uv.y = crange(vPos.y, uBoundingMin.y, uBoundingMax.y, 0.0, 1.0);
    return uv;
}

void main() {
    float alpha = msdf(tMap, vUv);

    //float noise = 0.5 + smoothstep(-1.0, 1.0, cnoise(vec3(vUv*8.0, time* 0.3))) * 0.5;
    //alpha *= noise;

    //alpha *= smoothstep(0.0, 0.1, uTransition);

    float flicker = max(1.0 - uFlicker, 0.6+sin(time*60.0)*0.4);
    float center = 0.3;
    float padding = 0.1;
    alpha *= mix(1.0, flicker, smoothstep(center-padding, center, uTransition)*smoothstep(center+padding, center, uTransition));

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha * uOpacity * vTrans * smoothstep(0.0, 0.1, uTransition);
}
{@}TweenUILPathFallbackShader.glsl{@}#!ATTRIBUTES
attribute float speed;

#!UNIFORMS
uniform vec3 uColor;
uniform vec3 uColor2;
uniform float uOpacity;

#!VARYINGS
varying vec3 vColor;

#!SHADER: Vertex

void main() {
    vColor = mix(uColor, uColor2, speed);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(vColor, uOpacity);
}
{@}TweenUILPathShader.glsl{@}#!ATTRIBUTES
attribute float speed;

#!UNIFORMS
uniform vec3 uColor2;

#!VARYINGS

#!SHADER: Vertex

void main() {
    vColor = mix(uColor, uColor2, speed);
}

void customDirection() {
    // Use screen space coordinates for final position, so line thickness is
    // independent of camera.
    finalPosition = vec4(currentP.x / aspect, currentP.y, min(0.0, finalPosition.z), 1.0);
}

#!SHADER: Fragment
float tri(float v) {
    return mix(v, 1.0 - v, step(0.5, v)) * 2.0;
}

void main() {
    float signedDist = tri(vUv.y) - 0.5;
    gl_FragColor.a *= clamp(signedDist/fwidth(signedDist) + 0.5, 0.0, 1.0);
}
{@}UnrealBloom.fs{@}uniform sampler2D tUnrealBloom;

vec3 getUnrealBloom(vec2 uv) {
    return texture2D(tUnrealBloom, uv).rgb;
}{@}UnrealBloomComposite.glsl{@}#!ATTRIBUTES

#!UNIFORMS

uniform sampler2D blurTexture1;
uniform float bloomStrength;
uniform float bloomRadius;
uniform vec3 bloomTintColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex.vs
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: Fragment.fs

float lerpBloomFactor(const in float factor) {
    float mirrorFactor = 1.2 - factor;
    return mix(factor, mirrorFactor, bloomRadius);
}

void main() {
    gl_FragColor = bloomStrength * (lerpBloomFactor(1.0) * vec4(bloomTintColor, 1.0) * texture2D(blurTexture1, vUv));
}{@}UnrealBloomGaussian.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D colorTexture;
uniform vec2 texSize;
uniform vec2 direction;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex.vs
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: Fragment.fs

float gaussianPdf(in float x, in float sigma) {
    return 0.39894 * exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

void main() {
    vec2 invSize = 1.0 / texSize;
    float fSigma = float(SIGMA);
    float weightSum = gaussianPdf(0.0, fSigma);
    vec3 diffuseSum = texture2D( colorTexture, vUv).rgb * weightSum;
    for(int i = 1; i < KERNEL_RADIUS; i ++) {
        float x = float(i);
        float w = gaussianPdf(x, fSigma);
        vec2 uvOffset = direction * invSize * x;
        vec3 sample1 = texture2D( colorTexture, vUv + uvOffset).rgb;
        vec3 sample2 = texture2D( colorTexture, vUv - uvOffset).rgb;
        diffuseSum += (sample1 + sample2) * w;
        weightSum += 2.0 * w;
    }
    gl_FragColor = vec4(diffuseSum/weightSum, 1.0);
}{@}UnrealBloomLuminosity.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tDiffuse;
uniform vec3 defaultColor;
uniform float defaultOpacity;
uniform float luminosityThreshold;
uniform float smoothWidth;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex.vs
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: Fragment.fs

#require(luma.fs)

void main() {
    vec4 texel = texture2D(tDiffuse, vUv);
    float v = luma(texel.xyz);
    vec4 outputColor = vec4(defaultColor.rgb, defaultOpacity);
    float alpha = smoothstep(luminosityThreshold, luminosityThreshold + smoothWidth, v);
    gl_FragColor = mix(outputColor, texel, alpha);
}{@}UnrealBloomPass.fs{@}#require(UnrealBloom.fs)

void main() {
    vec4 color = texture2D(tDiffuse, vUv);
    color.rgb += getUnrealBloom(vUv);
    gl_FragColor = color;
}{@}luma.fs{@}float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float luma(vec4 color) {
  return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}{@}GazeSelector.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uTime;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uAlpha2;
uniform float uVisible;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#define pi 3.1415926538
#require(transformUV.glsl)
#require(range.glsl)
#require(simplenoise.glsl)

float circle(vec2 _st, in float _radius){
    vec2 dist = _st-vec2(0.5);
    return 1.-smoothstep(_radius-(_radius*0.1), _radius+(_radius*0.1), dot(dist,dist)*4.0);
}

float arc(vec2 uv, float outerRadius, float innerRadius, float angle) {
    uv = rotateUV(uv, radians(180.0));
    float cc = circle(uv, outerRadius) - circle(uv, innerRadius);
    vec2 d = vec2(0.5) - uv;

    float angdist = mod(atan(d.x, d.y), 2.0*pi);
    cc *= mix(uAlpha2, uAlpha, uTime);

    float dotCircle = circle(uv, mix(0.0025, outerRadius, uTime)) - circle(uv, mix(0.0, mix(innerRadius*0.8, innerRadius, uTime), uTime));
    cc += dotCircle * mix(uAlpha2, uAlpha, uTime) * mix(0.4, 0.8, uTime);

    return cc;
}

void main() {
    float alpha = 1.0;

    float radius = crange(uAlpha, 0.0, 1.0, 0.2, 0.3);
    float offset = crange(uAlpha, 0.0, 1.0, 1.06, 1.1);

    vec2 arcUV = scaleUV(vUv, vec2(0.4));
    alpha *= arc(arcUV, radius*offset, radius, radians(uTime * 360.0));
    alpha *= uVisible;

    vec2 rippleUV = vUv;
    rippleUV += cnoise(rippleUV*3.0+time*0.2)*0.005;
    float ripple = fract(length(rippleUV-0.5)*mix(4.0, 7.0, uTime)-time*0.2);

    float midPoint = mix(0.6, 0.1, uTime);
    ripple *= smoothstep(0.0, midPoint, ripple) * smoothstep(1.0, midPoint, ripple);
    ripple *= smoothstep(0.5, 0.25, length(rippleUV-0.5)) * smoothstep(0.1, 0.15, length(rippleUV-0.5));
    alpha += ripple * mix(0.07, 0.3, uTime) * uVisible;

    gl_FragColor = vec4(uColor, alpha);
}
{@}TeleportCylinderShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform vec3 uMissColor;
uniform float uAlpha;
uniform float uMiss;
uniform float uVis;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(eases.glsl)
#require(rgb2hsv.fs)

void main() {
    vec3 color = mix(uColor, uMissColor, uMiss);
    float alpha = pow(sineIn(1.0 - vUv.y), 8.0);
    color = rgb2hsv(color);
    color.x += 0.04 * (1.0 - alpha);
    color = hsv2rgb(color);

    gl_FragColor = vec4(color, alpha * uVis * uAlpha);
}{@}TeleportLineShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uLColor;
uniform float uLAlpha;
uniform float uVis;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
}

#!SHADER: Fragment

#require(range.glsl)
#require(rgb2hsv.fs)

void main() {
    float blend = crange(vUv.x, 0.1, 0.3, 0.0, 1.0) * crange(vUv.x, 0.5, 0.7, 1.0, 0.0);
    float t = mix(1.0, 0.6, crange(sin((vUv.x*30.0) - time*10.0), -1.0, 1.0, 0.0, 1.0));

    vec3 ocolor = rgb2hsv(uLColor);
    ocolor.x += 0.04 * vUv.x;
    ocolor = hsv2rgb(ocolor);

    gl_FragColor = vec4(ocolor, alpha * uLAlpha * blend * t * uVis);
}
{@}ARCameraQuad.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    #test !!window.Metal
    vUv.y = 1.0 - vUv.y;
    #endtest

    gl_FragColor = texture2D(tMap, vUv);
}{@}VRInputControllerDefault.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS
varying vec3 vViewDir;
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex
void main() {
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    vViewDir = -mvPosition.xyz;
    vPos = position;
    vNormal = normalMatrix * normal;
    gl_Position = projectionMatrix * mvPosition;
}

#!SHADER: Fragment

#require(fresnel.glsl)
#require(range.glsl)

void main() {
    float f = getFresnel(vNormal, vViewDir, 0.8);

    f *= crange(vPos.z, 0.04, 0.1, 1.0, 0.0);

    vec3 color = vec3(1.0);
    gl_FragColor = vec4(color, f);
}{@}VRHand.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uStatic;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;

#!SHADER: Vertex

#require(skinning.glsl)

void main() {
    vNormal = normalize(normalMatrix * normal);
    vUv = uv;
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    vec3 pos = position;

    if (uStatic < 0.5) {
        applySkin(pos, vNormal);
    }

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(fresnel.glsl)

void main() {
    gl_FragColor = vec4(uColor * (1.0 - getFresnel(vNormal, vViewDir, 5.0)), 1.0);
}{@}Composite.fs{@}uniform sampler2D tBloom;
uniform float uRGBStrength;
uniform float uNoise;
uniform float uVignette;
uniform float uDistortion;
uniform float uFakeBloom;
uniform vec2 uContrast;
uniform float uGradientIntensity;
uniform float uGradientSide;
uniform float uLocked;
uniform float uRippleTransition;
uniform float uHexScale;

uniform float uOverlayMix;
uniform vec3 uOverlayColor;

uniform float uError;
uniform vec3 uErrorColor;

uniform float uSuccess;
uniform vec3 uSuccessColor;

#require(range.glsl)
#require(transformUV.glsl)
#require(eases.glsl)
#require(simplenoise.glsl)
#require(rgbshift.fs)
#require(UnrealBloom.fs)
#require(contrast.glsl)
#require(blendmodes.glsl)
#require(mousefluid.fs)

#define S(r,v) smoothstep(9./resolution.y,0.,abs(v-(r)))
const vec2 s = vec2(1, 1.7320508);
const vec3 baseCol = vec3(1.0);
const float borderThickness = .02;

float calcHexDistance(vec2 p) {
    p = abs(p);
    return max(dot(p, s * .5), p.x);
}

float random(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 sround(vec4 i) {
    return floor(i + 0.5);
}

vec4 calcHexInfo(vec2 uv) {
    vec4 hexCenter = sround(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? vec4(offset.xy, hexCenter.xy) : vec4(offset.zw, hexCenter.zw);
}

vec3 getHexagons(vec2 uv) {
    vec2 hexUV = uv;
    float distort = 0.2 + sin(time*0.15) * 0.1;
    float distortion2 = 1.0 + smoothstep(0.1, 1.1, length(uv - 0.5)) * distort + sin(time*0.15) * 0.04;
    hexUV = scaleUV(uv, vec2(1.0, resolution.x/resolution.y));
    hexUV = scaleUV(hexUV, vec2(distortion2));
    hexUV = scaleUV(hexUV, vec2(uHexScale));
    vec4 hexInfo = calcHexInfo(hexUV);

    float totalDist = calcHexDistance(hexInfo.xy) + borderThickness;
    float rand = random(hexInfo.zw);
    float angle = atan(hexInfo.y, hexInfo.x) + rand * 5. + time;
    float sinOffset = sin(time * 0.2 + rand * 8.);
    float aa = 5. / resolution.y;

    vec3 hexagons = vec3(0.0);
    hexagons.x = 1.0-smoothstep(.51, .51 - aa, totalDist);
    hexagons.y = pow(1. - max(0., .5 - totalDist), 10.) * 1.5;
    hexagons.z = sinOffset;

    return hexagons;
}

void main() {
    float len = length(vUv - 0.5);
    vec3 hexagons = getHexagons(vUv);

    vec2 uv = vUv;
    uv *= 1.0+hexagons.y*hexagons.z*0.04*smoothstep(0.4, 1.4, len);

    float value = uRippleTransition;
    float squareLen = length(scaleUV(vUv, vec2(1.0, resolution.x/resolution.y)) - 0.5);
    float ripple = smoothstep(value+0.2, value, squareLen) * smoothstep(value-0.2, value, squareLen) * uRippleTransition;
    uv = scaleUV(uv, vec2(1.0+ripple*0.15*smoothstep(0.1, 0.3, uRippleTransition)*smoothstep(1.0, 0.8, uRippleTransition)));

    vec3 color;

    float distortion = sineIn(crange(len, 0.0, 0.8, 1.0, uDistortion));
    uv = scaleUV(uv, vec2(distortion));

    #test Tests.renderRGBShift()
    color = getRGB(tDiffuse, uv, 0.3, 0.001 * uRGBStrength + 0.012*ripple).rgb;
    #endtest

    #test !Tests.renderRGBShift()
    color = texture2D(tDiffuse, uv).rgb;
    #endtest

    color = adjustContrast(color, uContrast.x, uContrast.y);

    #test Tests.renderBloom()
    color += getUnrealBloom(uv);
    #endtest

    #test !Tests.renderBloom()
//    color *= uFakeBloom;
    #endtest

    //color *= crange(getNoise(vUv, time), 0.0, 1.0, uNoiseMin, 1.0);
    color += crange(getNoise(vUv, time), 0.0, 1.0, -uNoise*0.5, uNoise*0.5);
    color = mix(color, color*smoothstep(0.7, 0.3, len), uVignette);//quarticOut(crange(len, 0.0, 0.5, 1.0, uVignetteMin));


    if (uOverlayMix > 0.0 || uError > 0.0) {
        float fluidMask = 0.0;//smoothstep(0.0, 1.0, texture2D(tFluidMask, vUv).r);
        float fluidOutline = 0.0;//smoothstep(0.0, 0.2, fluidMask) * smoothstep(1.0, 0.2, fluidMask);
        vec2 fluid = vec2(0.0);

        #test Tests.renderMouseFluid()
        fluidMask = smoothstep(0.0, 1.0, texture2D(tFluidMask, vUv).r);
        fluidOutline = smoothstep(0.0, 0.2, fluidMask) * smoothstep(1.0, 0.2, fluidMask);
        fluid = texture2D(tFluid, vUv).xy * fluidMask;
        #endtest

        vec3 overlayColor = mix(uOverlayColor, uErrorColor, uError);
        overlayColor = mix(overlayColor, uSuccessColor, uSuccess);
        vec3 hexColor = overlayColor * hexagons.x;
        hexColor *= crange(cnoise(vUv*20.0+time*0.1), -1.0, 1.0, 0.1, 1.0);
        hexColor += hexagons.z * mix(0.05, 0.3, fluidMask);
        hexColor += hexagons.y * 0.3;

        float mixOverlay = uOverlayMix * 0.5 + fluidMask;
        mixOverlay += uError*0.6;
        mixOverlay += uSuccess*0.15;
        mixOverlay += uLocked * 0.5;
        mixOverlay *= crange(cnoise(vUv*2.2+time*0.1), -1.0, 1.0, 0.5, 1.0);
        mixOverlay *= smoothstep(0.3-uError*0.2-uSuccess*0.2, 1.4, len);

        color = mix(color, blendSoftLight(color, hexColor), mixOverlay);
        color = mix(color, blendAdd(color, hexColor), mixOverlay*uLocked*0.5);

        color = mix(color, blendSoftLight(color, overlayColor), smoothstep(0.3, 1.4, len)*max(uError, uSuccess)*0.7);
    }

    gl_FragColor = vec4(color, 1.0);
}
{@}LineStructureGeometry.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uValue;
uniform float uRange;
uniform sampler2D tInside;
uniform float uTransparent;
uniform float uDistortStrength;
uniform float uTimeScale;
uniform float uShowLines;
uniform vec3 uColor;
uniform float uColorNScale;
uniform vec3 uHSL;
uniform float uTransition;
uniform float uTransitionPadding;
uniform float uTransitionHeight;
uniform float uTransitionType;
uniform float uGlassDarken;
uniform vec3 uMod;
uniform vec2 uFog;
uniform vec4 uDamage;
uniform vec3 uDamageColor;

#!VARYINGS
varying vec3 vWorldPos;
varying vec3 vPos;

#!SHADER: Vertex

#require(glass.vs)

void main() {
    setupGlass(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vPos = position;
    vWorldPos = vec3(modelMatrix * vec4(position, 1.0));
}

#!SHADER: Fragment

#require(glass.fs)
#require(simplenoise.glsl)
#require(eases.glsl)
#require(rgb2hsv.fs)

void main() {
    float f = fract((vPos.y * uRange) + time*uTimeScale);
    float lines = smoothstep(uValue - 0.1, uValue + 0.1, f);
    lines *= crange(lines, 1.0, 0.9, 0.0, 1.0);
    lines *= mix(1.0, 0.5, step(mod(vPos.y * uMod.x, uMod.y), uMod.z));
//    if (alpha < 0.01) discard;
//    vec4 color = vec4(vec3(1.0), alpha);
//    gl_FragColor = color;

    vec3 normal = normalMatrix * (gl_FrontFacing == false ? -vNormal : vNormal);

    gl_FragColor = getGlass(normal);
    gl_FragColor.rgb = crange(gl_FragColor.rgb, vec3(0.0), vec3(1.0), vec3(0.0), vec3(uGlassDarken));

    vec3 color = rgb2hsv(uColor);
    float n = cnoise(vPos * uColorNScale);
    color += n * uHSL * 0.1;
    color = hsv2rgb(color);

    gl_FragColor.rgb *= color;

    if (uShowLines > 0.0) {
        gl_FragColor.a += lines;
        gl_FragColor.rgb = mix(gl_FragColor.rgb, color, lines);
    }

    if (uTransitionType < 0.5) gl_FragColor.a *= rangeTransition(uTransition, vPos.y / uTransitionHeight, uTransitionPadding);
    else gl_FragColor.a *= rangeTransition(uTransition, length(vPos) / uTransitionHeight, uTransitionPadding);
    gl_FragColor.a *= sineOut(crange(length(cameraPosition - vWorldPos), uFog.x, uFog.x + uFog.y, 1.0, 0.0));

    float damage = crange(length(uDamage.xyz - vWorldPos), 0.0, uDamage.w, 1.0, 0.0);
    gl_FragColor.rgb *= mix(vec3(1.0), uDamageColor, damage);
}{@}LineStructureLines.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uTransition;
uniform float uTransitionPadding;
uniform float uLineCount;
uniform float uColorNScale;
uniform vec3 uHSL;
uniform float uAlpha;

#!VARYINGS
varying vec3 vPos;

#!SHADER: Vertex
void main() {
    vPos = pos;
}

#!SHADER: Fragment

#require(rgb2hsv.fs)
#require(simplenoise.glsl)

void main() {
    alpha *= rangeTransition(uTransition, (vUv.x + vLineIndex) / uLineCount, uTransitionPadding);

    color = rgb2hsv(uColor);
    float n = cnoise(vPos * uColorNScale);
    color += n * uHSL * 0.1;
    color = hsv2rgb(color);

    gl_FragColor = vec4(color, alpha * uAlpha);
}{@}LineStructureParticles.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform float DPR;
uniform float uSize;
uniform vec2 uScale;
uniform vec2 uLifeFade;
uniform sampler2D tLifeData;
uniform sampler2D tPos;
uniform sampler2D tMask;
uniform float uAlpha;
uniform float uMinAlpha;
uniform vec3 uColor;
uniform vec3 uHSL;
uniform vec2 uFog;
uniform float uColorNScale;
uniform float uSplineCount;
uniform float uTransition;
uniform float uTransitionPadding;
uniform float uTransitionRadius;
uniform vec4 uDamage;
uniform vec3 uDamageColor;

#!VARYINGS
varying float vAlpha;
varying vec3 vColor;

#!SHADER: Vertex

#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)
#require(rgb2hsv.fs)

void main() {
    vec3 lifeData = texture2D(tLifeData, position.xy).xyz;
    float life = lifeData.z;
    float splineIndex = lifeData.x;

    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    vec3 worldPos = vec3(modelMatrix * vec4(pos, 1.0));

    float size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    size *= uSize * crange(random.w, 0.0, 1.0, uScale.x, uScale.y);

    vAlpha = crange(random.y, 0.0, 1.0, uMinAlpha, 1.0) * uAlpha;
    vAlpha *= crange(life, uLifeFade.y, 0.99, 1.0, 0.0);
    vAlpha *= crange(life, 0.01, uLifeFade.x, 0.0, 1.0);
    vAlpha *= sineOut(crange(length(cameraPosition - worldPos), uFog.x, uFog.x + uFog.y, 1.0, 0.0));

    if (uTransitionRadius < 0.01) {
        vAlpha *= rangeTransition(uTransition, (life + splineIndex) / uSplineCount, uTransitionPadding);
    } else {
        vAlpha *= rangeTransition(uTransition, length(pos) / uTransitionRadius, uTransitionPadding);
    }

    vec3 color = rgb2hsv(uColor);
    float n = cnoise(pos * uColorNScale);
    color += n * uHSL * 0.1;
    color = hsv2rgb(color);
    vColor = color;

    gl_PointSize = size;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    float damage = crange(length(uDamage.xyz - worldPos), 0.0, uDamage.w, 1.0, 0.0);
    vColor *= mix(vec3(1.0), uDamageColor, damage);
}

#!SHADER: Fragment
void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    vec2 mask = texture2D(tMask, uv).rg;

    if (mask.g < 0.01) discard;

    gl_FragColor = vec4(vColor, vAlpha * mask.g);
}{@}PointCloudGazeDistortion.fs{@}uniform sampler2D tPointCloud;
uniform sampler2D tInputPos;
uniform mat4 uModelMatrix;
uniform mat4 uInvCamera;
uniform float uMaxCount;
uniform float uSetup;
uniform float uMultiplierMin;
uniform vec2 uGazeRad;
uniform vec2 uFar;
uniform float HZ;
uniform float uLerp;
uniform float uShapeScale;

#require(range.glsl)

void main() {
    vec2 uv = vUv;

    if (vUv.x + vUv.y * fSize > uMaxCount) {
        gl_FragColor = vec4(9999.0);
        return;
    }

    vec4 data = getData4(tInput, uv);

//    vec3 shape = texture2D(tPointCloud, vUv).xyz;
//    vec3 moshape = vec3(uModelMatrix * vec4(shape, 1.0));

    vec3 pos = texture2D(tInputPos, vUv).xyz;
    pos *= uShapeScale;

    vec3 worldPos = vec3(uModelMatrix * vec4(pos, 1.0));
    vec3 invPos = vec3(uInvCamera * vec4(worldPos, 1.0));

    float target = uMultiplierMin;

    if (invPos.z < 0.0) {
        float gazeMin = uGazeRad.x;
        float gazeMax = uGazeRad.x + uGazeRad.y;
        float gazeScalar = crange(invPos.z, 0.0, uFar.x, 1.0, uFar.y);
        gazeMin *= gazeScalar;
        gazeMax *= gazeScalar;
        target = crange(abs(invPos.x), gazeMin, gazeMax, 1.0, uMultiplierMin);
    }

    data.x += (target - data.x) * uLerp * HZ;

    if (uSetup > 0.5) data = vec4(1.0);

    gl_FragColor = data;
}{@}PointCloudLines.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform float uThickness;
uniform float uYScale;
uniform float uYTime;
uniform float uYStrength;
uniform float uTransition;
uniform float uTransitionPadding;
uniform float uLineCount;
uniform float uByLine;
uniform float uMouseStrength;
uniform vec3 uPulse;
uniform sampler2D tFluid;
uniform sampler2D tFluidMask;
uniform mat4 uProjNormalMatrix;
uniform mat4 uProjMatrix;
uniform vec2 uFog;
uniform vec2 uColorNoise;

#!VARYINGS
varying float vFog;
varying vec3 vPos;

#!SHADER: Vertex

#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)
#require(glscreenprojection.glsl)

void main() {
//    vFeather = 0.5;
    lineWidth = uThickness;

    vec3 mpos = vec3(modelMatrix * vec4(pos, 1.0));
    vec2 screenUV = getProjection(mpos, uProjMatrix);
    vec3 flow = vec3(texture2D(tFluid, screenUV).xy, 0.0);
    applyNormal(flow, uProjNormalMatrix);
    float fluidStrength = 1.0;//crange(random.y, 0.0, 1.0, 0.5, 1.0);
//    fluidStrength *= crange(length(cameraPosition - pos), 0.0, uMouseFar, 1.0, 0.5);
    vec3 fluidFlow = flow * 0.0001 * uMouseStrength * 1.0 * texture2D(tFluidMask, screenUV).r;

    float depth = length(mpos - cameraPosition);
    vFog = sineOut(crange(depth, uFog.x, uFog.x + uFog.y, 1.0, 0.0));

    float offset = cnoise(pos * uYScale * 0.001 + (time*0.1*uYTime)) * uYStrength;
    pos.y += offset;
    prevPos.y += offset;
    nextPos.y += offset;
    pos += fluidFlow;
    prevPos += fluidFlow;
    nextPos += fluidFlow;

    vPos = pos;
}

#!SHADER: Fragment

#require(rgb2hsv.fs)
#require(simplenoise.glsl)

void main() {
    alpha *= uAlpha;

    float x = uByLine > 0.5 ? (vUv.x + vLineIndex) / uLineCount : vUv.x;
    alpha *= rangeTransition(uTransition, x, uTransitionPadding);
    float offset = vLineIndex * uPulse.z;
    float tmod = mod(((time + offset)*0.4), 2.0);
    alpha *= mix(1.0, uPulse.x, rangeTransition(tmod > 1.0 ? 1.0 - (tmod - 1.0) : tmod, vUv.x, uPulse.y));
    alpha *= vFog;
    alpha *= crange(sin(vLineIndex * 100.0), -1.0, 1.0, 0.3, 1.0);

    color = rgb2hsv(uColor);
    color.x += cnoise(vPos * uColorNoise.x * 0.1) * 0.1 * uColorNoise.y;
    color = hsv2rgb(color);

    gl_FragColor = vec4(color, alpha);
}{@}PointCloudShader.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform sampler2D tPointColor;
uniform sampler2D tPos;
uniform sampler2D tMask;
uniform sampler2D tFinalShape;
uniform sampler2D tGazeDistortion;
uniform sampler2D tColorRamp;
uniform float uSize;
uniform float DPR;
uniform float uDOFStrength;
uniform vec2 uNear;
uniform vec2 uFar;
uniform vec2 uDOFScale;
uniform vec2 uDOFAlpha;
uniform vec3 uColor;
uniform float uColorOverride;
uniform float uAlpha;
uniform float uTransition;
uniform float uTransitionPadding;
uniform float uTransitionAxis;
uniform vec2 uScale;
uniform vec2 uFog;
uniform vec2 uShapeBound;
uniform float uDesaturate;
uniform vec3 uHSL;
uniform float uColorNScale;
uniform float uDFScalar;
uniform float uColorRampMix;
uniform float uRampBlend;
uniform vec3 uTint;
uniform float uAirmanBlend;
uniform vec2 uAirmanCenter;
uniform float uAirmanBlendScale;
uniform float uRippleAlpha;

uniform vec3 uSoundPos;
uniform float uRippleFrequency;
uniform float uRippleAmplitude;
uniform float uRippleRadialLength;
uniform float uRippleSpeed;
uniform float uRippleHeightLength;
uniform vec2 uRippleAngle;


// Cavity uniforms
uniform vec3 uCavityPos;
uniform float uCavityRadius;
uniform float uCavityFalloff;
uniform float uCavityPower;

#!VARYINGS
varying vec3 vColor;
varying vec3 vPos;
varying float vBlur;
varying float vAlpha;
varying float vRot;
varying float vTransition;
varying float vParticleTransition;
varying vec4 vRandom;
varying vec4 vMvPosition;

varying float vRippleDistance;

#!SHADER: Vertex

#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)
#require(rgb2hsv.fs)
#require(desaturate.fs)

void main() {
    vRandom = random;
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;


    vec3 soundPos = uSoundPos;
    soundPos.y -= 2.0;
    vec3 rippleVector = vec3(0., 0., 0.);
    vec3 ripplePos = pos - soundPos;

    float ll = length(ripplePos.xyz);

    //The ripples are plannar, these rotations allow to make the ripples
    //in any direction.
    float c = cos(radians(uRippleAngle.x));
    float s = sin(radians(uRippleAngle.x));
    mat3 rotationX = mat3(1., 0., 0., 0., c, s, 0., -s, c);

    c = cos(radians(uRippleAngle.y));
    s = sin(radians(uRippleAngle.y));
    mat3 rotationY = mat3(c, 0., s, 0., 1., 0., -s, 0., c);

    rippleVector = rotationY * rotationX * rippleVector;

    //amplitude limited by the radial distance
    float radius = clamp(uRippleRadialLength - ll, 0., uRippleRadialLength) / uRippleRadialLength;
    float amplitude = uRippleAmplitude * radius;

    //amplitude limited by the height distance
    //amplitude *= clamp(uRippleHeightLength - abs(ripplePos.y), 0., uRippleHeightLength) / uRippleHeightLength;

    //wave ripple
    vec3 ripple = amplitude * sin(uRippleFrequency * ll * radius - uRippleSpeed * time) * rippleVector;

    pos += ripple;

    float rippleRadius = clamp(uRippleRadialLength - ll, 0., uRippleRadialLength) / uRippleRadialLength;
    vRippleDistance = uRippleAmplitude * radius * (0.7 + sin(uRippleFrequency * ll - uRippleSpeed * time) * rippleVector.y * 0.3);




    vec4 mPosition = modelMatrix * vec4(pos, 1.0);
    vec4 mvPosition = viewMatrix * mPosition;

    vParticleTransition = mix(0.5, 0.0, uTransition);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    float pSize = mix(uSize, 50.0, vParticleTransition*uAlpha);
    size *= pSize * crange(expoIn(random.w), 0.0, 1.0, uScale.x, uScale.y);

    vec3 oshape = texture2D(tFinalShape, position.xy).rgb;

    float axis = uTransitionAxis < 0.1 ? oshape.x : oshape.y;
    if (uTransitionAxis > 1.9) axis = oshape.z;
    if (uTransitionAxis > 2.9) axis = length(oshape);

    float mixValue = rangeTransition(uTransition, crange(axis, uShapeBound.x, uShapeBound.y, 0.0, 1.0), uTransitionPadding);
    vTransition = mixValue;

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    float near = crange(depth, uNear.x, uNear.x + uNear.y, 1.0, 0.0);
    float far = crange(depth, uFar.x, uFar.x + uFar.y, 0.0, 1.0);
    vBlur = max(near, far) * uDOFStrength;
    vAlpha = uAlpha;
    vAlpha *= mix(1.0, uDOFAlpha.x, near * uDOFStrength);
    vAlpha *= mix(1.0, uDOFAlpha.y, far * uDOFStrength);
    vAlpha *= mix(1.0, crange(depth, uFog.x, uFog.x + uFog.y, 1.0, 0.0), mixValue);
    vAlpha *= crange(depth, 0.1, 1.0, 0.0, 1.0);
    vAlpha *= crange(random.y, 0.0, 1.0, 0.5, 1.0);

    if (uDFScalar > 5.0) {
        float dfScalar = crange(uTransition, 0.5, 1.0, 6.0, 1.0);
        vAlpha *= crange(length(cameraPosition - mPosition.xyz), 5.0 * dfScalar, 15.0 * dfScalar, 0.0, 1.0);
    } else {
        float dfScalar = crange(uTransition, 0.5, 1.0, 3.0, 0.5);
        vAlpha *= crange(length(cameraPosition - mPosition.xyz), 3.0 * dfScalar, 5.0 * dfScalar, 0.0, 1.0);
    }

    // Create cavity if point is within radius
    //    if (uCavityRadius > 0.0) {
    //        float cavityDist = distance(uCavityPos.xz, pos.xz);
    //        float radiusOuter = max(0.0, uCavityRadius);
    //        float radiusInner = radiusOuter * min(0.99999, 1.0 - uCavityFalloff);
    //        float cavityInfluence = smoothstep(radiusOuter, radiusInner, cavityDist);
    //        vAlpha -= cavityInfluence * cavityInfluence;
    //    }

    vPos = pos;

    size *= 1.0 + sin(time*5.0+vRandom.x*20.0)*0.02;
    //size *= mix(2.0, 1.0, smoothstep(0.0, 0.3, vTransition));

    gl_PointSize = size * mix(1.0, uDOFScale.y, far * uDOFStrength) * mix(1.0, uDOFScale.x, near * uDOFStrength);
    gl_Position = projectionMatrix * mvPosition;

    vec3 pointColor = desaturate(texture2D(tPointColor, position.xy).rgb, uDesaturate) * uTint;
    vec3 color = mix(uColor, pointColor, mixValue * texture2D(tGazeDistortion, position.xy).x);
    vColor = mix(color, uColor, uColorOverride);
    vRot = dot(normalize(pos), vec3(0.0, 1.0, 0.0)) * radians(60.0);

    vColor = rgb2hsv(vColor);
    float n = cnoise(pos * uColorNScale);
    vColor += n * uHSL * 0.1;
    vColor = hsv2rgb(vColor);
}

#!SHADER: Fragment

#require(range.glsl)
#require(shadows.fs)
#require(transformUV.glsl)
#require(blendmodes.glsl)
#require(rgb2hsv.fs)

void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    vec2 mask = texture2D(tMask, uv).rg;
    float blurredMask = mix(mask.g, mask.r, vBlur);
    if (blurredMask < 0.01) discard;

    if(length(vPos.xz - uAirmanCenter) < 1.5 * uAirmanBlendScale && uAirmanBlend > 0.) discard;

    vec3 color = vColor;
    vec2 luv = rotateUV(uv, vRot);
    color *= crange(luv.y, 0.0, 1.0, 0.8, 1.2);

    color *= crange(smoothstep(0.3, 1.0, luv.y)*0.5 - smoothstep(0.5, 1.1, 1.0-luv.y)*0.2, 0.0, 0.3, 0.7, 1.2);
    color += sin(time*10.0+vRandom.z*20.0)*vParticleTransition;

    float luma = rgb2hsv(color).z;
    luma = mix(luma, vRandom.y, vParticleTransition);
    vec3 ramp = texture2D(tColorRamp, vec2(luma, 0.0)).rgb;
    color = mix(color, ramp, max(vParticleTransition, crange(luma, 0.0, 0.4, 1.0, uColorRampMix)*uRampBlend));

    float alpha = blurredMask * vAlpha;
    //alpha *= 1.0 + 1.0*mix(vRippleDistance, 0.0, vRandom.y*0.3);

    //color *= mix(1.0, 1.2+vRandom.z*0.7, smoothstep(0.0, 0.8, uTransition) * smoothstep(1.0, 0.7, uTransition));
    //vec3 flash = vec3(0.6+sin(time*4.0+vRandom.z*20.0)*0.3, 0.0, 0.0);
    //color = vec3(uTransition, 0.0, 0.0);

    if (uAirmanBlend == 0.0) {
        float flicker = 0.8 + sin(time*3.0+vRandom.x*20.0)*0.5 + sin(time*10.0+vRandom.x*20.0)*0.5;
        vec3 flashColor = mix(vec3(1.0), vec3(1.0), vRippleDistance);
        color = mix(color, flashColor, vRippleDistance*flicker*smoothstep(0.9, 1.0, uTransition));
        alpha = mix(alpha, 1.0, vRippleDistance*flicker*blurredMask*smoothstep(0.9, 1.0, uTransition));
        alpha *= range(uTransition, 0.0, 0.1, 0.0, 1.0);
    }

    if (uAirmanBlend > 0.0) {
        alpha *= 0.6+sin(time*5.0+vRandom.z*20.0)*0.4;
    } else {
        alpha *= 0.9+sin(time*5.0+vRandom.z*20.0)*0.1;
    }

    gl_FragColor = vec4(color, alpha);
}
{@}PointCloudTubes.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tLifeData;
uniform sampler2D tRandom;
uniform vec2 uLifeFade;
uniform float uAlpha;
uniform float uTransition;
uniform float uTransition2;
uniform float uTransitionPadding;
uniform vec3 uColor;
uniform vec2 uColorNoise;
uniform vec2 uFog;
uniform vec2 uFade;
uniform float uTail;
uniform float uHide;

#!VARYINGS
varying float vAlpha;

#!SHADER: Vertex

#require(range.glsl)

void extrudeTube() {
    vec4 random = texture2D(tRandom, iuv);
    scale *= crange(random.y, 0.0, 1.0, 0.25, 1.5);
}

void main() {
    float splineLife = texture2D(tLifeData, iuv).z;
//    vec4 random = texture2D(tRandom, iuv);

    vAlpha = uAlpha;
    vAlpha *= crange(splineLife, uLifeFade.y, 0.95, 1.0, 0.0);
    vAlpha *= crange(splineLife, 0.05, uLifeFade.x, 0.0, 1.0);
    vAlpha *= crange(random.x, 0.0, 1.0, uFade.x, 1.0);
    vAlpha *= crange(vLength, uTail, 1.0, 1.0, uFade.y);
    vAlpha *= rangeTransition(uTransition, vLength, uTransitionPadding);
    vAlpha *= rangeTransition(uTransition2, random.x, uTransitionPadding);
    vAlpha *= smoothstep(uHide-0.01, uHide+0.01, random.z);
}

#!SHADER: Fragment
varying vec3 vPos;
varying vec2 vUv;

#require(rgb2hsv.fs)
#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)

void main() {
    if (vAlpha < 0.01) discard;

    vec3 color = rgb2hsv(uColor);
    color.x += cnoise(vPos * uColorNoise.x * 0.1) * 0.1 * uColorNoise.y;
    color = hsv2rgb(color);
    color *= crange(length(vUv.x - 0.5), 0.0, 0.5, 0.7, 1.0);

    float alpha = vAlpha;
    float depth = length(vec3(modelMatrix * vec4(vPos, 1.0)) - cameraPosition);
    alpha *= sineOut(crange(depth, uFog.x, uFog.x + uFog.y, 1.0, 0.0));

    gl_FragColor = vec4(color, alpha);
}{@}LevelTestShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    setupBase(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    if (transitionDiscard()) discard;
    gl_FragColor = vec4(1.0);
}{@}BaseLevelFloorShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uLightDir;
uniform sampler2D tNoise;
uniform sampler2D tShadow;
uniform sampler2D tGradient;
uniform vec2 uNoiseUv;
uniform float uNoiseStrength;
uniform vec2 uNoiseOffset;
uniform float uNoiseSpeed;
uniform float uWave;
uniform vec2 uDepthRange;
uniform vec2 uValueRange;
uniform float uHeightOffset;
uniform vec2 uShadowNoiseUv;

uniform float uTile;
uniform float uLineThickness;
uniform float uLineDistance;

uniform float uShockwaveStrength;
uniform float uShockwaveProgress;
uniform float uShockwaveWidth;


#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying float vNoise;
varying vec2 vNoiseUv;
varying vec3 vPos;
varying float vDepth;
varying float vShadowNoise;
varying float vShockwave;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    setupBase(position);
    vec3 pos = position;

    vec3 instancePos = vec3(1.0);
    #ifdef INSTANCED
    instancePos = offset;
    #endif

    vec2 noiseUv = instancePos.xz * uNoiseUv + uNoiseOffset + vec2(0.0, time * uNoiseSpeed);
    float noise = texture2D(tNoise, noiseUv).r;

    pos.y += crange(noise, 0.0, 1.0, -1.0, 0.0) * uNoiseStrength;
    pos.y += length(instancePos.xz * uWave);
    pos.y += uHeightOffset;

    float circularGradient = length(instancePos.xz * 0.01);
    float shockwave = smoothstep(uShockwaveProgress, uShockwaveProgress + uShockwaveWidth, circularGradient);
    shockwave += (1.0 - smoothstep(uShockwaveProgress - uShockwaveWidth, uShockwaveProgress, circularGradient));
    shockwave = 1.0 - shockwave;
    shockwave = mix(0.0, shockwave, uShockwaveStrength) * smoothstep(0.05, 0.1, circularGradient);

    pos.y += shockwave + shockwave * (cnoise(instancePos.xz * 0.2) * 0.5);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vNormal = normal;
    vNoise = noise;
    vNoiseUv = noiseUv;
    vPos = pos;

    vDepth = crange(vPos.x, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vDepth *= crange(vPos.x, -uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vDepth *= crange(vPos.z, -uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vDepth *= crange(vPos.z, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vDepth = pow(vDepth * 1.4, 2.0);

    vShadowNoise = cnoise(vPos.xz * uShadowNoiseUv + vec2(time, time) * 0.15) * 0.08;

    vUv = uv;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    float depth = vDepth;

    float dp = dot(vNormal, uLightDir);
    dp = clamp(dp, 0.45, 0.57);

    float value = mix(1.0, vNoise, uNoiseStrength * 0.2) * depth * dp - vShadowNoise * depth;
    value = crange(value, uValueRange.x, uValueRange.y, 0.0, 1.0);

    float scanlines = mix(mod(vPos.z, uTile), 1.0, 0.92);
    value *= scanlines;

    // float square = 
    //     smoothstep(0.05, 0.06, vUv.x) - smoothstep(0.06, 0.07, vUv.x) +
    //     smoothstep(0.95, 0.96, vUv.x) - smoothstep(0.96, 0.97, vUv.x) +
    //     smoothstep(0.05, 0.06, vUv.y) - smoothstep(0.06, 0.07, vUv.y) +
    //     smoothstep(0.95, 0.96, vUv.y) - smoothstep(0.96, 0.97, vUv.y);
    // value += square;

    vec2 shadowUv = vPos.xz * 0.03 + vec2(0.5, 0.5);
    float shadow = crange(texture2D(tShadow, shadowUv).r, 0.0, 1.0, 0.5, 1.0);
    shadow = mix(1.0, shadow, 0.5);
    value *= shadow;


    vec4 color = texture2D(tGradient, vec2(value, 0.0));
    // color = vec4(vShockwave);

    gl_FragColor = color;
    gl_FragColor.a = 0.1;
}{@}AmbientParticleShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uSize;
uniform float uVRSize;
uniform float uIsVR;
uniform float uAlpha;
uniform float uAlpha2;
uniform vec2 uFadeRange;
uniform vec3 uColor;
uniform vec3 uColor2;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vMvPos;

#!SHADER: VertexShader.vs

#require(BaseShader.vs)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    setupBase(pos);
    
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01;

    if (uIsVR > 0.0) {
        size *= uVRSize;
    } else {
        size *= uSize;
    }

    gl_PointSize = size;
    gl_Position = projectionMatrix * mvPosition;

    vPos = pos;
    vMvPos = mvPosition.xyz;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    float dist = 1.0 - distance(uv, vec2(0.5));
    dist = crange(dist, 0.5, 1.0, 0.0, 1.0);

    // gl_FragColor.rgb = mix(uColor, uColor2, );
    // gl_FragColor.rgb = vec3(dist);
    // gl_FragColor.rgb = vec3(1.0);
    gl_FragColor.rgb = uColor;
    gl_FragColor.a = dist * uAlpha * uAlpha2 * crange(length(vPos), uFadeRange.x, uFadeRange.y, 0.0, 1.0) * crange(vMvPos.z, -0.3, -1.0, 0.0, 1.0);
}{@}CeilingParticleShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGradient;
uniform float uSize;
uniform vec2 uDepthRange;
uniform float uNoiseScale;
uniform float uNoiseSpeed;
uniform float uNoiseStrength;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: VertexShader.vs

#require(BaseShader.fs)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    // pos.x = floor(pos.x * 3.0) / 3.0;
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01;
    size *= uSize;

    gl_PointSize = size;
    gl_Position = projectionMatrix * mvPosition;
    vPos = pos;
}

#!SHADER: FragmentShader.fs

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    float depthFade = crange(vPos.z, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    if (depthFade < 0.1) discard;
    vec2 uv = vec2(gl_PointCoord.x, -gl_PointCoord.y + 1.0);
    float circle = 1.0 - length(uv);
    float sideFade = 1.0 - abs(sin(vPos.x * 0.1));

    float noise = cnoise(vPos.xz * uNoiseScale + vec2(0.0, time) * uNoiseSpeed);
    noise = clamp(noise, 1.0 - uNoiseStrength, 1.0);
    noise = 0.7 * sideFade, depthFade * noise;

    vec3 color = texture2D(tGradient, vec2(circle * noise, 0.0)).rgb;

    gl_FragColor.rgb = color;
    gl_FragColor.a = 1.0;
}{@}BaseLevelPlatformShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGrid;
uniform sampler2D tGradient;
uniform float uTile;
uniform float uTile2;
uniform float uSpeed;
uniform float uSpeed2;
uniform vec2 uRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    vec3 pos = position;
    setupBase(pos);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vNormal = normal;
    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;
    
    float noise = cnoise(vUv + vec2(time, time * 0.1));
    vec3 color = texture2D(tMap, vUv * uTile + vec2(time * uSpeed * 0.5, time * uSpeed)).rgb;
    color *= texture2D(tMap, vUv * uTile2 + vec2(time * uSpeed2, time * uSpeed2) ).rgb;

    vec3 grid = texture2D(tGrid, vUv).rgb;
    color = grid * vec3(smoothstep(uRange.x, uRange.y, color.r));
    color += grid.r * 0.1;
    color += 0.03;

    color = texture2D(tGradient, vec2(color.r * 1.3, 0.0)).rgb;
    
    gl_FragColor.rgb = color;
    gl_FragColor.a = 1.0;
}{@}BaseLevelPlatformSolidShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGradient;
uniform float uBrightness;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    vec3 pos = position;
    setupBase(pos);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vNormal = normal;
    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    vec3 color = texture2D(tMap, vUv).rgb;
    
    gl_FragColor.rgb = color * uBrightness;
    gl_FragColor.a = 1.0;
}{@}RingShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tLightmap;
uniform sampler2D tGradient;
uniform float uSpeed;
uniform float uDelay;
uniform float uTile;
uniform float uLineThickness;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vOffset;
varying float vFade;
varying float vScanlineFade;

#!SHADER: Vertex

#require(BaseShader.vs)

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main() {
    vec3 pos = position;
    float t = time * uSpeed;
    float zOffset = (fract(t / 10.0) * 10.0);
    pos.z += zOffset;
    setupBase(pos);

    vec3 instancePos = vec3(1.0);
    #ifdef INSTANCED
    instancePos = offset + zOffset;
    #endif

    pos.xy = rotate(pos.xy, instancePos.z * uDelay);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vOffset = offset;
    vPos = pos;
    vFade = crange(abs(pos.z), 0.0, 150.0, 1.0, 0.0);
    vScanlineFade = crange(abs(pos.z), 10.0, 50.0, 1.0, 0.0);
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    vec4 color = texture2D(tLightmap, vUv);

    float scanlines = mod(vPos.y, uTile);
    color += scanlines;

    color = mix(vec4(0.5, 0.5, 0.5, 1.0), color, vScanlineFade);

    color = texture2D(tGradient, vec2(color.r, 0.0));
    color *= vFade;
    gl_FragColor = color;
}{@}BaseLevelSkyShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tGradient;
uniform vec2 uDepthRange;
uniform vec2 uHeightRange;
uniform float uFresnel;
uniform float uNoiseScale;
uniform float uNoiseSpeed;
uniform float uNoiseStrength;
uniform vec2 uValueRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;
varying float vDepth;
varying vec3 vViewDir;
varying float vHorizon;


#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    setupBase(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);

    vNormal = normalMatrix * normal;
    vDepth = crange(position.z, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    vHorizon = pow(crange(position.y, uHeightRange.x, uHeightRange.y, 0.0, 1.0), 2.0);
    vUv = uv;
    vPos = position;
}

#!SHADER: Fragment

#require(BaseShader.fs)
#require(fresnel.glsl)

void main() {
    // if (transitionDiscard()) discard;
    
    float noise = cnoise(vUv * uNoiseScale + vec2(0.0, time) * uNoiseSpeed);
    vec3 normal = normalize(vNormal);
    float fresnel = 1.0 - getFresnel(normal, vViewDir, uFresnel);
    float value = fresnel * vHorizon - clamp(noise * uNoiseStrength, 0.0, 1.0) * vHorizon;
    value *= clamp(-vPos.z, 0.2, 1.0);
    value = crange(value, uValueRange.x, uValueRange.y, 0.0, 1.0);
    vec4 color = texture2D(tGradient, vec2(value, 0.0));
    gl_FragColor = color;
}{@}BackgroundSphere.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uBrightness;
uniform float uNoiseScale;
uniform float uNoiseSpeed;
uniform sampler2D tColorRamp;
uniform vec2 uColorRange;
uniform float uVisible;
uniform float uDark;
uniform float uError;
uniform float uLevelChange;
uniform float uSaturation;
uniform vec3 uErrorColor;
uniform float uContrastAdjust;

#!VARYINGS
varying vec3 vPos;
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;

    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)
#require(blendmodes.glsl)
#require(rgb2hsv.fs)
#require(contrast.glsl)
#require(levels.glsl)

void main() {
    float noise = 1.0;

    #test Tests.backgroundSphereNoise()
    noise = cnoise(vPos * uNoiseScale * 2.0 + time * uNoiseSpeed * 0.1 + uColorRange.x + uColorRange.y + uLevelChange*0.5);
    #endtest

    float bgNoise = crange(noise, -1.0, 1.0, uColorRange.x, uColorRange.y+uLevelChange*0.5);
    bgNoise += getNoise(vUv, time) * 0.01;
    //bgNoise = mix(bgNoise, mix(0.95, 0.05, uDark), 1.0-uVisible);
    bgNoise += uBrightness;

    vec3 color = texture2D(tColorRamp, vec2(mix(bgNoise, 1.0, smoothstep(0.2, 1.0, uLevelChange)*0.7), 0.0)).rgb;

    color = rgb2hsv(color);
    color.y *= uSaturation;
    color = hsv2rgb(color);

    if (uError > 0.0) {
        float errorNoise = crange(cnoise(vPos * uNoiseScale * 5.0 + time * uNoiseSpeed * 2.0), -1.0, 1.0, 0.2, 1.0);
        color = mix(color, blendSoftLight(color, uErrorColor), uError * errorNoise * 0.7);
    }

    color = mix(color, adjustContrast(color, 0.5, 0.5), uContrastAdjust);

    //color += getNoise(vUv, time) * 0.05;

    gl_FragColor = vec4(color, 1.0);
}
{@}BaseShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS

#!SHADER: Vertex
#require(range.glsl)
#require(simplenoise.glsl)
#require(transition.vs)

void setupBase(vec3 pos) {
    setupTransition(pos);
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(transition.fs){@}SphereTransitionShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uNoiseSize;
uniform float uNoiseSpeed;
uniform sampler2D tMap;
uniform sampler2D tColorRamp;
uniform vec2 uColorRange;
uniform float uTransition;
uniform float uPadding;
uniform vec2 uTile;
uniform vec3 uNoiseOffset;
uniform float uNoiseStrength;

#!VARYINGS
varying vec3 vPos;
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    vPos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    float noise = cnoise(vPos * uNoiseSize * 3.0 + uNoiseOffset + vec3(0.0, 0.0, time * uNoiseSpeed)) * uNoiseStrength;
    float value = 1.0;

    // line texture
    vec3 tex = texture2D(tMap, vUv * uTile + vec2(noise)).rgb;

    // lines
    float transition1 = clamp(uTransition - 0.05, 0.0, 1.0);
    float lines = tex.r;
    lines *= 1.0 - smoothstep(transition1 - uPadding * 5.0, transition1, vUv.y);

    // dark gradient
    float transition2 = clamp(uTransition - 0.1, 0.0, 1.0);
    float gradient = vUv.y;
    gradient = 1.0 - smoothstep(transition2 - uPadding * 7.0, transition2, gradient);

    lines += gradient;
    lines = smoothstep(0.1, 0.45, lines);
    value = 1.0 - lines;

    vec3 color = texture2D(tColorRamp, vec2(value, 0.0)).rgb;
    gl_FragColor = vec4(color, 1.0);
}{@}LevelFog.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec4 uQuaternion;

#!VARYINGS

#!SHADER: Vertex
void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(vec3(1.0), 0.5);
}{@}TimerBackground.glsl{@}#!ATTRIBUTES


#!UNIFORMS
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

void main() {
    vec2 uv = vUv;

    float border = 0.0;
    float size = 0.03;
    border += step(uv.x, size);
    border += step(1.0 - uv.x, size);
    border += step(uv.y, size);
    border += step(1.0 - uv.y, size);

    gl_FragColor.rgb = mix(vec3(0.0), vec3(1.0), border);
    gl_FragColor.a = uAlpha;
}{@}transition.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float u_Transition;
uniform vec4 u_TNProps;

#!VARYINGS
varying vec3 vTransitionPos;

#!SHADER: Vertex
void setupTransition(vec3 pos) {
    vTransitionPos = vec3(modelMatrix * vec4(pos, 1.0));
}

#!SHADER: Fragment
bool transitionDiscard() {
    float n = cnoise((vTransitionPos + (time * 0.1 * u_TNProps.z)) * u_TNProps.x);
    return step(vTransitionPos.y + n*u_TNProps.y, u_Transition) < 1.0;
}{@}DomeAttackLinesShader.glsl{@}#!ATTRIBUTES
attribute vec2 uv2;

#!UNIFORMS
uniform float uProgress1;
uniform float uProgress2;
uniform float uProgress3;
uniform float uProgress4;
uniform float uAlpha;

//Use a single uniform.
uniform vec4 uProgress;

uniform vec3 uColor;
uniform vec3 uColor2;
uniform float uBrightness;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vMvPos;

#!SHADER: Vertex

float attackLine(vec2 uv, float progress, float strength, float len) {
    progress *= 1.042;

    float al = smoothstep(-len + progress, progress, uv.y) - smoothstep(progress - 0.03, progress + 0.01, uv.y);
    return al;
}

void main() {
    float al = attackLine(uv, uProgress1, 0.0, 0.11);
    al += attackLine(uv, uProgress2, 0.0, 0.11);
    al += attackLine(uv, uProgress3, 0.0, 0.11);
    al += attackLine(uv, uProgress4, 0.0, 0.11);

    vec3 pos = position;
    pos += normal * al * 0.7 * ((uv.x - 0.5) * 1.6);

    vec4 modelViewPos = modelViewMatrix * vec4(pos, 1.0);
    gl_Position = projectionMatrix * modelViewPos;
    vUv = uv;
    vPos = pos;
    vMvPos = modelViewPos.xyz;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

vec3 attackLine(vec2 uv, float progress, float strength, float len, vec3 color) {
    progress *= 1.04;

    float attackline = smoothstep(-len + progress, progress, uv.y) - smoothstep(0.008 + progress, 0.009 + progress, uv.y);
    float tip = attackline - smoothstep(progress, -0.03 + progress, uv.y - 0.01);
    tip *= 0.5 * strength;
    tip = clamp(tip, 0.0, 1.0);

    color *= attackline;
    color += vec3(tip);

    return color;
}

void main() {
    float brightness = 0.12;
    float attacklength = 0.1;
    float noise = 0.5 * cnoise(vec3(vPos.x, vUv.y, vUv.x) * vec3(1.0, 38.0, 2.0) + vec3(0.0, -time * 1.21, time * 1.1)) + 0.5;

    //Try using a power function but this can work.
    float startendfade = smoothstep(0.985, 0.975, vUv.y);
    startendfade *= smoothstep(0.05, 0.15, vUv.y);
    startendfade *= smoothstep(1.0, 0.8, vUv.x);
    startendfade *= smoothstep(0.0, 0.2, vUv.x);

    float pulse1 = 0.5 * sin(vUv.y * 23.0 * vPos.y + time * 2.0 + vUv.x) + 0.2;
    float pulse2 = 0.5 * sin(vUv.y * 78.0 - time * 4.1527 + vUv.x) + 0.5;
    float pulse3 = 0.5 * sin(vUv.y * 28.13 - time * 3.1517 + vUv.x) + 0.5;

    // always-present background line
    float line = startendfade + (pulse1 + pulse2 + pulse3) * startendfade;
    line *= brightness;

    float finelines = sin(vUv.y * 155.0 + noise + vUv.x * 20.0 - time * 2.0);
    finelines *= sin(vUv.x * 10.0);
    line *= finelines;

    // strobe
    float strobe = 0.5 * sin(vUv.y * 152.0) + 0.5;
    noise *= 2.0;
    // noise = step(0.3, noise);

    vec3 attackcolor = uColor;

    //Try encoding this four operations with a single call since smoothstep allows you
    //to work with vec4 (four values at once)
    vec3 attackline = attackLine(vUv, uProgress1, strobe, attacklength, attackcolor);
    attackline += attackLine(vUv, uProgress2, strobe, attacklength, attackcolor);
    attackline += attackLine(vUv, uProgress3, strobe, attacklength, attackcolor);
    attackline += attackLine(vUv, uProgress4, strobe, attacklength, attackcolor);

    attackline *= startendfade;
    attackline *= noise;
    attackline += line;

    attackline *= smoothstep(-45.0, -10.0, vMvPos.z);
    attackline *= uBrightness;

    gl_FragColor = vec4(attackline, uAlpha);
}{@}DetectAndInterceptBaseShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uFresnelPow;
uniform float uContrastMix;
uniform float uAlpha;
uniform float uHealth;

uniform float uMatcapIndex;
uniform float uBrightness;

uniform vec2 uFogRange;

uniform float uThreatLevel;
uniform float uHit;

uniform float uActivated;

uniform vec2 uColorRange;
uniform float uSaturation;
uniform float uFocused;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;
varying float vAlpha;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
    vNormal = normalMatrix * normal;
    vViewDir = -(modelViewMatrix * vec4(pos, 1.0)).xyz;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha = smoothstep(1.0, 3.0, depth);
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)
#require(rgb2hsv.fs)

void main() {
    float fresnel = getFresnel(normalize(vNormal), vViewDir, uFresnelPow);
    fresnel = mix(fresnel*0.1+0.1, fresnel, uActivated);

    float offset = crange(fresnel, 0.0, 1.0, -1.0, 1.0);
    float c = texture2D(tMap, ((gl_FragCoord.xy/resolution * 8.0) * offset + vec2(-time * 0.15))).r * fresnel;

    float matcap = texture2D(tMatcap, vMuv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0)).r;

    c *= 2.0;
    c += matcap;

    c = clamp(c, 0.0, 1.0);
    c = mix(c, mix(.1, 1., uMatcapIndex), uContrastMix);
    c *= uBrightness;

    vec3 red = vec3(1.0, 0.2, 0.2);

    float coreMid = 0.015 + uFocused*0.05;
    coreMid += cnoise(vPos*3.0+time*0.2)*0.002;
    float core = (1.0 - smoothstep(coreMid, coreMid-0.025, fresnel)) * (1.0 - smoothstep(coreMid, coreMid+0.002, fresnel));
    float avoidCore = (1.0 - smoothstep(coreMid+0.2, coreMid-0.1, fresnel));

    // Core
    c += core * uHealth * uActivated * (0.8 + sin(time*5.0) * 0.2);

    vec3 color = texture2D(tRamp, vec2(c, 0.0)).rgb;

    float threatLevel = uThreatLevel;
    threatLevel = max(threatLevel - 0.5, 0.0);
    float isActive = min(threatLevel, 1.0);
    float strobe = crange(sin(time * 4.0 * threatLevel - fresnel * 8.0), -1.0, 1.0, 0.0, 1.0);
    float flash = crange(sin(time * 4.0 * threatLevel), -1.0, 1.0, 0.0, 1.0);

    color -= strobe * 1.3 * isActive * avoidCore;
    color += red * strobe * 1.3 * isActive * avoidCore;
    color += red * flash * 0.5 * isActive * avoidCore;
    color += red * core * isActive;

    //color += core * flash * isActive;

    float hit = uHit;
    hit *= 3.0;
    color += vec3(1.0, 0.8, 0.8) * hit * avoidCore;

    float speed = 0.05;
    float noise = cnoise(vPos*0.6+time*speed+uActivated);
    noise = mix(noise, cnoise(vPos*2.5-time*speed*2.0), 0.15);
    color *= 1.0 + smoothstep(-0.2, 0.0, noise) * smoothstep(0.2, 0.0, noise) * 0.8 * uActivated;

    //color *= mix(0.2, 1.0, avoidCore);

    color *= crange(fresnel, 0.0, 1.0, 0.8, 1.0);
    color *= 1.0 + hit*0.2;

    color *= mix(0.6, 1.0, uActivated);

    float luma = rgb2hsv(color).z;
    vec3 final = texture2D(tRamp, vec2(crange(luma, 0.0, 1.0, uColorRange.x, uColorRange.y), 0.0)).rgb;

    final = rgb2hsv(final);
    final.y *= uSaturation;
    final = hsv2rgb(final);


    gl_FragColor.rgb = color;
    gl_FragColor.a = uAlpha;
    gl_FragColor.a *= vAlpha;
}
{@}DetectAndInterceptCoreShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS
#!SHADER: Vertex
void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(1.0);
}{@}DetectAndInterceptGlowShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uThreatLevel;
uniform float uHit;
uniform float uAlpha;
uniform float uActivated;

#!VARYINGS
varying vec2 vUv;
varying float vAlpha;

#!SHADER: Vertex
void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha = smoothstep(2.0, 4.0, depth);
}

#!SHADER: Fragment
#require(range.glsl)

void main() {
    float dist = distance(vUv, vec2(0.5));
    dist = (1.0 - smoothstep(0.1, 0.5, dist)) + (1.0 - smoothstep(0.1, 0.2, dist));

    float threatLevel = uThreatLevel;
    threatLevel = max(threatLevel - 0.5, 0.0);
    float isActive = min(threatLevel, 1.0);
    float flash = crange(sin(time * 4.0 * threatLevel), -1.0, 1.0, 0.0, 1.0);

    vec3 color = vec3(0.0);
    vec3 red = vec3(1.0, 0.2, 0.22);
    color += red * flash * 0.7 * dist * isActive * uActivated;
    color += smoothstep(0.65, 0.8, dist) * flash * isActive * uActivated;
    
    float hit = uHit;
    color += vec3(1.0, 0.8, 0.8) * hit * dist;

    gl_FragColor = vec4(color, uAlpha*uActivated);
    gl_FragColor.a *= vAlpha * smoothstep(-0.1, 0.5, length(vUv-0.5));
}{@}CyberAttackIndicatorShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uCircleColor;
uniform float uCircleRadius; 
uniform float uCircleAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(range.glsl)
#require(eases.glsl)

void main() {
    vec2 uv = vUv * 2. - 1.;
    float r = length( uv );

    //Border
  	float border = mix( 1., 0., smoothstep(0.01, 0.05, abs(r-uCircleRadius)));
    //Circle center

    float col = border;
    
    if(col < .01) {
        discard;
    }

    vec3 color = vec3(0.);
    float alpha = uCircleAlpha;

    gl_FragColor = vec4(uCircleColor, alpha * col);
}{@}CyberAttackArcShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform float uAlpha2;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex

void main() {
    vUv = uv;

    vec3 pos = position;


    pos.z += smoothstep(0.7, 1.0, uAlpha2)*0.06;
    pos.z -= (1.0-uAlpha)*0.4;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

float aastep(float threshold, float value) {
  float afwidth = 1.5 * length(vec2(dFdx(value), dFdy(value)));
  return smoothstep(threshold - afwidth, threshold + afwidth, value);
}

float arc(vec2 uv, float radius, float width) {
    return (1. - aastep(radius - width, length(uv))) * aastep(radius - 2. * width, length(uv));
}

void main() {

    vec2 st = 2. * vUv - 1.;

    gl_FragColor = vec4(vec3(0.0), smoothstep(1.0, 0.7, length(st))*0.2);

    float radius = 0.95 + smoothstep(0.7, 1.0, uAlpha2)*0.05;
    float thickness = 0.08 + smoothstep(0.7, 1.0, uAlpha2)*0.02;

    gl_FragColor += arc(st, radius, thickness) * vec4(uAlpha2);

    float circle = (radius - aastep(0.2, length(st)));
    gl_FragColor += vec4(vec3(1.), uAlpha2) * circle;

    #test Tests.usingVR()
        const float steps = 4.;
    #endtest

    #test !Tests.usingVR()
        const float steps = 6.;
    #endtest

    vec4 color = vec4(vec3(0.), 1.0);
    float divider = 0.;
    for(float i = 0.; i < steps; i ++) {
        for(float j = 0.; j < steps; j ++) {
            vec2 uv = vec2(i, j) / steps;
            uv = 2. * uv - 1.;
            uv *= 0.065;
            color += vec4(arc(uv + st, radius*0.75, thickness));
        }
    }

    color /= (steps * steps);
    gl_FragColor += color * uAlpha2;

    gl_FragColor.rgb *= uColor;

    float alpha = uAlpha;
    float flicker = 0.5+sin(time*22.0)*0.4+sin(time*50.0)*0.4;
    alpha = mix(alpha, alpha * flicker, smoothstep(0.0, 0.3, uAlpha) * smoothstep(1.0, 0.8, uAlpha));
    alpha = mix(alpha, alpha * flicker, smoothstep(0.7, 0.8, uAlpha2) * smoothstep(0.9, 0.8, uAlpha2) * 0.5);

    gl_FragColor.a *= alpha;
}
 {@}CyberAttackCorners.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;
uniform float uWidth;
uniform float uDither;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex

void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

float aastep(float threshold, float value) {
  float afwidth = 0.7 * length(vec2(dFdx(value), dFdy(value)));
  return smoothstep(threshold - afwidth, threshold + afwidth, value);
}

void main() {

    vec2 st = vUv;

    const float border = 0.005;
    const float length = 0.035;

    float rangeY = float(st.y < length || st.y > 1. - length);
    float rangeX = float(st.x < length || st.x > 1. - length);
    vec4 color = vec4(aastep(1. - border, st.x) * rangeY);
    color += vec4(aastep(1. - border, 1. - st.x) * rangeY);
    color += vec4(aastep(1. - border, 1. - st.y) * rangeX);
    color += vec4(aastep(1. - border, st.y) * rangeX);

    gl_FragColor = color;
    gl_FragColor.a *= uAlpha;
}
 {@}CyberAttackGestureGlowSphere.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 color;
uniform float uAlpha;

#!VARYINGS
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex
void main() {
    vec4 pos = modelViewMatrix * vec4(position, 1.0);

    vNormal = mat3(modelViewMatrix) * normal;
    vPos = pos.rgb;

    gl_Position = projectionMatrix * pos;
}

#!SHADER: Fragment
void main() {
    float intensity = pow(dot(normalize(vNormal), vec3(0., 0., 1.)), 6.);
    gl_FragColor = vec4(color * intensity, intensity * uAlpha);
}{@}CyberAttackShapeBG.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

void main() {
    vUv = uv;
    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

void main() {
    float alpha = uAlpha;
    alpha *= smoothstep(0.5, 0.1, length(vUv-0.5));

    gl_FragColor.rgb = vec3(0.0);
    gl_FragColor.a = alpha;
}{@}CyberAttackShapeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uPadding;
uniform float uTransition;
uniform float uSize;
uniform float uFrequency;
uniform float uAlpha;
uniform float uRange;

#!VARYINGS
varying float vTransition;
varying float vProgress;
#!SHADER: Vertex
void main() {
    vProgress = 1. - step(uTransition - uPadding, uv.x);
    lineWidth = mix(.7, 1.5, vProgress);
}

#!SHADER: Fragment
void main() {
    vec2 uv = vUv;
    float range = sin(uv.x *200. + -time * 15.);
    range = 0.5 * (range + 0.7);
    float dash = step(uSize, range);
    float wave = max(.6 , sin(-uv.x * 10. + time * 5.));
    vec3 diffuse = mix(vec3(dash), vec3(1.) * wave, vProgress);
    float display = float(uv.x <= uRange);
    float a11yAlpha = clamp(uAlpha * 2.6, 0., 1.);
    gl_FragColor = vec4(uColor, a11yAlpha * diffuse * display);
}
{@}CyberAttackSphere.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 color;
uniform float uAlpha;
uniform float uPower;

#!VARYINGS
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: CyberAttackSphere.vs
void main() {
    vec4 pos = modelViewMatrix * vec4(position, 1.0);

    vNormal = mat3(modelViewMatrix) * normal;
    vPos = pos.rgb;

    gl_Position = projectionMatrix * pos;
}

#!SHADER: CyberAttackSphere.fs
void main() {

    float indexOfReflection = 1.3;
    float R0 = pow((indexOfReflection - 1.) / (indexOfReflection + 1.), 2.);
    float R = R0 + (1. - R0) * pow(1. - dot(vNormal, normalize(cameraPosition - vPos)), uPower);
    vec3 color = mix(vec3(0.), color, vec3(R));

    gl_FragColor = vec4(color, uAlpha);
}{@}HideMaterial.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 color;
uniform float uAlpha;

#!VARYINGS

#!SHADER: HideMaterial.vs
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: HideMaterial.fs
void main() {
    gl_FragColor = vec4(color, uAlpha);
}{@}TestBgShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS

#!VARYINGS
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(vec3(0.),1.0);
}{@}CyberAttackDomeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uFresnelPow;
uniform float uAlpha;
uniform float uBrightness;
uniform float uRed;

uniform float uMatcapIndex;

uniform vec2 uFogRange;

uniform vec2 uNoiseRange;

uniform vec2 uRange1;
uniform vec2 uRange2;
uniform vec2 uRange3;
uniform vec2 uRange4;
uniform vec2 uRange5;
uniform vec2 uRange6;

uniform float uRadius;

uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;
varying float vAlpha;
varying vec4 vMvPos;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)

void main() {
    vec3 pos = position;

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha = crange(depth, 0.1, 1.0, 0.0, 1.0);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = position;
    vNormal = normalMatrix * normal;
    vViewDir = -(modelViewMatrix * vec4(pos, 1.0)).xyz;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));
    vMvPos = modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)

void main() {
    float fresnel = getFresnel(normalize(vNormal), vViewDir, uFresnelPow);

    // value that will be fed into final gradient map
    float c = 0.0;

    // uv distortion noise
    vec2 distortion = vec2(cnoise(vPos * vec3(uNoiseTile.y, uNoiseTile.x, uNoiseTile.y) + vec3(0.0, time * uNoiseSpeed, 0.0)));
    distortion *= smoothstep(uRange4.x, uRange4.y, vPos.y);

    // disintegration map
    vec3 tex = vec3(distortion * uNoiseRange.y + time * 0.031 * 0.05);
    float color = tex.r;
    color *= (1.0 - smoothstep(uRadius + 0.0, uRadius + 0.3, texture2D(tMap, vUv).g));

    // disintegration border
    float outer = smoothstep(uRange3.x, uRange3.y, color);
    float inner = smoothstep(uRange5.x, uRange5.y, color);

    color = outer - inner;

    float matcap = texture2D(tMatcap, vMuv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0) + distortion * uNoiseRange.x).r;
    c += matcap;
    c += color;
    c *= uBrightness;

    float alpha = uAlpha * crange(fresnel, 0.0, 1.0, 0.5, 1.0) * crange(vPos.y, uNoiseTile.x, uNoiseTile.y, 0.0, 1.0) * (1.0 - inner) * smoothstep(0.5, 0.52, vUv.y) + smoothstep(uRange6.x, uRange6.y, color) * 2.0 * smoothstep(0.5, 0.55, vUv.y);
    alpha *= crange(uRadius, 0.7, 0.8, 1.0, 0.0);
    alpha += (uBrightness - 1.0);

    vec3 final = texture2D(tRamp, vec2(c, 0.0)).rgb + smoothstep(uRange6.x, uRange6.y, color) * 2.0;
    final *= mix(vec3(1.0), uColor, crange(uBrightness * uRed, 1.0, 4.0, 0.0, 1.0));
    final += uColor * crange(uBrightness * uRed, 1.0, 4.0, 0.0, 1.0);


    gl_FragColor.rgb = final;
    gl_FragColor.a = alpha * vAlpha;
}{@}CyberAttackLinesShader.glsl{@}#!ATTRIBUTES
attribute vec2 uv2;

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform vec2 uNoiseCenter;
uniform float uNoiseSpeed;
uniform float uBrightness;

uniform float uThreatIntensity;

uniform float uUpgradeOffset;
uniform float uUpgradeFlash;
uniform float uRed;

uniform vec2 uRange1;
uniform vec2 uRange2;

uniform vec3 uColor;

uniform float uTextureIndex;

#!VARYINGS
varying vec2 vUv;
varying vec2 vUv2;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vUv2 = uv2;
    vPos = position;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)

void main() {
    vec2 uv = vUv;
    float n1 = crange(sin(distance(uv, vec2(0.5)) * uNoiseTile.x + time * uNoiseSpeed), uRange1.x, uRange1.y, uRange2.x, uRange2.y);
    float n3 = sin(distance(uv, vec2(0.5)) * uNoiseTile.y + time * uNoiseSpeed);

    vec3 lines = texture2D(tMap, uv).rgb;
    float c = lines.r;

    c *= uBrightness;
    c *= n1;
    c += lines.g + lines.g * 0.5 * uThreatIntensity * crange(sin(lines.b * 15.0 - time * uThreatIntensity * 3.5 + vPos.x * 10.0), -1.0, 1.0, 0.0, 1.0);

    c += lines.g * crange(sin(lines.b * 7.0 + uUpgradeOffset), -1.0, 1.0, 0.0, 1.0) * 4.0 * uUpgradeFlash;

    c *= uBrightness;

    vec3 color = texture2D(tRamp, vec2(c, 0.0)).rgb;
    color *= mix(vec3(1.0), uColor, crange(uUpgradeFlash * uRed, 1.0, 2.0, 0.0, 1.0));
    color += uColor * crange(uUpgradeFlash * uRed, 1.0, 2.0, 0.0, 1.0);

    gl_FragColor.rgb = color;
    gl_FragColor.a = c;
}{@}DetectAndInterceptDomeShader.glsl{@}#!ATTRIBUTES
attribute vec2 uv2;

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tCracks;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uFresnelPow;
uniform float uContrastMix;
uniform float uAlpha;

uniform float uMatcapIndex;
uniform float uBrightness;

uniform vec2 uFogRange;

uniform float uThreatLevel1;
uniform float uThreatLevel2;
uniform float uThreatLevel3;
uniform float uThreatLevel4;
uniform float uThreatLevel5;
uniform float uThreatLevel6;

uniform float uHit1;
uniform float uHit2;
uniform float uHit3;
uniform float uHit4;
uniform float uHit5;
uniform float uHit6;

uniform float uActive1;
uniform float uActive2;
uniform float uActive3;
uniform float uActive4;
uniform float uActive5;
uniform float uActive6;

uniform float uActivated;

uniform vec2 uColorRange;
uniform vec2 uCrackRange;
uniform float uSaturation;

#!VARYINGS
varying vec2 vUv;
varying vec2 vUv2;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;
varying float vHeight;
varying float vFog;

varying float vMask1;
varying float vMask2;
varying float vMask3;
varying float vMask4;
varying float vMask5;
varying float vMask6;
varying float vAlpha;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vUv2 = uv2;
    vPos = pos;
    vNormal = normalMatrix * normal;
    vViewDir = -(modelViewMatrix * vec4(pos, 1.0)).xyz;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));
    vHeight = smoothstep(-5.0, 6.0, pos.y);

    // Individual base masks
    vMask1 = 1.0 - (step(0.15, uv2.y) + step(uv2.y, 0.02));
    vMask2 = 1.0 - (step(0.33, uv2.y) + step(uv2.y, 0.15));
    vMask3 = 1.0 - (step(0.5, uv2.y) + step(uv2.y, 0.33));
    vMask4 = 1.0 - (step(0.68, uv2.y) + step(uv2.y, 0.51));
    vMask5 = 1.0 - (step(0.86, uv2.y) + step(uv2.y, 0.69));
    vMask6 = 1.0 - step(uv2.y, 0.87);

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha = smoothstep(2.0, 8.0, depth);

}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)
#require(rgb2hsv.fs)

float transformThread(float threatLevel) {
    threatLevel = max(threatLevel - 0.5, 0.0);
    float isActive = min(threatLevel, 1.0);
    float flash = 0.5 * sin(time * 4.0 * threatLevel) + 0.5;
    return flash * isActive;
}

void main() {
    float fresnel = clamp(getFresnel(normalize(vNormal), vViewDir, uFresnelPow * (1.0 + sin(time*0.1)*0.3)), 0., 1.);
    float offset = 2. * fresnel - 1.;
    float c = texture2D(tMap, ((gl_FragCoord.xy/resolution * 8.0) * offset + vec2(-time * 0.15))).r * fresnel;

    vec2 matcapUV = vMuv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0);
    matcapUV += cnoise(matcapUV*3.0+time*0.05)*0.04;

    float matcap = texture2D(tMatcap, matcapUV).r;

    //c *= 2.0;
    c += matcap;
    c = clamp(c, 0.0, 1.0);
    c = mix(c, mix(.1, 1., uMatcapIndex), uContrastMix);
    c*= uBrightness;

    vec3 color = vec3(c);
    float cracks = texture2D(tCracks, vUv).r;
    float dist = distance(vUv, vec2(0.5));
    dist = (1.0 - smoothstep(0.1, 0.3, dist));

    cracks = 1.0 - cracks;
    cracks *= 4.0;
    cracks = dist + cracks;

    vec3 red = vec3(1.0, 0.2, 0.22);
    float threatLevel = dot(vec4((uThreatLevel1), (uThreatLevel2), (uThreatLevel3), (uThreatLevel4)), vec4(vMask1, vMask2, vMask3, vMask4)) +
                        dot(vec2((uThreatLevel5), (uThreatLevel6)), vec2(vMask5, vMask6)); 
    float flash = dot(vec4(transformThread(uThreatLevel1), transformThread(uThreatLevel2), transformThread(uThreatLevel3), transformThread(uThreatLevel4)), vec4(vMask1, vMask2, vMask3, vMask4)) +
                        dot(vec2(transformThread(uThreatLevel5), transformThread(uThreatLevel6)), vec2(vMask5, vMask6)); 

    color += red * dist * cracks * flash;

    // Flash when a base is hit. Do this for all 6 bases
    vec3 brightRed = vec3(1.0, 0.8, 0.8);

    float multiplier = dist * (dot(vec4(uHit1, uHit2, uHit3, uHit4), vec4(vMask1, vMask2, vMask3, vMask4)) + dot(vec2(uHit5, uHit6), vec2(vMask5, vMask6))); 

    color += brightRed * cracks * multiplier;

    color *= (0.8 + 0.2 * fresnel);


    float glow = dist * (dot(vec4(uActive1, uActive2, uActive3, uActive4), vec4(vMask1, vMask2, vMask3, vMask4)) + dot(vec2(uActive5, uActive6), vec2(vMask5, vMask6)));

    color *= 1.0 + dist * glow;

    float destroyed = 1.;
    if(threatLevel < 0.) {
        destroyed = (1.0 - dist) - smoothstep(uCrackRange.x, uCrackRange.y, cracks);
    }

//    float speed = 0.1;
//    float noise = cnoise(vPos*3.0+time*speed);
//    color *= 1.0 + smoothstep(-0.4, 0.0, noise) * smoothstep(0.4, 0.0, noise) * 0.3;


    float luma = rgb2hsv(color).z;
    vec3 final = texture2D(tRamp, vec2(crange(luma, 0.0, 1.0, uColorRange.x, uColorRange.y), 0.0)).rgb;

    final = rgb2hsv(final);
    final.y *= uSaturation;
    final = hsv2rgb(final);

    // Increase alpha when base is hit to brighten flash. Do this for all 6 bases
    float alpha = uAlpha * vHeight + multiplier;
    alpha *= vAlpha * destroyed;
    if(alpha < .01 ) {
        discard;
    }
    //alpha *= mix(0.0, 1.0, 1.0-dist);


    gl_FragColor.rgb = final;
    gl_FragColor.a = alpha;
}{@}DomeLinesShader.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform float uSize;
uniform sampler2D tPos;
uniform sampler2D tLifeData;
uniform vec2 uLifeFade;
uniform float uAlpha;
uniform vec3 uColor;

#!VARYINGS
varying float vAlpha;
varying vec4 vMvPos;
varying vec2 vUv;
varying vec4 vRandom;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)
void main() {
    vec3 pos = texture2D(tPos, position.xy).xyz;
    vPos = pos;
    float life = texture2D(tLifeData, position.xy).z;
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    gl_PointSize = 0.06 * uSize * (1000.0 / length(mvPosition.xyz));
    gl_Position = projectionMatrix * mvPosition;

    vMvPos = mvPosition;
    vRandom = random;
    vUv = uv;
    vAlpha = uAlpha;
    vAlpha *= crange(life, uLifeFade.y, 0.99, 1.0, 0.0);
    vAlpha *= crange(life, 0.01, uLifeFade.x, 0.0, 1.0);

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha *= smoothstep(6.0, 15.0, depth);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    float dist = 1.0 - distance(uv, vec2(0.5));

    dist = smoothstep(0.4, 0.9, dist);
    gl_FragColor.rgb = mix(vec3(1.0), uColor, step(vRandom.x, 0.5));
    gl_FragColor.a = vAlpha * dist;

    gl_FragColor.a *= 0.5 + sin(time*15.0+vRandom.y*20.0)*0.5;
    gl_FragColor.a *= crange(cnoise(vPos*0.3+time*0.2), -1.0, 1.0, 0.1, 1.0);
}{@}TintShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}

#!SHADER: Fragment

void main() {
    gl_FragColor.rgb = texture2D(tMap, vUv).rgb * uColor;
    gl_FragColor.a = 1.0;
}{@}CyberAttackSkyShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tNoise;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uBrightness;

uniform vec2 uHorizon;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    float t = time * uNoiseSpeed;
    float c = texture2D(tNoise, vUv + vec2(t * 0.02)).r * uBrightness;
    c += getNoise(vUv, time) * 0.05;

    c *= smoothstep(0.05, 0.5, vUv.y);
    c *= 1.0 - smoothstep(0.5, 0.95, vUv.y);
    c = clamp(c, 0.0, 1.0);

    c *= smoothstep(uHorizon.x, uHorizon.y, vPos.y);

    gl_FragColor.rgb = texture2D(tRamp, vec2(c, 0.0)).rgb;
    gl_FragColor.a = 1.0;
}{@}CyberAttackParticleShader.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform float DPR;
uniform float uSize;
uniform vec2 uScale;
uniform vec2 uLifeFade;
uniform sampler2D tLife;
uniform sampler2D tPos;
uniform sampler2D tMask;
uniform sampler2D tColor;
uniform float uAlpha;
uniform float uMinAlpha;
uniform vec3 uColor;
uniform vec3 uHSL;

#!VARYINGS
varying float vAlpha;
varying vec3 vColor;

#!SHADER: Vertex

#require(range.glsl)
#require(simplenoise.glsl)
#require(rgb2hsv.fs)

void main() {
    float life = texture2D(tLife, position.xy).x;

    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    size *= uSize * crange(random.w, 0.0, 1.0, uScale.x, uScale.y);

    vAlpha = crange(random.y, 0.0, 1.0, uMinAlpha, 1.0) * uAlpha;
    vAlpha *= crange(life, uLifeFade.y, 0.99, 1.0, 0.0);
    vAlpha *= crange(life, 0.01, uLifeFade.x, 0.0, 1.0);

    vec3 color = rgb2hsv(texture2D(tColor, position.xy).rgb);
    color += crange(random.y, 0.0, 1.0, -1.0, 1.0) * uHSL * 0.1;
    color = hsv2rgb(color);
    vColor = color;

    gl_PointSize = size;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    vec2 mask = texture2D(tMask, uv).rg;

    if (mask.g < 0.01) discard;

    gl_FragColor = vec4(vColor, vAlpha * mask.g);
}{@}CyberAttackStructure.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tHeightmap;
uniform float uMaxHeight;
uniform float uRange;
uniform float uValue;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying float vMaxHeight;

#!SHADER: Vertex
void main() {
    float height = texture2D(tHeightmap, uv).r;
    vec3 pos = position;
    pos.z += height * uMaxHeight;

    vUv = uv;
    vPos = pos;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
void main() {
    float alpha = smoothstep(uValue - 0.1, uValue + 0.1, fract(vPos.z * uRange));
    if (alpha < 0.01 || vPos.z <= 0.01) discard;
    gl_FragColor = vec4(vec3(1.0), alpha * uAlpha);
}{@}ParticleCityParticles.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uIsVR;
uniform float DPR;

#!VARYINGS
varying float vGradient;
varying float vDark;

#!SHADER: Vertex
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    gl_PointSize = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR * 25.0;
    gl_Position = projectionMatrix * mvPosition;

    vGradient = 1.0 - crange(length(position), 0.0, 5.0, 0.0, 1.0);
    vDark = crange(cnoise(vec3(position.x, position.y, position.z + time * 0.1) * 4.3), -1.0, 1.0, 0.4, 1.0);
}

#!SHADER: Fragment
#require(range.glsl)

void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    float circle = 1.0 - crange(distance(uv, vec2(0.5)), vGradient * 0.4, 0.45, 0.0, 1.0);
    float alpha = 0.7 * vGradient * circle * vDark;

    if (uIsVR > 0.0) {
        alpha *= 0.4;
    }

    gl_FragColor = vec4(0.7, 0.85, 1.0, alpha);
}{@}CyberAttackCloudShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;

uniform vec3 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uBrightness;

uniform float uPadding;

uniform vec2 uHorizon;

uniform vec2 uRange1;
uniform vec2 uRange2;
uniform vec2 uRange3;
uniform vec2 uRange4;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vOffset;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
    vOffset = offset;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    vec2 uv = vUv;
    vec3 color = texture2D(tMap, uv + vOffset.xy + vec2(0.0, time * 0.17 * uNoiseSpeed)).rgb;
    color.r = crange(color.r, uRange3.x, 1.0, 0.0, 1.0);
    color.r *= crange(texture2D(tMap, vOffset.xz + uv * 0.5 + vec2(0.0, time * 0.217 * uNoiseSpeed)).r, uRange3.y, 1.0, 0.0, 1.0);
    float noise = cnoise(vPos * uNoiseTile + vec3(time * uNoiseSpeed, 0.0, time * uNoiseSpeed * 0.2) + vOffset);
    noise *= cnoise(vPos * 0.25 * uNoiseTile + vec3(time * uNoiseSpeed * 2.0, 0.0, time * uNoiseSpeed * 0.2) + vOffset);
    noise = crange(noise, -1.0, 1.0, uRange2.x, uRange2.y);
    color.r *= noise;

    float mask = 1.0;
    mask *= crange(uv.x, 0.0, uPadding, 0.0, 1.0) * crange(uv.x, 1.0 - uPadding, 1.0, 1.0, 0.0);
    mask *= crange(uv.y, 0.0, uPadding, 0.0, 1.0) * crange(uv.y, 1.0 - uPadding, 1.0, 1.0, 0.0);

    color.r *= mask;

    gl_FragColor.rgb = texture2D(tRamp, vec2(color.r, 0.0)).rgb;
    gl_FragColor.a = 1.0;
}{@}CyberAttackSpaceSkyShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;

uniform vec3 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uBrightness;

uniform vec2 uHorizon;

uniform vec2 uRange1;
uniform vec2 uRange2;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    vec3 color = texture2D(tMap, vUv).rgb;
    float mask = color.g;

    float noise = cnoise(vPos * uNoiseTile + vec3(time * uNoiseSpeed, 0.0, time * uNoiseSpeed * 0.5));
    noise = crange(noise, -1.0, 1.0, uRange2.x, uRange2.y);
    noise *= crange(distance(vUv, vec2(0.5)), uRange1.x, uRange1.y, 0.0, 1.0);
    noise += getNoise(vUv, time) * 0.01;
    color.r += noise * mix(mask, 1.0, 1.0);
    color.r *= uBrightness;

    gl_FragColor.rgb = texture2D(tRamp, vec2(color.r, 0.0)).rgb;
    gl_FragColor.a = 1.0;
}{@}DetectAndInterceptSplaneShader.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec3 scale;
attribute vec4 orientation;
#!UNIFORMS
uniform vec4 uQuaternion;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uLife;
uniform float uRandom;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vOffset;
varying float vFade;

#!SHADER: Vertex
#require(range.glsl)
#require(simplenoise.glsl)
#require(instance.vs)

void main() {
    vec3 transformedScale = scale + cnoise(offset * 0.6) * 0.3;
    vec3 pos = transformPosition(position, offset, transformedScale, uQuaternion);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vOffset = offset;

    vUv = uv;
    vFade = 1.0;
    vFade *= 1.0 - smoothstep(0.97, 1.0, uLife);
    vFade *= smoothstep(-5.0, -1.0, pos.y);
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    vec2 uv = vUv;
    //uv += cnoise(vec3(vUv,time*0.5))*0.02;

    float dist = 1.0 - distance(uv, vec2(.5));

    if (dist < 0.2) {
        discard;
    }


    float alpha = smoothstep(0.5, 0.9, dist);
    alpha *= uAlpha * vFade;

    alpha *= 0.6 + sin(time*40.0+uRandom*20.0)*0.4;

    vec3 color = uColor;

    color = mix(color, vec3(1.0), smoothstep(0.7, 1.2, dist)*0.6);

    //dist += cnoise(vPos) * dist;
    
    gl_FragColor = vec4(color, alpha);
}{@}CyberAttackTubeShader.glsl{@}#!ATTRIBUTES
attribute vec2 iuv;
#!UNIFORMS
uniform sampler2D tLife;
uniform sampler2D tRandom;
uniform vec2 uLifeFade;
uniform float uAlpha;
uniform float uTransition;
uniform float uTransition2;
uniform float uTransitionPadding;
uniform vec3 uColor;
uniform vec3 uColor2;
uniform vec2 uRange1;
uniform vec2 uRange2;
uniform vec2 uScaleRange;
uniform vec2 uColorNoise;
uniform vec2 uFade;
uniform float uTail;
uniform float uHide;

#!VARYINGS
varying float vAlpha;
varying vec2 vUv;

#!SHADER: Vertex

#require(range.glsl)

void extrudeTube() {
    vec4 random = texture2D(tRandom, iuv);
    scale *= crange(random.x, 0.0, 1.0, uScaleRange.x, uScaleRange.y);
}

void main() {
    float splineLife = texture2D(tLife, iuv).r;
    vAlpha = 1.0 - splineLife;
}

#!SHADER: Fragment
varying vec3 vPos;
varying vec2 vUv;

#require(rgb2hsv.fs)
#require(range.glsl)
#require(simplenoise.glsl)
#require(eases.glsl)

void main() {
    if (vAlpha < 0.01) discard;
    // vec2 uv = vUv * 2. -1.;
    // float alpha = vAlpha;
    // float remapped = crange(uv.x, -1. , 1., .5, 1.);
    float noise = crange(getNoise(vUv, time), 0. , 1., uRange2.x, uRange2.y);
    float gradient = smoothstep(uRange1.x, uRange1.y, vUv.x);

    vec3 color = mix(uColor, uColor2, gradient);
    // color *= ((1. - gradient) * noise);

    gl_FragColor = vec4(color, vAlpha);
}{@}HideAndSeekParticles.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform sampler2D tPos;
uniform float DPR;
uniform vec2 uFadeRange;
uniform vec2 uOpacityRange;
uniform vec2 uSizeRange;
uniform vec2 uScaleRange;
uniform float uFadeIn;
uniform float uPadding;
uniform float uTake3DShape;

#!VARYINGS
varying float vOpacity;
varying float vCameraOpacity;
varying vec4 vRandom;
#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = texture2D(tPos, position.xy).xyz;
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);
    vec3 worldPos = vec3(modelMatrix * vec4(pos, 1.0));

    float cameraDist = length(cameraPosition - worldPos);
    float cameraScale = crange(sqrt(cameraDist), uFadeRange.x, uFadeRange.y, 0., 1.);
    float ptSize = crange(cameraScale, 0., 1., uSizeRange.x, uSizeRange.y);
    ptSize *= crange(random.y, 0., 1., .5, 2.);
    
    gl_PointSize = ptSize * DPR * (1000.0 / length(mvPosition.xyz));
    gl_Position = projectionMatrix * mvPosition;

    vOpacity = crange(random.x, 0.,1.,uOpacityRange.x,uOpacityRange.y);
    float cameraOpacity = crange(cameraDist, uFadeRange.x, uFadeRange.y, 1., .01 + (.49 * uTake3DShape));
    vOpacity*=cameraOpacity;
    vCameraOpacity = cameraOpacity;
    vRandom = random;
}

#!SHADER: Fragment
#require(range.glsl)
#require(eases.glsl)

void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    float dist = length(uv - vec2(0.5));
    float opacityFactor = step(.2, vCameraOpacity);
    float mask = 1.0 - smoothstep(mix(0.2, 0.4, opacityFactor), .5, dist);
    if(mask < .15) {
        discard;
    }
    float transition = crange(uFadeIn, 0.0, 1.0, -uPadding, 1.0 + uPadding);
    float mixValue = crange(transition, vRandom.x - uPadding, vRandom.x + uPadding, 0.0, 1.0);
    float opacity = vOpacity * sineInOut(mixValue);
    gl_FragColor = vec4(vec3(mask * (max(.5,2. * opacityFactor))), opacity);
}{@}HideAndSeekSoundsShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform float uActive;
uniform float uIndex;

#!VARYINGS

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)
#require(rgb2hsv.fs)

void main() {
    vec3 color = vec3(0.6);
    color = rgb2hsv(color);
    color.x = uIndex;
    color.y = 0.7;
    color.z = mix(0.6, 1.0, uActive);
    color = hsv2rgb(color);

    gl_FragColor = vec4(color, uAlpha);
}{@}HideAndSeekFloor.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying float vAlpha;
#!SHADER: Vertex

void main() {
    vUv = uv;
    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    float depth = length(cameraPosition - vec3(modelMatrix * vec4(pos, 1.0)));
    vAlpha = smoothstep(3.0, 6.0, depth);
}

#!SHADER: Fragment

#require(range.glsl)
#require(simplenoise.glsl)
#require(rgb2hsv.fs)
#require(transformUV.glsl)

#define S(r,v) smoothstep(9./resolution.y,0.,abs(v-(r)))
const vec2 s = vec2(1, 1.7320508); // 1.7320508 = sqrt(3)
const vec3 baseCol = vec3(1.0);
const float borderThickness = .02;
const float isolineOffset = .4;
const float isolineOffset2 = .4;

float calcHexDistance(vec2 p) {
    p = abs(p);
    return max(dot(p, s * .5), p.x);
}

float random(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec4 sround(vec4 i) {
    return floor(i + 0.5);
}

vec4 calcHexInfo(vec2 uv) {
    vec4 hexCenter = sround(vec4(uv, uv - vec2(.5, 1.)) / s.xyxy);
    vec4 offset = vec4(uv - hexCenter.xy * s, uv - (hexCenter.zw + .5) * s);
    return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? vec4(offset.xy, hexCenter.xy) : vec4(offset.zw, hexCenter.zw);
}

void main() {
    vec2 overlayUV = vUv;
    overlayUV = scaleUV(overlayUV, vec2(0.009));
    vec4 hexInfo = calcHexInfo(overlayUV);
    float totalDist = calcHexDistance(hexInfo.xy) + borderThickness;
    float rand = random(hexInfo.zw);
    float angle = atan(hexInfo.y, hexInfo.x) + rand * 5. + time;
    float sinOffset = sin(time * 0.2 + rand * 8.);
    float aa = 5. / resolution.y;

    float hexagons = (1.0-smoothstep(.51, .51 - aa, totalDist));
    hexagons += sinOffset * 0.4;
    //hexagons += (pow(1. - max(0., .5 - totalDist), 10.) * 1.5) * (baseCol + rand * vec3(0., .1, .09)) * 0.3;
    hexagons *= crange(cnoise(vUv*10.0+time*0.1), -1.0, 1.0, 0.0, 1.0);

    float alpha = hexagons * uAlpha * vAlpha;
    alpha *= smoothstep(0.5, 0.0, length(vUv-0.5));
    //alpha *= fract(length(vUv-0.5)*15.0-mod(time*0.2, 20.0))*0.1;
    //alpha *= crange(cnoise(vPos*10.0+time*0.1), -1.0, 1.0, 0.2, 1.0);

    gl_FragColor.rgb = vec3(1.0);
    gl_FragColor.a = alpha;
}{@}HologramBaseCubes.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uLightDir;
uniform sampler2D tNoise;
uniform sampler2D tShadow;
uniform sampler2D tGradient;
uniform vec2 uNoiseUv;
uniform float uNoiseStrength;
uniform vec2 uNoiseOffset;
uniform float uNoiseSpeed;
uniform vec2 uDepthRange;
uniform vec2 uValueRange;
uniform float uHeightOffset;
uniform vec2 uShadowNoiseUv;

uniform float uTile;

uniform float uShockwaveStrength;
uniform float uShockwaveProgress;
uniform float uShockwaveWidth;


#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying float vNoise;
varying vec2 vNoiseUv;
varying vec3 vPos;
varying float vFog;
varying float vShadowNoise;
varying float vShockwave;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    setupBase(position);
    vec3 pos = position;

    vec3 instancePos = vec3(1.0);
    #ifdef INSTANCED
    instancePos = offset;
    #endif

    vec2 noiseUv = instancePos.xz * uNoiseUv + uNoiseOffset + vec2(0.0, time * uNoiseSpeed);
    float noise = texture2D(tNoise, noiseUv).r;

    pos.y += crange(noise, 0.0, 1.0, -1.0, 0.0) * uNoiseStrength;
    pos.y += uHeightOffset;

    float circularGradient = length(instancePos.xz * 0.01);
    float shockwave = smoothstep(uShockwaveProgress, uShockwaveProgress + uShockwaveWidth, circularGradient);
    shockwave += (1.0 - smoothstep(uShockwaveProgress - uShockwaveWidth, uShockwaveProgress, circularGradient));
    shockwave = 1.0 - shockwave;
    shockwave = mix(0.0, shockwave, uShockwaveStrength) * smoothstep(0.05, 0.1, circularGradient);

    pos.y += shockwave + shockwave * (cnoise(instancePos.xz * 0.2) * 0.5);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vFog = crange(pos.x, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vFog *= crange(pos.x, -uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vFog *= crange(pos.z, -uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vFog *= crange(pos.z, uDepthRange.x, uDepthRange.y, 0.0, 1.0);
    vFog = pow(vFog * 1.4, 2.0);

    vShadowNoise = cnoise(pos.xz * uShadowNoiseUv + vec2(time, time) * 0.15) * 0.08;

    vNormal = normal;
    vNoise = noise;
    vNoiseUv = noiseUv;
    vPos = pos;
    vUv = uv;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    // main grayscale color of cubes (noise + lighting)
    float light = dot(vNormal, uLightDir);
    light = clamp(light, 0.45, 0.57);

    float grayscale = mix(1.0, vNoise, uNoiseStrength * 0.2) * vFog * light - vShadowNoise * vFog;
    grayscale = crange(grayscale, uValueRange.x, uValueRange.y, 0.0, 1.0);

    float scanlines = mix(mod(vPos.z, uTile), 1.0, 0.92);
    grayscale *= scanlines;

    // add soft shadow underneath platform, so that players can see platform when they look down
    vec2 shadowUv = vPos.xz * 0.03 + vec2(0.5, 0.5);
    float shadow = crange(texture2D(tShadow, shadowUv).r, 0.0, 1.0, 0.5, 1.0);
    shadow = mix(1.0, shadow, 0.6);
    grayscale *= shadow;

    // apply blue color by sampling along gradient texture
    vec4 color = texture2D(tGradient, vec2(grayscale, 0.0));

    gl_FragColor = color;
    gl_FragColor.a = 0.1;
}{@}HologramBaseAmbientParticles.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uSize;
uniform float uAlpha;
uniform vec2 uFadeVertical;
uniform vec3 uColor;
uniform vec3 uColor2;
uniform vec2 uFadeRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: VertexShader.vs

#require(BaseShader.vs)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    setupBase(pos);
    
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01;
    size *= uSize;
    size *= crange(pos.y, 10.0, 20.0, 1.0, 0.6);

    gl_PointSize = size;
    gl_Position = projectionMatrix * mvPosition;

    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    // vec2 uv = vec2(gl_PointCoord.x, -gl_PointCoord.y + 1.0);
    // vec4 color = texture2D(tMap, uv);
    // color += color * (1.0 - length(vPos));
    // color += color * crange(length(vPos), 0.0, 3.0, 5.0, 0.0);
    gl_FragColor.rgb = mix(uColor, uColor2, crange(length(vPos), uFadeRange.x, uFadeRange.y, 0.0, 1.0));
    gl_FragColor.a = uAlpha;
    // gl_FragColor.a = uAlpha * crange(vPos.y, uFadeVertical.x, uFadeVertical.y, 0.0, 1.0);
    // gl_FragColor.a = 1.0;
}{@}HologramBasePlatformGrid.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGrid;
uniform sampler2D tGradient;
uniform float uTile;
uniform float uTile2;
uniform float uSpeed;
uniform float uSpeed2;
uniform vec2 uRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    vec3 pos = position;
    setupBase(pos);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vNormal = normal;
    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;
    
    float noise = cnoise(vUv + vec2(time, time * 0.1));
    vec3 color = texture2D(tMap, vUv * uTile + vec2(time * uSpeed * 0.5, time * uSpeed)).rgb;
    color *= texture2D(tMap, vUv * uTile2 + vec2(time * uSpeed2, time * uSpeed2) ).rgb;

    vec3 grid = texture2D(tGrid, vUv).rgb;
    color = grid * vec3(smoothstep(uRange.x, uRange.y, color.r));
    color += grid.r * 0.1;

    color = vec3(1.0) - texture2D(tGradient, vec2(color.r, 0.0)).rgb;
    
    gl_FragColor.rgb = vec3(0.0);
    gl_FragColor.a = clamp((1.0 - color.r) * 5.0, 0.0, 1.0);
}{@}HologramBasePlatformLights.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGradient;
uniform float uBrightness;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;

#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    vec3 pos = position;
    setupBase(pos);

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);

    vUv = uv;
    vNormal = normal;
    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    vec3 color = texture2D(tMap, vUv).rgb;
    
    gl_FragColor.rgb = color * uBrightness;
    gl_FragColor.a = 1.0;
}{@}HologramBaseSky.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tGradient;
uniform vec2 uHeightRange;
uniform float uFresnel;
uniform float uNoiseScale;
uniform float uNoiseSpeed;
uniform float uNoiseStrength;
uniform vec2 uValueRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vPos;
varying vec3 vViewDir;
varying float vHorizon;


#!SHADER: Vertex

#require(BaseShader.vs)

void main() {
    setupBase(position);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);

    vNormal = normalMatrix * normal;
    vViewDir = -vec3(modelViewMatrix * vec4(position, 1.0));
    vHorizon = pow(crange(position.y, uHeightRange.x, uHeightRange.y, 0.0, 1.0), 2.0);
    vUv = uv;
    vPos = position;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;
    
    float noise = cnoise(vUv * uNoiseScale + vec2(0.0, time) * uNoiseSpeed) * vHorizon;
    float value = crange(noise * uNoiseStrength, -1.0, 1.0, uValueRange.x, uValueRange.y);
    value *= 1.0 - smoothstep(0.6, 0.95, vUv.y);
    value *= 1.0 - smoothstep(0.8, 0.95, vUv.x);
    value *= smoothstep(0.0, 0.1, vUv.x) * vHorizon;

    vec4 color = texture2D(tGradient, vec2(value, 0.0));
    gl_FragColor = color;
}{@}HologramBaseSquare.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tGradient;
uniform float uSpeed;
uniform float uDelay;
uniform float uTile;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying float vFade;
varying float vScanlineFade;

#!SHADER: Vertex

#require(BaseShader.vs)

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main() {
    vec3 pos = position;
    float t = time * uSpeed;
    float zOffset = (fract(t / 10.0) * 10.0);
    pos.z += zOffset;
    setupBase(pos);

    vec3 instancePos = vec3(1.0);
    #ifdef INSTANCED
    instancePos = offset + zOffset;
    #endif

    pos.xy = rotate(pos.xy, instancePos.z * uDelay);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
    vFade = crange(abs(pos.z), 0.0, 150.0, 1.0, 0.0);
    vScanlineFade = crange(abs(pos.z), 10.0, 50.0, 1.0, 0.0);
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    // if (transitionDiscard()) discard;

    vec4 color = texture2D(tMap, vUv);

    float scanlines = mod(vPos.y, uTile);
    color += scanlines;

    color = mix(vec4(0.5, 0.5, 0.5, 1.0), color, vScanlineFade);

    color = texture2D(tGradient, vec2(color.r, 0.0));
    color *= vFade;
    gl_FragColor = color;
}{@}LandingEyeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec2 uTile;
uniform vec2 uPinchRange;
uniform vec4 uFadeRange;
uniform vec4 uBands1;
uniform vec4 uBands2;
uniform vec3 uColor;
uniform float uTransition;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
void main() {
    float pinch = 1.0 - smoothstep(uPinchRange.x, uPinchRange.y, uv.y);
    vec3 pos = position * mix(1.0, 0.0, pinch);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(rgb2hsv.fs)
#require(mousefluid.fs)

void main() {


    float noise = 0.5;
    #test Tests.backgroundSphereNoise()
    noise *= cnoise(vPos * 0.25 + vec3(0.0, 0.0, -time * 0.3));
    #endtest
    noise += 0.5;
    noise *= 0.3;

    float distort = smoothstep(uTransition - 0.6, uTransition, vUv.y);
    vec2 uv = vUv * uTile + vec2(noise * 0.1, -time * 0.05 + distort);

    vec2 uv2 = vUv;

    #test Tests.renderMouseFluid()
    vec2 fluidUV = gl_FragCoord.xy / resolution;
    float fluidMask = smoothstep(0.0, 1.0, texture2D(tFluidMask, fluidUV).r);
    float fluidOutline = smoothstep(0.0, 0.2, fluidMask) * smoothstep(1.0, 0.2, fluidMask);
    vec2 fluid = texture2D(tFluid, vUv).xy * fluidMask;

    uv += fluid * 0.0005;
    #endtest


    vec4 tex = texture2D(tMap, uv);
    float linesSharp = tex.r;
    float linesBlur = tex.g * 4.0;

    float innerGradient = smoothstep(uFadeRange.x, uFadeRange.y, uv2.y);
    float outerGradient = 1.0 - smoothstep(uFadeRange.z, uFadeRange.w, uv2.y);
    float gradient = innerGradient * outerGradient;

    vec3 color = uColor;
    color *= 1.0 + noise * 0.3;

    float noise2 = 0.0;

    #test Tests.backgroundSphereNoise()
    cnoise(vPos * 0.05 + time * 0.03);
    #endtest

    color = mix(color, vec3(1.0), smoothstep(0.0, 1.0, noise2));

    color = rgb2hsv(color);
    //color.x += cnoise(vPos * 0.3 + vec3(0.0, 0.0, -time * 0.3)) * 0.01;
    color = hsv2rgb(color);

    float alpha = linesBlur;
    alpha *= gradient;
    alpha *= 1.0 - smoothstep(uFadeRange.z, uFadeRange.w, uv2.y);
    alpha -= smoothstep(uBands1.x, uBands1.y, uv2.y) - smoothstep(uBands1.z, uBands1.w, uv2.y);
    alpha += smoothstep(uBands2.x, uBands2.y, uv2.y) - smoothstep(uBands2.z, uBands2.w, uv2.y);
    alpha += linesSharp * gradient * 0.8;
    alpha -= noise * alpha;
    alpha += noise * gradient;
    alpha += (0.5 * sin(time) + 0.5) * 0.1 * gradient;
    alpha *= 1.0 - distort;

    gl_FragColor.rgb = color;
    gl_FragColor.a = clamp(alpha, 0.0, 1.0);
}{@}LandingLensShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMatcap;
uniform vec3 uReflectOffset;
uniform vec3 uColor;
uniform float uTransition;

#!VARYINGS
varying vec2 vUv;
varying vec2 vMuv;

#!SHADER: Vertex
#require(matcap.vs)
#require(range.glsl)
#require(simplenoise.glsl)

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main() {
    float noise = 0.0;
    #test Tests.backgroundSphereNoise()
    cnoise(position * 2.0 + vec3(0.0, time * 0.3, 0.0));
    #endtest
    noise *= 0.08;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vMuv = reflectMatcap(position + uReflectOffset, modelViewMatrix, normalize(normalMatrix * (normal + vec3(noise, noise, 0.0))));
}

#!SHADER: Fragment
void main() {
    float alpha = texture2D(tMatcap, vMuv).r;
    vec3 color = uColor;
    alpha *= 0.85;
    alpha *= uTransition;
    gl_FragColor = vec4(color, alpha);
}{@}GradientPlane.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tRamp;
uniform float uPadding;
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vPos = position;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {

    float mask = 1.0;
    mask *= crange(vUv.x, 0.0, uPadding, 0.0, 1.0) * crange(vUv.x, 1.0 - uPadding, 1.0, 1.0, 0.0);
    mask *= crange(vUv.y, 0.0, uPadding, 0.0, 1.0) * crange(vUv.y, 1.0 - uPadding, 1.0, 1.0, 0.0);
    mask += getNoise(vUv, time) * 0.05;

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = mask * uAlpha;
}{@}RootStructureParticles.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform sampler2D tMask;
uniform sampler2D tShape;
uniform float uHasShape;
uniform float uSize;
uniform float DPR;
uniform vec3 uColor;
uniform vec2 uScale;
uniform vec2 uRange;
uniform float uAlpha;
uniform float uTransition;
uniform float uRangeScale;

#!VARYINGS
varying float vAlpha;
varying vec4 vRandom;
varying vec2 vUv;
varying vec2 vPos;

#!SHADER: Vertex

#require(eases.glsl)
#require(range.glsl)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    vec4 mPosition = modelMatrix * vec4(pos, 1.0);
    vec4 mvPosition = viewMatrix * mPosition;

    vRandom = random;
    vPos = crange(pos.xy, vec2(uRange.x), vec2(uRange.y), vec2(0.), vec2(1.));
    vAlpha = uAlpha;
    //vAlpha = crange(random.y, 0.0, 1.0, 0.3, 1.0) * uAlpha;

    float size = 1.;
    if(uHasShape < 1.) {
        vAlpha *= smoothstep(1.0, 6.0, length(mPosition.xyz - cameraPosition));
        size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    }
    //vAlpha *= rangeTransition(uTransition, random.w, 0.1);


    if(uHasShape > .01) {
        vec4 diffuse = texture2D(tShape, vPos);
        size = 1000.0 * 0.01 * DPR;
        vAlpha = rangeTransition(sineIn(uTransition), random.x, .3);
        vAlpha *= uAlpha * uAlpha;
        vAlpha = clamp(vAlpha, 0., 1.);

        if(diffuse.g  > .1) {
           vAlpha = 0.;
        }
    }

    size *= uSize * crange(expoIn(random.w), 0.0, 1.0, uScale.x, uScale.y);
    //size *= vAlpha;

    gl_Position = projectionMatrix * mvPosition;
    gl_PointSize = size;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

void main() {
    vec3 color = uColor;
    color *= 0.7 + smoothstep(0.8, 1.0, abs(sin(time+vRandom.y*20.0)));


    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);

    float alpha = 1.;
    alpha = smoothstep(0.5, 0.0, length(uv-0.5));
    alpha *= 0.5+sin(time+vRandom.x*20.0)*0.5;
    alpha *= featheredSliderAlpha();
   // vec2 coords = gl_FragCoord.xy/resolution.xy;
    // vec2 sUv = vec2(0.);


    gl_FragColor = vec4(color, clamp(alpha * vAlpha, 0., 1.));
}{@}TrackPadLineShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uLineOpacity;
uniform vec3 uColor2;
uniform float uLineCount;
uniform float uTransition;
uniform float uPadding;

#!VARYINGS

#!SHADER: Vertex

void main() {
}

#!SHADER: Fragment

#require(range.glsl)

//fsparams

void main() {
    alpha *= rangeTransition(uTransition, (1. - vUv.x + vLineIndex) / uLineCount, uPadding);
    alpha *= uLineOpacity;
    gl_FragColor = vec4(uColor2, alpha);
}
{@}TrackReactPadDotShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uAlpha;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
void main() {
    float dist = 1. - smoothstep(.1 - .01, .1, length(vUv - .5));

    if (dist < .01) {
        discard;
    }


    gl_FragColor = vec4(uColor, uAlpha*dist);
}{@}TrackReactPadSquareShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uCircleColor;
uniform vec3 uBorderColor;
uniform vec3 uErrorColor;
uniform vec3 uSuccessColor;

uniform float uCircleRadius; 
uniform float uCircleAlpha;
uniform float uBorderAlpha;
uniform float uHover;
uniform float uAlpha;

uniform float uError;
uniform float uSuccess;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vec3 pos = position;

    pos.z += uBorderAlpha*0.04;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(range.glsl)
#require(eases.glsl)

void main() {
    vec3 color = vec3(1.0);
    color = mix(color, uErrorColor, uError*0.8);
    color = mix(color, uSuccessColor, uSuccess);

    float alpha = uCircleAlpha * uAlpha;
    float line = 0.35;
    alpha *= smoothstep(0.5, -0.2, length(vUv-0.5));

    alpha *= mix(1.0, 0.0, smoothstep(line+0.02, line, length(vUv-0.5)));
    alpha += smoothstep(line-0.02, line, length(vUv-0.5))*smoothstep(line+0.02, line, length(vUv-0.5))*uBorderAlpha;

    float flicker = 0.5+sin(time*22.0)*0.4+sin(time*50.0)*0.4;
    alpha = mix(alpha, alpha * flicker, smoothstep(0.0, 0.3, uAlpha) * smoothstep(1.0, 0.8, uAlpha));

    gl_FragColor = vec4(color, alpha);
}{@}TrackReactSpinnerShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;

uniform float uMatcapIndex;
uniform float uFresnelPowLight;
uniform float uFresnelPowDark;
uniform float uAlpha;
uniform float uContrastMix;
uniform float uStrength;
uniform float uCircleStrength;
uniform float uBrightness;
uniform float uFrequency;
uniform float uSpeed;
uniform float uRotation;
uniform float uHit;

uniform vec3 uColor;
uniform vec2 uRange;
uniform vec2 uRange2;
uniform vec2 uRange3;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)

void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vPos = position;
    vNormal = normalMatrix * normal;
    vViewDir = -(modelViewMatrix * vec4(position, 1.0)).xyz;
    vMuv = reflectMatcap(position, modelViewMatrix, normalize(vNormal));
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)
#require(transformUV.glsl)
#require(blendmodes.glsl)

void main() {
    float fresnelPow = mix(uFresnelPowDark, uFresnelPowLight, uMatcapIndex);
    float fresnel =  getFresnel(vNormal, vViewDir, fresnelPow);
    float offset = crange(fresnel, 0.0, 1.0, -1.0, 1.0);

    vec2 uv = vMuv;
    uv = rotateUV(uv, uRotation);

    float c = texture2D(tMap, uv).r * fresnel;

    float matcap = texture2D(tMatcap, uv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0)).r;

    if (uMatcapIndex < 0.1) {
        matcap = crange(matcap, 0.4, 1.0, 0.0, 1.0);
    } else {
        matcap = crange(matcap, 0.0, 0.9, 0.0, 1.0);
    }

    c *= 2.0;
    c += matcap;

    c = clamp(c, 0.0, 1.0);
    c = mix(c, mix(.2, 1., uMatcapIndex), uContrastMix);
    c*=uBrightness;

    vec3 color =  texture2D(tRamp, vec2(c, 0.0)).rgb * crange(fresnel, 0.0, 1.0, 0.5, 1.0);
  
    float mappedX = crange(vUv.x, uRange.x, uRange.y, 0., 1.);
    float dash = smoothstep(uRange2.x, uRange2.y, sin((1. + mappedX) * uFrequency + (time * uSpeed)));

    float strength = uStrength;
    if (mappedX > .99) {
        dash = 1.;
        strength = uCircleStrength;
    }
    color += mix(vec3(.3), vec3(1.), uMatcapIndex + (1.0-uAlpha)) * dash * strength;

    //color *= 1.0+abs(uRange2.x)*0.5;
    color = mix(color, blendLinearBurn(color, uColor), uHit*0.7);

    float alpha = uAlpha * crange(fresnel, 0., 1., .8, 1.);

    float flicker = 0.5+sin(time*22.0)*0.4+sin(time*50.0)*0.4;
    alpha = mix(alpha, alpha * flicker, smoothstep(0.3, 0.6, uAlpha) * smoothstep(0.9, 0.7, uAlpha)*0.5);

    gl_FragColor.rgb = color;
    gl_FragColor.a = alpha;
}{@}TrackReactSpinnerSplashShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tRamp;
uniform vec2 uDistortTile;

uniform float uDistortSpeed;
uniform float uForce;
uniform float uSize;
uniform float uFeather;
uniform float uThickness;
uniform float uAlpha;
uniform float uOffset;

uniform vec3 uColor;
uniform float uHit;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(blendmodes.glsl)

void main() {
    vec2 dist = normalize(vUv - vec2(.5)) * uForce;
    float circle = (1. - smoothstep(uSize - uFeather, uSize, length(vUv - vec2(.5)))) - (1. - smoothstep(uSize - uThickness - uFeather, uSize - uThickness, length(vUv - vec2(.5)))) ;
    float noise = 1.;
    float mask = noise * circle;

    if (mask < .01) {
        discard;
    }
    float res = mask*uAlpha;

    vec3 color = texture2D(tRamp, vec2(res, 0.0)).rgb;

    color = mix(color, blendOverlay(color, uColor), uHit*0.7);

    gl_FragColor.rgb = color;
    gl_FragColor.a = res * 50.;
}{@}TrackAndReactEyeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;

uniform float uSpeed;
uniform float uSpeed2;
uniform vec2 uTile;
uniform float uOffset;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform vec2 uNoiseRange;
uniform float uNoiseOffset;

uniform vec2 uGradientInner;
uniform vec2 uGradientOuter;

uniform float uDilate;
uniform float uBrightness;
uniform float uVisible;
uniform float uError;
uniform float uSuccess;

uniform float uMask;
uniform float uBlur;
uniform float uBlurAll;
uniform vec2 uBlurRange;

uniform float uDistortStrength;
uniform float uDistortStrength2;
uniform vec2 uDistortTile;
uniform float uDistortSpeed;

uniform float uTransition;
uniform vec2 uCenterRange;
uniform vec2 uCenterRange2;
uniform vec2 uCenterRange3;
uniform vec3 uErrorColor;

uniform float uSpiralStrength;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vMvPos;
varying vec2 vMuv;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    pos += pos * pow(1.0 - uv.y, 2.0) * uDilate;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(transformUV.glsl)

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main() {
    vec2 uv = vUv;
    uv.x += uSpiralStrength * uv.y;
    // fade eye in/out for animation
    float mask = uMask;

    #test Tests.backgroundSphereNoise()
    uv += cnoise(vPos*1.5+time*0.4) * mix(0.001, 0.004, uError);
    #endtest

    // fade to black at both ends of geometry
    float grad = 1.0;
    grad *= smoothstep(uGradientInner.x, uGradientInner.y, uv.y);
    grad *= 1.0 - smoothstep(uGradientOuter.x, uGradientOuter.y, uv.y);

    // highlight towards eye center
    float highlight = 1.0;
    highlight *= smoothstep(uGradientInner.x, uGradientInner.y, uv.y);
    highlight *= 1.0 - smoothstep(0.25 - uDilate * 0.05, 0.35 - uDilate * 0.07, uv.y);
    highlight *= 0.5;

    // pulsing brightness outwards from center
    float n1 = cnoise(uv * uNoiseTile - vec2(0.32, time * uNoiseSpeed + uDilate) + vec2(0.0, uNoiseOffset));
    #test Tests.backgroundSphereNoise()
    n1 += cnoise(uv * uNoiseTile * 1.6 - vec2(0.3, time * uNoiseSpeed + uDilate) + vec2(0.0, uNoiseOffset));
    n1 /= 2.0;
    #endtest

    //Pulse for error
    float center = 1. - smoothstep(uCenterRange.x, uCenterRange.y, uv.y);
    float cutout = 1. - smoothstep(uCenterRange2.x, uCenterRange2.y, uv.y);
    center = crange(center - cutout, uCenterRange3.x, uCenterRange3.y, 0., 1.);

    // uv distortion
    float n2 = 0.0;
    #test Tests.backgroundSphereNoise()
    n2 = cnoise(uv * uDistortTile - vec2(0.32, time * uDistortSpeed));
    #endtest

    vec3 distort = vec3(0.0, n2 * uDistortStrength, 0.0);

    //distortion used for error
    vec3 wave = vec3(0.0, n2 * uDistortStrength2, 0.0);
    distort = mix(distort, wave, center);

    // blur
    float blur = crange(length(vPos.xy), 7.0, 15.0, uBlurRange.x, uBlurRange.y) * uBlur * n1 + n1;
    blur = clamp(blur, 0.0, 1.0);
    blur = mix(blur, 1.0, uBlurAll);

    // main lines
    float t = time * mix(uSpeed, uSpeed2, center);
    float c = texture2D(tMap, uv - vec2(cameraPosition.x * 0.02, cameraPosition.y) * 0.002).b * 1.5 * grad;
    vec2 layer1 = texture2D(tMap, uv * (vec2(-0.5, 1.0 - uDilate * 0.05)) * uTile * vec2(1.0, uv.y * 2.0) + vec2(0.0, t * 0.5) + distort.zy + vec2(0.0, uOffset)).rg;
    c += mix(layer1.r, layer1.g, blur) * grad;
    vec2 layer2 = texture2D(tMap, uv * (vec2(0.5, 1.0 - uDilate * 0.07) * uTile * vec2(1.0, uv.y * 2.0)) + vec2(0.0, t) + distort.zy + vec2(0.0, uOffset)).rg;
    c += mix(layer2.r, layer2.g, blur) * grad;

    c /= 2.0;

    float alpha = c;

    c *= grad;

    n1 += highlight;

    alpha += clamp(n1 * c * 2.0, 0.0, 1.0);

    n1 = crange(n1, -1.0, 1.0, uNoiseRange.x, uNoiseRange.y);


    c += n1 * grad;

    c *= uBrightness;
    c *= mask;

    c *= 1.0;

    alpha = alpha * mask + n1 * grad * 0.1 * mask;

    vec3 color = texture2D(tRamp, vec2((c), 0.0)).rgb;
    //Mix in error color
    color = mix(color, uErrorColor, center);

    alpha *= uVisible;

    alpha *= smoothstep(3.0, 2.0, vPos.z);

    gl_FragColor.rgb = color;
    gl_FragColor.a = alpha;
}{@}TrackAndReactFloorShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;
uniform vec2 uTile;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform vec2 uNoiseRange;
uniform float uEdgeBlur;
uniform float uBrightness;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    float t = time * uNoiseSpeed;
    float color = texture2D(tMap, vUv * uTile).r;
    float c = cnoise(vUv * uNoiseTile + vec2(time * 0.1 * uNoiseSpeed));
    c = crange(c, -1.0, 1.0, uNoiseRange.x, uNoiseRange.y);
    c += getNoise(vUv, time) * 0.05;

    color += c;

    color *= smoothstep(0.0, uEdgeBlur, vUv.x);
    color *= 1.0 - smoothstep(1.0 - uEdgeBlur, 1.0, vUv.x);
    color *= smoothstep(0.0, uEdgeBlur, vUv.y);
    color *= 1.0 - smoothstep(1.0 - uEdgeBlur, 1.0, vUv.y);

    color *= uBrightness;

    gl_FragColor.rgb = texture2D(tRamp, vec2(color, 0.0)).rgb;
    gl_FragColor.a = color * uAlpha;
}{@}TrackAndReactGridParticleShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uSize;
uniform float uAlpha;
uniform vec2 uFadeRange;
uniform vec3 uColor;
uniform vec3 uColor2;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: VertexShader.vs

#require(BaseShader.vs)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;

    setupBase(pos);
    
    vec4 mvPosition = modelViewMatrix * vec4(pos, 1.0);

    float size = 1000.0 / length(mvPosition.xyz) * 0.01;
    size *= uSize;

    gl_PointSize = size;
    gl_Position = projectionMatrix * mvPosition;

    vPos = pos;
}

#!SHADER: Fragment

#require(BaseShader.fs)

void main() {
    gl_FragColor.rgb = uColor;
    gl_FragColor.a = uAlpha;
}{@}TrackAndReactGridShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tRamp;

uniform float uTile;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uEdgeBlur;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    float t = time * uNoiseSpeed;
    float color = texture2D(tMap, vUv * uTile).r;
    float c = cnoise(vUv * uNoiseTile + vec2(time * 0.1 * uNoiseSpeed));
    c = crange(c, -1.0, 1.0, 0.0, 1.0);
    // c += getNoise(vUv, time) * 0.05;


    // color += c;
    float alpha = color;
    alpha *= smoothstep(0.0, uEdgeBlur, vUv.x);
    alpha *= 1.0 - smoothstep(1.0 - uEdgeBlur, 1.0, vUv.x);
    alpha *= smoothstep(0.0, uEdgeBlur, vUv.y);
    alpha *= 1.0 - smoothstep(1.0 - uEdgeBlur, 1.0, vUv.y);

    gl_FragColor.rgb = texture2D(tRamp, vec2(1.0 - color, 0.0)).rgb;
    gl_FragColor.a = min(alpha, c) * uAlpha;
}{@}TrackAndReactImpactShader.glsl{@}#!ATTRIBUTES
attribute vec3 offset;
attribute vec3 scale;
attribute vec4 orientation;
#!UNIFORMS
uniform vec4 uQuaternion;
uniform sampler2D tMap;
uniform sampler2D tRamp;
uniform sampler2D tErrorRamp;
uniform float uBrightness;
uniform vec2 uPolarRadius;
uniform vec2 uOuterRange;
uniform vec2 uInnerRange;
uniform float uOffset;
uniform float uError;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex

#require(instance.vs)
void main() {
    vec3 pos = transformPosition(position, offset, scale, uQuaternion);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}
#!SHADER: Fragment
#require(transformUV.glsl)
void main() {
    // polar coords
    float PI = 3.1416;
    float r_inner = uPolarRadius.x;
    float r_outer = uPolarRadius.y;

    vec2 x = vUv - vec2(0.5);
    float radius = length(x);
    float angle = atan(x.y, x.x);

    vec2 tc_polar; // the new polar texcoords
    // map radius so that for r=r_inner -> 0 and r=r_outer -> 1
    tc_polar.s = ( radius - r_inner) / (r_outer - r_inner);

    // map angle from [-PI,PI] to [0,1]
    tc_polar.t = angle * 0.5 / PI + 0.5;

    tc_polar.s -= uOffset + time;

    float maskOuter = 1.0 - smoothstep(uOuterRange.x, uOuterRange.y, distance(vUv, vec2(0.5)));
    float maskInner = smoothstep(uInnerRange.x, uInnerRange.y, distance(vUv, vec2(0.5)));
    vec2 expandUv = scaleUV(vUv, vec2(abs(sin(time) + 1.0)), vec2(0.5));
    vec4 color = texture2D(tMap, tc_polar);

    float res = color.b * maskOuter * maskInner * uBrightness;
    gl_FragColor.rgb = mix(
        texture2D(tRamp, vec2(res, 0.0)).rgb,
        texture2D(tErrorRamp, vec2(res, 0.0)).rgb,
        uError
    );
    gl_FragColor.a = res * 50.0;
}{@}TrackAndReactOrbShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tMatcap;
uniform sampler2D tRamp;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;
uniform float uFresnelPow;
uniform float uContrastMix;
uniform float uAlpha;

uniform float uMatcapIndex;
uniform float uBrightness;

uniform vec2 uFogRange;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)

void main() {
    vec3 pos = position;


    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
    vNormal = normalMatrix * normal;
    vViewDir = -(modelViewMatrix * vec4(pos, 1.0)).xyz;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)

void main() {
    float fresnel = getFresnel(normalize(vNormal), vViewDir, uFresnelPow);
    float offset = crange(fresnel, 0.0, 1.0, -1.0, 1.0);
    float c = texture2D(tMap, ((gl_FragCoord.xy/resolution * 8.0) * offset + vec2(-time * 0.15))).r * fresnel;

    float matcap = texture2D(tMatcap, vMuv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0)).r;

    c *= 2.0;
    c += matcap;

    // Fog
    // c += crange(length(vViewDir), uFogRange.x, uFogRange.y, 0.0, 1.0);

    c = clamp(c, 0.0, 1.0);
    c = mix(c, mix(.1, 1., uMatcapIndex), uContrastMix);
    c*=uBrightness;

    vec3 color = texture2D(tRamp, vec2(c, 0.0)).rgb;
    
    gl_FragColor.rgb = color;
    gl_FragColor.a = uAlpha * crange(fresnel, 0.0, 1.0, 0.8, 1.0);
}{@}TrackAndReactSkyShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tNoise;
uniform sampler2D tRamp;

uniform float uBrightness;

uniform vec2 uNoiseTile;
uniform float uNoiseSpeed;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)

void main() {
    float t = time * uNoiseSpeed;

    float c = texture2D(tNoise, vUv + vec2(time * 0.02)).r * 0.2;
    c += getNoise(vUv, time) * 0.05 - (1.0 - uBrightness);

    c *= smoothstep(0.05, 0.5, vUv.y);
    c *= 1.0 - smoothstep(0.5, 0.95, vUv.y);

    c *= uBrightness;

    gl_FragColor.rgb = texture2D(tRamp, vec2(c, 0.0)).rgb;
    gl_FragColor.a = 1.0;
}{@}TrackAndReactSpikeyOrbShader.glsl{@}#!ATTRIBUTES
attribute vec3 vdata;

#!UNIFORMS
uniform sampler2D tMatcap;
uniform sampler2D tRamp;
uniform float uFresnelPow;
uniform float uAlpha;
uniform float uMatcapIndex;
uniform vec2 uFogRange;
uniform float uRippleScale;
uniform float uBrightness;
uniform float uFresnelStrength;

#!VARYINGS
varying vec3 vNormal;
varying vec3 vViewDir;
varying vec2 vMuv;
varying vec3 vVdata;

#!SHADER: Vertex
#require(range.glsl)
#require(matcap.vs)
#require(rotation.glsl)

void main() {
    vec3 pos = vec3(rotationMatrix(vec3(0.0, 0.0, 1.0), time) * vec4(position, 1.0));//little trick so meshbatch doesn't get weird
    pos = pos;
    vec3 offset = vdata * sin(vdata.y * 3.0 + time * 5.0) * uRippleScale;
    pos += offset;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vNormal = normalMatrix * vec3(rotationMatrix(vec3(0.0, 0.0, 1.0), time) * vec4(normal, 1.0));
    vViewDir = -(modelViewMatrix * vec4(pos, 1.0)).xyz;
    vMuv = reflectMatcap(pos, modelViewMatrix, normalize(vNormal));
    vVdata = vdata;
}

#!SHADER: Fragment
#require(range.glsl)
#require(simplenoise.glsl)
#require(fresnel.glsl)

void main() {
    float fresnel = getFresnel(normalize(vNormal), vViewDir, uFresnelPow);
    float offset = crange(fresnel, 0.0, 1.0, -1.0, 1.0);
    float c = 0.0;
    float matcap = texture2D(tMatcap, vMuv * vec2(0.5, 1.0) + vec2(0.5 * uMatcapIndex, 0.0)).r * fresnel * uFresnelStrength;

    c *= 2.0;
    c += matcap;

    // Fog
    // c += crange(length(vViewDir), uFogRange.x, uFogRange.y, 0.0, 1.0);
    c = clamp(c, 0.0, 1.0);
    c *= uBrightness;
    gl_FragColor.rgb = texture2D(tRamp, vec2(c, 0.0)).rgb;
    gl_FragColor.a = uAlpha * crange(fresnel, 0.0, 1.0, 0.8, 1.0);
}{@}TrackReactFeedbackParticles.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform float DPR;
uniform sampler2D tPos;
uniform sampler2D tMask;
uniform sampler2D tColor;
uniform sampler2D tColorRamp;
uniform sampler2D tLife;

uniform vec3 uLightColor;
uniform vec3 uDarkColor;
uniform vec3 uHSL;

uniform vec2 uScale;
uniform vec2 uDOFScale;
uniform vec2 uFar;
uniform vec2 uNear;

uniform float uAlpha;
uniform float uSize;
uniform float uDOFStrength;
uniform float uColorNScale;
uniform float uColorRampMix;

#!VARYINGS
varying vec4 vRandom;

varying vec3 vColor;

varying float vAlpha;
varying float vRot;
varying float vLife;

#!SHADER: Vertex

#require(range.glsl)
#require(simplenoise.glsl)
#require(rgb2hsv.fs)
#require(eases.glsl)


void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    vec4 mPosition = modelMatrix * vec4(pos, 1.0);
    vec4 mvPosition = viewMatrix * mPosition;
    float size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    size *= uSize * crange(expoIn(random.w), 0.0, 1.0, uScale.x, uScale.y);
    
    gl_PointSize = size;
    gl_Position = projectionMatrix * mvPosition;
    
    float decodedColor = texture2D(tColor, position.xy).g;

    vec3 color = vec3(0.);

    if(decodedColor < .5) {
        color = uDarkColor;
    }else{
        color = uLightColor;
    }   

    vColor = color;
    vRot = dot(normalize(pos), vec3(0.0, 1.0, 0.0)) * radians(60.0);

    vColor = rgb2hsv(vColor);
    float n = cnoise(pos * uColorNScale);
    vColor += n * uHSL * 0.1;
    vColor = hsv2rgb(vColor);
    vAlpha = uAlpha;
    vRandom = random;

    float life = texture2D(tLife, position.xy).x;
    vAlpha *= crange(life, 1.0, 0.9, 0.0, 1.0);
    vAlpha *= crange(life, 0.5, 0.0, 1.0, 0.0);
}

#!SHADER: Fragment
#require(range.glsl)
#require(transformUV.glsl)
#require(rgb2hsv.fs)
void main() {
    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    vec2 mask = texture2D(tMask, uv).rg;
    float blurredMask = mix(mask.g, mask.r, .5);
    if (blurredMask < 0.01) discard;


    vec3 color = vColor;
    vec2 luv = rotateUV(uv, vRot);

    color *= crange(smoothstep(0.3, 1.0, luv.y)*0.5 - smoothstep(0.5, 1.1, 1.0-luv.y)*0.2, 0.0, 0.3, 0.7, 1.2);
    color += sin(time*5.0+vRandom.z*20.0)*mix(0.4, 0.04, 1.);

    float luma = rgb2hsv(color).z;
    vec3 ramp = texture2D(tColorRamp, vec2(luma, 0.0)).rgb;
    color = mix(color, ramp, crange(luma, 0.0, 0.4, 1.0, uColorRampMix));

    gl_FragColor = vec4(color, blurredMask * vAlpha);
}{@}TrackAndReactRing.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;
uniform float uMoved;
uniform float uHit;
uniform vec3 uColor;
uniform vec3 uColor2;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

void main() {
    vUv = uv;
    vec3 pos = position;
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(range.glsl)
#require(blendmodes.glsl)

void main() {
    float alpha = texture2D(tMap, vUv).r;


    float scan = fract(time*0.3+vUv.y*1.2);
    scan = smoothstep(0.0, 0.5, scan) * smoothstep(1.0, 0.5, scan);
    scan = mix(scan, 1.0, smoothstep(0.0, 1.5, vUv.y));
    alpha *= scan;

    vec3 color = uColor;

    color = mix(color, blendLinearBurn(color, uColor2), uHit*0.7);

    gl_FragColor.rgb = color;
    gl_FragColor.a = alpha * uAlpha * uMoved;
}{@}VRWorldLoaderIconShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    if (vUv.y < 0.2) discard;
    gl_FragColor = texture2D(tMap, vUv);
    gl_FragColor.a *= uAlpha;
}
{@}VRWorldLoaderSkyboxShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(uColor, uAlpha);
}
{@}AnimTestShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;

#!VARYINGS

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(uColor, 1.0);
}{@}CurveTest.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uPadding;
uniform float uTransition;

#!VARYINGS
varying float vTransition;

#!SHADER: Vertex
void main() {

}

#!SHADER: Fragment
void main() {
    alpha *= rangeTransition(uTransition, vUv.x, uPadding);
    gl_FragColor = vec4(vec3(1.), alpha);
}
 {@}FoveationTest.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    highp vec2 dx = dFdx(gl_FragCoord.xy), dy = dFdy(gl_FragCoord.xy);
    highp vec2 level = floor(0.5 * log2(vec2(dot(dx, dx), dot(dy, dy))));
    float a = float(all(equal(level, vec2(0.))));
    float b = float(all(equal(level, vec2(1., 0.))));
    float c = float(all(equal(level, vec2(1., 1.))));
    float d = float(all(equal(level, vec2(2., 1.))));
    float e = float(all(equal(level, vec2(2., 2.))));
    float f = 1. - a - b - c - d - e;
    lowp vec4 color = vec4(0.0, 0.0, 0.0, 1.0) * f +
        vec4(1.0, 1.0, 1.0, 1.0) * a +    //  1:1 = White
        vec4(1.0, 0.0, 0.0, 1.0) * b +    //  1:2 = Red
        vec4(0.0, 1.0, 0.0, 1.0) * c +    //  1:4 = Green
        vec4(0.0, 0.0, 1.0, 1.0) * d +    //  1:8 = Blue
        vec4(1.0, 0.0, 1.0, 1.0) * e;     //  1:16 = Purple
    gl_FragColor = color;
}
{@}LineShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor2;
uniform float uTransition;
uniform float uPadding;
uniform float uLineCount;

#!VARYINGS

#!SHADER: Vertex
void main() {

}

#!SHADER: Fragment
void main() {
    alpha *= rangeTransition(uTransition, (vUv.x + vLineIndex) / uLineCount, uPadding);
    gl_FragColor = vec4(uColor2, alpha);
}
{@}FlowmapShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tLines;
uniform sampler2D tMap;
uniform sampler2D tFlow;
uniform sampler2D tOffset;
uniform float uFlowSpeed;
uniform float uFlowAmp;
uniform float uFlowTimeMult;
uniform float uStrength;

uniform float uAngle;

uniform float uAlpha;
uniform float uLineTile;
uniform float uLineFreq;
uniform float uLineSpeed;

uniform float uMaskStep;
uniform vec2 uFlowOffset;
uniform vec2 uFlowScale;
uniform float uThreshold;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)

void main() {
    vec3 pos = position;

    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vPos = pos;
}

#!SHADER: Fragment
#require(range.glsl)

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

vec3 getFlow(sampler2D tMap, sampler2D tFlow, vec2 uv, float speed, float strength, float time) {
    float t = time * speed;
    float mask = fract(t);
    mask = (mask- 0.5) * 2.0;
    mask = abs(mask);
    
    vec2 flow = texture2D(tFlow, uv).rg;
    flow = crange(flow, vec2(0.0), vec2(1.0), vec2(-1.0), vec2(1.0));

    vec3 color = texture2D(tMap, uv + flow * strength * fract(t + 0.5)).rgb;
    vec3 color2 = texture2D(tMap, uv + flow * strength * fract(t + 0.0)).rgb; 
    color = mix(color2, color, mask);
    return color;
}

void main() {
    vec2 uv = vUv * vec2(uLineTile, 1.0);

    vec2 flowOffset = uFlowOffset * time * 0.2 * uFlowTimeMult;
    vec3 flow = getFlow(tFlow, tFlow, (uv + flowOffset) * uFlowScale, uFlowSpeed, uFlowAmp, time * uFlowTimeMult);

    vec4 color = texture2D(tLines, uv + ((flow.rg - 0.5) * 2.0) * uStrength);
    float mask = step(uMaskStep, color.g);
    if (mask < uThreshold) discard;

    float curveu = color.r;
    float animatedline = sin(curveu * uLineFreq + time * uLineSpeed);

    gl_FragColor.rgb = vec3(animatedline);
    gl_FragColor.a = uAlpha;
}{@}BlurPass.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec2 uDirection;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Fragment
#require(gaussianblur.fs)

#test Tests.ui3dBlurSamples() == 13
    #define blur blur13
#endtest
#test Tests.ui3dBlurSamples() == 9
    #define blur blur9
#endtest
#test Tests.ui3dBlurSamples() == 5
    #define blur blur5
#endtest

void main() {
    vec2 uv = vUv;
    gl_FragColor = blur(tDiffuse, uv, uSize, uDirection);
}
{@}UIButtonShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec3 uColor;
uniform float uColorAlpha;
uniform vec3 uHoverColor;
uniform vec3 uBorderColor;
uniform vec3 uHoverBorderColor;
uniform float uHover;
uniform float uTransparent;
uniform float uAlpha;
uniform float uAccessibilityMode;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(roundedBorder.glsl)
#require(FeatheredSlider.fs)

#test Tests.isMobilePhone()
const float borderWidth = 1.25;
#endtest

#test !Tests.isMobilePhone()
const float borderWidth = 2.0;
#endtest

void main() {
    float inside;
    vec3 borderColor3 = mix(uBorderColor, uHoverBorderColor, uHover);
    vec4 borderColor = vec4(borderColor3, roundedBorder(borderWidth, 4., vUv, uSize, inside));

    vec4 color = mix(vec4(uColor, uColorAlpha), vec4(uHoverColor, uColorAlpha), uHover);
    color.a *= inside;
    float a = borderColor.a + color.a * (1. - borderColor.a);
    color = vec4((borderColor.rgb * borderColor.a + color.rgb * color.a * (1. - borderColor.a)) / a, a);

    color.a *= uAlpha * featheredSliderAlpha();

    if(uTransparent > .01 && color.a < .01) {
        discard;
    }

    gl_FragColor = color;
}
{@}UIButtonText.glsl{@}#!ATTRIBUTES

#!UNIFORMS

uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uAccessibilityMode;

#!VARYINGS

varying vec2 vUv;

#!SHADER: Vertex

void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(msdf.glsl)
#require(FeatheredSlider.fs)

void main() {
    float alpha = msdf(tMap, vUv);

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha * featheredSliderAlpha();
}
{@}UIDescriptionShader.glsl{@}#!ATTRIBUTES
attribute vec3 animation;
#!UNIFORMS
uniform sampler2D tMap;
uniform vec2 uRange;
uniform float uTransition;
uniform float uTransparency;
uniform float uWordCount;
uniform vec3 uColor;
#!VARYINGS
varying vec2 vUv;
varying float vId;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vId = animation.x;
}

#!SHADER: Fragment

#require(msdf.glsl)
#require(range.glsl)
void main() {
    float alpha = msdf(tMap, vUv);
    alpha *= crange((uWordCount - (vId))/uWordCount, uRange.x, uRange.y, 0., 1.);
    alpha *= uTransparency;
    gl_FragColor = vec4(uColor, alpha);
}
{@}UIHeaderLogo.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform float uAlpha;
uniform vec3 uColor;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
void main() {
    gl_FragColor = vec4(uColor, texture2D(tMap, vUv).a * uAlpha);
}
{@}GLUIIconShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec2 uPattern;
uniform vec2 uDimensions;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uRotation;

#!VARYINGS
varying vec2 vUv;
varying vec2 vUv2;

#!SHADER: Vertex
#require(transformUV.glsl)

void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
    vUv2 = translateUV(scaleUV(rotateUV(uv, uRotation), vec2(uDimensions.x, uDimensions.y), vec2(0.0)), vec2(-(uPattern.x / uDimensions.x), -(uPattern.y / uDimensions.y)));
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

void main() {
    float a = texture2D(tMap, vUv2).a;
    if(a < 0.001) {
        discard;
    }
    
    a*= featheredSliderAlpha();

    gl_FragColor = vec4(uColor, a * uAlpha);
}{@}UIAudioIconShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uActive;
uniform float uTime;
uniform float uSpeed;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

float sinLoop(float offset) {
	return 0.2 + 0.6 * abs(sin(uTime * uSpeed * 0.6 - offset)) + 0.2 * abs(sin(uTime * uSpeed * 0.8 - offset * 2.2));
}

const float count = 10.;

void main() {
    vec2 uv = vUv;

    float repeatX = mod(uv.x * count, 1.0);
    vec2 lineUv = vec2(
        (repeatX * 2. - 1.) / count,
        uv.y * 2. - 1.
    );

    float x = floor(uv.x * count) / count;
    float height = 0.65 * sinLoop(x * 5.);
    height *= smoothstep(0.0, 0.2, x) * smoothstep(1.0, 0.8, x);
    height = mix(0.1, height, uActive);

    float radius = 0.5 / count;
    vec2 halfSize = vec2(radius, height);

    float dist = length(max(abs(lineUv) + vec2(radius) - halfSize, 0.0)) - radius;
    float delta = fwidth(dist) / 3.;
    float line = 1.0 - smoothstep(-delta, delta, dist);

    float alpha = line * uAlpha * featheredSliderAlpha();

    gl_FragColor = vec4(uColor, alpha);
}
{@}UICaptionsIconShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;
uniform float uActive;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)
#require(roundedBorder.glsl)

const float borderWidth = 1.5 / 32.;
const float radius = 2. / 32.;
const vec2 size = vec2(30., 23.) / 32.;

void main() {
    vec2 uv = ((vUv * 2.) - 1.) / size;
    uv = (uv + 1.) / 2.;

    vec3 fillColor3 = vec3(1.);
    vec3 borderColor3 = mix(uColor, fillColor3, uActive);

    float inside;
    vec4 borderColor = vec4(borderColor3, roundedBorder(borderWidth, radius, uv, size, inside));
    vec4 fillColor = vec4(fillColor3, inside * uActive);

    float a = borderColor.a + fillColor.a * (1. - borderColor.a);
    vec4 color = vec4((borderColor.rgb * borderColor.a + fillColor.rgb * fillColor.a * (1. - borderColor.a)) / a, a);

    gl_FragColor = vec4(color.rgb, color.a * uAlpha * featheredSliderAlpha());
}
{@}UICircleShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform float uBorderWidth;
uniform vec3 uBorderColor;
uniform vec3 uFillColor;
uniform float uBorderTransition;
uniform float uFillTransition;
uniform float uAlpha;
uniform float uFillAlpha;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vec3 pos = position;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)
#require(eases.glsl)
#ifndef PI2
#define PI2 6.283185307179586
#endif
float getAngle(vec2 p){
    float angle = 2.0 * atan(p.y, length(p) + p.x);
    return PI2 - mod(angle + PI2 - HALF_PI, PI2);
}


void main() {
    float pAngle = mod(getAngle(vUv - 0.5), radians(360.0));
    pAngle = crange(pAngle, 0., PI2, 0., 1.);

    vec2 uv = vUv * 2. - 1.; // -1.0 ... 1.0
    float r = length(uv);

    // border
    float borderWidth = uBorderWidth / uSize.y;
    float dist = abs(r-(1. - borderWidth));
    float delta = fwidth(dist);
  	float alpha = 1.0 - smoothstep(-delta, delta, dist - borderWidth);
    alpha *= (1. - smoothstep(uBorderTransition - .1, uBorderTransition, pAngle));
    vec4 border = vec4(uBorderColor, alpha);

    // fill
    dist = r-(1. - borderWidth);
    delta = fwidth(dist);
    float limit = borderWidth * 0.5;
    alpha = 1.0 - smoothstep(-delta, delta, dist - limit);
    alpha *= smoothstep(uFillTransition, uFillTransition - borderWidth, r);
    vec4 fill = vec4(uFillColor, uFillAlpha * alpha);

    alpha = border.a + fill.a * (1. - border.a);
    if(alpha < .01) {
        discard;
    }

    vec4 diffuse = vec4((border.rgb * border.a + fill.rgb * fill.a * (1. - border.a)) / alpha, alpha);
    diffuse.a *= featheredSliderAlpha();
    gl_FragColor = vec4(diffuse.rgb, diffuse.a * uAlpha);
}
{@}UIThemeSwitchIconShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColorA;
uniform vec3 uColorB;
uniform float uAlpha;
uniform float uTransition;


#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

    #!SHADER: Fragment
float circle(vec2 dist, float radius){
    return 1.-smoothstep(radius-(radius*0.1),
    radius+(radius*0.1),
    dot(dist,dist)*4.0);
}

void main() {
    float w = fwidth(vUv.x) * 4.;
    vec2 d = vUv-vec2(0.5);
    float c = circle(d, 0.95);
    float shape = c - circle(d, 0.95 - (w * 2.));

    float x = 0.5 * uTransition;
    shape += step(vUv.x - x, 0.5) * step(0., vUv.x - x);
    shape = min(shape * c, 1.);

    vec3 color = shape * mix(uColorA, uColorB, 1.0 - uTransition);

    gl_FragColor = vec4(color, shape);
    gl_FragColor.a *= uAlpha;
//    gl_FragColor = vec4(vUv, 0.0, 1.0);
}
{@}UIResultsViewFadeShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform vec2 uRange;
uniform float uDirection;
#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(range.glsl)
void main() {
    float alpha = 1.;
    if(uDirection > 0.01) {
        if(1. - vUv.x > .85){
            alpha = 1. - crange(1. - vUv.x, .85, 1., 0., .8);
        }
    }

    if(uDirection < .01) {
        if(vUv.x > .85){
            alpha = 1. - crange(vUv.x, .85, 1., 0., .8);
        }
    }

    gl_FragColor = vec4(uColor, alpha);
}{@}UIResultsViewHeaderButtonShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec3 uColor;
uniform vec3 uBorderColor;
uniform float uHover;
uniform float uTransparent;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(roundedBorder.glsl)

void main() {
    float inside;
    vec4 borderColor = vec4(uBorderColor, roundedBorder(1.3, 4., vUv, uSize, inside));

    vec4 color = vec4(uColor, uHover * inside);
    float a = borderColor.a + color.a * (1. - borderColor.a);
    color = vec4((borderColor.rgb * borderColor.a + color.rgb * color.a * (1. - borderColor.a)) / a, a);

    color.a *= uAlpha;

    if(uTransparent > .01 && color.a < .01) {
        discard;
    }

    gl_FragColor = color;
}{@}UIResultsViewIndicatorShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

void main() {
    gl_FragColor = vec4(uColor, uAlpha * featheredSliderAlpha());
}{@}UIResultsViewTextShader.glsl{@}#!ATTRIBUTES
attribute vec3 animation;

#!UNIFORMS

uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform vec3 uTranslate;
uniform vec3 uRotate;
uniform float uTransition;
uniform float uWordCount;
uniform float uLineCount;
uniform float uLetterCount;
uniform float uByWord;
uniform float uByLine;
uniform float uPadding;
uniform float uFlicker;
uniform vec3 uBoundingMin;
uniform vec3 uBoundingMax;

#!VARYINGS

varying vec2 vUv;
varying float vTrans;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)
#require(eases.glsl)
#require(rotation.glsl)
#require(conditionals.glsl)

void main() {
    vUv = uv;
    vTrans = 1.0;
    vec3 pos = position;
    vPos = pos;

    if (uTransition < 5.0) {
        float padding = uPadding;
        float letter = (animation.x + 1.0) / uLetterCount;
        float word = (animation.y + 1.0) / uWordCount;
        float line = (animation.z + 1.0) / uLineCount;

        float letterTrans = crange(uTransition, letter - padding, letter + padding, 0.0, 1.0);
        float wordTrans = crange(uTransition, word - padding, word + padding, 0.0, 1.0);
        float lineTrans = crange(uTransition, line - padding, line + padding, 0.0, 1.0);

        vTrans = mix(cubicOut(letterTrans), cubicOut(wordTrans), uByWord);
        vTrans = mix(vTrans, cubicOut(lineTrans), uByLine);

        float invTrans = (1.0 - vTrans);
        vec3 nRotate = normalize(uRotate);
        vec3 axisX = vec3(1.0, 0.0, 0.0);
        vec3 axisY = vec3(0.0, 1.0, 0.0);
        vec3 axisZ = vec3(0.0, 0.0, 1.0);
        vec3 axis = mix(axisX, axisY, when_gt(nRotate.y, nRotate.x));
        axis = mix(axis, axisZ, when_gt(nRotate.z, nRotate.x));
        pos = vec3(vec4(position, 1.0) * rotationMatrix(axis, radians(max(max(uRotate.x, uRotate.y), uRotate.z) * invTrans)));
        pos += uTranslate * invTrans;
    }


    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(FeatheredSlider.fs)
#require(msdf.glsl)

void main() {
    float alpha = msdf(tMap, vUv);
    alpha *= featheredSliderAlpha();

    float flicker = max(1.0 - uFlicker, 0.6+sin(time*60.0)*0.4);
    float center = 0.3;
    float padding = 0.2;
    alpha *= mix(1.0, flicker, smoothstep(center-padding, center, uTransition)*smoothstep(center+padding, center, uTransition));

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha * vTrans * smoothstep(0.0, 0.1, uTransition);
}{@}UISpiderGraphShape.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec3 uColor;
uniform float uAlpha;
uniform float uTransition;

#!VARYINGS
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex
#require(range.glsl)
#require(eases.glsl)

const float PI_2 = 6.283185307179586;
const float stagger = 0.2;

void main() {
    vUv = uv;
    // To animate in/out, move the position of each point from the center along its axis,
    // in sequence around the graph in a clockwise direction.
    vec3 pos = vec3(0.);
    float angle = atan(position.x, position.y);
    // atan returns angles in both a clockwise direction (rhs) and counter clockwise (lhs),
    // Ao need to adjust those on the lhs to go clockwise too.
    angle = angle < 0. ? (PI_2 + angle) : angle;
    // Animate in six segments around the clock.
    float t1 = crange(angle, 0., PI_2, 0., 1.) * 6.;
    float t2 = uTransition * 6.;
    float t = clamp(t2 * (1. - stagger) - t1 * stagger, 0., 1.);
    pos = mix(pos, position, cubicOut(t));
    vPos = pos;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)
#require(simplenoise.glsl)

void main() {
    float alpha = uAlpha * featheredSliderAlpha();

    float noise = cnoise(vPos.xy*0.001+time*0.2);
    alpha *= 0.8 + noise * 0.2;


    gl_FragColor = vec4(uColor, alpha);
}
{@}UIStatCardBackgroundShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec3 uBorderColor;
uniform float uAlpha;
uniform float uScale;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(roundedBorder.glsl)
#require(FeatheredSlider.fs)
const float borderWidth = 1.5;
const float borderRadius = 10.0;

float random (in float x) {
    return fract(sin(x)*1e4);
}

float random (in vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))* 43758.5453123);
}

float pattern(vec2 st, vec2 v, float t) {
    vec2 p = floor(st+v);
    return step(t, random(100.+p*.0005)+random(p.x)*0.7 );
}

void main() {
    float inside;
    float borderValue = roundedBorder(borderWidth, borderRadius, vUv, uSize, inside) * 0.5;
    float alpha = borderValue * smoothstep(uAlpha+0.001, uAlpha, mix(vUv.x, 1.0-vUv.y, 0.2));//crange(, uAlpha+0.01, uAlpha, 0.0, 1.0);

    float flicker = 0.5+sin(time*35.0)*0.5;
    alpha = mix(alpha, flicker*alpha, smoothstep(1.0, 0.3, uAlpha));
    float fill = (1.0-vUv.y)*mix(1.0, vUv.x, uAlpha)*(mix(0.4, 0.2, uAlpha)) * smoothstep(0.0, 0.5, uAlpha);

    #test Tests.uiCipherBackground()
        vec2 st = vUv.yx / uScale;
        st.x *= uSize.y / uSize.x;

        vec2 grid = vec2(80.0, 80.0);
        st *= grid;

        vec2 ipos = floor(st);  // integer
        vec2 fpos = fract(st);  // fraction

        vec2 vel = vec2((time/2.*max(grid.x,grid.y))+uAlpha*20.0); // time
        vel *= vec2(0.05,0.0) * random(1.0+ipos.y); // direction

        // Assign a random value base on the integer coord
        vec2 offset = vec2(0.1,0.);

        float c = clamp(pattern(st+offset,vel,0.9), 0., 1.);
        float a = step(.7,fpos.y);
        fill += c * a * 0.4 * uAlpha;
        fill *= inside;
    #endtest
    //fill *= smoothstep(uAlpha+0.1, uAlpha-0.2*smoothstep(1.0, 0.8, uAlpha), mix(vUv.x, 1.0-vUv.y, 0.2)) * smoothstep(0.0, 0.5, uAlpha);

    alpha += mix(fill, flicker*fill, smoothstep(0.5, 0.0, uAlpha)*0.2);
    alpha *= featheredSliderAlpha();

    gl_FragColor = vec4(uBorderColor, alpha);
    //gl_FragColor.a *= uAlpha;
}{@}FeatheredSlider.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform float uFeatherWidth;
uniform vec2 uFeatherDirection;
uniform vec2 uFeatherBounds;

#!VARYINGS

#!SHADER: Vertex

#!SHADER: Fragment
#require(range.glsl)

float featheredSliderAlpha() {

    if(uFeatherDirection.x > 0.01) {
        float width = uFeatherWidth / resolution.x;
        float x = gl_FragCoord.x / resolution.x;
        float left = crange(x, uFeatherBounds.x, uFeatherBounds.x + width, 0.0, 1.0);
        float right = crange(x, uFeatherBounds.y - width, uFeatherBounds.y, 1.0, 0.0);
        float feather = left * right;
        if (feather < 0.01) {
            discard;
        }
        return feather;
    }

    if(uFeatherDirection.y > .01) {
        float height = uFeatherWidth / resolution.y;
        float y = 1. - gl_FragCoord.y / resolution.y;
        float top = crange(y, uFeatherBounds.x, uFeatherBounds.x + height, 0.0, 1.0);
        float bottom = crange(y, uFeatherBounds.y - height, uFeatherBounds.y, 1.0, 0.0);
        float feather = top * bottom;
        if (feather < 0.01) {
            discard;
        }
        return feather;
    }

    return 1.;
}{@}UITimelineResultBorderShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;


#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

void main() {
    vec4 diffuse = texture2D(tMap, vUv);
    float alpha = diffuse.r * featheredSliderAlpha();
    if(alpha < .01) {
        discard;
    }

    gl_FragColor = vec4(uColor, uAlpha * alpha);
}{@}GLUIModalBackground.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform float uAlpha;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment

void main() {
    float aspect = resolution.x / resolution.y;
    vec2 ratio = vec2(min(1.0, aspect), min(1.0, 1.0 / aspect));
    vec2 squareUv = (2.0 * vUv - 1.0) * ratio;

    float dist = length(squareUv - vec2(0.));
    vec3 color = mix(vec3(.62, .66, .67), vec3(.816, .839, .835), 1. -smoothstep(.7,1., dist));

    gl_FragColor = vec4(color, uAlpha);
}{@}FeatheredDefaultText.glsl{@}#!ATTRIBUTES

#!UNIFORMS

uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;

#!VARYINGS

varying vec2 vUv;

#!SHADER: Vertex

void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment

#require(FeatheredSlider.fs)
#require(msdf.glsl)

void main() {
    float alpha = msdf(tMap, vUv);

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha * featheredSliderAlpha();
}
{@}HexBgShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform float uAlpha2;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)
#require(simplenoise.glsl)

void main() {
    vec4 diffuse = texture2D(tMap, vUv);
    float alpha = diffuse.r * featheredSliderAlpha();
    alpha *= smoothstep(uAlpha+0.2, uAlpha, diffuse.g);

    float noise = cnoise(vUv*2.0-time*0.2);
    alpha *= 0.8 + noise * 0.2;

    if(alpha < .01) {
        discard;
    }

    gl_FragColor = vec4(uColor, alpha*uAlpha2);
}{@}RegularBorderShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec3 uBorderColor;
uniform float uBorderAlpha;
uniform float uFillAlpha;
uniform float uAlpha;
uniform float uHover;

#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(roundedBorder.glsl)
#require(FeatheredSlider.fs)

#test Tests.isMobilePhone()
const float borderWidth = 1.5;
const float borderRadius = 4.0;
#endtest

#test !Tests.isMobilePhone()
const float borderWidth = 2.5;
const float borderRadius = 10.0;
#endtest

void main() {
    float insideBorder;
    float borderValue = roundedBorder(borderWidth, borderRadius, vUv, uSize, insideBorder) * uBorderAlpha;
    float alpha = borderValue * smoothstep(uAlpha+0.001, uAlpha, mix(vUv.x, 1.0-vUv.y, 0.2));

    float flicker = 0.5+sin(time*35.0)*0.5;
    alpha = mix(alpha, flicker*alpha, smoothstep(1.0, 0.3, uAlpha));

    float fill = insideBorder * clamp((1.0-vUv.y)*mix(1.0, vUv.x, uAlpha)*(mix(0.7, 0.4, uAlpha)) * smoothstep(0.0, 0.5, uAlpha) + uHover, 0., 1.);
    fill *= uFillAlpha;

    alpha += mix(fill, flicker*fill, smoothstep(0.5, 0.0, uAlpha)*0.2);
    alpha *= featheredSliderAlpha();

    if (alpha < .01) {
        discard;
    }
    gl_FragColor = vec4(uBorderColor, alpha);
}{@}RegularImageShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)

void main() {
    vec4 diffuse = texture2D(tMap, vUv);
    float alpha = diffuse.r * featheredSliderAlpha();
    if(alpha < .01) {
        discard;
    }

    gl_FragColor = vec4(uColor, alpha);
}{@}UIText3D.glsl{@}#!ATTRIBUTES
attribute vec3 animation;

#!UNIFORMS
uniform sampler2D tMap;
uniform vec3 uColor;
uniform float uAlpha;
uniform vec3 uTranslate;
uniform vec3 uRotate;
uniform vec4 uCount;
uniform vec4 uAnim;

#!VARYINGS
varying float vTrans;
varying vec2 vUv;
varying vec3 vPos;

#!SHADER: Vertex

#require(range.glsl)
#require(eases.glsl)
#require(rotation.glsl)
#require(conditionals.glsl)

void main() {

    vec3 pos = position;

    vPos = pos;

    //start batch main
    vTrans = 1.0;

    if (uCount.w < 5.0) {
        float padding = uAnim.z;
        float letter = (animation.x + 1.0) / uCount.x;
        float word = (animation.y + 1.0) / uCount.y;
        float line = (animation.z + 1.0) / uCount.z;

        float letterTrans = crange(uCount.w, letter - padding, letter + padding, 0.0, 1.0);
        float wordTrans = crange(uCount.w, word - padding, word + padding, 0.0, 1.0);
        float lineTrans = crange(uCount.w, line - padding, line + padding, 0.0, 1.0);

        vTrans = mix(cubicOut(letterTrans), cubicOut(wordTrans), uAnim.x);
        vTrans = mix(vTrans, cubicOut(lineTrans), uAnim.y);

        float invTrans = (1.0 - vTrans);
        vec3 nRotate = normalize(uRotate);
        vec3 axisX = vec3(1.0, 0.0, 0.0);
        vec3 axisY = vec3(0.0, 1.0, 0.0);
        vec3 axisZ = vec3(0.0, 0.0, 1.0);
        vec3 axis = mix(axisX, axisY, when_gt(nRotate.y, nRotate.x));
        axis = mix(axis, axisZ, when_gt(nRotate.z, nRotate.x));
        pos = vec3(vec4(position, 1.0) * rotationMatrix(axis, radians(max(max(uRotate.x, uRotate.y), uRotate.z) * invTrans)));
        pos += uTranslate * invTrans;
    }
    //end batch main
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}

#!SHADER: Fragment

#require(FeatheredSlider.fs)
#require(msdf.glsl)
#require(simplenoise.glsl)

void main() {
    float alpha = msdf(tMap, vUv);

    //float noise = 0.5 + smoothstep(-1.0, 1.0, cnoise(vec3(vUv*8.0, time* 0.3))) * 0.5;
    //alpha *= noise;

    //alpha *= smoothstep(0.0, 0.1, uTransition);

    float flicker = max(1.0 - uAnim.w, 0.6+sin(time*60.0)*0.4);
    float center = 0.3;
    float padding = 0.2;
    alpha *= mix(1.0, flicker, smoothstep(center-padding, center, uCount.w)*smoothstep(center+padding, center, uCount.w));
    alpha *= featheredSliderAlpha();

    gl_FragColor.rgb = uColor;
    gl_FragColor.a = alpha * uAlpha * vTrans * smoothstep(0.0, 0.1, uCount.w);
}
{@}LandingTextShader.glsl{@}#!ATTRIBUTES
attribute vec3 animation;
#!UNIFORMS
uniform sampler2D tMap;
uniform vec2 uRange;
uniform float uTransparency;
uniform float uGlyphCount;
#!VARYINGS
varying vec2 vUv;
varying float vId;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
    vId = animation.x;
}

#!SHADER: Fragment

#require(msdf.glsl)
#require(eases.glsl)
void main() {
    float alpha = msdf(tMap, vUv);
    alpha *= smoothstep(uRange.x, uRange.y, vUv.y);
    alpha *= cubicOut(uTransparency);
    gl_FragColor = vec4(vec3(1.0), alpha);
}{@}UI3DElementShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
uniform sampler2D tBg;
uniform float uGlassAlpha;
uniform vec2 uSize;
uniform vec2 uBlurDirection;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    vUv = uv;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}

#!SHADER: Fragment
#require(range.glsl)

void main() {
    vec4 original = texture2D(tMap, vUv);
    vec4 diffuse = original;

    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec4 bg = texture2D(tBg, uv) * uGlassAlpha;
    // The RT (tMap) started out fully transparent, so after having blended things onto it,
    // it’s now premultipled alpha. Normal blending with premultiplied alpha is different than
    // with straight alpha:
    //     src + dst * (1 - srcAlpha)
    diffuse += bg * (1. - original.a);

    gl_FragColor = diffuse;
}{@}UIBreakdownCard.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform vec2 uSize;
uniform vec3 uBorderColor;
uniform vec3 uColor;
uniform float uValue1;
uniform float uValue2;
uniform float uValue3;
uniform float uValue4;
uniform float uValue5;
uniform float uValue6;
uniform float uValue7;
uniform float uValue8;
uniform float uValue9;
uniform float uValueCount;
uniform float uBorderTransition;
uniform float uAlpha;
uniform float uTransition;
uniform float uTransition2;

#!VARYINGS
varying vec2 vUv;

#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
#require(FeatheredSlider.fs)
#require(eases.glsl)
#require(simplenoise.glsl)
#require(roundedBorder.glsl)

const float borderWidth = 1.0;
const float borderRadius = 10.0;

float chart(float height, vec2 uv, vec2 resolution) {
    const float thickness = 2.62;
    const float gap = 2.0;

    vec2 coords = vec2(uv.x * resolution.x, uv.y * resolution.y);

    float dx = thickness * 0.5 - mod(coords.x, thickness + gap);
    float ax = smoothstep(1.0, 0.9, abs(dx / (thickness / 2.0)));

    float columnIndex = floor(coords.x / (thickness + gap));
    float columnCount = floor(resolution.x / (thickness + gap));
    float x = columnIndex / columnCount;

    float value = uValue1;
    float valueStep = 1. / (uValueCount - 1.);
    value = mix(value, uValue2, smoothstep(valueStep * 0., valueStep * 1., x));
    value = mix(value, uValue3, smoothstep(valueStep * 1., valueStep * 2., x));
    value = mix(value, uValue4, smoothstep(valueStep * 2., valueStep * 3., x));
    value = mix(value, uValue5, smoothstep(valueStep * 3., valueStep * 4., x));
    value = mix(value, uValue6, smoothstep(valueStep * 4., valueStep * 5., x));
    value = mix(value, uValue7, smoothstep(valueStep * 5., valueStep * 6., x));
    value = mix(value, uValue8, smoothstep(valueStep * 6., valueStep * 7., x));
    value = mix(value, uValue9, smoothstep(valueStep * 7., valueStep * 8., x));
    value += sin(x*8.0) * sin(x*45.0) * sin(x*95.0) * sin(x*160.0) * 1.5;
    value = clamp(0.0, 10.0, value);

    float heightFactor = value/5.0;

    float columnTransition = crange(cubicOut(uTransition), x, 1.0, 0.0, 1.0);
    float heightTransitionFactor = cubicOut(columnTransition);

    float columnHeight = heightTransitionFactor * height * heightFactor;
    float dy = columnHeight - coords.y;
    float ay = smoothstep(0.0, 0.01, dy);
    #test !Tests.uiCipherBackground()
        float shine = 1.0;
    #endtest
    #test Tests.uiCipherBackground()
        float shine = (0.8 + sin(time*4.0-uv.x*5.0)*0.2);
    #endtest

    return uTransition2 * ax * ay * shine;
}

void main() {
    float heightFactor = 0.3;
    float chartValue = chart(uSize.y * heightFactor, vUv, uSize);

    float maskValue;
    float borderValue = roundedBorder(borderWidth, borderRadius, vUv, uSize, maskValue);
    borderValue *= smoothstep(uBorderTransition+0.001, uBorderTransition, mix(vUv.x, 1.0-vUv.y, 0.2));

    vec4 diffuse = mix(
        vec4(uColor, maskValue * chartValue),
        vec4(uBorderColor, borderValue),
        borderValue
    );

    float fill = maskValue * (1.0-vUv.y)*mix(1.0, vUv.x, uBorderTransition)*(mix(0.4, 0.2, uBorderTransition)) * crange(uBorderTransition, 0.3, 0.8, 0.0, 1.0);
    diffuse = mix(diffuse, vec4(uBorderColor, 1.0), fill);
    diffuse.a *= uAlpha  * featheredSliderAlpha();

    if (diffuse.a < .01) {
        discard;
    }

    gl_FragColor = diffuse;
}
{@}SpiderGraphParticlesShader.glsl{@}#!ATTRIBUTES
attribute vec4 random;

#!UNIFORMS
uniform sampler2D tMask;
uniform sampler2D tShape;
uniform float uHasShape;
uniform float uSize;
uniform float DPR;
uniform vec3 uColor;
uniform vec2 uScale;
uniform vec2 uRange;
uniform float uAlpha;
uniform float uTransition;

#!VARYINGS
varying float vAlpha;
varying vec4 vRandom;
varying vec2 vUv;
varying vec2 vPos;

#!SHADER: Vertex

#require(eases.glsl)
#require(range.glsl)

void main() {
    vec4 decodedPos = texture2D(tPos, position.xy);
    vec3 pos = decodedPos.xyz;
    vec4 mPosition = modelMatrix * vec4(pos, 1.0);
    vec4 mvPosition = viewMatrix * mPosition;

    vRandom = random;
    vPos = pos.xy;

    vAlpha = uAlpha;
    //vAlpha = crange(random.y, 0.0, 1.0, 0.3, 1.0) * uAlpha;
    vAlpha *= smoothstep(1.0, 6.0, length(mPosition.xyz - cameraPosition));
    //vAlpha *= rangeTransition(uTransition, random.w, 0.1);


    float size = 1000.0 / length(mvPosition.xyz) * 0.01 * DPR;
    size *= uSize * crange(expoIn(random.w), 0.0, 1.0, uScale.x, uScale.y);
    //size *= vAlpha;

    gl_Position = projectionMatrix * mvPosition;
    gl_PointSize = size * 1.;
}

#!SHADER: Fragment
#require(range.glsl)

void main() {
    vec3 color = uColor;
    color *= 0.7 + smoothstep(0.8, 1.0, abs(sin(time+vRandom.y*20.0)));

    vec2 uv = vec2(gl_PointCoord.x, 1.0 - gl_PointCoord.y);
    float alpha = smoothstep(0.5, 0.0, length(uv-0.5));
    alpha *= 0.5+sin(time+vRandom.x*20.0)*0.5;

   // vec2 coords = gl_FragCoord.xy/resolution.xy;
    // vec2 sUv = vec2(0.);
    // if(uHasShape > .01) {
    //     vec2 sUv = crange(vPos, vec2(0.), vec2(1.), vec2(uRange.x), vec2(uRange.y));

    //     vec4 diffuse = texture2D(tShape, sUv);
    //     if(diffuse.r < .01) {
    //         discard;
    //     }
    // }

    gl_FragColor = vec4(color, alpha * vAlpha);
}{@}TestGraphShader.glsl{@}#!ATTRIBUTES

#!UNIFORMS
uniform sampler2D tMap;
#!VARYINGS
varying vec2 vUv;
#!SHADER: Vertex
void main() {
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
    vUv = uv;
}

#!SHADER: Fragment
void main() {
    vec4 diffuse = texture2D(tMap, vUv);
    gl_FragColor = vec4(diffuse);
}