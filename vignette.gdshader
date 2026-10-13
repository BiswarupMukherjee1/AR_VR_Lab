// Vignette for vection reduction: darkens the peripheral vision.
// Code from the Godot docs tutorial "XR full screen effects":
// https://docs.godotengine.org/en/latest/tutorials/xr/xr_full_screen_effects.html
// It is drawn on a 2x2 QuadMesh (subdivided 5x5), child of the XRCamera3D.
shader_type spatial;
render_mode depth_test_disabled, skip_vertex_transform, unshaded, cull_disabled;

// Modify VERTEX.xy using the projection matrix to correctly center the effect.
void vertex() {
	vec2 vert_pos = VERTEX.xy;

	// The quad's corners/edges stay on the screen border (full coverage).
	// The inner vertices are shifted to the real centre of each eye's view
	// (the field of view of each eye of a headset is not symmetric).
	if (length(vert_pos) < 0.99) {
		vec4 offset = PROJECTION_MATRIX * vec4(0.0, 0.0, 1.0, 1.0);
		vert_pos += (offset.xy / offset.w);
	}

	// Write the position directly in screen (clip) space: x and y in [-1, 1]
	// cover the whole screen, whatever the position of the camera.
	POSITION = vec4(vert_pos, 1.0, 1.0);
}

void fragment() {
	// Black, transparent in the centre and more and more opaque towards the edges.
	ALBEDO = vec3(0.0);
	ALPHA = dot(UV * 2.0 - 1.0, UV * 2.0 - 1.0) * 2.0;
}
