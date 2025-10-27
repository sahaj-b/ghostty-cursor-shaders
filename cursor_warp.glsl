// --- CONFIGURATION ---
vec4 TRAIL_COLOR = iCurrentCursorColor; // can change to eg: vec4(0.2, 0.6, 1.0, 0.5);
const float DURATION = 0.2;   // total animation time (Neovide's `animation_length`)
const float TRAIL_SIZE = 0.8; // 0.0 = all corners move together. 1.0 = max smear (leading corners jump instantly)
const float THRESHOLD_MIN_DISTANCE = 1.5; // min distance to show trail (units of cursor width)

// --- CONSTANTS for easing functions ---
const float PI = 3.14159265359;
const float C1_BACK = 1.70158;
const float C2_BACK = C1_BACK * 1.525;
const float C3_BACK = C1_BACK + 1.0;
const float C4_ELASTIC = (2.0 * PI) / 3.0;
const float C5_ELASTIC = (2.0 * PI) / 4.5;
const float SPRING_STIFFNESS = 9.0;
const float SPRING_DAMPING = 0.9;

// --- EASING FUNCTIONS ---

// // Linear
// float ease(float x) {
//     return x;
// }

// // EaseOutQuad
// float ease(float x) {
//     return 1.0 - (1.0 - x) * (1.0 - x);
// }

// // EaseOutCubic
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 3.0);
// }

// // EaseOutQuart
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 4.0);
// }

// // EaseOutQuint
// float ease(float x) {
//     return 1.0 - pow(1.0 - x, 5.0);
// }

// // EaseOutSine
// float ease(float x) {
//     return sin((x * PI) / 2.0);
// }

// // EaseOutExpo
// float ease(float x) {
//     return x == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * x);
// }

// EaseOutCirc
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0));
}

// // EaseOutBack
// float ease(float x) {
//     return 1.0 + C3_BACK * pow(x - 1.0, 3.0) + C1_BACK * pow(x - 1.0, 2.0);
// }

// // EaseOutElastic
// float ease(float x) {
//     return x == 0.0 ? 0.0
//          : x == 1.0 ? 1.0
//                     : pow(2.0, -10.0 * x) * sin((x * 10.0 - 0.75) * C4_ELASTIC) + 1.0;
// }

// // Parametric Spring
// float ease(float x) {
//     x = clamp(x, 0.0, 1.0);
//     float decay = exp(-SPRING_DAMPING * SPRING_STIFFNESS * x);
//     float freq = sqrt(SPRING_STIFFNESS * (1.0 - SPRING_DAMPING * SPRING_DAMPING));
//     float osc = cos(freq * 6.283185 * x) + (SPRING_DAMPING * sqrt(SPRING_STIFFNESS) / freq) * sin(freq * 6.283185 * x);
//     return 1.0 - decay * osc;
// }

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching
float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfConvexQuad(in vec2 p, in vec2 v1, in vec2 v2, in vec2 v3, in vec2 v4) {
    float s = 1.0;
    float d = dot(p - v1, p - v1);

    d = seg(p, v1, v2, s, d);
    d = seg(p, v2, v3, s, d);
    d = seg(p, v3, v4, s, d);
    d = seg(p, v4, v1, s, d);

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
    return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
}

