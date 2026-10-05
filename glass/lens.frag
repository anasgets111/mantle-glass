// Liquid Glass refraction over the backdrop (effect.shader, input = "backdrop"). The outer `bezel`
// px of the shape rise as a squircle to a glass `thickness` px tall; a straight-down ray refracts
// at that surface (Snell, glass 1.5) and lands inward, so the rim magnifies what lies under it and
// it seems to wrap the edge. `dispersion` splits the shift per colour channel. The kit has no
// refraction, so the values are estimates; the model is kube.io/blog/liquid-glass-css-svg.
uniform float bezel;
uniform float thickness;
uniform float dispersion;

const float IOR = 1.5;

void main() {
    vec2 p = v_uv * u_size;
    float d = mantle_sdf(p);
    // The output replaces what is under the box, so outside the outline it is the ground unchanged.
    if (d > 0.5) {
        fragColor = mantle_input(v_uv);
        return;
    }
    // The outward normal: the distance field's gradient.
    vec2 e = vec2(0.5, 0.0);
    vec2 n = vec2(mantle_sdf(p + e.xy) - mantle_sdf(p - e.xy), mantle_sdf(p + e.yx) - mantle_sdf(p - e.yx));
    n /= max(length(n), 1e-4);
    // A shape thinner than two bezels curves all the way to its middle, where the shift is zero.
    float b = min(bezel, 0.5 * min(u_size.x, u_size.y));
    float x = clamp(-d / b, 1e-3, 1.0);
    // Squircle height h = (1 - (1 - x)^4)^(1/4), its slope, the incidence angle and the refracted one.
    float k = 1.0 - pow(1.0 - x, 4.0);
    float h = pow(k, 0.25);
    float slope = thickness / b * pow(1.0 - x, 3.0) / pow(k, 0.75);
    float incidence = atan(slope);
    float refracted = asin(sin(incidence) / IOR);
    vec2 shift = -n * thickness * h * tan(incidence - refracted) / u_size;
    vec4 c = mantle_input_blurred(v_uv + shift);
    if (dispersion > 0.0) {
        c.r = mantle_input_blurred(v_uv + shift * (1.0 + dispersion)).r;
        c.b = mantle_input_blurred(v_uv + shift * (1.0 - dispersion)).b;
    }
    fragColor = mix(mantle_input(v_uv), c, 1.0 - smoothstep(-0.5, 0.5, d));
}
