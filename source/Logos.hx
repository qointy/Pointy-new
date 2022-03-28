package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.addons.effects.FlxSkewedSprite;
import WeekData;

using StringTools;

class Logos extends MusicBeatState
{
	var lg:Array<FlxSprite> = [];
	var maxTime = 4;
	var timer:Float;
	var fade:FlxSprite = new FlxSprite(0, 0).makeGraphic(2000, 2000, FlxColor.BLACK);
	var next = false;
	var tTime = 0.7;
	var onWho = 0;
	var wFade:FlxSprite = new FlxSprite(0, 0).makeGraphic(2000, 2000, FlxColor.WHITE);
	var lagStart = false;
	override function create()
	{
		timer = maxTime;
		for (i in 0...2)
		{
			lg[i] = new FlxSprite(0, 0, Paths.image("logos_" + (i + 1)));
			lg[i].antialiasing = ClientPrefs.globalAntialiasing;
			lg[i].setGraphicSize(1280);
			lg[i].updateHitbox();
			if (i != 0) lg[i].alpha = 0;
			add(lg[i]);
			trace(i);
		}
		add(fade);
		wFade.alpha = 0;
		add(wFade);
		FlxTween.tween(fade, {alpha : 0}, tTime);
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (lagStart && !next)
		{
			timer -= elapsed;
			if (controls.ACCEPT) timer = 0;
			if (timer <= 0)
			{
				next = true;
				var f = fade;
				if (onWho == lg.length - 1) f = wFade;
				FlxTween.tween(f, {alpha : 1}, tTime, {
					onComplete: function(twn:FlxTween)
					{
						onWho ++;
						if (onWho >= lg.length)
						{
							FlxTransitionableState.skipNextTransIn = true;
							FlxTransitionableState.skipNextTransOut = true;
							MusicBeatState.switchState(new MainMenuState());
						}
						else
						{
							timer = maxTime;
							next = false;
							lg[onWho - 1].alpha = 0;
							lg[onWho].alpha = 1;
							FlxTween.tween(fade, {alpha : 0}, tTime);
						}
					}
				});
			}
		}

		if (!lagStart)
		{
			lagStart = true;
		}
		super.update(elapsed);
	}
}
