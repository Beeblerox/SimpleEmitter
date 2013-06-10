package simple;
import org.flixel.FlxBasic;
import org.flixel.FlxG;
import org.flixel.FlxObject;
	
/**
 * This is a simple particle class that extends the default behavior
 * of <code>FlxSprite</code> to have slightly more specialized behavior
 * common to many game scenarios.  You can override and extend this class
 * just like you would <code>FlxSprite</code>. While <code>FlxEmitter</code>
 * used to work with just any old sprite, it now requires a
 * <code>FlxParticle</code> based class.
*/

class SimpleParticle extends SimpleSprite
{
	/**
	 * How long this particle lives before it disappears.
	 * NOTE: this is a maximum, not a minimum; the object
	 * could get recycled before its lifespan is up.
	 */
	public var lifespan:Float;
	
	/**
	 * Determines how quickly the particles come to rest on the ground.
	 * Only used if the particle has gravity-like acceleration applied.
	 * @default 500
	 */
	public var friction:Float;
	
	/**
	 * If this is set to true, particles will slowly fade away by
	 * decreasing their alpha value based on their lifespan.
	*/
	public var useFading:Bool = false;

	/**
	 * If this is set to true, particles will slowly decrease in scale
	 * based on their lifespan.
	 * WARNING: This severely impacts performance on flash target.
	*/
	public var useScaling:Bool = false;
	
	/**
	 * Helper variable for fading, scaling and coloring particle.
	 */
	public var maxLifespan:Float;
	
	/**
	 * Start value for particle's alpha
	 */
	public var startAlpha:Float;
	
	/**
	 * Range of alpha change during particle's life
	 */
	public var rangeAlpha:Float;
	
	/**
	 * Start value for particle's scale.x and scale.y
	 */
	public var startScale:Float;
	
	/**
	 * Range of scale change during particle's life
	 */
	public var rangeScale:Float;
	
	/**
	 * Instantiate a new particle.  Like <code>FlxSprite</code>, all meaningful creation
	 * happens during <code>loadGraphic()</code> or <code>makeGraphic()</code> or whatever.
	 */
	public function new()
	{
		super();
		lifespan = 0;
		friction = 500;
		exists = false;
	}
	
	/**
	 * The particle's main update logic.  Basically it checks to see if it should
	 * be dead yet, and then has some special bounce behavior if there is some gravity on it.
	 */
	override public function update():Void
	{
		FlxBasic._ACTIVECOUNT++;
		
		if (_flickerTimer > 0)
		{
			_flickerTimer -= FlxG.elapsed;
			if(_flickerTimer <= 0)
			{
				_flickerTimer = 0;
				_flicker = false;
			}
		}
		
		last.x = x;
		last.y = y;
		
		//lifespan behavior
		if (lifespan > 0)
		{
			lifespan -= FlxG.elapsed;
			if (lifespan <= 0)
			{
				kill();
			}
			
			var lifespanRatio:Float = (1 - lifespan / maxLifespan);
			
			// Fading
			if (useFading)
			{
				alpha = startAlpha + lifespanRatio * rangeAlpha;
			}
			
			// Changing size
			if (useScaling)
			{
				scale.x = scale.y = startScale + lifespanRatio * rangeScale;
			}
			
			//simpler bounce/spin behavior for now
			if (touching != 0)
			{
				if (angularVelocity != 0)
				{
					angularVelocity = -angularVelocity;
				}
			}
			if (acceleration.y > 0) //special behavior for particles with gravity
			{
				if ((touching & FlxObject.FLOOR) != 0)
				{
					drag.x = friction;
					
					if ((wasTouching & FlxObject.FLOOR) == 0)
					{
						if (velocity.y < -elasticity * 10)
						{
							if (angularVelocity != 0)
							{
								angularVelocity *= -elasticity;
							}
						}
						else
						{
							velocity.y = 0;
							angularVelocity = 0;
						}
					}
				}
				else
				{
					drag.x = 0;
				}
			}
		}
		
		if (exists && alive)
		{
			updateMotion();
			wasTouching = touching;
			touching = FlxObject.NONE;
		}
	}
	
	override public function reset(X:Float, Y:Float):Void 
	{
		super.reset(X, Y);
		
		alpha = 1.0;
		scale.x = scale.y = 1.0;
	}
	
	/**
	 * Triggered whenever this object is launched by a <code>FlxEmitter</code>.
	 * You can override this to add custom behavior like a sound or AI or something.
	 */
	public function onEmit():Void { }	
}