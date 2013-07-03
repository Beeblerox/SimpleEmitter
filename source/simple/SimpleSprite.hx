package simple;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.Graphics;
import flixel.system.FlxAssets;
import flixel.util.loaders.TexturePackerData;
import openfl.display.Tilesheet;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.util.FlxAngle;
import flixel.util.FlxArray;
import flixel.util.FlxPoint;
import flixel.system.layer.DrawStackItem;
import flixel.system.layer.frames.FlxFrame;
import flixel.system.layer.Node;

#if !flash
import flixel.system.layer.TileSheetData;
#end

import flixel.FlxG;

/**
 * The main "game object" class, the sprite is a <code>FlxObject</code>
 * with a bunch of graphics options and abilities, like animation and stamping.
 */
class SimpleSprite extends FlxObject
{
	/**
	 * Set <code>facing</code> using <code>FlxObject.LEFT</code>,<code>RIGHT</code>,
	 * <code>UP</code>, and <code>DOWN</code> to take advantage of
	 * flipped sprites and/or just track player orientation more easily.
	 */
	public var facing(default, set_facing):Int;
	
	public var frame(get_frame, set_frame):Int;
	
	/**
	 * If the Sprite is flipped.
	 * This property shouldn't be changed unless you know what are you doing.
	 */
	public var flipped(get_flipped, null):Int;
	
	private var _flipped:Int;
	
	private function get_flipped():Int
	{
		return _flipped;
	}
	
	/**
	 * Change the size of your sprite's graphic.
	 * NOTE: Scale doesn't currently affect collisions automatically,
	 * you will need to adjust the width, height and offset manually.
	 * WARNING: scaling sprites decreases rendering performance for this sprite by a factor of 10x!
	 */
	public var scale:FlxPoint;
	/**
	 * Blending modes, just like Photoshop or whatever.
	 * E.g. "multiply", "screen", etc.
	 * @default null
	 */
	#if flash
	public var blend:BlendMode;
	#else
	private var _blend:BlendMode;
	private var _blendInt:Int = 0;
	#end
	/**
	 * The width of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 * NOTE: Edit at your own risk!!  This is intended to be read-only.
	 */
	public var frameWidth:Int;
	/**
	 * The height of the actual graphic or image being displayed (not necessarily the game object/bounding box).
	 * NOTE: Edit at your own risk!!  This is intended to be read-only.
	 */
	public var frameHeight:Int;
	/**
	 * The total number of frames in this image.  WARNING: assumes each row in the sprite sheet is full!
	 */
	public var frames(default, null):Int;
	/**
	 * The actual Flash <code>BitmapData</code> object representing the current display state of the sprite.
	 */
	public var framePixels:BitmapData;
	/**
	 * Set this flag to true to force the sprite to update during the draw() call.
	 * NOTE: Rarely if ever necessary, most sprite operations will flip this flag automatically.
	 */
	public var dirty:Bool;
	
	/**
	 * Internal, keeps track of the current index into the tile sheet based on animation or rotation.
	 */
	private var _curIndex:Int;
	/**
	 * Internal tracker for color tint, used with Flash getter/setter.
	 */
	private var _color:Int;
	/**
	 * Internal, stores the entire source graphic (not the current displayed animation frame), used with Flash getter/setter.
	 */
	private var _pixels:BitmapData;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashPoint:Point;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect:Rectangle;
	/**
	 * Internal, reused frequently during drawing and animating.
	 */
	private var _flashRect2:Rectangle;
	/**
	 * Internal, reused frequently during drawing and animating. Always contains (0,0).
	 */
	private var _flashPointZero:Point;
	/**
	 * Internal, helps with animation, caching and drawing.
	 */
	private var _colorTransform:ColorTransform;
	/**
	 * Internal, reflects the need to use _colorTransform object
	 */
	private var _useColorTransform:Bool;
	/**
	 * Internal, helps with animation, caching and drawing.
	 */
	private var _matrix:Matrix;
	
	/**
	 * Link to current FlxFrame from loaded atlas
	 */
	private var _flxFrame:FlxFrame;
	
