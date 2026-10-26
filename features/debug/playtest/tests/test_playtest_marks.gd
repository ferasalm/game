class_name TestPlaytestMarks
extends TestCase
## purpose: PlaytestMarks paints a stroke onto the screenshot through the capture transform, leaves pixels away from
## it untouched, dots a lone point and clips points outside the image.


func _image() -> Image:
	var image := Image.create(64, 36, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	return image


func test_a_stroke_turns_pixels_red_under_the_transform() -> void:
	var image: Image = _image()
	var stroke := PackedVector2Array([Vector2(5.0, 5.0), Vector2(15.0, 5.0)])
	var strokes: Array[PackedVector2Array] = [stroke]
	PlaytestMarks.paint(image, strokes, Transform2D(0.0, Vector2(5.0, 5.0)), Color.RED, 2)
	check(image.get_pixel(15, 10).is_equal_approx(Color.RED), "under the stroke is red")
	check(image.get_pixel(15, 20).is_equal_approx(Color.BLACK), "away from it stays black")


func test_a_lone_point_is_a_dot() -> void:
	var image: Image = _image()
	var strokes: Array[PackedVector2Array] = [PackedVector2Array([Vector2(30.0, 20.0)])]
	PlaytestMarks.paint(image, strokes, Transform2D.IDENTITY, Color.RED, 2)
	check(image.get_pixel(30, 20).is_equal_approx(Color.RED), "the point is painted")


func test_points_outside_the_image_are_safe() -> void:
	var image: Image = _image()
	var strokes: Array[PackedVector2Array] = [PackedVector2Array([Vector2(-100.0, -100.0), Vector2(-90.0, -90.0)])]
	PlaytestMarks.paint(image, strokes, Transform2D.IDENTITY, Color.RED, 2)
	check(image.get_pixel(0, 0).is_equal_approx(Color.BLACK), "the image is untouched")
