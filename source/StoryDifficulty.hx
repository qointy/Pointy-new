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

class MenuImage extends FlxSprite
{
	public function new(X, Y, graphic, ?gScale:Float = 1)
	{
		super(X, Y, graphic);
		defaults(gScale);
	}
	public function defaults(gScale:Float)
	{
		setGraphicSize(Std.int(1280 * gScale));
		updateHitbox();
		antialiasing = ClientPrefs.globalAntialiasing;
	}
}
class BGrid extends FlxSkewedSprite
{
	public var maxSkew:Float = 0;
	public var skewSpeed:Float = 15;
	public var dMulti:Float = 1;
	public var skewVal:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, image:String, ?desY:Float = 0, ?skewSpeed:Float = 15, ?maxim:Float = 0)
	{
		super(X, Y);

		loadGraphic(Paths.image(image));
		updateHitbox();
		offset.set(width / 2, height / 2 + desY);
		maxSkew = maxim;
		this.skewSpeed = skewSpeed;

		antialiasing = ClientPrefs.globalAntialiasing;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		skew.x = skewVal;
		skewVal += skewSpeed * elapsed;
		if (maxSkew > 0)
		{
			while (skewVal > maxSkew) skewVal -= maxSkew;
		}
		else if (maxSkew < 0)
		{
			while (skewVal < maxSkew) skewVal -= maxSkew;
		}
	}
}
class StoryDifficulty extends MusicBeatState
{
	var curve:MenuImage;
	var fadeIn:FlxSprite;
	var pointy:MenuImage;
	var grid:BGrid;
	var bttx:Array<Float> = [];
	var btt:Array<MenuImage> = [];
	var sel:Array<MenuImage> = [];
	var time:Float;
	var curSelected = 0;
	var canMove = true;
	var accepted = false;
	override function create()
	{
		WeekData.reloadWeekFiles(true);
		var bg = new MenuImage(0, 0, Paths.image("menustory/bg"));
		add(bg);

		grid = new BGrid(1280 / 2, 720 / 2, "menustory/gridup", 0, -19, -33.9);
		add(grid);
		var gridd = new BGrid(1280 / 2, 720 / 2, "menustory/griddown", 0, 19, 33.9);
		add(gridd);

		var guidebg = new MenuImage(0, 0, Paths.image("menustory/buttonbg"));
		add(guidebg);

		var guide = new MenuImage(0, 0, Paths.image("menustory/buttonguide"));
		add(guide);

		curve = new MenuImage(-1280, 0, Paths.image("menustory/curve"));
		add(curve);

		var name = new MenuImage(0, 0, Paths.image("menustory/name"));
		add(name);

		pointy = new MenuImage(-1280, -400, Paths.image("menustory/pointy"));
		add(pointy);

		var names = ["easy", "normal", "hard"];
		var xx = 450;
		var yy = 100;
		for (i in 0...3)
		{
			btt[i] = new MenuImage(1280, yy - 150, Paths.image("menustory/btt/" + names[i]), 0.7);
			FlxTween.tween(btt[i], {x : xx + i * 50, y : yy}, 0.6, {startDelay : 0.1 * i, ease : FlxEase.elasticOut});
			bttx[i] = xx + i * 50;
			add(btt[i]);
			sel[i] = new MenuImage(1280, 0, Paths.image("menustory/btt/select-" + names[i]), 0.7);
			add(sel[i]);
		}


		fadeIn = new FlxSprite().makeGraphic(2000, 2000, FlxColor.BLACK);
		add(fadeIn);
		super.create();
	}
	override function update(elapsed:Float)
	{
		if (elapsed > 0.17) elapsed = 0.17;
		time += elapsed;
		curve.x += (0 - curve.x) / 6 * elapsed * 60;
		fadeIn.alpha -= elapsed * 5;
		//grid.alpha = 0.75 + Math.cos(time * 8) * 0.25;

		for (i in 0...3)
		{
			sel[i].x = btt[i].x;
			sel[i].y = btt[i].y;
			sel[i].alpha = 1;
			if (curSelected != i)
			{
				sel[i].alpha = 0;
			}
		}

		if (canMove)
		{
			var mov = 0;
			if (controls.UI_DOWN_P) mov ++;
			if (controls.UI_UP_P) mov --;
			if (mov != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				curSelected += mov;
				if (curSelected < 0) curSelected = 2;
				if (curSelected > 2) curSelected = 0;

				var c = curSelected;
				btt[c].x = bttx[c];
				var t = 0.1;
				FlxTween.tween(btt[c], {x : bttx[c] - 70}, t, {ease : FlxEase.circOut});
				FlxTween.tween(btt[c], {x : bttx[c]}, t, {startDelay : t, ease : FlxEase.circIn});
			}

			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				canMove = false;
			}
			else if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				canMove = false;
				accepted = true;
				for (i in 0...3)
				{
					if (i != curSelected)
					{
						FlxTween.tween(btt[i], {alpha : 0}, 0.5);
					}
					else
					{
						FlxFlicker.flicker(sel[i], 1, 0.06, false, false, function(flick:FlxFlicker)
						{
							Main.storyPercent = 0;
							var songArray:Array<String> = [];
							var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[0]).songs;
							WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[0]));
							for (i in 0...leWeek.length) {
								songArray.push(leWeek[i][0]);
							}

							PlayState.storyPlaylist = songArray;
							PlayState.isStoryMode = true;

							var diffic = CoolUtil.getDifficultyFilePath(curSelected);
							if(diffic == null) diffic = '';

							PlayState.storyDifficulty = curSelected;

							PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
							PlayState.storyWeek = 0;
							PlayState.campaignScore = 0;
							PlayState.campaignMisses = 0;

							LoadingState.loadAndSwitchState(new PlayState(), true);
							FreeplayState.destroyFreeplayVocals();
						});
					}
				}
			}
		}
		if (time > 0.1)
		{
			pointy.x += (0 - pointy.x) / 6 * elapsed * 60;
			pointy.y += (0 - pointy.y) / 6 * elapsed * 60;
		}
		super.update(elapsed);
	}
}
