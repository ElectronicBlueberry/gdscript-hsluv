tool
extends Reference

class_name HSLuv


class Line:
	var slope: float
	var intercept: float
	
	func _init(with_slope, with_intercept):
		self.slope = with_slope
		self.intercept = with_intercept
	
	func intersects_line(line: Line):
		return (self.intercept - line.intercept) / (self.slope - line.slope)
	
	func length_of_ray_until_intersect(theta: float) -> float:
		return self.intercept / (sin(theta) - self.slope * cos(theta))
	
	func perpendicular_through_point(point: Vector2) -> Line:
		var _slope := -1.0 / self.slope
		var _intercept := point.y - slope * point.x
		
		return Line.new(_slope, _intercept)
	
	func distance_from_origin() -> float:
		return abs( self.intercept) / sqrt( pow( self.slope, 2.0) + 1.0)


# -- Private --

const _m := [
	[3.240969941904521, -1.537383177570093, -0.498610760293],
	[-0.96924363628087, 1.87596750150772, 0.041555057407175],
	[0.055630079696993, -0.20397695888897, 1.056971514242878]
]

const _minv := [
	[0.41239079926595, 0.35758433938387, 0.18048078840183],
	[0.21263900587151, 0.71516867876775, 0.072192315360733],
	[0.019330818715591, 0.11919477979462, 0.95053215224966]
]

const _ref_x := 0.95045592705167
const _ref_y := 1.0
const _ref_z := 1.089057750759878

const _ref_u := 0.19783000664283
const _ref_v := 0.46831999493879

const _kappa := 903.2962962
const _epsilon := 0.0088564516


static func _dot_product(a: Array, b: Array) -> float:
	var sum := 0.0
	
	for i in a.size():
		sum += a[i] * b[i]
	
	return sum


static func _from_linear(c: float) -> float:
	if c <= 0.0031308:
		return 12.92 * c
	else:
		return 1.055 * pow(c, 1.0 / 2.4) - 0.055


static func _to_linear(c: float) -> float:
	if c > 0.04045:
		return pow((c + 0.055) / (1.0 + 0.055), 2.4)
	else:
		return c / 12.92


# -- Public --

static func get_bounds(l: float) -> Array:
	var result := []
	
	var sub_1 := pow(l + 16.0, 3.0) / 1560896.0
	var sub_2 := sub_1 if sub_1 > _epsilon else l / _kappa
	
	for c in 3:
		var m_1: float = _m[c][0]
		var m_2: float = _m[c][1]
		var m_3: float = _m[c][2]
		
		for t in 2:
			var top_1: float = (284517.0 * m_1 - 94839.0 * m_3) * sub_2
			var top_2: float = (838422.0 * m_3 + 769860.0 * m_2 + 731718.0 * m_1) * l * sub_2 - 769860.0 * t * l
			var bottom: float = (632260.0 * m_3 - 126452.0 * m_2) * sub_2 + 126452.0 * t
			
			result.append( Line.new(top_1 / bottom, top_2 / bottom) )
	
	return result


static func max_safe_chroma_for_l(l: float) -> float:
	var bounds := get_bounds(l)
	var smallest_dist := INF
	
	for bound in bounds:
		var dist: float = bound.distance_from_origin()
		smallest_dist = min(smallest_dist, dist)
	
	return smallest_dist


static func max_chroma_for_lh(l: float, h: float) -> float:
	var h_rad := deg2rad(h)
	var bounds := get_bounds(l)
	var smallest_length := INF
	
	for bound in bounds:
		var length: float = bound.length_of_ray_until_intersect(h_rad)
		
		if length >= 0.0:
			smallest_length = min(smallest_length, length)
	
	return smallest_length


# xyz: Array containing the colors x, y, and z values in the 0 to 1 range
# returns: Array containing the colors r, g, and b values in the 0 to 1 range
static func xyz_to_rgb(xyz: Array) -> Array:
	return [
		_from_linear( _dot_product(_m[0], xyz)),
		_from_linear( _dot_product(_m[1], xyz)),
		_from_linear( _dot_product(_m[2], xyz))
	]


# xyz: Array containing the colors x, y, and z values in the 0 to 1 range
# returns: Color
static func xyz_to_color(xyz: Array) -> Color:
	var rgb := xyz_to_rgb(xyz)
	return Color(rgb[0], rgb[1], rgb[2])


# rgb: Array containing the colors r, g, and b values in the 0 to 1 range
# returns: Array containing the colors x, y, and z values in the 0 to 1 range
static func rgb_to_xyz(rgb: Array) -> Array:
	var rgb_1 := [
		_to_linear(rgb[0]),
		_to_linear(rgb[1]),
		_to_linear(rgb[2])
	]
	
	return [
		_dot_product(_minv[0], rgb_1),
		_dot_product(_minv[1], rgb_1),
		_dot_product(_minv[2], rgb_1)
	]