	private var _halfWidth:Float = 0;
	private var _halfHeight:Float = 0;
	
	/**
	 * Creates a white 8x8 square <code>FlxSprite</code> at the specified position.
	 * Optionally can load a simple, one-frame graphic instead.
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	SimpleGraphic	The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 */
	public function new(X:Float = 0, Y:Float = 0, SimpleGraphic:Dynamic = null)
	{
		super(X, Y);
		
		_flashPoint = new Point();
		_flashRect = new Rectangle();
		_flashRect2 = new Rectangle();
		_flashPointZero = new Point();
		scale = new FlxPoint(1.0, 1.0);
		_color = 0x00ffffff;
		alpha = 1.0;
		#if flash
		blend = null;
		#else
		_blend = null;
		#end
		antialiasing = false;
		
		facing = FlxObject.RIGHT;
		_flipped = 0;
		_curIndex = 0;
		
		_matrix = new Matrix();
		
		_flxFrame = null;
		
		if (SimpleGraphic == null)
		{
			SimpleGraphic = FlxAssets.imgDefault;
		}
		loadGraphic(SimpleGraphic);
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		_flashPoint = null;
		_flashRect = null;
		_flashRect2 = null;
		_flashPointZero = null;
		scale = null;
		_matrix = null;
		_colorTransform = null;
		if (framePixels != null)
		{
			framePixels.dispose();
		}
		framePixels = null;
		#if flash
		blend = null;
		#else
		_blend = null;
		#end
		
		_textureData = null;
		_flxFrame = null;
		
		super.destroy();
	}
	
	/**
	 * Load an image from an embedded graphic file.
	 * @param	Graphic		The image you want to use.
	 * @param	Animated	Whether the Graphic parameter is a single sprite or a row of sprites.
	 * @param	Reverse		Whether you need this class to generate horizontally flipped versions of the animation frames.
	 * @param	Width		Optional, specify the width of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Height		Optional, specify the height of your sprite (helps FlxSprite figure out what to do with non-square sprites or sprite sheets).
	 * @param	Unique		Optional, whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 * @param	Key			Optional, set this parameter if you're loading BitmapData.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadGraphic(Graphic:Dynamic, Animated:Bool = false, Reverse:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, Key:String = null):SimpleSprite
	{
		#if !flash
		_pixels = FlxG.bitmap.add(Graphic, false, Unique, Key);
		_bitmapDataKey = FlxG.bitmap._lastBitmapDataKey;
		#else
		_pixels = FlxG.bitmap.add(Graphic, Reverse, Unique, Key);
		#end
		
		if (Reverse)
		{
			_flipped = _pixels.width >> 1;
		}
		else
		{
			_flipped = 0;
		}
		if (Width == 0)
		{
			if (Animated)
			{
				Width = _pixels.height;
			}
			else if (_flipped > 0)
			{
				#if flash
				Width = Std.int(_pixels.width * 0.5);
				#else
				Width = _pixels.width;
				#end
			}
			else
			{
				Width = _pixels.width;
			}
		}
		width = frameWidth = Width;
		if (Height == 0)
		{
			if (Animated)
			{
				Height = Std.int(width);
			}
			else
			{
				Height = _pixels.height;
			}
		}
		
		#if !flash
		if (Key != null && (Width != 0 || Height != 0))
		{
			Key += "FrameSize:" + Width + "_" + Height;
		}
		_pixels = FlxG.bitmap.add(Graphic, false, Unique, Key, Width, Height);
		_bitmapDataKey = FlxG.bitmap._lastBitmapDataKey;
		#else
		nullTextureData();
		#end
		
		height = frameHeight = Height;
		resetHelpers();
		updateAtlasInfo();
		return this;
	}
	
	/**
	 * This function creates a flat colored square image dynamically.
	 * @param	Width		The width of the sprite you want to generate.
	 * @param	Height		The height of the sprite you want to generate.
	 * @param	Color		Specifies the color of the generated block.
	 * @param	Unique		Whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 * @param	Key			Optional parameter - specify a string key to identify this graphic in the cache.  Trumps Unique flag.
	 * @return	This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function makeGraphic(Width:Int, Height:Int, Color:Int = 0xffffffff, Unique:Bool = false, Key:String = null):SimpleSprite
	{
		_pixels = FlxG.bitmap.create(Width, Height, Color, Unique, Key);
		#if !flash
		_bitmapDataKey = FlxG.bitmap._lastBitmapDataKey;
		#else
		nullTextureData();
		#end
		width = frameWidth = _pixels.width;
		height = frameHeight = _pixels.height;
		resetHelpers();
		updateAtlasInfo();
		return this;
	}
	
	/**
	 * Loads TexturePacker atlas.
	 * @param	Data		Atlas data holding links to json-data and atlas image
	 * @param	Reverse		Whether you need this class to generate horizontally flipped versions of the animation frames.
	 * @param	Unique		Optional, whether the graphic should be a unique instance in the graphics cache.  Default is false.
	 * @param	FrameName	Default frame to show. If null then will be used first available frame.
	 *
	 * @return This FlxSprite instance (nice for chaining stuff together, if you're into that).
	 */
	public function loadImageFromTexture(Data:TexturePackerData, Reverse:Bool = false, Unique:Bool = false, FrameName:String = null):SimpleSprite
	{
		_textureData = Data;
		
		_pixels = FlxG.bitmap.add(Data.assetName, false, Unique);
		_bitmapDataKey = FlxG.bitmap._lastBitmapDataKey;
		
		if (Reverse)
		{
			_flipped = _pixels.width >> 1;
		}
		else
		{
			_flipped = 0;
		}
		
		updateAtlasInfo();
		resetHelpers();
		
		if (FrameName != null)
		{
			frameName = FrameName;
		}
		
		return this;
	}
	
