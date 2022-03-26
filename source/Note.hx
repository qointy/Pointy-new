package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flash.display.BitmapData;
import editors.ChartingState;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var rStrumTime:Float = 0;
	public var susLen:Float;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	private var earlyHitMult:Float = 0.5;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;//plan on doing scroll directions soon -bb

	var pointyR = false;
	public var pointyAngle = 0;

	public var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var qColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, BLUE_NOTE, 2];
	public var defAngles:Array<Int> = [180, 90, 270, 0];
	public var arrowAngles:Array<Int> = [0, 0, 0, 0];//[180, 90, 270, 0];

	var curSection:Float;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;
		colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
		colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
		colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'No Animation':
					noAnimation = true;
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}

	var bpmLeak:Float = PlayState.SONG.bpm;
	function sectionStartTime(add:Int = 0):Float
	{
		var _song = PlayState.SONG;
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;
		var sec = Std.int(curSection);
		for (i in 0...sec + add)
		{
			if (_song.notes[i].changeBPM)
			{
				daBPM = _song.notes[i].bpm;
				bpmLeak = daBPM;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		if (_song.notes[sec].changeBPM)
		{
			bpmLeak = _song.notes[sec].bpm;
		}
		return daPos;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?sec:Float = 0, ?_susLen:Float = 0)
	{
		super();

		curSection = sec;
		susLen = _susLen;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		rStrumTime = strumTime;
		this.strumTime = rStrumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % 4);
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				switch (noteData % 4)
				{
					case 0:
						animToPlay = 'purple';
					case 1:
						animToPlay = 'blue';
					case 2:
						animToPlay = 'green';
					case 3:
						animToPlay = 'red';
				}
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if (!isSustainNote) earlyHitMult = 1;
		reloadSus();
		//quantCalc();
	}

	var divs = [4, 8, 12, 16, 24, 32, 48, 64];

	function quantCalc(?force = false)
	{
		if ((force || texture == 'qnotes') && !isSustainNote)
		{
			var col:Int = 0;

			if (susLen == 0)
			{
				var secStart = sectionStartTime();
				/*
				var sCrochet = ((60 / bpmLeak) * 1000) / 4;
				var beat = Math.round(FlxMath.remapToRange(rStrumTime - secStart, 0, 16 * sCrochet, 0, 32));
				*/
				var crochet = (60 / bpmLeak) * 1000;
				var beat = (rStrumTime - secStart) / crochet;
				var beatRow = Math.round(beat * 48);

				var q = 1;
				for (i in 0...divs.length)
				{
					if (beatRow % (192/divs[i]) == 0)
					{
						q = i;
						break;
					}	
				}
				col = q;
				animation.play("" + q);
				//pointyAngle -= arrowAngles[col];
			}
			else
			{
				animation.play("2");
			}

			pointyAngle += defAngles[noteData];
			
			//originAngle = localAngle;
			//originColor = col;
		}
	}

	public var tailSus:Note = null;
	public var mainSus = false;
	public var ogNote:Note = null;
	public var ogSus:Note = null;
	var initSusScale:Float = 1;

	function reloadSus()
	{
		if (isSustainNote && prevNote != null)
		{
			offset.y = 0;
			scale.y = 0.7;
			var colName = ['purple', 'blue', 'green', 'red'];
			if (prevNote.isSustainNote)
			{
				animation.play(colName[noteData] + 'holdend');
				if (prevNote.mainSus)
				{
					ogSus = prevNote;
				}
				else
				{
					ogSus = prevNote.ogSus;
					prevNote.alpha = 0;
					prevNote.multAlpha = 0;
				}
				ogNote = prevNote.ogNote;
				ogSus.tailSus = this;
			}
			else
			{
				animation.play(colName[noteData] + 'hold');
				//scale.y = 1 / frameHeight;
				initSusScale = scale.y;
				mainSus = true;
				ogNote = prevNote;
				//y = 4000; //bull
			}
		}
	}
	function renderSus()
	{
		if (isSustainNote)
		{
			var downS = (ClientPrefs.downScroll && mustPress);
			updateHitbox();
			offset.y = 0;
			offset.x = frameWidth / 2;
			offset.x -= swagWidth / 2;

			//scale.x = 1 / frameWidth * swagWidth;
			if (mainSus)
			{
				offset.y = frameHeight / 2;
				scale.y = (tailSus.y - y) / frameHeight;
				offset.y = - (tailSus.y - y) / 2;
				//y = ogNote.getGraphicMidpoint().y;

				if ((downS && scale.y > 0) || (!downS && scale.y < 0))
				{
					kill();
					tailSus.kill();
					PlayState.notes.remove(this, true);
					PlayState.notes.remove(tailSus, true);
					tailSus.destroy();
					destroy();
				}
			}
			else
			{
				if (downS)
				{
					scale.y = -0.7;
					offset.y = frameHeight * 0.7 - 20;
				}
			}
		}
	}

	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';
		
		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}
		if (skin == 'qnotes')
		{
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims(true);
			antialiasing = ClientPrefs.globalAntialiasing;
			quantCalc(true);
		}
		//skin = 'NOTEPOINTY_assets';

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 4;
				height = height / 2;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
		} else if (skin != "qnotes"){
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims(skin == 'qnotes');
			antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
			if(ClientPrefs.keSustains) {
				scale.y *= 0.75;
			}
		}
		//updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims(arePointy = false) {
		if (arePointy)
		{
			for (i in 0...6)
			{
				animation.addByPrefix("" + i, "quant_" + divs[i] + "th", 24);
			}
			animation.addByPrefix("6", "quant_def", 24);
			animation.addByPrefix("7", "quant_def", 24);
		}
		else
		{
			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');

			if (isSustainNote)
			{
				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');

				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');
			}
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		if (!isSustainNote)
		{
			offset.set(frameWidth / 2, frameHeight / 2);
			offset.x -= swagWidth / 2;
			offset.y -= swagWidth / 2;
		}
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			animation.add('purpleholdend', [PURP_NOTE + 4]);
			animation.add('greenholdend', [GREEN_NOTE + 4]);
			animation.add('redholdend', [RED_NOTE + 4]);
			animation.add('blueholdend', [BLUE_NOTE + 4]);

			animation.add('purplehold', [PURP_NOTE]);
			animation.add('greenhold', [GREEN_NOTE]);
			animation.add('redhold', [RED_NOTE]);
			animation.add('bluehold', [BLUE_NOTE]);
		} else {
			animation.add('greenScroll', [GREEN_NOTE + 4]);
			animation.add('redScroll', [RED_NOTE + 4]);
			animation.add('blueScroll', [BLUE_NOTE + 4]);
			animation.add('purpleScroll', [PURP_NOTE + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// ok river
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
				canBeHit = true;
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (flipY) flipY = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;

			if (!pointyR)
			{
				pointyR = true;
				if (isSustainNote)
				{
					reloadNote('', 'NOTEPOINTY_assets');
				}
				else
				{
					reloadNote('', 'qnotes');
				}
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		if (inEditor)
		{
			angle = pointyAngle;
		}
		renderSus();
	}
}
