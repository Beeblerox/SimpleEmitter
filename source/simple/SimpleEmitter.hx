package simple;


class SimpleEmitter extends SimpleTypedEmitter<SimpleParticle>
{
	public function new(X:Float = 0, Y:Float = 0, Size:Int = 50)
	{
		super(X, Y, Size);
	}
	
	override function createParticle():SimpleParticle
	{
		return recycle(SimpleParticle);
	}
}