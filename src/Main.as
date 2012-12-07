package
{
	//Desktop Browser
	import flash.display.*;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StageOrientationEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.filesystem.*;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.text.*;
	import flash.utils.Timer;
	
	import qnx.dialog.DialogSize;
	import qnx.dialog.PopupList;
	import qnx.display.IowWindow;
	import qnx.events.*;
	import qnx.events.QNXApplicationEvent;
	import qnx.events.WebViewEvent;
	import qnx.media.QNXStageWebView;
	import qnx.system.QNXApplication;
	import qnx.ui.buttons.BackButton;
	import qnx.ui.buttons.Button;
	import qnx.ui.buttons.LabelButton;
	import qnx.ui.core.*;
	import qnx.ui.events.SliderEvent;
	import qnx.ui.listClasses.List;
	import qnx.ui.skins.SkinStates;
	import qnx.ui.slider.Slider;
	import qnx.ui.text.*;
	
	
	[SWF(height="600", width="1024", frameRate="60", backgroundColor="#CCCCCC")]
	
	// A simple container layout example
	
	public class Main extends Sprite
	{
		private var myVersion:String = "1.0.5.206";
		
		//containers
		private var myMain:Container = new Container();
		private var myStatus:Label = new Label();
		private var offY:Number = 35;
		private var mySwv:QNXStageWebView = new QNXStageWebView("myBrowser");
		private var labelFormat:TextFormat = new TextFormat();
		
		private var myMenu:Container = new Container();
		
		// default URL to use
		private var myURL:TextInput = new TextInput();
		
		// page controls
		private var myBack:LabelButton  = new LabelButton();
		private var myGo:LabelButton = new LabelButton();
		private var myNext:LabelButton = new LabelButton();
		
		// formatting
		private var btnDownFormat:TextFormat  = new TextFormat ();
		private var btnUpFormat:TextFormat  = new TextFormat ();
		private var btnSize:uint      = 40;
		
		// set defaults
		private var setAgent:uint = 1; // sets our user agent string
		private var setPrivate:Boolean = true;
		private var defaultURL:String = "http://www.google.com";
		private var changeDefaultFont:Boolean = false;
		private var defaultFont:String = "BBAlpha Sans";
		private var defaultFontSize:uint = 16;
		
		// mode.  0 = browser, 1 = preferences screen
		private var myMode:uint = 1;
		
		// pref buttons and labels
		private var agentLabel:Label = new Label();
		private var agentSlider:Slider = new Slider();
		private var privateLabel:Label = new Label();
		private var privateSlider:Slider = new Slider();
		private var defaultUrlLabel:Label = new Label();
		private var defaultTextInput:TextInput = new TextInput();
		private var okBtn:LabelButton  = new LabelButton();
		private var cancelBtn:LabelButton = new LabelButton();
		private var resetBtn:LabelButton = new LabelButton();
		
		
		private var versionLabel:Label = new Label();
		private var dFontOnLabel:Label = new Label();
		private var dFontOnSlider:Slider = new Slider();
		private var dFontLabel:Label = new Label();
		private var dFontPickerBtn:LabelButton = new LabelButton();		
		
		private var dFontPopUp:PopupList = new PopupList;
		private var dFontSizeLabel:Label = new Label();
		private var dFontSizeSlider:Slider = new Slider;
		
		private var loadTimer:Timer = new Timer(10);
		private var loadTimerMax:uint = 100;
		private var loadTimerCount:uint = 0;
		
		private var loadPercentTimer:Timer = new Timer(10,0);
		
		public function Main()
		{
			addEventListener(Event.ADDED_TO_STAGE,handleAddedToStage);
			initializeUI();
		}
		
		
		private function handleAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE,handleAddedToStage);
			
			// stage is available, we can now listen for events
			stage.addEventListener( Event.RESIZE, onResize );
			
			// force a resize call
			onResize(new Event(Event.RESIZE));
		}
		
		
		private function initializeUI():void
		{
			// set basic stage controls
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// try and load settings
			tryGetSettings();
			
			myMain.flow = ContainerFlow.HORIZONTAL;
			myMain.addChild(myStatus);
			myMain.addChild(myURL);
			myMain.addChild(myGo);
			myMain.addChild(myNext);
			myMain.addChild(myBack);
			
			addChild(myMain);
			
			myMenu.addChild(agentLabel);
			myMenu.addChild(privateLabel);
			myMenu.addChild(defaultUrlLabel);
			myMenu.addChild(agentSlider);
			myMenu.addChild(privateSlider);
			myMenu.addChild(defaultTextInput);
			myMenu.addChild(okBtn);
			myMenu.addChild(cancelBtn);
			myMenu.addChild(resetBtn);
			
			myMenu.addChild(dFontOnLabel);
			myMenu.addChild(dFontOnSlider);
			myMenu.addChild(dFontLabel);
			myMenu.addChild(dFontPickerBtn);
			//myMenu.addChild(dFontPopUp);
			myMenu.addChild(dFontSizeLabel);
			myMenu.addChild(dFontSizeSlider);
			
			myMenu.addChild(versionLabel);

			
			//pop-up manager
			dFontPopUp.addButton("OK");
			dFontPopUp.addButton("Cancel");
			
			// add our event listeners
			stage.addEventListener(StageOrientationEvent.ORIENTATION_CHANGE, onChange);
			mySwv.addEventListener(WebViewEvent.DOCUMENT_LOAD_FINISHED, onLoad);
			mySwv.addEventListener(WebViewEvent.DOCUMENT_LOAD_FAILED, onFail);          
			mySwv.addEventListener(WebViewEvent.DOCUMENT_LOAD_COMMITTED, onStartLoad);
			myURL.addEventListener(KeyboardEvent.KEY_DOWN, keySelect);
			
			// add our event listeners for the menu page
			agentSlider.addEventListener(SliderEvent.MOVE, agentSliderChange);  
			privateSlider.addEventListener(SliderEvent.MOVE, privateSliderChange); 
			dFontPickerBtn.addEventListener(MouseEvent.CLICK, showFontPopup);
			dFontOnSlider.addEventListener(SliderEvent.MOVE, dFontOnSliderChange); 
			dFontSizeSlider.addEventListener(SliderEvent.MOVE, dFontSizeSliderChange);  
			
			// Watch for button presses
			myBack.addEventListener(MouseEvent.CLICK, goBack);
			myNext.addEventListener(MouseEvent.CLICK, goNext);
			myGo.addEventListener(MouseEvent.CLICK, goURL);
			okBtn.addEventListener(MouseEvent.CLICK, okPref);
			cancelBtn.addEventListener(MouseEvent.CLICK, cancelPref);
			resetBtn.addEventListener(MouseEvent.CLICK, resetSettingsBtn);
			dFontPopUp.addEventListener(Event.SELECT, selectFontFromPopUp); 
			
			loadTimer.addEventListener(TimerEvent.TIMER,showLoading);
			loadPercentTimer.addEventListener(TimerEvent.TIMER,showLoadingPercent);
			
			// Watch for swipe
			QNXApplication.qnxApplication.addEventListener(QNXApplicationEvent.SWIPE_DOWN, showAppMenu);
			
			// Site Default
			myURL.text = defaultURL;
			myURL.clearIconMode = 0;
			
			btnUpFormat.font = "BBAlpha Sans";
			btnUpFormat.size = 16;
			btnUpFormat.color = 0x000000;
			btnUpFormat.align = TextFormatAlign.CENTER;
			
			btnDownFormat.font = "BBAlpha Sans";
			btnDownFormat.size = 16;
			btnDownFormat.color = 0xFFFFFF;
			btnDownFormat.align = TextFormatAlign.CENTER;
			
			myBack.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			myBack.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			myBack.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			myBack.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			myBack.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
			
			myGo.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			myGo.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			myGo.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			myGo.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			myGo.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
			
			myNext.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			myNext.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			myNext.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			myNext.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			myNext.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
			
			okBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			okBtn.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			okBtn.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			okBtn.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			okBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
			
			cancelBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			cancelBtn.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			cancelBtn.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			cancelBtn.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			cancelBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
			
			resetBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
			resetBtn.setTextFormatForState(btnUpFormat,SkinStates.UP); 
			resetBtn.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
			resetBtn.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
			resetBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);	
			
			// start in appropriate mode.
			onStart();
			
			//update URL
			checkURL();
			//mySwv.loadURL(myURL.text);
			
		}	
		
		
		public function onStart():void {
			switch (stage.orientation){
				case StageOrientation.DEFAULT :
					portrait();
					break;
				case StageOrientation.ROTATED_RIGHT :
					landscape();
					break;
				case StageOrientation.ROTATED_LEFT :
					landscape();
					break;
				case StageOrientation.UPSIDE_DOWN :
					portrait();
					break;
			}
		}
		
		public function onChange(e:StageOrientationEvent):void {
			switch (e.afterOrientation) {
				case StageOrientation.DEFAULT :
					portrait();
					break;
				case StageOrientation.ROTATED_RIGHT :
					landscape();
					break;
				case StageOrientation.ROTATED_LEFT :
					landscape();
					break;
				case StageOrientation.UPSIDE_DOWN :
					portrait();
					break;
			}
		}
		
		private function portrait():void{
			if (myMode == 1) {
				
				
				//myMain = new Container();
				myMain.margins = Vector.<Number>([0,0,0,0]);
				myMain.width = Capabilities.screenResolutionX;
				myMain.height = Capabilities.screenResolutionY;
				
				//			myBack.label_txt.text = "<";			
				myBack.label = "<";
				myBack.x = 0
				myBack.y = 0;
				myBack.height = btnSize;
				myBack.width = btnSize;
				
				myGo.label = "Go";
				myGo.x = myMain.width - btnSize - btnSize;
				myGo.y = 0;
				myGo.height = btnSize;
				myGo.width = btnSize;
				
				myNext.label = ">";
				myNext.x = myMain.width - btnSize;
				myNext.y = 0;
				myNext.height = btnSize;
				myNext.width = btnSize;
				
				// add input text box
				myURL.setPosition(btnSize, 3);
				myURL.width = myMain.width - btnSize - btnSize - btnSize;
				// set the keyboard type to be url
				myURL.keyboardType = KeyboardType.URL;
				myURL.returnKeyType = ReturnKeyType.GO;
				myURL.clearIconMode = TextInputIconMode.NEVER;
				//this.addChild(myInput);
				
				// create and add UI components to the left container           
				labelFormat.size = 22;			
				myStatus.format = labelFormat;
				myStatus.size=35;
				myStatus.width = myMain.width;
				myStatus.x = 0;
				myStatus.y = myMain.height - offY;
				
				// add to UI			
				trace("Portrait...");
				
				mySwv.stage = myMain.stage;
				mySwv.viewPort = new Rectangle(0,offY+5,myMain.width,myMain.height- (offY*2));
				mySwv.zoomToFitWidthOnLoad = true;
				mySwv.defaultFontSize=defaultFontSize;
				
				loadCSS();
				
				// load any last minute preferences
				mySwv.privateBrowsing = setPrivate;
				
				// emulate browser type
				selectUserAgent()
				
			}
			
			if (myMode == 2) {
				
				// REMOVE ME LATER WHEN FIXED
				dFontOnLabel.visible = false;
				dFontOnSlider.visible = false;
				dFontLabel.visible = false;
				dFontPickerBtn.visible = false;
								
				// raw gray box
				myMenu.width = Capabilities.screenResolutionX;
				myMenu.height = Capabilities.screenResolutionY;
				myMenu.graphics.clear();
				myMenu.graphics.beginFill(0x999999);
				myMenu.graphics.drawRect(0,0,myMenu.width, myMenu.height);
				myMenu.graphics.endFill();
				myMenu.graphics.beginFill(0xCCCCCC);
				myMenu.graphics.drawRoundRect(30,30,myMenu.width-60, myMenu.height-60,15,15);
				//myMenu.graphics.drawRoundRect(30,30,400-60, 550-60,15,15);
				myMenu.graphics.endFill();
				
				agentLabel.x = 50;
				agentLabel.y = 50;
				agentLabel.text = "Set Browser Agent: ";
				agentLabel.autoSize = TextFieldAutoSize.LEFT;
				
				privateLabel.x = 50;
				privateLabel.y = 125;
				privateLabel.text = "Set Private Browsing: ";
				privateLabel.autoSize = TextFieldAutoSize.LEFT;
				
				defaultUrlLabel.x = 50;
				defaultUrlLabel.y = 200;
				defaultUrlLabel.text = "Set Homepage URL";
				defaultUrlLabel.autoSize = TextFieldAutoSize.LEFT;
				
				agentSlider.setPosition(50,85)
				agentSlider.width = 300;
				agentSlider.height = 25;
				agentSlider.minimum = 1;
				agentSlider.maximum = 11;
				agentSlider.value = setAgent;
				showAgent(setAgent);
				
				// privateSlider
				privateSlider.setPosition(50,160);
				privateSlider.width = 300;
				privateSlider.height = 25;
				privateSlider.minimum = 0;
				privateSlider.maximum = 1;
				
				var tmpSlide:uint = new uint;
				if (setPrivate == true)
				{
					tmpSlide = 1
				}
				else
				{
					tmpSlide = 0;
				}
				privateSlider.value = tmpSlide; 
				showPrivacy(tmpSlide);
				// defaultTextInput
				
				defaultTextInput.setPosition(50,235);
				defaultTextInput.width = 500;
				defaultTextInput.text = defaultURL;
				
				dFontOnLabel.x = 50;
				dFontOnLabel.y = 300;
				dFontOnLabel.text = "Change Default Fonts?: ";
				dFontOnLabel.autoSize = TextFieldAutoSize.LEFT;
				
				dFontOnSlider.setPosition(50,335)
				dFontOnSlider.width = 300;
				dFontOnSlider.height = 25;
				dFontOnSlider.minimum = 0;
				dFontOnSlider.maximum = 1;
				if (changeDefaultFont == true) {
					dFontOnSlider.value = 1;
				}
				else
				{
					dFontOnSlider.value = 0;
				}
				showDFontOn(dFontOnSlider.value);
				
				if(dFontOnSlider.value == 1) {
					dFontPickerBtn.enabled = true;
					dFontPickerBtn.label = defaultFont;
					
					var tmpFormat:TextFormat = new TextFormat();
					tmpFormat.font = dFontPickerBtn.label;
					tmpFormat.size = defaultFontSize;
					tmpFormat.color = 0x000000;
					tmpFormat.align = TextFormatAlign.CENTER;
					
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.UP); 
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DOWN);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.SELECTED);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED_SELECTED);			
					
				}
				else
				{
					dFontPickerBtn.enabled = false;
					dFontPickerBtn.label = "(System Default)";
					
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.UP); 
					dFontPickerBtn.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
				}
				
				dFontPickerBtn.x = 50
				dFontPickerBtn.y = 375;
				dFontPickerBtn.height = btnSize;
				dFontPickerBtn.width = 500;
				
				// should be done
				dFontSizeLabel.x = 50;
				dFontSizeLabel.y = 300;
				dFontSizeLabel.text = "Default Font Size: ";
				dFontSizeLabel.autoSize = TextFieldAutoSize.LEFT;
				
				dFontSizeSlider.setPosition(50,335)
				dFontSizeSlider.width = 300;
				dFontSizeSlider.height = 25;
				dFontSizeSlider.minimum = 6;
				dFontSizeSlider.maximum = 48;
				dFontSizeSlider.value = defaultFontSize;				
				showFontSize(dFontSizeSlider.value);
				
				// should be done
				//dFontSizeLabel.x = 50;
				//dFontSizeLabel.y = 425;
				//dFontSizeLabel.text = "Default Font Size: ";
				//dFontSizeLabel.autoSize = TextFieldAutoSize.LEFT;
				
				//dFontSizeSlider.setPosition(50,460)
				//dFontSizeSlider.width = 300;
				//dFontSizeSlider.height = 25;
				//dFontSizeSlider.minimum = 6;
				//dFontSizeSlider.maximum = 48;
				//dFontSizeSlider.value = defaultFontSize;				
				//showFontSize(dFontSizeSlider.value);

				// Show Version
				// Show Version
				versionLabel.text = "Current Version: " + myVersion;				
				versionLabel.x = 50;				
				versionLabel.y = 500;
				versionLabel.width = 300;

				
				// OK, Cancel, Reset
				okBtn.label = "Ok";
				okBtn.x = 50;
				okBtn.y = 525;
				okBtn.height = btnSize;
				okBtn.width = 100;
				
				
				cancelBtn.label = "Cancel";
				cancelBtn.x = 250
				cancelBtn.y = 525;
				cancelBtn.height = btnSize;
				cancelBtn.width = 100;
				
				resetBtn.label = "Reset";
				resetBtn.x = 450
				resetBtn.y = 525;
				resetBtn.height = btnSize;
				resetBtn.width = 100;
				
				//setAgent = fileStream.readUnsignedInt();
				//setPrivate = fileStream.readBoolean();
				//defaultURL = fileStream.readUTF();
				
			}
			
		}
		
		
		private function landscape():void
		{
			
			if (myMode == 1) {
				
				
				//myMain = new Container();
				myMain.margins = Vector.<Number>([0,0,0,0]);
				myMain.width = Capabilities.screenResolutionY;
				myMain.height = Capabilities.screenResolutionX;
				
				//			myBack.label_txt.text = "<";			
				myBack.label = "<";
				myBack.x = 0
				myBack.y = 0;
				myBack.height = btnSize;
				myBack.width = btnSize;
				
				myGo.label = "Go";
				myGo.x = myMain.width - btnSize - btnSize;
				myGo.y = 0;
				myGo.height = btnSize;
				myGo.width = btnSize;
				
				myNext.label = ">";
				myNext.x = myMain.width - btnSize;
				myNext.y = 0;
				myNext.height = btnSize;
				myNext.width = btnSize;
				
				// add input text box
				myURL.setPosition(btnSize, 3);
				myURL.width = myMain.width - btnSize - btnSize - btnSize;
				// set the keyboard type to be url
				myURL.keyboardType = KeyboardType.URL;
				myURL.returnKeyType = ReturnKeyType.GO;
				myURL.clearIconMode = TextInputIconMode.NEVER;
				//this.addChild(myInput);
				
				// create and add UI components to the left container           
				labelFormat.size = 22;			
				myStatus.format = labelFormat;
				myStatus.size=35;
				myStatus.width = myMain.width;
				myStatus.x = 0;
				myStatus.y = myMain.height - offY;
				
				// add to UI			
				trace("Landscape...");
				
				mySwv.stage = myMain.stage;
				mySwv.viewPort = new Rectangle(0,offY+5,myMain.width,myMain.height- (offY*2));
				mySwv.zoomToFitWidthOnLoad = true;
				mySwv.defaultFontSize=defaultFontSize;
				
				loadCSS();
				
				// load any last minute preferences
				mySwv.privateBrowsing = setPrivate;
				
				// emulate browser type
				selectUserAgent()
				
			}
			
			if (myMode == 2) {
				
				// REMOVE ME LATER WHEN FIXED
				dFontOnLabel.visible = false;
				dFontOnSlider.visible = false;
				dFontLabel.visible = false;
				dFontPickerBtn.visible = false;
				
				
				// raw gray box
				myMenu.width = Capabilities.screenResolutionY;
				myMenu.height = Capabilities.screenResolutionX;
				myMenu.graphics.clear();
				myMenu.graphics.beginFill(0x999999);
				myMenu.graphics.drawRect(0,0,myMenu.width, myMenu.height);
				myMenu.graphics.endFill();
				myMenu.graphics.beginFill(0xCCCCCC);
				myMenu.graphics.drawRoundRect(30,30,myMenu.width-60, myMenu.height-60,15,15);
				//myMenu.graphics.drawRoundRect(30,30,400-60, 550-60,15,15);
				myMenu.graphics.endFill();
				
				agentLabel.x = 50;
				agentLabel.y = 50;
				agentLabel.text = "Set Browser Agent: ";
				agentLabel.autoSize = TextFieldAutoSize.LEFT;
				
				privateLabel.x = 50;
				privateLabel.y = 125;
				privateLabel.text = "Set Private Browsing: ";
				privateLabel.autoSize = TextFieldAutoSize.LEFT;
				
				defaultUrlLabel.x = 50;
				defaultUrlLabel.y = 200;
				defaultUrlLabel.text = "Set Homepage URL";
				defaultUrlLabel.autoSize = TextFieldAutoSize.LEFT;
				
				agentSlider.setPosition(50,85)
				agentSlider.width = 300;
				agentSlider.height = 25;
				agentSlider.minimum = 1;
				agentSlider.maximum = 11;
				agentSlider.value = setAgent;
				showAgent(setAgent);
				
				// privateSlider
				privateSlider.setPosition(50,160);
				privateSlider.width = 300;
				privateSlider.height = 25;
				privateSlider.minimum = 0;
				privateSlider.maximum = 1;
				
				var tmpSlide:uint = new uint;
				if (setPrivate == true)
				{
					tmpSlide = 1
				}
				else
				{
					tmpSlide = 0;
				}
				privateSlider.value = tmpSlide; 
				showPrivacy(tmpSlide);
				// defaultTextInput
				
				defaultTextInput.setPosition(50,235);
				defaultTextInput.width = 500;
				defaultTextInput.text = defaultURL;
				
				dFontOnLabel.x = 50;
				dFontOnLabel.y = 300;
				dFontOnLabel.text = "Change Default Fonts?: ";
				dFontOnLabel.autoSize = TextFieldAutoSize.LEFT;
				
				dFontOnSlider.setPosition(50,335)
				dFontOnSlider.width = 300;
				dFontOnSlider.height = 25;
				dFontOnSlider.minimum = 0;
				dFontOnSlider.maximum = 1;
				if (changeDefaultFont == true) {
					dFontOnSlider.value = 1;
				}
				else
				{
					dFontOnSlider.value = 0;
				}
				showDFontOn(dFontOnSlider.value);
				
				if(dFontOnSlider.value == 1) {
					dFontPickerBtn.enabled = true;
					dFontPickerBtn.label = defaultFont;
					
					var tmpFormat:TextFormat = new TextFormat();
					tmpFormat.font = dFontPickerBtn.label;
					tmpFormat.size = defaultFontSize;
					tmpFormat.color = 0x000000;
					tmpFormat.align = TextFormatAlign.CENTER;
					
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.UP); 
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DOWN);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.SELECTED);
					dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED_SELECTED);			
					
				}
				else
				{
					dFontPickerBtn.enabled = false;
					dFontPickerBtn.label = "(System Default)";
					
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.UP); 
					dFontPickerBtn.setTextFormatForState(btnDownFormat,SkinStates.DOWN);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.SELECTED);
					dFontPickerBtn.setTextFormatForState(btnUpFormat,SkinStates.DISABLED_SELECTED);			
				}
				
				dFontPickerBtn.x = 50
				dFontPickerBtn.y = 375;
				dFontPickerBtn.height = btnSize;
				dFontPickerBtn.width = 500;
				
				// should be done
				dFontSizeLabel.x = 50;
				dFontSizeLabel.y = 300;
				dFontSizeLabel.text = "Default Font Size: ";
				dFontSizeLabel.autoSize = TextFieldAutoSize.LEFT;
				
				dFontSizeSlider.setPosition(50,335)
				dFontSizeSlider.width = 300;
				dFontSizeSlider.height = 25;
				dFontSizeSlider.minimum = 6;
				dFontSizeSlider.maximum = 48;
				dFontSizeSlider.value = defaultFontSize;				
				showFontSize(dFontSizeSlider.value);

				// Show Version
				versionLabel.text = "Current Version: " + myVersion;				
				versionLabel.x = 50;				
				versionLabel.y = 500;
				versionLabel.width = 300;

				
				// OK, Cancel, Reset
				okBtn.label = "Ok";
				okBtn.x = 50
				okBtn.y = 525;
				okBtn.height = btnSize;
				okBtn.width = 100;
				
				cancelBtn.label = "Cancel";
				cancelBtn.x = 250
				cancelBtn.y = 525;
				cancelBtn.height = btnSize;
				cancelBtn.width = 100;
				
				resetBtn.label = "Reset";
				resetBtn.x = 450
				resetBtn.y = 525;
				resetBtn.height = btnSize;
				resetBtn.width = 100;
				
				//setAgent = fileStream.readUnsignedInt();
				//setPrivate = fileStream.readBoolean();
				//defaultURL = fileStream.readUTF();
				
			}
			
		}
		
		private function selectUserAgent():void
		{
			switch (setAgent) {
				case 1 :
					// Firefox 5
					mySwv.userAgent = "Mozilla/5.0 (X11; Linux i686 on x86_64; rv:5.0a2) Gecko/20110524 Firefox/5.0a2"
					break;	
				case 2 :
					// Internet Explorer 7 
					mySwv.userAgent = "Mozilla /4.0 (compatible;MSIE 7.0;Windows NT6.0)"
					break;	
				case 3 :
					// Chrome 15
					mySwv.userAgent = "Chrome/15.0.860.0 (Windows; U; Windows NT 6.0; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/15.0.860.0"
					break;	
				case 4 :
					// Safari 5
					mySwv.userAgent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
					break;					
				case 5 :
					// Blackberry 9800
					mySwv.userAgent = "Mozilla/5.0 (BlackBerry; U; BlackBerry 9850; en-US) AppleWebKit/534.11+ (KHTML, like Gecko) Version/7.0.0.115 Mobile Safari/534.11+"
					break;		
				case 6 :
					// Android 2.3
					mySwv.userAgent = "Mozilla/5.0 (Linux; U; Android 2.3; en-us) AppleWebKit/999+ (KHTML, like Gecko) Safari/999.9"
					break;		
				case 7 :
					// iPad 2
					mySwv.userAgent = "Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.0.2 Mobile/9A5248d Safari/6533.18.5"
					break;		
				case 8 :
					// PlayBook
					mySwv.userAgent = "Mozilla/5.0 (PlayBook; U; RIM Tablet OS 1.0.0; en-US) AppleWebKit/534.8+ (KHTML, like Gecko) Version/0.0.1 Safari/534.8+"
					break;		
				case 9 :
					// Netscape 9.1
					mySwv.userAgent = "Mozilla/5.0 (Windows; U; Win 9x 4.90; SG; rv:1.9.2.4) Gecko/20101104 Netscape/9.1.0285"
					break;		
				case 10 :
					// Opera 12
					mySwv.userAgent = "Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00"
					break;		
				case 11 :
					// Konqueror 4.5
					mySwv.userAgent = "Mozilla/5.0 (compatible; Konqueror/4.5; FreeBSD) KHTML/4.5.4 (like Gecko)"
					break;		
			}
			
		}
		
		
		private function onResize(event:Event):void
		{
			trace("Screen was rotated.................");
			// we are ignoring these events, because we dont want to trust the auto-resize
			myStatus.text = "Screen rotated.";
			
			//Shows status and counts down
			loadTimerCount = 0;  
			showLoading(null);
			loadTimer.start();	
		
		}
		
		public function onStartLoad(event:Event):void
		{
			trace("Loading URL swv location" + mySwv.location);
			myStatus.text = "Loading... " + mySwv.location;			
			//myURL.text = mySwv.location;

			//Shows status bar and freezes it
			loadTimerCount = 0;  
			showLoading(null);
			loadTimer.stop();
			loadPercentTimer.start();

			trace("onStartLoad | myURL: " + myURL.text + ", mySWV: " + mySwv.location);

		}
		
		public function onLoad(event:Event):void
		{
			trace("Loaded.");		
			loadPercentTimer.stop();

			myStatus.text = "Loaded.";		
			
			var uDURL:Boolean = true;
			
			if (mySwv.location.length == 6) { if (mySwv.location=="http:/") { uDURL=false; } } 
			if (mySwv.location.length == 11) { if (mySwv.location=="about:blank") { uDURL=false; } } 				
			if(uDURL==true) { 
				myURL.text = mySwv.location; 
			}
			
			loadCSS();

			//Shows status and counts down
			loadTimerCount = 0;  
			showLoading(null);
			loadTimer.start();	

			trace("onLoad | myURL: " + myURL.text + ", mySWV: " + mySwv.location);			

		}
		
		public function onFail(event:Event):void
		{
			trace("Failed.");
			
			var tString:String = myURL.text;			
			
			mySwv.loadURL("about:blank");
			mySwv.stop();
			mySwv.loadString("<h1>404: This website will not load.</h1> <p>Please ensure you have steady internet access, are tethered to a device, or have BlackBerry Bridge connected between your Tablet and your Phone.  <br /><br />Additionally you can try reloading the website by clicking GO and double checking that your URL above starts with HTTP://.<br />");
			myStatus.text = "Page Load Failed.";			

			// Shows loader and 'freezes' on screen
			loadTimerCount = 0;  
			showLoading(null);
			loadTimer.stop();	
			
			//inherits the bad URL we typed in
			myURL.text = mySwv.location;
			trace("onFail | myURL: " + myURL.text + ", mySWV: " + mySwv.location);			

		}
		
		
		public function keySelect(event:KeyboardEvent):void
		{
			//trace("Key pressed: " + event.keyCode );
			
			switch (event.keyCode) {
				case 13 :
					// Go was pressed
					trace("URL Changed to: " + myURL.text + " event:" + event);
					myStatus.text = "Loading...";
					//mySwv.loadURL(myURL.text);		
					//loadPercentTimer.start();
					stage.focus = null;
					trace("keySelect | myURL: " + myURL.text + ", mySWV: " + mySwv.location);

					checkURL();					
			}
		}
		
		public function goBack(event:Event):void
		{
			trace("Go back");
			mySwv.historyBack();
		}
		
		public function goNext(event:Event):void
		{
			trace("Go back");
			mySwv.historyForward();
		}
		
		public function goURL(event:Event):void
		{
			trace("URL Changed to: " + myURL.text + " event:" + event);
			myStatus.text = "Loading...";

			trace("goURL | myURL: " + myURL.text + ", mySWV: " + mySwv.location);
			

			checkURL();
						
		}
		
		public function tryGetSettings():void
		{
			var prefsFile:File = File.applicationStorageDirectory; 
			prefsFile = prefsFile.resolvePath("preferences.xml"); 
			
			if (prefsFile.exists == true) {
				// file exists
				trace("Preferences file found... loading defaults");
				loadSettings();
			}
			else
			{
				// file doesn't exist - save settings to create file
				trace("Preferences file wasnt found... creating defaults");
				saveSettings();
			}			
		}
		
		public function saveSettings():void
		{
			var prefsFile:File = File.applicationStorageDirectory; 
			prefsFile = prefsFile.resolvePath("preferences.xml"); 
			trace("Saving prefs file... " + prefsFile);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(prefsFile, FileMode.WRITE);
			fileStream.writeUnsignedInt(setAgent);
			fileStream.writeBoolean(setPrivate);
			fileStream.writeUTF(defaultURL);
			fileStream.writeBoolean(changeDefaultFont);
			fileStream.writeUTF(defaultFont);
			fileStream.writeUnsignedInt(defaultFontSize);
			fileStream.addEventListener(Event.CLOSE, fileClosed);
			fileStream.close();
			
			function fileClosed(event:Event):void {
				trace("closed");
			}            
			
			// save UserMode
			// save Private Mode
			// save default URL
			
		}
		
		public function loadSettings():void
		{
			var prefsFile:File = File.applicationStorageDirectory; 
			prefsFile = prefsFile.resolvePath("preferences.xml"); 
			trace("Loading prefs file... " + prefsFile);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(prefsFile, FileMode.READ);
			setAgent = fileStream.readUnsignedInt();
			setPrivate = fileStream.readBoolean();
			defaultURL = fileStream.readUTF();
			changeDefaultFont = fileStream.readBoolean();
			defaultFont = fileStream.readUTF();
			defaultFontSize = fileStream.readUnsignedInt();
			fileStream.addEventListener(Event.CLOSE, fileClosed);
			fileStream.close();
			trace("Loaded:  Agent " + setAgent + " | Private " + setPrivate + " | defaultURL " + defaultURL + " | ChangeDefaultFont " + changeDefaultFont + " | defaultFont " + defaultFont + " | defaultFontSize " + defaultFontSize);
			
			function fileClosed(event:Event):void {
				trace("closed");
			}            
		}
		
		
		public function resetSettingsBtn(event:Event):void
		{
			resetSettings();
		}
		
		public function resetSettings():void
		{
			
			setAgent = 1; // sets our user agent string
			setPrivate = true;
			defaultURL = "http://www.google.com";
			changeDefaultFont = false;
			defaultFont = "BBAlpha Sans";
			defaultFontSize = 16;
			
			var prefsFile:File = File.applicationStorageDirectory; 
			prefsFile = prefsFile.resolvePath("preferences.xml"); 
			trace("Deleting prefs file... " + prefsFile);
			
			trace("File exists? " + prefsFile.exists); // true
			if (prefsFile.exists==true) {
				prefsFile.deleteFile();
			}
			trace("File exists? " + prefsFile.exists); // true		
			
			if (myMode==2) {		
				
				myMode = 1;	
				trace("Cancelled from preferences, returning.");
				removeChild(myMenu);
				addChild(myMain);
				mySwv.visible = true;
			}
			
			onStart();
			
			
		}
		
		public function showAppMenu(event:QNXApplicationEvent):void
		{
			// decide on menu reaction
			
			if (myMode==2) {
				myMode = 1;
				trace("Sub menu called.  Already visible.  Hiding.");
				removeChild(myMenu);
				addChild(myMain);
				mySwv.visible = true;
				
				loadTimerCount = 0;  
				loadTimer.start();	
				
			}
			else
			{
				myMode = 2;	
				trace("Sub menu called.  Showing.");
				removeChild(myMain);
				addChild(myMenu);
				mySwv.visible = false;
			}
			
			onStart();
		}
		
		public function agentSliderChange(event:SliderEvent):void
		{
			agentSlider.value = Math.round( agentSlider.value );
			showAgent(agentSlider.value);
			trace( "agentSlider value ="+ agentSlider.value + " - " + showAgent(agentSlider.value));	
		}	
		
		public function privateSliderChange(event:SliderEvent):void
		{
			privateSlider.value = Math.round( privateSlider.value );
			showPrivacy(privateSlider.value);
			
			trace( "privateSlider value ="+ privateSlider.value + " - 0=Off, 1=On");	
		}
		
		
		public function showAgent(fromMenu:uint):void
		{
			switch (fromMenu) {
				case 1 :
					// Firefox 5
					agentLabel.text = "Set Browser Agent: FireFox [5] (default)";
					break;	
				case 2 :
					// Internet Explorer 7 
					agentLabel.text = "Set Browser Agent: Internet Explorer [7]";
					break;	
				case 3 :
					// Chrome 15
					agentLabel.text = "Set Browser Agent: Chrome [15]";
					break;	
				case 4 :
					// Safari 5
					agentLabel.text = "Set Browser Agent: Safari [5]";
					break;					
				case 5 :
					// Blackberry 9800
					agentLabel.text = "Set Browser Agent: BlackBerry [9800]";
					break;		
				case 6 :
					// Android 2.3
					agentLabel.text = "Set Browser Agent: Android [2.3]";
					break;		
				case 7 :
					// iPad 2
					agentLabel.text = "Set Browser Agent: iPad 2 [5.0.2]";
					break;		
				case 8 :
					// PlayBook
					agentLabel.text = "Set Browser Agent: PlayBook [1.0]";
					break;		
				case 9 :
					// Netscape
					agentLabel.text = "Set Browser Agent: Netscape [9.1]";
					break;		
				case 10 :
					// Opera
					agentLabel.text = "Set Browser Agent: Opera [12]";
					break;		
				case 11 :
					// Konqueror
					agentLabel.text = "Set Browser Agent: Konqueror [4.5]";
					break;		
			}
			
		}
		
		public function showPrivacy(fromMenu:uint):void
		{
			switch (fromMenu) {
				case 0 :
					// Firefox 5
					privateLabel.text = "Set Private Browsing: Off";
					break;	
				case 1 :
					// Internet Explorer 7 
					privateLabel.text = "Set Private Browsing: On (default)";
					break;	
			}
			
		}
		
		public function okPref(event:Event):void
		{
			if (myMode==2) {
				
				setAgent = agentSlider.value;
				
				if (privateSlider.value ==1)
				{
					setPrivate = true;
				}
				else
				{
					setPrivate = false;
				}
				defaultURL = defaultTextInput.text;
				defaultFontSize = dFontSizeSlider.value;
				
				if (dFontOnSlider.value == 1) {
					changeDefaultFont = true;
					defaultFont = dFontPickerBtn.label;
				}
				else
				{
					changeDefaultFont = false;
				}
				
				saveSettings()
				
				myMode = 1;	
				trace("OK from preferences, saving, setting and returning.");
				removeChild(myMenu);
				addChild(myMain);
				mySwv.visible = true;
				loadCSS();
				
				loadTimerCount = 0;  
				loadTimer.start();	
				
			}
			
			onStart();
		}
		
		
		public function cancelPref(event:Event):void
		{
			if (myMode==2) {		
				
				myMode = 1;	
				trace("Cancelled from preferences, returning.");
				removeChild(myMenu);
				addChild(myMain);
				mySwv.visible = true;
				
				loadTimerCount = 0;  
				loadTimer.start();	
			}
			
			onStart();
		}
		
		public function createCSS():void
		{
			var prefsFile:File = File.applicationStorageDirectory; 
			prefsFile = prefsFile.resolvePath("custom.css"); 
			trace("Creating CSS... " + prefsFile);
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(prefsFile, FileMode.WRITE);
			fileStream.writeMultiByte("content, p, h1, h2, h3, h4, body {\n","iso-8859-1");
			fileStream.writeMultiByte("	font-family:" + defaultFont + ";\n","iso-8859-1");
			fileStream.writeMultiByte("}","iso-8859-1");
			fileStream.close();
			
			function fileClosed(event:Event):void {
				trace("closed");
			}            
			
			// prefsFile.openWithDefaultApplication();
		}
		
		public function showFontSize(fromMenu:uint):void
		{
			dFontSizeLabel.text = "Default Font Size: " + fromMenu;
		}
		
		public function dFontSizeSliderChange(event:SliderEvent):void
		{
			dFontSizeSlider.value = Math.round( dFontSizeSlider.value );
			showFontSize(dFontSizeSlider.value);
			trace( "dFontSizeSlider value ="+ dFontSizeSlider.value);		
		}
		
		
		public function showDFontOn(fromMenu:uint):void
		{
			
			if (dFontOnSlider.value == 1) {
				//changeDefaultFont = true;
				dFontOnLabel.text = "Change Default Fonts?: On";			
				dFontPickerBtn.enabled = true;
				dFontPickerBtn.label = defaultFont;
				
			}
			else
			{
				dFontOnLabel.text = "Change Default Fonts?: Off";
				//dFontOnSlider.value = 0;
				dFontPickerBtn.enabled = false;
				dFontPickerBtn.label = "(System Default)";
			}
		}
		
		public function dFontOnSliderChange(event:SliderEvent):void
		{
			dFontOnSlider.value = Math.round( dFontOnSlider.value );
			showDFontOn(dFontOnSlider.value);
			
			trace( "privateSlider value ="+ privateSlider.value + " - 0=Off, 1=On");	
		}
		
		private function showFontPopup(event:Event):void
		{
			var fonts:Array = Font.enumerateFonts(true);
			var font:Font;
			var fontNames:Array = [];
			
			trace ("Number of fonts: " + fonts.length)
			
			//Print out fonts
			//fonts.forEach(function(item, arr, index) {trace(item.fontName); } );
			
			for(var x:uint=0; x<fonts.length;x++){	
				font = fonts[x];
				fontNames[x]=font.fontName;			
			}
			
			//var popUp:PopupList = new PopupList();
			dFontPopUp.title = "Select Font";
			dFontPopUp.items = fontNames;
			dFontPopUp.dialogSize= DialogSize.SIZE_MEDIUM;
			dFontPopUp.show(IowWindow.getAirWindow().group);    
			dFontPopUp.selectedIndices
		} 
		
		private function selectFontFromPopUp(event:Event):void
		{
			var fonts:Array = Font.enumerateFonts(true);
			var font:Font;
			
			font = fonts[dFontPopUp.selectedIndices]
						
			if (dFontPopUp.selectedIndex==0) {
				// update our GUI name for Font
				dFontPickerBtn.label=font.fontName;
				
				var tmpFormat:TextFormat = new TextFormat();
				tmpFormat.font = dFontPickerBtn.label;
				tmpFormat.size = dFontSizeSlider.value;
				tmpFormat.color = 0x000000;
				tmpFormat.align = TextFormatAlign.CENTER;
				
				dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED);
				dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.UP); 
				dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DOWN);
				dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.SELECTED);
				dFontPickerBtn.setTextFormatForState(tmpFormat,SkinStates.DISABLED_SELECTED);			
				
			}
			
		}
		
		private function loadCSS():void {
			trace("Call to load CSS File");
			
			if (changeDefaultFont==true) {
				createCSS()
				var prefsFile:File = File.applicationStorageDirectory; 
				prefsFile = prefsFile.resolvePath("custom.css");
				trace("Loading CSS File!  prefsFile.url: " + prefsFile.url);
				trace("prefsFile.nativePath: " + prefsFile.nativePath);
				mySwv.userStyleSheet = "data://"+prefsFile.url;
				
				// lets try this...
				// mySwv.userStyleSheet="www.filearchivehaven.com/css/courier.css";
				
				// Unencrypted			content%2C+p%2C+h1%2C+h2%2C+h3%2C+h4%2C+body+%7B%0A%09font-family%3ACourier+New%3B%0A%7D
				// Base64                 Y29udGVudCwgcCwgaDEsIGgyLCBoMywgaDQsIGJvZHkgewoJZm9udC1mYW1pbHk6Q291cmllciBOZXc7Cgp9
				// HEX				636f6e74656e742c20702c2068312c2068322c2068332c2068342c20626f6479207b0a09666f6e742d66616d696c793a436f7572696572204e65773b0a7d
				trace("Style sheet status: " + mySwv.userStyleSheet);
			}
			else
			{
				mySwv.userStyleSheet = "";
			}
			
		}
		
		private function showLoadingPercent(event:Event):void {

			myStatus.text = "Loading: [" + mySwv.loadProgress + " / 100] URL: " + mySwv.location;
		}
		
		private function showLoading(event:Event):void
		{
			//hide
			if (loadTimerCount>loadTimerMax){
				
				// reset our load timer!
				loadTimerCount=0;
				loadTimer.stop();	
				mySwv.viewPort = new Rectangle(0,offY+5,myMain.width,myMain.height-offY-5);
				myStatus.y = myMain.height+1;
				
			}
			else
			{
				// reduce our counter
				loadTimerCount = loadTimerCount + 1;
		
				// if our counter is smaller than offY, time to hide
				if (loadTimerCount > (loadTimerMax-offY)) {
					// trace("myStatus adjusted to: "+ (myMain.height-((loadTimerCount-loadTimerMax)*-1)));
					myStatus.y = myMain.height-((loadTimerCount-loadTimerMax)*-1); 
					
					// trace("View adjusted to: " +(offY+5+myStatus.y-offY-5-1))
					mySwv.viewPort = new Rectangle(0,offY+5,myMain.width,myStatus.y-offY-5-1);
				}
				else
				{
					// show normal
					mySwv.viewPort = new Rectangle(0,offY+5,myMain.width,myMain.height-offY-offY-5);
					myStatus.y = myMain.height-offY;
				}
				
			}
		}
		
		private function checkURL():void
		{
			var validURL:Boolean = false;
			var sLen:uint = myURL.text.length;
			var tString:String = "";
			var tLongString:String = myURL.text;

			
			if (validURL==false) { 
				if (myURL.text.indexOf("://") > 1) {
				} else {
					// should auto-populate http when needed.
					myStatus.text = "Missing ://, added HTTP.  Revalidating URL.";
					myURL.text = "http://" + myURL.text;				
					//					webView.loadURL("http://" + addressInput.text);
				}
			}

			//Verify length
			if (validURL==false && sLen>7  && myURL.text.substr(0,7)  == "http://") 	  { validURL = true; }
			if (validURL==false && sLen>8  && myURL.text.substr(0,8)  == "https://") 	  { validURL = true; }
			if (validURL==false && sLen>7  && myURL.text.substr(0,7)  == "file://") 	  { validURL = true; }
			if (validURL==false && sLen>7  && myURL.text.substr(0,7)  == "data://") 	  { validURL = true; }
			if (validURL==false && sLen>13 && myURL.text.substr(0,13) == "javascript://") { validURL = true; }
			// Check length			
			if (validURL==false) {
				mySwv.loadString("<h1>Invalid URL.</h1> <p>Please double check your URL.  Does it start with <em>http://</em>?<br />");
				mySwv.stop();
				myStatus.text = "Invalid URL.";			

				// Shows loader and 'freezes' on screen
				loadTimerCount = 0;  
				showLoading(null);
				loadTimer.stop();
				trace("Check URL myURL: " + myURL.text + ", mySWV: " + mySwv.location);
				myURL.text = tLongString;
				
			}
			else
			{
				
				mySwv.loadURL(myURL.text);
				//Shows status bar and freezes it
				loadTimerCount = 0;  
				showLoading(null);
				loadTimer.stop();
				loadPercentTimer.start();
				trace("Check URL myURL: " + myURL.text + ", mySWV: " + mySwv.location);
				//myURL.text = mySwv.location;
				
				var uDURL:Boolean = true;
				
				if (mySwv.location.length == 6) { if (mySwv.location=="http:/") { uDURL=false; } } 
			    if (mySwv.location.length == 11) { if (mySwv.location=="about:blank") { uDURL=false; } } 				
				if(uDURL==true) { 
					myURL.text = mySwv.location; 
				}

			}
		}
	}
}