# color: Color to be converted
# returns: Array containing the colors x, y, and z values in the 0 to 1 range
static func color_to_xyz(color: Color) -> Array:
	var rgb_1 := [
		_to_linear(color.r),
		_to_linear(color.g),
		_to_linear(color.b)
	]
	
	return [
		_dot_product(_minv[0], rgb_1),
		_dot_product(_minv[1], rgb_1),
		_dot_product(_minv[2], rgb_1)
	]


# http://en.wikipedia.org/wiki/CIELUV
# In these formulas, Yn refers to the reference white point. We are using
# illuminant D65, so Yn (see _ref_y) equals 1. The formula is
# simplified accordingly.
static func y_to_l(y: float) -> float:
	if y <= _epsilon:
		return (y / _ref_y) * _kappa
	else:
		return 116.0 * pow(y / _ref_y, 1.0 / 3.0) - 16.0

static func l_to_y(l: float) -> float:
	if l <= 8:
		return _ref_y * l / _kappa
	else:
		return _ref_y * pow((l + 16.0) / 116.0, 3.0)


# xyz: Array containing the colors x, y, and z values in the 0 to 1 range
# returns: Array containing the colors LUV values
static func xyz_to_luv(xyz: Array) -> Array:
	var x: float = xyz[0]
	var y: float = xyz[1]
	var z: float = xyz[2]
	
	var l := y_to_l(y)
	
	if l == 0.0:
		return [0.0, 0.0, 0.0]
	
	var divider := (x + (15.0 * y) + (3.0 * z))
	var var_u := 4.0 * x
	var var_v := 9.0 * y
	
	if divider != 0.0:
		var_u /= divider
		var_v /= divider
	else:
		var_u = NAN
		var_v = NAN
	
	var u := 13.0 * l * (var_u - _ref_u)
	var v := 13.0 * l * (var_v - _ref_v)
	
	return [l, u, v]


# luv: Array containing the colors LUV values
# returns: Array containing the colors x, y, and z values in the 0 to 1 range
static func luv_to_xyz(luv: Array) -> Array:
	var l: float = luv[0]
	var u: float = luv[1]
	var v: float = luv[2]
	
	if l == 0.0:
		return [0.0, 0.0, 0.0]
	
	var var_u := u / (13.0 * l) + _ref_u
	var var_v := v / (13.0 * l) + _ref_v
	
	var y := l_to_y(l)
	var x := - (9.0 * y * var_u) / ((var_u - 4.0) * var_v - var_u * var_v)
	var z := (9.0 * y - (15.0 * var_v * y) - (var_v * x)) / (3.0 * var_v)
	
	return [x, y, z]


# luv: Array containing the colors LUV values
# returns: Array containing the colors LCH values
static func luv_to_lch(luv: Array) -> Array:
	var l: float = luv[0]
	var u: float = luv[1]
	var v: float = luv[2]
	
	var c := sqrt(u * u + v * v)
	var h: float
	
	if c < 0.00000001:
		h = 0.0
	else:
		var h_rad = atan2(v, u)
		h = rad2deg(h_rad)
		
		if h < 0.0:
			h = 360.0 + h
	
	return [l, c, h]


# lch: Array containing the colors LCH values
# returns: Array containing the colors LUV values
static func lch_to_luv(lch: Array) -> Array:
	var l: float = lch[0]
	var c: float = lch[1]
	var h: float = lch[2]
	
	var h_rad := deg2rad(h)
	var u := cos(h_rad) * c
	var v := sin(h_rad) * c
	
	return [l, u, v]


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hsluv: Array containing the colors HSL values in HSLuv color space
# returns: Array containing the colors LCH values
static func hsluv_to_lch(hsluv: Array) -> Array:
	var h: float = hsluv[0]
	var s: float = hsluv[1]
	var l: float = hsluv[2]
	
	if l > 99.9999999:
		return [100.0, 0.0, h]
	
	if l < 0.00000001:
		return [0.0, 0.0, h]
	
	var max_chroma := max_chroma_for_lh(l, h)
	var c := max_chroma / 100.0 * s
	
	return [l, c, h]


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# lch: Array containing the colors LCH values
# returns: Array containing the colors HSL values in HSLuv color space
static func lch_to_hsluv(lch: Array) -> Array:
	var l: float = lch[0]
	var c: float = lch[1]
	var h: float = lch[2]
	
	if l > 99.9999999:
		return [h, 0.0, 100.0]
	
	if l < 0.00000001:
		return [h, 0.0, 0.0]
	
	var max_chroma := max_chroma_for_lh(l, h)
	var s := c / max_chroma * 100.0
	
	return [h, s, l]


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hpluv: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
# returns: Array containing the colors LCH values
static func hpluv_to_lch(hpluv: Array) -> Array:
	var h: float = hpluv[0]
	var s: float = hpluv[1]
	var l: float = hpluv[2]
	
	if l > 99.9999999:
		return [100.0, 0.0, h]
	
	if l < 0.00000001:
		return [0.0, 0.0, h]
	
	var max_chroma := max_safe_chroma_for_l(l)
	var c := max_chroma / 100.0 * s
	
	return [l, c, h]


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# lch: Array containing the colors LCH values
# returns: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
static func lch_to_hpluv(lch: Array) -> Array:
	var l: float = lch[0]
	var c: float = lch[1]
	var h: float = lch[2]
	
	if l > 99.9999999:
		return [h, 0.0, 100.0]
	
	if l < 0.00000001:
		return [h, 0.0, 0.0]
	
	var max_chroma := max_safe_chroma_for_l(l)
	var s := c / max_chroma * 100.0
	
	return [h, s, l]