	/**
	 * Resets _flashRect variable used for frame bitmapData calculation
	 */
	private function resetSize():Void
	{
		_flashRect.x = 0;
		_flashRect.y = 0;
		_flashRect.width = frameWidth;
		_flashRect.height = frameHeight;
	}
	
	/**
	 * Resets frame size to _flxFrame dimensions
	 */
	private function resetFrameSize():Void
	{
		frameWidth = Std.int(_flxFrame.sourceSize.x);
		frameHeight = Std.int(_flxFrame.sourceSize.y);
		resetSize();
	}
	
	/**
	 * Resets sprite's size back to frame size
	 */
	public function resetSizeFromFrame():Void
	{
		width = frameWidth;
		height = frameHeight;
	}
	
	/**
	 * Resets some important variables for sprite optimization and rendering.
	 */
	private function resetHelpers():Void
	{
		resetSize();
		_flashRect2.x = 0;
		_flashRect2.y = 0;
		_flashRect2.width = _pixels.width;
		_flashRect2.height = _pixels.height;
		
	#if flash
		if ((framePixels == null) || (framePixels.width != frameWidth) || (framePixels.height != frameHeight))
		{
			framePixels = new BitmapData(Std.int(width), Std.int(height));
		}
		framePixels.copyPixels(_pixels, _flashRect, _flashPointZero);
		if (_useColorTransform) framePixels.colorTransform(_flashRect, _colorTransform);
	#end
		
		if (_textureData == null)
		{
			#if flash
			frames = Std.int(_flashRect2.width / _flashRect.width * _flashRect2.height / _flashRect.height);
			#else
			frames = Std.int(_flashRect2.width / (_flashRect.width + 1) * _flashRect2.height / (_flashRect.height + 1));
			if (frames == 0) frames = 1;
			#end
		}
		else
		{
			frames = _framesData.frames.length;
		}
	
	#if flash
		if (_textureData != null)
		{
	#end
			if (_flipped > 0)
			{
				frames *= 2;
			}
	#if flash
		}
	#end
		
		_curIndex = 0;
		#if !flash
		if (_framesData != null)
		{
			_flxFrame = _framesData.frames[_curIndex];
		}
		#end
		
		_halfWidth = frameWidth * 0.5;
		_halfHeight = frameHeight * 0.5;
	}
	
