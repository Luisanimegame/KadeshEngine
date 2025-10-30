package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	public static var leftState:Bool = false;
	public static var needVer:String = "IDFK LOL";
	public static var currChanges:String = "dk";
	private var colorRotation:Int = 1;

	override function create()
	{
		super.create();
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('gayblack', 'shared'));
		bg.screenCenter();
		bg.setGraphicSize(Std.int(bg.width * 1.137));
		add(bg);
		
		var txt:FlxText = new FlxText(0, 0, FlxG.width, "Fuck, ta podendo desistir disso? vou chorar", 32);
		
		txt.setFormat("VCR OSD Mono", 32, FlxColor.fromRGB(200, 200, 200), CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 3;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		#if mobile
        var jusTouched:Bool = false;

        for (touch in FlxG.touches.list)
          if (touch.justPressed)
            jusTouched = true;
        #end
		if (controls.ACCEPT #if mobile || jusTouched #end)
		{
			leftState = true;
			FlxG.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