# lch: Array containing the colors LCH values
# returns: Array containing the colors r, g, and b values in the 0 to 1 range
static func lch_to_rgb(lch: Array) -> Array:
	return xyz_to_rgb( luv_to_xyz( lch_to_luv(lch)))


# lch: Array containing the colors LCH values
# returns: Color
static func lch_to_color(lch: Array) -> Color:
	return xyz_to_color( luv_to_xyz( lch_to_luv(lch)))


# rgb: Array containing the colors r, g, and b values in the 0 to 1 range
# returns: Array containing the colors LCH values
static func rgb_to_lch(rgb: Array) -> Array:
	return luv_to_lch( xyz_to_luv( rgb_to_xyz(rgb)))


# color: Color to be converted
# returns: Array containing the colors LCH values
static func color_to_lch(color: Color) -> Array:
	return luv_to_lch( xyz_to_luv( color_to_xyz(color)))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hsluv: Array containing the colors HSL values in HSLuv color space
# returns: Array containing the colors r, g, and b values in the 0 to 1 range
static func hsluv_to_rgb(hsluv: Array) -> Array:
	return lch_to_rgb( hsluv_to_lch(hsluv))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hsluv: Array containing the colors HSL values in HSLuv color space
# returns: Color
static func hsluv_to_color(hsluv: Array) -> Color:
	return lch_to_color( hsluv_to_lch(hsluv))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# rgb: Array containing the colors r, g, and b values in the 0 to 1 range
# returns: Array containing the colors HSL values in HSLuv color space
static func rgb_to_hsluv(rgb: Array) -> Array:
	return lch_to_hsluv( rgb_to_lch(rgb))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# color:  to be converted
# returns: Array containing the colors HSL values in HSLuv color space
static func color_to_hsluv(color: Color) -> Array:
	return lch_to_hsluv( color_to_lch(color))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hpluv: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
# returns: Array containing the colors r, g, and b values in the 0 to 1 range
static func hpluv_to_rgb(hpluv: Array) -> Array:
	return lch_to_rgb( hpluv_to_lch(hpluv))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hpluv: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
# returns: Color
static func hpluv_to_color(hpluv: Array) -> Color:
	return lch_to_color( hpluv_to_lch(hpluv))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# rgb: Array containing the colors r, g, and b values in the 0 to 1 range
# returns: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
static func rgb_to_hpluv(rgb: Array) -> Array:
	return lch_to_hpluv( rgb_to_lch(rgb))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# color:  to be converted
# returns: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
static func color_to_hpluv(color: Color) -> Array:
	return lch_to_hpluv( color_to_lch(color))


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hsluv: Array containing the colors HSL values in HSLuv color space
# returns: #RRGGBB representation of a color
static func hsluv_to_hex(hsluv: Array) -> String:
	var col := hsluv_to_color(hsluv)
	return "#" + col.to_html(false)


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hpluv: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
# returns: #RRGGBB representation of a color
static func hpluv_to_hex(hpluv: Array) -> String:
	var col := hpluv_to_color(hpluv)
	return "#" + col.to_html(false)


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hex: #RRGGBB representation of a color
# returns: Array containing the colors HSL values in HSLuv color space
static func hex_to_hsluv(hex: String) -> Array:
	var col := Color(hex)
	return color_to_hsluv(col)


# HSLuv values are ranging in (0 ... 360), (0 ... 100) and (0 ... 100)
# hex: #RRGGBB representation of a color
# returns: Array containing the colors HSL values in HPLuv (pastel HSLuv variant) color space
static func hex_to_hpluv(hex: String) -> Array:
	var col := Color(hex)
	return color_to_hpluv(col)

