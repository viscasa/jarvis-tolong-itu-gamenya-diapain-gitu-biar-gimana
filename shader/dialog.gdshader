shader_type canvas_item;

/* Progress 0..1 */
uniform float progress : hint_range(-0.1, 1.0) = 0.0;

/* --- [BARU] Opacity Global --- */
uniform float opacity : hint_range(0.0, 1.0) = 1.0; 
/* ----------------------------- */

/* Wipe direction (bottom-left to top-right) */
uniform float wipe_angle : hint_range(-180.0, 180.0) = 45.0;

/* Cover color (pure black like Hades) */
uniform vec4 cover_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

/* ----- INK EDGE STYLE (Hades-accurate) ----- */
// Hades menggunakan edge yang lebih organic dan irregular
uniform float ink_frequency : hint_range(30.0, 120.0) = 65.0;
uniform float ink_amplitude : hint_range(0.0, 0.12) = 0.045;
uniform float ink_distortion : hint_range(0.5, 3.0) = 1.8;

/* Noise texture untuk organic irregularity */
uniform sampler2D noise_texture;
uniform float noise_strength : hint_range(0.0, 0.15) = 0.055;
uniform float noise_scale : hint_range(0.5, 4.0) = 1.8;

/* Edge transition (Hades sangat smooth tapi tetap sharp) */
uniform float edge_sharpness : hint_range(0.005, 0.08) = 0.018;

/* Subtle golden glow di edge (ciri khas Hades) */
uniform float edge_glow_width : hint_range(0.01, 0.1) = 0.042;
uniform float edge_glow_intensity : hint_range(0.0, 0.5) = 0.22;
uniform vec3 edge_glow_color : source_color = vec3(1.0, 0.92, 0.7);  // golden

/* Secondary darker glow untuk depth */
uniform float dark_glow_intensity : hint_range(0.0, 0.3) = 0.12;
uniform vec3 dark_glow_color : source_color = vec3(0.8, 0.65, 0.4);

/* Smooth organic noise function */
float smoothNoise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);  // smoothstep interpolation
    
    float a = texture(noise_texture, (i + vec2(0.0, 0.0)) / 256.0).r;
    float b = texture(noise_texture, (i + vec2(1.0, 0.0)) / 256.0).r;
    float c = texture(noise_texture, (i + vec2(0.0, 1.0)) / 256.0).r;
    float d = texture(noise_texture, (i + vec2(1.0, 1.0)) / 256.0).r;
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/* Layered noise untuk detail lebih organic */
float fbm(vec2 uv) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < 3; i++) {
        value += amplitude * smoothNoise(uv * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value;
}

/* Organic ink edge function */
float inkEdge(float pos, float time_offset) {
    // Kombinasi sin wave dengan distortion untuk organic feel
    float wave1 = sin(pos * ink_frequency) * 0.5 + 0.5;
    float wave2 = sin(pos * ink_frequency * 1.7 + time_offset) * 0.5 + 0.5;
    
    // Blend waves dengan power untuk create irregular peaks
    float combined = mix(wave1, wave2, 0.4);
    combined = pow(combined, ink_distortion);
    
    return combined * ink_amplitude;
}

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    
    /* Panel shape mask */
    if (base.a < 0.01) discard;
    
    /* Rotate UV untuk diagonal wipe (bottom-left to top-right) */
    vec2 center = UV - vec2(0.5);
    float angle_rad = radians(wipe_angle);
    float cos_a = cos(angle_rad);
    float sin_a = sin(angle_rad);
    
    vec2 rotated = vec2(
        center.x * cos_a - center.y * sin_a,
        center.x * sin_a + center.y * cos_a
    );
    
    /* Diagonal distance dengan proper range untuk corner-to-corner */
    float diagonal_dist = (rotated.x + 0.707);
    float wipe_progress = progress * 1.414;  // √2 untuk full diagonal
    
    /* Base distance ke wipe line */
    float dist = diagonal_dist - wipe_progress;
    
    /* Organic ink edge distortion */
    float edge_distort = inkEdge(rotated.y * 10.0, UV.x * 3.0);
    dist -= edge_distort;
    
    /* Layered noise untuk texture organic (seperti tinta real) */
    float noise = fbm(UV * noise_scale * 8.0) - 0.5;
    dist -= noise * noise_strength;
    
    /* Secondary noise layer untuk detail halus */
    float detail_noise = smoothNoise(UV * noise_scale * 20.0) - 0.5;
    dist -= detail_noise * (noise_strength * 0.3);
    
    /* Sharp reveal dengan smooth edge (Hades style) */
    float reveal = smoothstep(edge_sharpness, 0.0, dist);
    
    /* Dual-layer glow untuk depth (golden + darker) */
    // Golden glow (primary, bright)
    float glow_primary = 1.0 - (abs(dist) / edge_glow_width);
    glow_primary = pow(clamp(glow_primary, 0.0, 1.0), 2.2) * edge_glow_intensity;
    
    // Darker glow (secondary, wider)
    float glow_dark = 1.0 - (abs(dist) / (edge_glow_width * 1.8));
    glow_dark = pow(clamp(glow_dark, 0.0, 1.0), 1.5) * dark_glow_intensity;
    
    /* Composite dengan glow layers */
    vec3 color = mix(cover_color.rgb, base.rgb, reveal);
    
    // Apply dark glow first (underneath)
    color += glow_dark * dark_glow_color * (1.0 - reveal);
    
    // Apply bright golden glow on top
    color += glow_primary * edge_glow_color * (1.0 - reveal);
    
    /* Output dengan proper alpha blending */
    float final_alpha = mix(cover_color.a, base.a, reveal);
    
    // --- [PERBAIKAN] Terapkan Opacity Global ---
    final_alpha *= opacity;
    // -------------------------------------------
    
    COLOR = vec4(color, final_alpha);
}