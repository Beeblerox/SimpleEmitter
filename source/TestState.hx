package;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxEmitterExt;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import openfl.display.FPS;
import simple.SimpleEmitter;
import simple.SimpleParticle;


class TestState extends FlxState
{
	private var _explosion:SimpleEmitter;
	
	public function new()
	{
		super();
	}
	
	override public function create():Void
	{
		FlxG.state.bgColor = 0xFF333333;
		FlxG.mouse.show();
		
		var fps:FPS = new FPS(10, 10, 0xffffff);
		FlxG.stage.addChild(fps);
		
		//add exlposion emitter
		_explosion = new SimpleEmitter(0, 0, 500, SimpleParticle);
		_explosion.makeParticles("assets/particles.png", 500, true);
		
		_explosion.setAlpha(1.0, 1.0, 0.0, 0.0);
		_explosion.setScale(2.0, 2.0, 1.0, 1.0);
		
		_explosion.x = FlxG.width * 0.5;
		_explosion.y = FlxG.height * 0.5;
		_explosion.start(false, 0.5, 0.0025, 0);
		add(_explosion);
	}
}