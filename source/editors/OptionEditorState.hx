package editors;

import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIInputText;
import haxe.Exception;
import flixel.group.FlxGroup;
import flixel.addons.ui.FlxUITabMenu;
import options.SoftcodeOption;
import options.Option;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class OptionEditorState extends MusicBeatState
{
	private var curSelected:Int = 0;

    private var UIElements:FlxGroup;

	private var descBox:FlxSprite;
	private var descText:FlxText;

    private var optionDisplay:SoftcodeOption;
    private var checkbox:CheckboxThingie;
    private var valueText:AttachedText;
	private var optionText:Alphabet;

    private var UI_box:FlxUITabMenu;
    private var optionTypeDropDown:FlxUIDropDownMenuCustom;

    private var numberStepper:FlxUINumericStepper;
    private var defaultValue:FlxUIDropDownMenuCustom;
	private var stringOptions:FlxUIInputText;

	private var UIMap:Map<String, Array<FlxSprite>>;

	public function new()
	{
		super();
		
		#if desktop
		DiscordClient.changePresence("Options Editor", null);
		#end
		
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		var titleText:Alphabet = new Alphabet(75, 40, 'Options Editor', true);
		titleText.scaleX = 0.6;
		titleText.scaleY = 0.6;
		titleText.alpha = 0.4;
		add(titleText);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

        optionDisplay = new SoftcodeOption('lorem', 'ipsum', 'editorOption', 'bool');
        optionDisplay.minValue = 0;
        optionDisplay.maxValue = 1;

		optionText = new Alphabet(290, 260, optionDisplay.name, false);
		optionText.isMenuItem = true;
		optionText.targetY = 0;
		add(optionText);

        checkbox = new CheckboxThingie(optionText.x - 105, optionText.y, optionDisplay.getValue() == true);
		checkbox.sprTracker = optionText;
		checkbox.ID = 0;
        add(checkbox);

        valueText = new AttachedText('' + optionDisplay.getValue(), optionText.width + 80);
		valueText.sprTracker = optionText;
		valueText.copyAlpha = false;
		valueText.ID = 0;
		add(valueText);
		optionDisplay.setChild(valueText);

        valueText.visible = false;

		if(optionDisplay.type != 'bool') {
			optionText.x == 80;
			optionText.startPosition.x -= 80;
				//optionText.xAdd -= 80;
		}
			//optionText.snapToPosition(); //Don't ignore me when i ask for not making a fucking pull request to uncomment this line ok
		updateTextFrom(optionDisplay);

		refreshOption();
		reloadCheckbox();

        var tabs = [
			//{name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(350, 200);
		UI_box.x = FlxG.width - UI_box.width - 25;
		UI_box.y = 25;
		UI_box.scrollFactor.set();
        add(UI_box);

        var tab_group = new FlxUI(null, UI_box);
        tab_group.name = 'Settings';

        var optionTypes = ['bool', 'string', 'int', 'float', 'percent'];

        optionTypeDropDown = new FlxUIDropDownMenuCustom(10, 35, FlxUIDropDownMenuCustom.makeStrIdLabelArray(optionTypes, true), function(option:String)
        {
            if (option != optionDisplay.type)
                optionDisplay.reloadOption(optionTypes[Std.parseInt(option)]);
                reloadOption();
                reloadCheckbox();
                updateTextFrom(optionDisplay);
				refreshUI(optionDisplay.type);
        });

		var optionTypes = [true, false];

		defaultValue = new FlxUIDropDownMenuCustom(10, optionTypeDropDown.height - 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(['true', 'false'], false), function(option:String)
		{
			if (option != optionDisplay.defaultValue)
				switch(optionDisplay.type) {
					case 'string': optionDisplay.defaultValue = option;
					default: optionDisplay.defaultValue = option == 'true' ? true : false;
				}
				optionDisplay.setValue(optionDisplay.defaultValue);
				reloadCheckbox();
				updateTextFrom(optionDisplay);
		});

		numberStepper = new FlxUINumericStepper(defaultValue.x+4, defaultValue.y+4, 1, 0);
		stringOptions = new FlxUIInputText(20 + optionTypeDropDown.width, optionTypeDropDown.y, 119, 'option1,option2,option3', 8);
        
		UIMap = [
			'bool' => [],
			'string' => [],
			'int' => [],
			'float' => [],
			'percent' => [],
			'ignore' => []
		];

		var textVar:FlxText = new FlxText(optionTypeDropDown.x, optionTypeDropDown.y - 18, 0, 'Option Type:');
        tab_group.add(textVar);
		UIMap['ignore'].push(textVar);

		var textVar:FlxText = new FlxText(defaultValue.x, defaultValue.y - 18, 0, 'Default Value:');
        tab_group.add(textVar);
		UIMap['ignore'].push(textVar);

		tab_group.add(defaultValue);
		UIMap['bool'].push(defaultValue);
		UIMap['string'].push(defaultValue);

		tab_group.add(numberStepper);
		UIMap['int'].push(numberStepper);
		UIMap['float'].push(numberStepper);
		UIMap['percent'].push(numberStepper);

		var textVar:FlxText = new FlxText(stringOptions.x, stringOptions.y - 18, 0, 'String Options:');
        tab_group.add(textVar);
		UIMap['string'].push(textVar);
		tab_group.add(stringOptions);
		UIMap['string'].push(stringOptions);

		tab_group.add(optionTypeDropDown);
		UIMap['ignore'].push(optionTypeDropDown);

        UI_box.addGroup(tab_group);
		refreshUI(optionDisplay.type);
        FlxG.mouse.visible = true;
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE) {
			MusicBeatState.switchState(new editors.MasterEditorMenu());
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		if(nextAccept <= 0)
		{
			var usesCheckbox = optionDisplay.type == 'bool';

			if(usesCheckbox)
			{
				if(controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					optionDisplay.setValue(!optionDisplay.getValue());
					reloadCheckbox();
				}
			} else {
				if(controls.UI_LEFT || controls.UI_RIGHT) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(optionDisplay.type != 'string') {
								add = optionDisplay.changeValue * (controls.UI_LEFT ? -1 : 1);
							}

							switch(optionDisplay.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = optionDisplay.getValue() + add;
									if(holdValue < optionDisplay.minValue) holdValue = optionDisplay.minValue;
									else if (holdValue > optionDisplay.maxValue) holdValue = optionDisplay.maxValue;

									switch(optionDisplay.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											optionDisplay.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, optionDisplay.decimals);
											optionDisplay.setValue(holdValue);
									}

								case 'string':
									var num:Int = optionDisplay.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0) {
										num = optionDisplay.options.length - 1;
									} else if(num >= optionDisplay.options.length) {
										num = 0;
									}

									optionDisplay.curOption = num;
									optionDisplay.setValue(optionDisplay.options[num]); //lol
									//trace(optionDisplay.options[num]);
							}
							updateTextFrom(optionDisplay);
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else if(optionDisplay.type != 'string') {

							holdValue += optionDisplay.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if(holdValue < optionDisplay.minValue) holdValue = optionDisplay.minValue;
							else if (holdValue > optionDisplay.maxValue) holdValue = optionDisplay.maxValue;

							switch(optionDisplay.type)
							{
								case 'int':
									optionDisplay.setValue(Math.round(holdValue));
								
								case 'float' | 'percent':
									optionDisplay.setValue(FlxMath.roundDecimal(holdValue, optionDisplay.decimals));
							}
							updateTextFrom(optionDisplay);
						}
					}

					if(optionDisplay.type != 'string') {
						holdTime += elapsed;
					}
				} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}
			}

			if(controls.RESET)
			{

				optionDisplay.setValue(optionDisplay.defaultValue);
				if(optionDisplay.type != 'bool')
				{
					if(optionDisplay.type == 'string')
					{
						optionDisplay.curOption = optionDisplay.options.indexOf(optionDisplay.getValue());
					}
					updateTextFrom(optionDisplay);
				}

				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckbox();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			
		}
		else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {

		}

		if (sender == numberStepper) {
			if (id == FlxUINumericStepper.CHANGE_EVENT) {
				optionDisplay.setValue(numberStepper.value);
				updateTextFrom(optionDisplay);
			}
			else if (id == FlxUINumericStepper.EDIT_EVENT) {
				trace('lololol');
			}
		}
	}

	function updateTextFrom(option:Option) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if(holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}
	
	function refreshOption()
	{
		descText.text = optionDisplay.description;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

    function reloadOption()
    {
		switch(optionDisplay.type) {
			case 'bool':
				optionText.startPosition.x = 290;
				defaultValue.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(['true', 'false'], false));
			case 'string':
				optionText.startPosition.x = 210;
				defaultValue.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(['option1', 'option2', 'option3'], false));
			case 'int' | 'percent' | 'float':
				numberStepper.value = 0;
				numberStepper.isPercent = optionDisplay.type == 'percent';

				numberStepper.min = -999;
				numberStepper.max = 999;

				switch(optionDisplay.type) {
					case 'float':
						numberStepper.stepSize = 0.1;
						numberStepper.decimals = 2;
					case 'percent':
						numberStepper.stepSize = 0.1;
						numberStepper.decimals = 2;
						numberStepper.min = 0;
						numberStepper.max = 1;
					default:
						numberStepper.stepSize = 1;
						numberStepper.decimals = 0;
				}
				

			default: optionText.startPosition.x = 210;
		}
    }

	function reloadCheckbox() {
		if (optionDisplay.type == 'bool')
        {
            if (!checkbox.alive || valueText.alpha > 0)
                valueText.alpha = 0;
                checkbox.revive();

            checkbox.daValue = optionDisplay.getValue() == true;
        } else {
            if (checkbox.alive)
                checkbox.kill();
                valueText.alpha = 1;
        }
	}

	private function refreshUI(optionType:String) { // kills all sprites and revives the important ones
		var ignore = UIMap.get('ignore');
		var objectsToAdd = UIMap.get(optionType);
		var group = UI_box.getTabGroup('Settings', 0);

		group.forEachAlive(function(sprite:FlxSprite) {
			if (sprite.alive && (!ignore.contains(sprite) && !objectsToAdd.contains(sprite)))
				sprite.kill();
		});

		for (object in objectsToAdd) {
			if (!object.alive)
				object.revive();
		}
	}
}