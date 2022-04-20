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

class ExtrasMenu extends MusicBeatState
{
    var curDifficulty = 2;
    var sel:Int = 0;
    var opt:Array<FlxText> = [];
    var sng:Array<String> = ["drift", "dynamism", "revolution"];
    public static var gameOver = false;
    public static var lastSel = 0;
    var overed = true;
    var title:FlxText;
    var goText:FlxText;
    var record:FlxText;
	override function create()
	{
        //Recororor
        if (FlxG.save.data.instRecords == null)
        {
            FlxG.save.data.instRecords = [0, 0, 0];
            FlxG.save.flush();
        }
        if (FlxG.save.data.instFC == null)
        {
            FlxG.save.data.instFC = [false, false, false];
            FlxG.save.flush();
        }
        overed = true;
        sel = ExtrasMenu.lastSel;
        WeekData.reloadWeekFiles(true);

		var bg = new FlxSprite().loadGraphic(Paths.image("extrasMenu"));
		add(bg);
        var xx = 410;

        var descText = new FlxText(xx, 60, 1180, "Instrumental charts", 32);
        descText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.GRAY, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(descText);
        title = descText;
        title.alpha = 0;

        record = new FlxText(xx + 550, 600, 300, "", 32);
        record.setFormat(Paths.font("vcr.ttf"), 38, FlxColor.GRAY, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(record);
        record.alpha = 0;

        goText = new FlxText(xx, 290, 1180, "GAME OVER", 32);
        goText.setFormat(Paths.font("vcr.ttf"), 76, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        goText.alpha = 0;
        add(goText);

        for (i in 0...3)
        {
            descText = new FlxText(xx, 160 + 180 * i, 1180, sng[i].toUpperCase(), 32);
            descText.setFormat(Paths.font("vcr.ttf"), 70, FlxColor.GREEN, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.GREEN);
            descText.borderSize = 2.4;
            add(descText);
            descText.alpha = 0;
            opt.push(descText);
        }

        if (ExtrasMenu.gameOver)
        {
            goText.alpha = 1;
            overed = false;
            FlxG.sound.play(Paths.sound('instGameOver'));
        }
		super.create();
	}
	override function update(elapsed:Float)
	{
		if (elapsed > 0.17) elapsed = 0.17;

        if (overed)
        {
            title.alpha = 1;
            record.alpha = 1;
            record.text = "";
            if (FlxG.save.data.instFC[sel]) record.text += "FC ";
            record.text += (Math.floor(FlxG.save.data.instRecords[sel] * 100) / 100) + "%";
            var mov = 0;
            if (controls.UI_DOWN_P) mov ++;
            if (controls.UI_UP_P) mov --;
            if (mov != 0)
            {
                FlxG.sound.play(Paths.sound('scrollMenu'));
                sel += mov;
                if (sel < 0) sel = 2;
                if (sel > 2) sel = 0;

                ExtrasMenu.lastSel = sel;
            }
            for (i in 0...3)
            {
                opt[i].alpha = 1;
                if (sel == i)
                {
                    opt[i].color = FlxColor.WHITE;
                }
                else
                {
                    opt[i].color = FlxColor.GREEN;
                }
            }
            if (controls.BACK)
            {
                FlxTransitionableState.skipNextTransIn = false;
                FlxTransitionableState.skipNextTransOut = false;

                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
            }
            else if (controls.ACCEPT)
            {
                Paths.currentModDirectory = "Pointer";
                PlayState.SONG = Song.loadFromJson(sng[sel] + "-inst", sng[sel]);
                PlayState.isStoryMode = false;
                PlayState.storyDifficulty = curDifficulty;

                PlayState.storyWeek = 0;

                FlxTransitionableState.skipNextTransIn = true;
                FlxTransitionableState.skipNextTransOut = true;

                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.play(Paths.sound('confirmMenu'));
                //trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
            }
        }
        else
        {
            if (controls.ACCEPT)
            {
                ExtrasMenu.gameOver = false;
                goText.alpha = 0;
                overed = true;
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
                FlxG.sound.music.fadeIn(0.1, 0.6, 0.7);
            }
        }
        
		super.update(elapsed);
	}
}