	/**
	 * Checks if we need to use tinting for rendering
	 */
	inline public function isColored():Bool
	{
		return (_color < 0xffffff);
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		#if !flash
		if (_atlas == null)
		{
			return;
		}
		#end
		
		if(_flickerTimer != 0)
		{
			_flicker = !_flicker;
			if (_flicker)
			{
				return;
			}
		}
		
		if (dirty)	//rarely
		{
			calcFrame();
		}
		
		var camera:FlxCamera = FlxG.cameras.defaultCamera;
		
	#if !flash
		var drawItem:DrawStackItem;
		var currDrawData:Array<Float>;
		var currIndex:Int;
		#if js
		var useAlpha:Bool = (alpha < 1);
		#end
		
		var radians:Float;
		var cos:Float;
		var sin:Float;
	#end
		
		if (!onScreenSprite(camera) || !camera.visible || !camera.exists)
		{
			return;
		}
		
	#if !flash
		#if !js
		drawItem = camera.getDrawStackItem(_atlas, false, _blendInt);
		#else
		drawItem = camera.getDrawStackItem(_atlas, useAlpha);
		#end
		currDrawData = drawItem.drawData;
		currIndex = drawItem.position;
		
		_point.x = x - (camera.scroll.x * scrollFactor.x);
		_point.y = y - (camera.scroll.y * scrollFactor.y);
		
		_point.x = (_point.x) + _halfWidth;
		_point.y = (_point.y) + _halfHeight;
		
		#if js
		_point.x = Math.floor(_point.x);
		_point.y = Math.floor(_point.y);
		#end
	#else
		_point.x = x - (camera.scroll.x * scrollFactor.x);
		_point.y = y - (camera.scroll.y * scrollFactor.y);
	#end
#if flash
		if (simpleRenderSprite())
		{
			_flashPoint.x = _point.x;
			_flashPoint.y = _point.y;
			
			camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
		}
		else
		{
			_matrix.identity();
			_matrix.translate( -_halfWidth, -_halfHeight);
			_matrix.scale(scale.x, scale.y);
			_matrix.translate(Std.int(_point.x + _halfWidth), Std.int(_point.y + _halfHeight));
			camera.buffer.draw(framePixels, _matrix, null, blend, null, antialiasing);
		}
#else
		var csx:Float = 1;
		var ssy:Float = 0;
		var ssx:Float = 0;
		var csy:Float = 1;
		
		var x1:Float = 0;
		var y1:Float = 0;
		
		var x2:Float = x1;
		var y2:Float = y1;
		
		var facingMult:Int = ((_flipped != 0) && (facing == FlxObject.LEFT)) ? -1 : 1;
		
		// transformation matrix coefficients
		var a:Float = csx;
		var b:Float = ssy;
		var c:Float = ssx;
		var d:Float = csy;
		
		if (!simpleRenderSprite())
		{
			radians = -(_flxFrame.additionalAngle) * FlxAngle.TO_RAD;
			cos = Math.cos(radians);
			sin = Math.sin(radians);
			
			csx = cos * scale.x * facingMult;
			ssy = sin * scale.y;
			ssx = sin * scale.x * facingMult;
			csy = cos * scale.y;
			
			if (_flxFrame.rotated)
			{
				x2 = x1 * ssx - y1 * csy;
				y2 = x1 * csx + y1 * ssy;
				
				a = csy;
				b = ssx;
				c = ssy;
				d = csx;
			}
			else
			{
				x2 = x1 * csx + y1 * ssy;
				y2 = -x1 * ssx + y1 * csy;
				
				a = csx;
				b = ssy;
				c = ssx;
				d = csy;
			}
		}
		else
		{
			csx *= facingMult;
			
			x2 = x1 * csx + y1 * ssy;
			y2 = -x1 * ssx + y1 * csy;
			
			a *= facingMult;
		}
		
		currDrawData[currIndex++] = _point.x - x2;
		currDrawData[currIndex++] = _point.y - y2;
		
		currDrawData[currIndex++] = _flxFrame.tileID;
		
		currDrawData[currIndex++] = a;
		currDrawData[currIndex++] = -c;
		currDrawData[currIndex++] = b;
		currDrawData[currIndex++] = d;
		
		#if !js
		currDrawData[currIndex++] = alpha;
		#else
		if (useAlpha)
		{
			currDrawData[currIndex++] = alpha;
		}
		#end
		drawItem.position = currIndex;
#end
		FlxBasic._VISIBLECOUNT++;
	}
	
