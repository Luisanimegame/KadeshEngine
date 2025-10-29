package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
#if mobile
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import mobile.FlxVirtualPad;
#end

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
	var vPad:FlxVirtualPad;
	var trackedinputs:Array<FlxActionInput> = [];

	public function addVPad(?DPad:FlxDPadMode, ?Action:FlxActionMode) {
		vPad = new FlxVirtualPad(DPad, Action);
		vPad.alpha = 0.35;
		add(vPad);
		controls.setUIVirtualPad(vPad, DPad, Action);
		trackedinputs = controls.trackedUIinputs;
		controls.trackedUIinputs = [];
	}
	
	public function addVPadCamera() {
	  var camcontrol = new FlxCamera(); 
    FlxG.cameras.add(camcontrol, false); 
    camcontrol.bgColor.alpha = 0; 
    vPad.cameras = [camcontrol];
	}

	public function removeVPad() {
	  if (vPad != null) {
	    remove(vPad);
	    controls.removeFlxInput(trackedinputs);
	  }
	}
	#end
	
	override function destroy()
	{
	  #if mobile
	  controls.removeFlxInput(trackedinputs);
	  #end

	  super.destroy();
	  
	  #if mobile
	  if (vPad != null) {
	    vPad.destroy();
	    vPad = null;
	  }
	  #end
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
