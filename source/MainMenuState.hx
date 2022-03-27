package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5b'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'options',
		'credits',
		'extras'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;
	var sqLeft:FlxTiledSprite;
	var sqRight:FlxTiledSprite;
	var chck:FlxSprite;
	var chATime:Float = 0;

	var passed = false;

	var buttonBg:FlxSprite;
	var bttName:Array<String> = ["story", "freeplay", "options", "credits", "extras"];
	var btt:Array<FlxSprite> = [];
	var show:Array<FlxSprite> = [];
	var prevBorder:FlxSprite;

	var logo:FlxSprite;
	var start:FlxSprite;

	var pTime = 0.0;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		passed = Main.passed;

		WeekData.setDirectoryFromWeek();
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		var w = 1920;
		var h = 1080;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxG.camera.zoom = 1280 / w;
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var l:Array<FlxSprite> = [];

		//var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menu/menubg'));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		l[1] = new FlxSprite().loadGraphic(Paths.image("menu/circlesthing"));
		add(l[1]);

		chck = new FlxSprite().loadGraphic(Paths.image("menu/checkboard"));
		chck.scrollFactor.set();
		chck.screenCenter();
		chck.antialiasing = ClientPrefs.globalAntialiasing;
		add(chck);

		sqLeft = new FlxTiledSprite(Paths.image("menu/upsquares"), w, h, false, true);
		sqLeft.scrollFactor.set();
		sqLeft.screenCenter();
		sqLeft.antialiasing = ClientPrefs.globalAntialiasing;
		add(sqLeft);

		sqRight = new FlxTiledSprite(Paths.image("menu/downsquares"), w, h, false, true);
		sqRight.scrollFactor.set();
		sqRight.screenCenter();
		sqRight.antialiasing = ClientPrefs.globalAntialiasing;
		add(sqRight);

		l[0] = new FlxSprite().loadGraphic(Paths.image("menu/menulines"));
		l[0].alpha = 0.25;

		add(l[0]);

		//cosssasss del botones menu frente del
		buttonBg = new FlxSprite().loadGraphic(Paths.image("menu/menubuttonsthing"));
		buttonBg.scrollFactor.set();
		buttonBg.updateHitbox();
		buttonBg.x = -buttonBg.width;
		buttonBg.offset.x = (w - 1280) / 2;
		buttonBg.screenCenter(Y);
		buttonBg.antialiasing = ClientPrefs.globalAntialiasing;
		add(buttonBg);

		logo = new FlxSprite().loadGraphic(Paths.image("titlelogo"));
		l[3] = logo;
		add(logo);

		prevBorder = new FlxSprite().loadGraphic(Paths.image("menu/menupreview"));
		l[2] = prevBorder;
		prevBorder.alpha = 0;
		add(prevBorder);

		l[4] = new FlxSprite().loadGraphic(Paths.image("menu/start"));
		add(l[4]);
		start = l[4];

		for (i in 0...bttName.length)
		{
			btt[i] = new FlxSprite().loadGraphic(Paths.image("menu/buttons/"+bttName[i]+"off"));
			btt[i].scrollFactor.set();
			btt[i].updateHitbox();
			btt[i].offset.x = (w - 1280) / 2;
			btt[i].antialiasing = ClientPrefs.globalAntialiasing;
			btt[i].screenCenter();
			btt[i].x = -w;
			add(btt[i]);

			show[i] = new FlxSprite().loadGraphic(Paths.image("menu/"+bttName[i]+"screen"));
			show[i].scrollFactor.set();
			show[i].alpha = 0;
			show[i].antialiasing = ClientPrefs.globalAntialiasing;
			show[i].screenCenter();
			add(show[i]);
		}

		for (i in 0...l.length)
		{
			l[i].scrollFactor.set();
			l[i].screenCenter();
			l[i].antialiasing = ClientPrefs.globalAntialiasing;
		}
		logo.y -= 120;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.visible = false;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		chATime += elapsed * 60;
		chck.alpha = 0.75 + Math.cos(chATime / 40) * 0.25;
		sqLeft.scrollY -= elapsed * 60;
		sqRight.scrollY += elapsed * 60;
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!passed)
		{
			if (controls.ACCEPT)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				passed = true;
				Main.passed = true;
			}
		}
		else
		{
			pTime += elapsed * 60;
			buttonBg.x += (0 - buttonBg.x) / 5 * elapsed * 60;

			logo.alpha -= elapsed * 3;
			start.alpha = logo.alpha;
			start.y += elapsed * 60 * 30;
			prevBorder.alpha += elapsed * 2;
			for (i in 0...btt.length)
			{
				if (!selectedSomethin)
				{
					if (pTime > 7 + 3*i)
					{
						btt[i].x += (0 - btt[i].x) / (8) * elapsed * 60;
					}
				}
				else
				{
					if (curSelected != i)
					{
						btt[i].x -= elapsed * 60 * 30;
					}
				}
				btt[i].scale.x += (1 - btt[i].scale.x) / 3 * elapsed * 60;

				if (curSelected == i)
				{
					show[i].alpha += elapsed * 8;
				}
				else
				{
					show[i].alpha -= elapsed * 8;
				}

				if (show[i].alpha < 0) show[i].alpha = 0;
				if (show[i].alpha > 1) show[i].alpha = 1;
			}
		}

		if (!selectedSomethin && passed && pTime > 10)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						spr.y = -2000;
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(show[spr.ID], 1, 0.06, false, false);
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										FlxTransitionableState.skipNextTransOut = true;
										MusicBeatState.switchState(new StoryDifficulty());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		var lsel = curSelected;
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		for (i in 0...btt.length)
		{
			if (curSelected == i)
			{
				btt[i].scale.x = 1.03;
				btt[i].color = FlxColor.YELLOW;
			}
			else if (lsel == i)
			{
				btt[i].color = FlxColor.WHITE;
			}
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}
}