	/**
	 * This function draws a circle on this sprite at position X,Y
	 * with the specified color.
	 * @param X X coordinate of the circle's center
	 * @param Y Y coordinate of the circle's center
	 * @param Radius Radius of the circle
	 * @param Color Color of the circle
	*/
	public function drawCircle(X:Float, Y:Float, Radius:Float, Color:Int):Void
	{
		var gfx:Graphics = FlxG.flashGfx;
		gfx.clear();
		gfx.beginFill(Color, 1);
		gfx.drawCircle(X, Y, Radius);
		gfx.endFill();

		_pixels.draw(FlxG.flashGfxSprite);
		dirty = true;
		
		resetFrameBitmapDatas();
		updateAtlasInfo(true);
	}
	
	/**
	 * Fills this sprite's graphic with a specific color.
	 * @param	Color		The color with which to fill the graphic, format 0xAARRGGBB.
	 */
	public function fill(Color:Int):Void
	{
		_pixels.fillRect(_flashRect2, Color);
		if (_pixels != framePixels)
		{
			dirty = true;
		}
		
		resetFrameBitmapDatas();
		updateAtlasInfo(true);
	}
	
	/**
	 * Request (or force) that the sprite update the frame before rendering.
	 * Useful if you are doing procedural generation or other weirdness!
	 * @param	Force	Force the frame to redraw, even if its not flagged as necessary.
	 */
	public function drawFrame(Force:Bool = false):Void
	{
		#if flash
		if (Force || dirty)
		{
			calcFrame();
		}
		#else
		calcFrame(true);
		#end
	}
	
	/**
	 * Tell the sprite to change to a random frame of animation
	 * Useful for instantiating particles or other weird things.
	 */
	public function randomFrame():Void
	{
		_curIndex = Std.int(Math.random() * frames);
		#if !flash
		if (_framesData != null)
		#else
		if (_textureData != null)
		#end
		{
			_flxFrame = _framesData.frames[_curIndex];
			resetFrameSize();
		}
		
		dirty = true;
	}
	
	/**
	 * Set <code>pixels</code> to any <code>BitmapData</code> object.
	 * Automatically adjust graphic size and render helpers.
	 */
	public var pixels(get_pixels, set_pixels):BitmapData;
	
	private function get_pixels():BitmapData
	{
		return _pixels;
	}
	
	/**
	 * @private
	 */
	private function set_pixels(Pixels:BitmapData):BitmapData
	{
		_pixels = Pixels;
		width = frameWidth = _pixels.width;
		height = frameHeight = _pixels.height;
		resetHelpers();
		#if !flash
		_bitmapDataKey = FlxG.bitmap.getCacheKeyFor(_pixels);
		if (_bitmapDataKey == null)
		{
			_bitmapDataKey = FlxG.bitmap.getUniqueKey();
			FlxG.bitmap.add(Pixels, false, false, _bitmapDataKey);
		}
		#else
		nullTextureData();
		#end
		updateAtlasInfo(true);
		return _pixels;
	}
	
	/**
	 * @private
	 */
	private function set_facing(Direction:Int):Int
	{
		if (facing != Direction)
		{
			dirty = true;
		}
		facing = Direction;
		return Direction;
	}
	
	/**
	 * Set <code>alpha</code> to a number between 0 and 1 to change the opacity of the sprite.
	 */
	public var alpha(default, set_alpha):Float;
	
