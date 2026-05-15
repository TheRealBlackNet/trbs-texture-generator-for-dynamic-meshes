extends Control

var noiseTex:Texture2D
var noise:Image
var image:Image

func makeImage() -> void:
	noiseTex  = await makeNoise()
	noise = noiseTex.get_image()
	
	var rectsize:int = %nudSize.value
	image = Image.create(\
		rectsize * (%nudColors.value + 1) ,\
		rectsize * %nudTones.value,\
		 false, Image.FORMAT_RGBA8)
	
	image.fill(Color.BLACK)
	# image.set_pixel(10, 20, Color.RED)
	var offset:float = %nudOffset.value / 360.0
	var ns:float = %nudSizeNoise.value
	
	for x in range(0, %nudColors.value+1):
		for y in range(0, %nudTones.value):
			var curcol:Color = Color.TRANSPARENT
			var dim:float =( (((%nudTones.value-1) - y) / (%nudTones.value-1) ))
			if x == 0:
				var i:float = 255.0 * dim
				@warning_ignore("narrowing_conversion")
				curcol = Color.from_rgba8(i,i,i)
			else:
				#Constructs a color from an HSV profile
				# . The hue (h), saturation (s), and value (v)
				#  are typically between 0.0 and 1.0.
				curcol = Color.from_hsv(\
					(1.0 / (%nudColors.value+1) * x) + offset,\
					1.0 * %nudS.value,\
					(1.0 - %nudDarkLimit.value) * dim + %nudDarkLimit.value)

			image.fill_rect(Rect2(x * rectsize, y * rectsize,\
				rectsize, rectsize), curcol)

			if %cbtnUseNoise.button_pressed:
				for xx in range(0, rectsize):
					for yy in range(0, rectsize):
						var fx:int = x * rectsize + xx
						var fy:int = y * rectsize + yy
						
						var raw:float = noise.get_pixel(\
									int(ns * float(xx) / float(rectsize)),\
									int(ns * float(yy) / float(rectsize))).r
						var color:Color = noiseTex.color_ramp.sample(raw)
						var luminance = color.get_luminance()
						
						image.set_pixel(fx,fy, curcol.darkened(luminance))

	# %imgOutputPrev
	%imgOutputPrev.texture = ImageTexture.create_from_image(image)
	
	pass

func makeNoise() -> NoiseTexture2D:
	# %imgNoise 
	var noiseTexture:NoiseTexture2D = NoiseTexture2D.new()
	noiseTexture.width = %nudSizeNoise.value
	noiseTexture.height = %nudSizeNoise.value

	var fastnoise:FastNoiseLite = FastNoiseLite.new()
	noiseTexture.noise = fastnoise
	fastnoise.seed = %nudSeed.value
	fastnoise.frequency = %nudScale.value
	fastnoise.noise_type = %optTypes.get_selected() 

	var ramp:Gradient = Gradient.new()
	ramp.offsets =[%nudMin.value / 100.0, %nudMax.value / 100.0]
	ramp.colors = [Color.BLACK, Color.WHITE]
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	noiseTexture.color_ramp = ramp

	await noiseTexture.changed
	#%imgNoise.texture = noiseTexture.get_image()
	%imgNoise.texture = noiseTexture
	return noiseTexture

func _on_nud_changed() -> void:
	makeImage()

func _on_check_button_toggled(_toggled_on: bool) -> void:
	makeImage()

func _ready() -> void:
	%optTypes.clear()
	%optTypes.add_item("TYPE_SIMPLEX", FastNoiseLite.NoiseType.TYPE_SIMPLEX)
	%optTypes.add_item("TYPE_SIMPLEX_SMOOTH", FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH)
	%optTypes.add_item("TYPE_PERLIN", FastNoiseLite.NoiseType.TYPE_PERLIN)
	%optTypes.add_item("TYPE_CELLULAR", FastNoiseLite.NoiseType.TYPE_CELLULAR)
	%optTypes.add_item("TYPE_VALUE", FastNoiseLite.NoiseType.TYPE_VALUE)
	%optTypes.add_item("TYPE_VALUE_CUBIC", FastNoiseLite.NoiseType.TYPE_VALUE_CUBIC)

	%optTypes.select(0)
	makeImage()

func _on_nud_value_changed(_value: float) -> void:
	makeImage()


func _on_opt_selected(_index: int) -> void:
	makeImage()

var savemeimage:Image


func __timeString() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%04.0f-%02.0f-%02.0f_%02.0f%02.0f%02.0f"%\
	[time["year"], time["month"],time["day"] , \
	time["hour"] , time["minute"] , time["second"]]

func _on_btn_save_image_button_up() -> void:
	savemeimage = image
	var x = "noNoise"
	if %cbtnUseNoise.button_pressed:
		x = "Noise"
	%SaveFileDialog.title = "Save color image"
	%SaveFileDialog.current_file = "UV_Color"\
		+ "_" + str(%nudColors.value)\
		+ "_" + str(%nudTones.value)\
		+ "_" + x + "_" + __timeString() + ".png"
	%SaveFileDialog.popup_centered()

func _on_btn_save_noise_button_up() -> void:
	savemeimage = noise
	%SaveFileDialog.title = "Save noise image"
	%SaveFileDialog.current_file = "UV_Noise"\
		+ "_" + str(%nudSeed.value)\
		+ "_" + str(%nudSizeNoise.value)\
		+ "_" + str(%nudScale.value)\
		+ "_" + __timeString() + ".png"
	%SaveFileDialog.popup_centered()

func _on_save_file_dialog_file_selected(path: String) -> void:
	savemeimage.save_png(path)
