package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;

class Floor extends FlxSkewedSprite
{
	public var maxSkew:Float = 30;
	public var minSkew:Float = -30;
	public var skewSpeed:Float = 15;
	public var dMulti:Float = 1;

	public function new(X:Float = 0, Y:Float = 0, image:String, ?desY:Float = 0, ?depth = 1)
	{
		super(X, Y);

		loadGraphic(Paths.image(image));
		updateHitbox();
		offset.set(width / 2, height / 2 + desY);
		dMulti = depth;

		antialiasing = ClientPrefs.globalAntialiasing;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		skew.x = -(PlayState.camFollowPos.x - x) / (25 / dMulti);
	}
}
