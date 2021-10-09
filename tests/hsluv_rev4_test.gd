extends Node2D


func _ready():
	var start_time := OS.get_ticks_msec()
	print("Loading Snapshot File...")
	
	var snapshot := {}
	
	var file := File.new()
	var err := file.open("res://tests/snapshots/snapshot-rev4.json", file.READ)
	if err != OK:
		push_error("Failed to open Snapshot File! Code: " + str(err))
		return
	
	var text := file.get_as_text()
	
	var result := JSON.parse(text)
	if result.error == OK:
		snapshot = result.result
	else:
		push_error("Failed to parse JSON from Snapshot File! " + result.error_string)
		return
	
	var end_time := OS.get_ticks_msec()
	print(str(end_time - start_time) + "ms")
	print("Testing HSLuv against Snapshot...")
	start_time = OS.get_ticks_msec()
	
	test_hsluv(snapshot)
	test_rgb_channel_bounds()
	
	end_time = OS.get_ticks_msec()
	
	print(str(end_time - start_time) + "ms")
	print("All Tests passed!")


func test_hsluv(snapshot: Dictionary) -> void:
	for hex in snapshot:
		var field: Dictionary = snapshot[hex]
		
		var color := Color(hex)
		
		# forward functions
		
		var xyz_from_color := HSLuv.color_to_xyz(color)
		
		var xyz_from_rgb := HSLuv.rgb_to_xyz(field.rgb)
		var luv_from_xyz := HSLuv.xyz_to_luv(field.xyz)
		var lch_from_luv := HSLuv.luv_to_lch(field.luv)
		var hsluv_from_lch := HSLuv.lch_to_hsluv(field.lch)
		var hpluv_from_lch := HSLuv.lch_to_hpluv(field.lch)
		var hsluv_from_hex := HSLuv.hex_to_hsluv(hex)
		var hpluv_from_hex := HSLuv.hex_to_hpluv(hex)
		
		assert_array_equals_approx(field.xyz, xyz_from_color, hex + " -> color_to_xyz()")
		assert_array_equals_approx(field.xyz, xyz_from_rgb, hex + " -> rgb_to_xyz()")
		assert_array_equals_approx(field.luv, luv_from_xyz, hex + " -> xyz_to_luv()")
		assert_array_equals_approx(field.lch, lch_from_luv, hex + " -> luv_to_lch()")
		assert_array_equals_approx(field.hsluv, hsluv_from_lch, hex + " -> lch_to_hsluv()")
		assert_array_equals_approx(field.hpluv, hpluv_from_lch, hex + " -> lch_to_hpluv()")
		assert_array_equals_approx(field.hsluv, hsluv_from_hex, hex + " -> hex_to_hsluv()")
		assert_array_equals_approx(field.hpluv, hpluv_from_hex, hex + " -> hex_to_hpluv()")
		
		# backwards functions
		
		var lch_from_hsluv := HSLuv.hsluv_to_lch(field.hsluv)
		var lch_from_hpluv := HSLuv.hpluv_to_lch(field.hpluv)
		var luv_from_lch := HSLuv.lch_to_luv(field.lch)
		var xyz_from_luv := HSLuv.luv_to_xyz(field.luv)
		var rgb_from_xyz := HSLuv.xyz_to_rgb(field.xyz)
		
		var color_from_xyz := HSLuv.xyz_to_color(field.xyz)
		
		var hex_from_hsluv := HSLuv.hsluv_to_hex(field.hsluv)
		var hex_from_hpluv := HSLuv.hpluv_to_hex(field.hpluv)
		
		assert_array_equals_approx(field.lch, lch_from_hsluv, "hsluv_to_lch()")
		assert_array_equals_approx(field.lch, lch_from_hpluv, "hpluv_to_lch()")
		assert_array_equals_approx(field.luv, luv_from_lch, "lch_to_luv()")
		assert_array_equals_approx(field.xyz, xyz_from_luv, "luv_to_xyz()")
		assert_array_equals_approx(field.rgb, rgb_from_xyz, "xyz_to_rgb()")
		
		assert_array_equals_approx(field.rgb, [color_from_xyz.r, color_from_xyz.g, color_from_xyz.b], "xyz_to_color()")
		
		assert( hex_from_hsluv, hex)
		assert( hex_from_hpluv, hex)


func assert_array_equals_approx(array_a: Array, array_b: Array, fail_msg: String) -> void:
	for i in array_a.size():
		var a: float = array_a[i]
		var b: float = array_b[i]
		assert( is_equal_approx(a, b), "Test Failed: " + fail_msg)


func test_rgb_channel_bounds() -> void:
	for r in [0.0, 1.0]:
		for g in [0.0, 1.0]:
			for b in [0.0, 1.0]:
				var sample := [r, g, b]
				var hsluv := HSLuv.rgb_to_hsluv(sample)
				var hpluv := HSLuv.rgb_to_hpluv(sample)
				
				var rgb_from_hsluv := HSLuv.hsluv_to_rgb(hsluv)
				var rgb_from_hpluv := HSLuv.hpluv_to_rgb(hpluv)
				
				assert_array_equals_approx(rgb_from_hsluv, sample, "RGB -> HSLuv -> RGB")
				assert_array_equals_approx(rgb_from_hpluv, sample, "RGB -> HPLuv -> RGB")