	/**
	 * @private
	 */
	private function set_alpha(Alpha:Float):Float
	{
		if (Alpha > 1)
		{
			Alpha = 1;
		}
		if (Alpha < 0)
		{
			Alpha = 0;
		}
		if (Alpha == alpha)
		{
			return alpha;
		}
		alpha = Alpha;
		#if flash
		if ((alpha != 1) || (_color != 0x00ffffff))
		{
			if (_colorTransform == null)
			{
				_colorTransform = new ColorTransform((_color >> 16) / 255, (_color >> 8 & 0xff) / 255, (_color & 0xff) / 255, alpha);
			}
			else
			{
				_colorTransform.redMultiplier = (_color >> 16) / 255;
				_colorTransform.greenMultiplier = (_color >> 8 & 0xff) / 255;
				_colorTransform.blueMultiplier = (_color & 0xff) / 255;
				_colorTransform.alphaMultiplier = alpha;
			}
			_useColorTransform = true;
		}
		else
		{
			if (_colorTransform != null)
			{
				_colorTransform.redMultiplier = 1;
				_colorTransform.greenMultiplier = 1;
				_colorTransform.blueMultiplier = 1;
				_colorTransform.alphaMultiplier = 1;
			}
			
			_useColorTransform = false;
		}
		dirty = true;
		#end
		return alpha;
	}
	
	/**
	 * Tell the sprite to change to a specific frame of animation.
	 *
	 * @param	Frame	The frame you want to display.
	 */
	private function get_frame():Int
	{
		return _curIndex;
	}
	
	/**
	 * @private
	 */
	private function set_frame(Frame:Int):Int
	{
		_curIndex = Frame % frames;
		#if !flash
		if (_framesData != null)
		#else
		if (_textureData != null)
		#end
		{
			_flxFrame = _framesData.frames[_curIndex];
			resetFrameSize();
		}
		
		dirty = true;
		return Frame;
	}
	
	/**
	 * Tell the sprite to change to a frame with specific name.
	 * Useful for sprites with loaded TexturePacker atlas.
	 */
	public var frameName(get_frameName, set_frameName):String;
	
	private function get_frameName():String
	{
		if (_flxFrame != null && _textureData != null)
		{
			return _flxFrame.name;
		}
		
		return null;
	}
	
	private function set_frameName(value:String):String
	{
		if (_textureData != null && _framesData != null && _framesData.framesHash.exists(value))
		{
			if (_framesData != null)
			{
				_flxFrame = _framesData.framesHash.get(value);
				_curIndex = getFrameIndex(_flxFrame);
				resetFrameSize();
			}
			dirty = true;
		}
		
		return value;
	}
	
	/**
	 * Helper function used for finding index of FlxFrame in _framesData's frames array
	 * @param	Frame	FlxFrame to find
	 * @return	position of specified FlxFrame object.
	 */
	public function getFrameIndex(Frame:FlxFrame):Int
	{
		return FlxArray.indexOf(_framesData.frames, Frame);
	}
	
	/**
	 * Check and see if this object is currently on screen.
	 * Differs from <code>FlxObject</code>'s implementation
	 * in that it takes the actual graphic into account,
	 * not just the hitbox or bounding box or whatever.
	 * @param	Camera		Specify which game camera you want.  If null getScreenXY() will just grab the first global camera.
	 * @return	Whether the object is on screen or not.
	 */
	override public function onScreen(Camera:FlxCamera = null):Bool
	{
		return onScreenSprite(Camera);
	}
	