// Determines animation duration based on a corner's alignment with the move direction(dot product)
// dot_val will be in [-2, 2]
// > 0.5 (1 or 2) = Leading
// > -0.5 (0)     = Side
// <= -0.5 (-1 or -2) = Trailing
float getDurationFromDot(float dot_val, float DURATION_LEAD, float DURATION_SIDE, float DURATION_TRAIL) {
    float isLead = step(0.5, dot_val);
    float isSide = step(-0.5, dot_val) * (1.0 - isLead);
    
    // Start with trailing duration
    float duration = mix(DURATION_TRAIL, DURATION_SIDE, isSide);
    // Mix in leading duration
    duration = mix(duration, DURATION_LEAD, isLead);
    return duration;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // normalization & setup(-1, 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    vec2 halfSizeCC = currentCursor.zw * 0.5;
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);
    vec2 halfSizeCP = previousCursor.zw * 0.5;

    // defining corners of cursors
    vec2 cc_tl = currentCursor.xy;
    vec2 cc_tr = vec2(currentCursor.x + currentCursor.z, currentCursor.y);
    vec2 cc_bl = vec2(currentCursor.x, currentCursor.y - currentCursor.w);
    vec2 cc_br = vec2(currentCursor.x + currentCursor.z, currentCursor.y - currentCursor.w);

    vec2 cp_tl = previousCursor.xy;
    vec2 cp_tr = vec2(previousCursor.x + previousCursor.z, previousCursor.y);
    vec2 cp_bl = vec2(previousCursor.x, previousCursor.y - previousCursor.w);
    vec2 cp_br = vec2(previousCursor.x + previousCursor.z, previousCursor.y - previousCursor.w);

    // calculating durations for every corner
    const float DURATION_TRAIL = DURATION;
    const float DURATION_LEAD = DURATION * (1.0 - TRAIL_SIZE);
    const float DURATION_SIDE = (DURATION_LEAD + DURATION_TRAIL) / 2.0;

    vec2 moveVec = centerCC - centerCP;
    vec2 s = sign(moveVec); // movement direction quadrant

    // dot products for each corner, determining alignment with movement direction
    float dot_tl = dot(vec2(-1., 1.), s);
    float dot_tr = dot(vec2( 1., 1.), s);
    float dot_bl = dot(vec2(-1.,-1.), s);
    float dot_br = dot(vec2( 1.,-1.), s);

    // assign durations based on dot products
    float dur_tl = getDurationFromDot(dot_tl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
    float dur_tr = getDurationFromDot(dot_tr, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
    float dur_bl = getDurationFromDot(dot_bl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
    float dur_br = getDurationFromDot(dot_br, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

    // ANIMATION LESGOOO
    // check direction of horizontal movement
    float isMovingRight = step(0.5, s.x); // 1.0 if s.x == 1.0 (right edge leads)
    float isMovingLeft  = step(0.5, -s.x); // 1.0 if s.x == -1.0 (left edge leads)

    // calculate vertical-rail durations (vertical-rail: the side of the trail that looks attached to the cursor)
    float dot_right_edge = (dot_tr + dot_br) * 0.5;
    float dur_right_rail = getDurationFromDot(dot_right_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
    
    float dot_left_edge = (dot_tl + dot_bl) * 0.5;
    float dur_left_rail = getDurationFromDot(dot_left_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

    // select if the vertial-rail is left edge or right edge
    // its like a 2-1 MUX

    float final_dur_tl = mix(dur_tl, dur_left_rail, isMovingLeft);
    float final_dur_bl = mix(dur_bl, dur_left_rail, isMovingLeft);
    
    float final_dur_tr = mix(dur_tr, dur_right_rail, isMovingRight);
    float final_dur_br = mix(dur_br, dur_right_rail, isMovingRight);

    // calculate progress for each corner based on the duration and time since cursor change
    // baseProgress / final_dur_xx = [0,1] progress value for each corner
    float baseProgress = iTime - iTimeCursorChange;
    float prog_tl = ease(clamp(baseProgress / final_dur_tl, 0.0, 1.0));
    float prog_tr = ease(clamp(baseProgress / final_dur_tr, 0.0, 1.0));
    float prog_bl = ease(clamp(baseProgress / final_dur_bl, 0.0, 1.0));
    float prog_br = ease(clamp(baseProgress / final_dur_br, 0.0, 1.0));

    // get the trial corner positions based on progress
    vec2 v_tl = mix(cp_tl, cc_tl, prog_tl);
    vec2 v_tr = mix(cp_tr, cc_tr, prog_tr);
    vec2 v_br = mix(cp_br, cc_br, prog_br);
    vec2 v_bl = mix(cp_bl, cc_bl, prog_bl);


    // DRAWING THE TRAIL
    float sdfTrail = getSdfConvexQuad(vu, v_tl, v_tr, v_br, v_bl);

    // kill trail on short moves
    float lineLength = distance(centerCC, centerCP);
    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
    // float isTrailVisble = smoothstep(minDist, minDist + currentCursor.w, lineLength); // this creates trasluct trails on short moves, meh
    float isTrailVisble = step(minDist, lineLength);
    vec4 newColor = vec4(fragColor);
    vec4 trail = TRAIL_COLOR;

    float trailAlpha = antialising(sdfTrail) * isTrailVisble;
    newColor = mix(newColor, trail, trailAlpha);

    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, halfSizeCC);
    // punch hole on the trail, so current cursor is drawn on top, so we can see the actual cursor
    newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));

    fragColor = newColor;
}
