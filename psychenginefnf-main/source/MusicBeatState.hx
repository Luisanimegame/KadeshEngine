package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
#if mobile
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import mobile.FlxVirtualPad;
import mobile.HitBox;
import mobile.Mobilecontrols;
#end

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;
	
	#if mobile
	var vPad:FlxVirtualPad;
	var mcontrols:Mobilecontrols;

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
	
	public function addMControls()
	{
	  mcontrols = new Mobilecontrols();
	  switch (mcontrols.mode.toLowerCase())
	  {
	    case 'vpad_right' | 'vpad_left' | 'vpad_custom':
	      controls.setVirtualPad(mcontrols.vPad, FULL, NONE);
	    case 'hitbox':
	      controls.setHitBox(mcontrols.hitbox);
	    default:
	  }

	  trackedinputs = controls.trackedinputs;
	  controls.trackedinputs = [];

	  var camcontrol = new FlxCamera();
	  FlxG.cameras.add(camcontrol, false);
	  camcontrol.bgColor.alpha = 0;
	  mcontrols.cameras = [camcontrol];

	  mcontrols.visible = false;
	  
	  add(mcontrols);
	}

	public function removeMControls()
	{
	  if (mcontrols != null) {
	    controls.removeFlxInput(trackedinputs);
	    remove(mcontrols);
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
	  
	  if (mcontrols != null) {
	    mcontrols.destroy();
	    mcontrols = null;
	  }
	  #end
	}

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
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

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