	inline private function onScreenSprite(Camera:FlxCamera = null):Bool
	{
		if (Camera == null)
		{
			Camera = FlxG.cameras.defaultCamera;
		}
		getScreenXY(_point, Camera);
		
		var result:Bool = false;
		var notRotated = true;
#if !flash
		// TODO: make less checks in subclasses
		if (_flxFrame != null)
		{
			notRotated = notRotated && _flxFrame.additionalAngle != 0.0;
		}
#end
		if ((notRotated) && (scale.x == 1) && (scale.y == 1))
		{
			result = ((_point.x + frameWidth > 0) && (_point.x < Camera.width) && (_point.y + frameHeight > 0) && (_point.y < Camera.height));
		}
		else
		{
			var halfWidth:Float = 0.5 * frameWidth;
			var halfHeight:Float = 0.5 * frameHeight;
			var absScaleX:Float = (scale.x > 0)?scale.x: -scale.x;
			var absScaleY:Float = (scale.y > 0)?scale.y: -scale.y;
			#if flash
			var radius:Float = Math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight) * ((absScaleX >= absScaleY)?absScaleX:absScaleY);
			#else
			var radius:Float = ((frameWidth >= frameHeight) ? frameWidth : frameHeight) * ((absScaleX >= absScaleY)?absScaleX:absScaleY);
			#end
			_point.x += halfWidth * scale.x;
			_point.y += halfHeight * scale.y;
			result = ((_point.x + radius > 0) && (_point.x - radius < Camera.width) && (_point.y + radius > 0) && (_point.y - radius < Camera.height));
		}
		
		return result;
	}
	
	/**
	 * Internal function to update the current animation frame.
	 */
	#if flash
	private function calcFrame():Void
	#else
	private function calcFrame(AreYouSure:Bool = false):Void
	#end
	{
	#if !flash
		// TODO: Maybe remove 'AreYouSure' parameter
		if (AreYouSure)
	#else
		if (_flxFrame != null)
	#end
		{
			if ((framePixels == null) || (framePixels.width != frameWidth) || (framePixels.height != frameHeight))
			{
				if (framePixels != null)
				{
					framePixels.dispose();
				}
				framePixels = new BitmapData(Std.int(_flxFrame.sourceSize.x), Std.int(_flxFrame.sourceSize.y));
			}
			
			framePixels.copyPixels(getFlxFrameBitmapData(), _flashRect, _flashPointZero);
		}
	#if flash
		else
		{
			var indexX:Int = _curIndex * frameWidth;
			var indexY:Int = 0;

			//Handle sprite sheets
			var widthHelper:Int = (_flipped != 0) ? _flipped : _pixels.width;
			if (indexX + frameWidth > widthHelper)
			{
				indexY = Std.int(indexX / widthHelper) * frameHeight;
				indexX %= widthHelper;
			}
			
			//handle reversed sprites
			if ((_flipped != 0) && (facing == FlxObject.LEFT))
			{
				indexX = (_flipped << 1) - indexX - frameWidth;
			}
			
			//Update display bitmap
			_flashRect.x = indexX;
			_flashRect.y = indexY;
			framePixels.copyPixels(_pixels, _flashRect, _flashPointZero);
			_flashRect.x = _flashRect.y = 0;
		}
	#end
		
	#if !flash
		if (AreYouSure)
		{
	#end
			if (_useColorTransform)
			{
				framePixels.colorTransform(_flashRect, _colorTransform);
			}
	#if !flash
		}
	#end
		
		dirty = false;
	}
	
	/**
	 * Controls whether the object is smoothed when rotated, affects performance.
	 * @default false
	 */
	public var antialiasing(default, set_antialiasing):Bool;
	
	private function set_antialiasing(val:Bool):Bool
	{
		antialiasing = val;
		return val;
	}
	
	/**
	 * If the Sprite is beeing rendered in simple mode.
	 */
	public var simpleRender(get_simpleRender, null):Bool;
	
	private function get_simpleRender():Bool
	{
		return simpleRenderSprite();
	}
	
	inline private function simpleRenderSprite():Bool
	{
		#if flash
		return ((scale.x == 1) && (scale.y == 1) && (blend == null));
		#else
		// TODO: fix this for subclasses (make less checks)
		var result:Bool = ((scale.x == 1) && (scale.y == 1));
		if (_flxFrame != null)
		{
			result = result && (_flxFrame.additionalAngle == 0);
		}
		return result;
		#end
	}
	
	#if !flash
	public var blend(get_blend, set_blend):BlendMode;
	
	private function get_blend():BlendMode
	{
		return _blend;
	}
	
	private function set_blend(value:BlendMode):BlendMode
	{
		if (value != null)
		{
			switch (value)
			{
				case BlendMode.ADD:
					_blendInt = Tilesheet.TILE_BLEND_ADD;
			#if !js
				case BlendMode.MULTIPLY:
					_blendInt = Tilesheet.TILE_BLEND_MULTIPLY;
				case BlendMode.SCREEN:
					_blendInt = Tilesheet.TILE_BLEND_SCREEN;
			#end
				default:
					_blendInt = Tilesheet.TILE_BLEND_NORMAL;
			}
		}
		else
		{
			_blendInt = 0;
		}
		
		_blend = value;
		return value;
	}
	#end
	
	override public function overlapsPoint(point:FlxPoint, InScreenSpace:Bool = false, Camera:FlxCamera = null):Bool
	{
		if (scale.x == 1 && scale.y == 1)
		{
			return super.overlapsPoint(point, InScreenSpace, Camera);
		}
		
		if (!InScreenSpace)
		{
			return (point.x > x - 0.5 * width * (scale.x - 1)) && (point.x < x + width + 0.5 * width * (scale.x - 1)) && (point.y > y - 0.5 * height * (scale.y - 1)) && (point.y < y + height + 0.5 * height * (scale.y - 1));
		}

		if (Camera == null)
		{
			Camera = FlxG.cameras.defaultCamera;
		}
		var X:Float = point.x - Camera.scroll.x;
		var Y:Float = point.y - Camera.scroll.y;
		getScreenXY(_point, Camera);
		return (X > _point.x - 0.5 * width * (scale.x - 1)) && (X < _point.x + width + 0.5 * width * (scale.x - 1)) && (Y > _point.y - 0.5 * height * (scale.y - 1)) && (Y < _point.y + height + 0.5 * height * (scale.y - 1));
	}
	
	/**
	 * Use this method for creating tileSheet for FlxSprite. Must be called after makeGraphic(), loadGraphic or loadRotatedGraphic().
	 * If you forget to call it then you will not see this FlxSprite on c++ target
	 */
	override public function updateFrameData():Void
	{
	#if !flash
		if (_textureData == null && _node != null && frameWidth >= 1 && frameHeight >= 1)
		{
			if (frames > 1)
			{
				_framesData = _node.getSpriteSheetFrames(Std.int(frameWidth), Std.int(frameHeight), null, 0, 0, 0, 0, 1, 1);
			}
			else
			{
				_framesData = _node.getSpriteSheetFrames(Std.int(frameWidth), Std.int(frameHeight));
			}
			_flxFrame = _framesData.frames[_curIndex];
			return;
		}
		else
	#end
			if (_textureData != null && _node != null)
		{
			_framesData = _node.getTexturePackerFrames(_textureData);
			_flxFrame = _framesData.frames[0];
			resetFrameSize();
			resetSizeFromFrame();
		}
	}
	
	/**
	 * Retrieves BitmapData of current FlxFrame
	 */
	public function getFlxFrameBitmapData():BitmapData
	{
		if (_flxFrame != null)
		{
			if (facing == FlxObject.LEFT && flipped > 0)
			{
				return _flxFrame.getReversedBitmap();
			}
			else
			{
				return _flxFrame.getBitmap();
			}
		}
		
		return null;
	}
	
	/**
	 * Helper function. Useful for flash target when switching to standard renderer
	 */
	private function nullTextureData():Void
	{
		_textureData = null;
		_flxFrame = null;
		_framesData = null;
		_node = null;
		_atlas = null;
	}
	
	/**
	 * Helper function for reseting precalculated FlxFrame bitmapdatas.
	 * Useful when _pixels bitmapdata changes (e.g. after stamp(), drawLine() and other similar method calls).
	 */
	private function resetFrameBitmapDatas():Void
	{
		#if flash
		if (_textureData != null)
		{
		#end
			_atlas._tileSheetData.destroyFrameBitmapDatas();
		#if flash
		}
		#end
	}
}