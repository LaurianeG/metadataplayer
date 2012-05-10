﻿package bab.player{		import fl.video.MetadataEvent;	import fl.video.SoundEvent;	import fl.video.VideoEvent;	import fl.video.VideoScaleMode;	import fl.video.VideoState;		import flash.display.Graphics;	import flash.display.Loader;	import flash.display.MovieClip;	import flash.display.Sprite;	import flash.events.Event;	import flash.events.IOErrorEvent;	import flash.events.MouseEvent;	import flash.events.TimerEvent;	import flash.net.URLRequest;	import flash.text.StyleSheet;	import flash.text.TextField;	import flash.text.TextFormat;	import flash.text.TextFormatAlign;	import flash.utils.Timer;		import fl.controls.ProgressBar;		import bab.player.events.EditEvent;		public class FlvPlayer extends Sprite	{		private var wMin:Number = 550;		private var hMin:Number = 400;		public var flvPB:FLVPlaybackLDT;		private var widthFlv:uint;		private var heightFlv:uint;		private var uic:Sprite;		private var loading:TextField;		private var tcLabel:TextField;		private var metas:Array = new Array();		private var curRatio:Number;		private var savePlay:Boolean = false;						public var editSkin:EditSkin;		//private var babAr:Array;		private var curInst:int = -1;		private var babRunning:Boolean = false;		private var babRunningTimer:Timer;		public var babSkin:MovieClip;		private var babRatio:Number = 1.25;		private var editList:Array;		private var mediaList:Array;		private var instanceToPlay:uint = 0;				private var imageLayer:MovieClip;		private var pictAr:Array;		private var nbPictLoaded:uint;		private var mcContainer:Sprite;		private var bgMcCtn:Sprite;		private var textLayer:TextField;		private var styles:StyleSheet;		private var tf:TextFormat;		private var pb:ProgressBar;				private var caption:FLVPlaybackCaptioningLDT;				private var fullScreenOn:Boolean = false;				public var writeTC:Boolean = true;				private var YTPlayer:ExternalPlayer;				private var currentTcBab:Number;		private var debugText:TextField;				public function FlvPlayer(wInit:Number=550, hInit:Number=400, urlSkin:String="", debug:TextField=null)		{			super();						wMin = wInit;			hMin = hInit;			debugText = debug;						// Container for text layer, image layer and flvPB			uic = new Sprite();			addChild(uic);						// Background container			mcContainer = new Sprite();			mcContainer.visible = false;			uic.addChild(mcContainer);			bgMcCtn = new Sprite();			bgMcCtn.graphics.beginFill(0x770000);			bgMcCtn.graphics.drawRect(0,0,wMin,hMin);			bgMcCtn.graphics.endFill();			mcContainer.addChild(bgMcCtn);			// Text layer			textLayer = new TextField();			textLayer.width = wMin;			tf = new TextFormat("Verdana",12,0xFFFFFF);			tf.align = TextFormatAlign.CENTER; 			/*styles = new StyleSheet();            var body:Object = new Object();            body.fontFamily = "Verdana";            body.fontSize = 12;            body.color = "#FFFFFF";            body.align = "center";            styles.setStyle("body", body);            textLayer.styleSheet = styles;*/			textLayer.wordWrap = true;			textLayer.visible = false;			mcContainer.addChild(textLayer);						// Flv playback component			flvPB = new FLVPlaybackLDT();			uic.addChild(flvPB);			flvPB.autoPlay = false;			flvPB.fullScreenTakeOver = false;			flvPB.scaleMode = VideoScaleMode.MAINTAIN_ASPECT_RATIO;			//flvPB.skin = urlSkin + "SkinUnderPlaySeekMuteVol.swf"; // urlSkin finishes with a "/"			//flvPB.skinBackgroundColor = 0xCCCCCC;			flvPB.addEventListener(MetadataEvent.METADATA_RECEIVED, onMDReceived);			flvPB.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onPlayheadUpdate);			flvPB.addEventListener(VideoEvent.READY, onReady);			flvPB.addEventListener(VideoEvent.SEEKED, onSeeked);			flvPB.addEventListener(VideoEvent.STATE_CHANGE, onStateChange);						caption = new FLVPlaybackCaptioningLDT();			uic.addChild(caption);						var loader:Loader = new Loader();			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, placeBabSkin);			loader.load(new URLRequest(urlSkin));			uic.addChild(loader);						imageLayer = new MovieClip();			this.addChild(imageLayer);						tcLabel = new TextField();			tcLabel.text = "[00:00:00]";			tcLabel.textColor = 0xFFFFFF;			tcLabel.x = 120;			this.addChild(tcLabel);						loading = new TextField();			loading.text = "Loading...";			loading.textColor = 0x0000FF;			loading.visible = false;			loading.mouseEnabled = false;			//loading.styleSheet.setStyle("horizontalCenter",0);			this.addChild(loading);						pb = new ProgressBar();			pb.visible = false;			addChild(pb);					}                                //        // On creation complete		//		private function placeBabSkin(e:Event):void {			babSkin = e.target.content;			//trace("babSkin 2 = " + babSkin.play_mc + ", " + babSkin.pause_mc + ", " + babSkin.back_mc + ", " + babSkin.forward_mc + ", " + babSkin.volumeBarHandle_mc + ", " + babSkin.volumeBar_mc);			babSkin.y = heightFlv;			babSkin.getChildAt(0).width = widthFlv;			babSkin.visible = false;			editSkin = new EditSkin(this);			editSkin.addEventListener(EditEvent.EDIT_PLAYPAUSE, onEditPlayPause);			editSkin.addEventListener(EditEvent.EDIT_BACK, onEditBack);			editSkin.addEventListener(EditEvent.EDIT_FORWARD, onEditForward);			editSkin.addEventListener(EditEvent.EDIT_SOUNDUPDATE, onEditVolumeUpdate);			// usefull to notice edit skin has been loaded.			dispatchEvent(new Event(EditEvent.EDIT_CHANGEINSTRUCTION));		}								//		// load media function		//		public function loadMedia(path:String, live:Boolean=false, paramPlay:Boolean=false, firstST:String="", extrasAr:Array=null):void{			//trace("loadMedia " + path);			stopBab();			// First, we check if the url to load is a Youtube url			if(path.search("youtube.com")>-1 || path.search("dailymotion.com")>-1){				pause();				// A valid youtube url is like : http://www.youtube.com/watch?v=PgEu923nxSE or http://www.youtube.com/v/PgEu923nxSE				if(YTPlayer==null){					YTPlayer = new ExternalPlayer(uic, path);					YTPlayer.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onPlayheadUpdate);					YTPlayer.addEventListener(VideoEvent.READY, initSizes);				}				else YTPlayer.loadVideo(path);				curRatio = ExternalPlayer.EXTERNALPLAYER_RATIO;				//initSizes();				YTPlayer.visible = true;				flvPB.visible = false;			}			else{				if(YTPlayer!=null) YTPlayer.visible = false;				flvPB.visible = true;				// We check if the media is already loaded				var nbMedias:uint = metas.length;				var vp:Number = getVp(path);				var vol:Number = flvPB.volume;				// We stop the current reading if possible				if(nbMedias>0 && allowFlvPB()) { flvPB.stop(); }				// We load the new content or play the already loaded content				if(isNaN(vp)){					vp = metas.length;					// We activate the good video player index					flvPB.activeVideoPlayerIndex = flvPB.visibleVideoPlayerIndex = vp;					flvPB.smoothing = true;					//trace("je load " + vp + ", " + path);					metas.push({path:path, w:3, h:1, ratio:3});					curRatio = metas[vp].ratio;					savePlay = paramPlay;					if(live==true){						savePlay = true;						flvPB.play(path, NaN, true);					}					else flvPB.load(path); // Then the window will be resized on metadata received					//trace("LoadMedia flvPB.volume : " + flvPB.volume);					// sets the volume to 0 (to avoid a bug) then sets it back to its previous level					flvPB.volume = 0;					flvPB.volume = vol;				}				else{					// We activate the good video player index					flvPB.activeVideoPlayerIndex = flvPB.visibleVideoPlayerIndex = vp;					flvPB.smoothing = true;					//trace("vp = " + flvPB.activeVideoPlayerIndex + ", " + flvPB.isLive);					//trace("je play " + vp + ", " + path);					if(allowFlvPB()){ savePlay==false ? flvPB.pause() : flvPB.play(); }					// sets the volume to 0 (to avoid a bug) then sets it back to its previous level					flvPB.volume = 0;					flvPB.volume = vol;					// We have to resize the window					curRatio = metas[vp].ratio;					initSizes();				}				// If a subtitle path is indicated we display it				var ext:String = firstST.toLowerCase().substr(firstST.length-3);				if(ext=="xml"){					caption.source = firstST;				}				else if(ext=="srt"){					caption.loadSrt(firstST);				}				// We set the caption/subtitles module to the good videoPlayerIndex index				caption.videoPlayerIndex = vp;			}				}		private function getVp(path:String):Number{						// We check if the media is already loaded			var i:uint = 0;			var nbMedias:uint = metas.length;			var vp:Number = NaN;			while(i<nbMedias && isNaN(vp)){				if(metas[i].path==path){					vp = i;				}				i++;			}			return vp;					}				//		// Function allowing to go to the wanted timecode. TC is in milliseconds, paramPlay enable to play or pause the video		//		public function goTo(tc:Number=0, paramPlay:Boolean=true):void{						//trace("goto " + paramPlay + ", flvPB.isLive = " + flvPB.isLive);			if((flvPB.isLive==false && allowFlvPB()) && metas.length>0 && (YTPlayer==null || !YTPlayer.visible)){				// It appears that we have some problems when the video is streamed : 				// if we ask seek while the video is being played, the server plays the video from the beginning,				// so we have to pause it first.				if((metas[flvPB.visibleVideoPlayerIndex].path.substr(0,4).toLowerCase()=="rtmp") && paramPlay){					if(allowFlvPB()) flvPB.pause();				}				if(allowFlvPB()) flvPB.seek(tc/1000);				savePlay = paramPlay;			}			else if(YTPlayer!=null){				if(YTPlayer.visible){					YTPlayer.goTo(tc/1000, paramPlay);				}			}					}				//		// Function enabling to know the flvPB is playing (or pause)		//		public function isPlaying():Boolean{ return flvPB.playing; }				//		// Function enabling to switch play-pause and pause-play		//		public function playPause():void{			//trace(this.name + " playPause " + babRunning + ", flvPB.playing = " + flvPB.playing);			if(babRunning==false){				if(flvPB.playing==true){					if(allowFlvPB()) flvPB.pause();					savePlay = false;				}				else{					if(allowFlvPB()) flvPB.play();					savePlay = true;				}			}			else onEditPlayPause();		}		public function play():void{			if(allowFlvPB()) flvPB.play();			savePlay = true;		}		public function pause():void{			if(allowFlvPB()) flvPB.pause();			savePlay = false;		}		public function stop():void{			if(metas.length>0 && allowFlvPB()){ flvPB.stop(); }			savePlay = false;			if(babRunning==true){				if(babRunningTimer!=null){ if(babRunningTimer.running==true){ babRunningTimer.stop(); } }				babRunning = false;			}		}		 		//		// Manage video events		//		private function onMDReceived(e:MetadataEvent):void{			/*var o:Object;			trace("MD");			for(o in e.info){				trace(o + " : " + e.info[o.toString()]);			}*/            if(e.info["duration"]!=null){                 //(this.parentApplication as LignesDeTempsFlex).debug.text += "\nw = " + e.info["width"] + "\nh = " + e.info["height"] + "\ndur = " + e.info["duration"];            }			var w:uint = Math.max(3, uint(e.info["width"]));			var h:uint = Math.max(1, uint(e.info["height"]));			metas[e.vp].w = w;			metas[e.vp].h = h;			metas[e.vp].ratio = w/h;			if(e.vp==flvPB.activeVideoPlayerIndex){				// If we load the content for a bout à bout (edit), we force the ratio at the bab Ratio				curRatio = (babRunning==true) ? babRatio : metas[e.vp].ratio;				initSizes();			}					}		private function getInfoID3(e:Event):void{			var o:Object;			trace("getInfoID3");			for(o in e){				trace(o + " : " + e[o.toString()]);			}		}		private function onStateChange(e:VideoEvent=null):void {			// If the user is not allowed to read the whole media, we hide the SeekBarHit			//if(Config.readFullLength==false) flvPB.hideSeekBarHit();			// We display an alert message if there is a connection error			dispatchEvent(new VideoEvent(VideoEvent.STATE_CHANGE, false, false, e.state));			if(e.state==VideoState.CONNECTION_ERROR){				//Alert.show("The player can not find the video file :\n" + metas[e.vp].path, "No video file");			}		}		private function allowFlvPB():Boolean{			return (flvPB.state!=VideoState.CONNECTION_ERROR && flvPB.state!=VideoState.DISCONNECTED);		}		private function onReady(e:VideoEvent=null):void {			//trace("onReady savePlay = " + savePlay);			// We have to do that to force pause on load			if(allowFlvPB()){ savePlay==false ? flvPB.pause() : flvPB.play(); }		}		private function onSeeked(e:VideoEvent):void {			//trace(name + " onSeeked savePlay = " + savePlay);			loading.visible = false;			// We have to do that to force pause on load			if(allowFlvPB()){ savePlay==false ? flvPB.pause() : flvPB.play(); }		}		public function onPlayheadUpdate(e:VideoEvent):void {			//trace("onPU " + e.state + ", " + e.playheadTime + ", " + babRunning);//editList[curInst].tOut + ", " +			if(e.state=="seeking"){ loading.visible = true; }			if(babRunning==false && writeTC==true){				tcLabel.text = "[" + convertTC(e.playheadTime*1000, false) + "]";				this.dispatchEvent(e);			}			else if(babRunning==true){				if(e.playheadTime>=editList[curInst].tOut && e.state=="playing"){					playBabInst(curInst+1);				}				//var tcBab:Number;				if(mediaList[editList[curInst].m].type=="v"){					//trace(editList[curInst].eIn + ", " + e.playheadTime + ", " + editList[curInst].tIn + ", diff = " + (editList[curInst].tIn - e.playheadTime));					// If the current playheadTime is inferior to editList[curInst].tIn more than 2 seconds, we reseek to the tIn					if((editList[curInst].tIn - e.playheadTime)>3){						if(allowFlvPB()) flvPB.seek(editList[curInst].tIn);					}					else{						// We apply max : because of the playhead's approximation, e.playheadTime can be inferior to tIn						currentTcBab = Math.max(editList[curInst].eIn*1000,(editList[curInst].eIn + e.playheadTime - editList[curInst].tIn)*1000);						//currentTcBab = tcBab;						tcLabel.text = "[" + convertTC(currentTcBab, false) + "]";						this.dispatchEvent(new EditEvent(EditEvent.EDIT_UPDATETC, currentTcBab));					}				}				else if(mediaList[editList[curInst].m].type=="p" || mediaList[editList[curInst].m].type=="t"){					currentTcBab = (editList[curInst].eIn)*1000;					tcLabel.text = "[" + convertTC(currentTcBab, false) + "]";					this.dispatchEvent(new EditEvent(EditEvent.EDIT_UPDATETC, currentTcBab));				}			}		}				//		// Set the good sizes function of the ratio		//		public function initSizes(e:VideoEvent=null):void{			// We set hMin and wMin for the video to take the maximum of space. wMax = 415, hMax = 310			/*if((Math.round(424/curRatio)+24+37)>310){				hMin = 310;				wMin = (310-24-37)*curRatio;			}			else{				wMin = 415;				hMin = Math.round(wMin/curRatio) + 24 + 37;			}			if(width<wMin) {}			else{				height = Math.round(width/curRatio) + 24 + 37;			}*/		}						//		// Function enabling to take or let control of the timecode label		//		public function set manageEventTimer(b:Boolean):void{			writeTC = b;		}		public function set tcText(s:String):void{			tcLabel.text = s;		}						private function onResize():void{			setSize(wMin, hMin - 37);		}		public function setSize(w:uint, h:uint):void{			//trace("setSize " + w + ", " + h);			if(h<1000){ // avoids resize problems if metadatas were not good				//mcContainer.width = imageLayer.width = widthFlv = w;				//mcContainer.height = imageLayer.height = heightFlv = h;				imageLayer.width = widthFlv = w;				imageLayer.height = heightFlv = h;				loading.y = heightFlv - 16;				tcLabel.y = heightFlv;				//if(metas.length==1 && metas[0]["path"].search("mp3:")>-1){				flvPB.setSize(widthFlv,heightFlv);				flvPB.scaleMode = VideoScaleMode.MAINTAIN_ASPECT_RATIO;				if(babSkin!=null){					babSkin.y = heightFlv - 3;					babSkin.getChildAt(0).width = widthFlv;				}				var nbChilds:uint = imageLayer.numChildren;				for(var i:uint=0;i<nbChilds;i++){					imageLayer.getChildren()[i].width = widthFlv;					imageLayer.getChildren()[i].height = heightFlv;				}				if(YTPlayer!=null) YTPlayer.setSize(widthFlv,heightFlv);			}					}				//		// BOUT A BOUT (EDIT) FUNCTIONS 		//		public function getEditList(editListPar:Array, mediaListPar:Array):void{			//if(Global.flv2==name) trace("flv getEditList " + editListPar.length + ", " + mediaListPar.length);			if(mediaListPar.length>0 && editListPar.length>0){				instanceToPlay = 0;				curInst = -1;				// We don't display the different layers				textLayer.visible = false;				mcContainer.visible = false;				imageLayer.visible = false;				flvPB.visible = false;				// We search for every media				var i:uint;				editList = editListPar;				mediaList = mediaListPar;				var nbMedias:uint = mediaList.length;				var nbLoaded:uint = metas.length;				var canStart:Boolean = true;				var a:Array = new Array();				for(i=0;i<nbMedias;i++){					// We check if the videos are not already loaded					if(mediaList[i].type=="v"){						var found:Boolean = false;						var j:uint = 0;						while(j<nbLoaded && found==false){							if(metas[j].path==mediaList[i].content){ found = true; }							j++;						}						// If the path was not found, we load the media						if(nbLoaded==0 || found==false){							loadMedia(mediaList[i].content);						}					}					// We load every picture before the bout a bout starts					else if(mediaList[i].type=="p"){						canStart = false;						// We add the Global.projPath to the pict url when its path is relative (= "_resources/...")						//a.push( ((mediaList[i].content.substr(0,9)=="_resource") ? Global.projPath : "") + mediaList[i].content);						a.push(mediaList[i].content);					}				}				if(canStart==true) startBab();				else{					// We delete doubloons			        a.sort(Array.CASEINSENSITIVE);			        for(i=0;i<a.length;i++){			            if(a[i]==a[i+1] || a[i]==""){			            	a.splice(i,1);			            	i--; // We do i-- because we spliced an index so we have to redo the test at "i" position			            }			        }			        loadPicts(a);				}							}					}		//		// Image load management		//		private function loadPicts(a:Array):void{						var i:uint;			// We delete the old pictures			pictAr = [];			var nbChilds:uint = imageLayer.getChildren().length;			for(i=0;i<nbChilds;i++){				imageLayer.removeChildAt(0);			}			// We add the new ones			var nbPict:uint = a.length;			nbPictLoaded = 0;			if(nbPict>0){				// We prepare pictAr				for(i=0;i<nbPict;i++){					pictAr.push({src:a[i], img:null});				}				loadPict(a[0]);			}			else startBab();					}		private function loadPict(src:String):void{						var nbPict:uint = pictAr.length;			var i:uint = 0;			var found:Boolean = false;			while(i<nbPict && found==false){				if(pictAr[i].src==src && pictAr[i].img!=null){ found = true; }				i++;			}			if(found==false){				var img:Image = new Image();				img.width = widthFlv;				img.height = widthFlv / babRatio;				//img.setStyle("horizontalAlign","center");				//img.setStyle("verticalAlign","center");				//img.maintainAspectRatio = true;				img.y = 0;				img.addEventListener(Event.INIT, imgComplete);				img.addEventListener(IOErrorEvent.IO_ERROR, imgError);				pb.visible = true;				//pb.label = "Loading picture " + (nbPictLoaded+1) + " %3%%";				pb.source = img;//				trace("load img :\n" + src);//				(this.parentApplication as LignesDeTempsFlex).debug.text += "\nload img :\n" + src;				img.source = src;				img.visible = false;				imageLayer.addChild(img);			}			else{				nbPictLoaded++;				if(nbPictLoaded==nbPict) startBab();			}			//(this.parentApplication as LignesDeTempsFlex).debug.text += "\nload img" + src					}		private function imgError(e:IOErrorEvent):void {			// We don't display the progress bar anymore			pb.visible = false;			// We update pictAr			var img:Image = e.target as Image;			var src:String = img.source as String;//			trace("imgError :\n" + src);//			(this.parentApplication as LignesDeTempsFlex).debug.text += "\nimgError" + src;			loadNextPict(src, img);					}		private function imgComplete(e:Event):void {			// We don't display the progress bar anymore			pb.visible = false;			// We update pictAr			var img:Image = e.target as Image;			var src:String = img.source as String;//			trace("imgComplete :\n" + src);//			(this.parentApplication as LignesDeTempsFlex).debug.text += "\nimgComplete" + src;			loadNextPict(src, img);		}		private function loadNextPict(src:String, img:Image):void{			var nbPict:uint = pictAr.length;			var i:uint = 0;			var found:Boolean = false;			while(i<nbPict && found==false){				if(pictAr[i].src==src){					found = true;					pictAr[i].img = img;				}				i++;			}			nbPictLoaded++;			if(nbPictLoaded==nbPict){				// Because of the time needed when we load picture, BaB can start before all pictures are loaded				// So we curInst we recall set curInst at -1 in order to call startBab at the correct time.				curInst = -1;				startBab();			}			else loadPict(pictAr[nbPictLoaded].src);		}		private function displayPict(src:String):void{						var nbPict:uint = pictAr.length;			for(var i:uint=0;i<nbPict;i++){				if(pictAr[i].src==src && pictAr[i].img!=null){//					trace("img vis : " + pictAr[i].src + " : " + pictAr[i].img);//					(this.parentApplication as LignesDeTempsFlex).debug.text += "\nimg vis : " + pictAr[i].src + " : " + pictAr[i].img;					pictAr[i].img.visible = true;				}				else if(pictAr[i].img!=null){ pictAr[i].img.visible = false; }			}					}		//		// Bab timer management		//		private function completeTimer(e:TimerEvent):void {			//trace("completeTimer");			babRunningTimer.stop();			babRunningTimer.removeEventListener(TimerEvent.TIMER, onRunningTimer);			babRunningTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,completeTimer);			playBabInst(curInst+1);		}		private function onRunningTimer(e:TimerEvent):void {			//trace("onRunningTimer " + babRunningTimer.currentCount + " sur " + babRunningTimer.repeatCount);			currentTcBab = editList[curInst].eOut*1000 - (babRunningTimer.repeatCount-babRunningTimer.currentCount)*250;			tcLabel.text = "[" + convertTC(currentTcBab, false) + "]";			//(this.parentApplication as LignesDeTempsFlex).debug.text += "[" + convertTC(tcBab, false) + "]";			dispatchEvent(new EditEvent(EditEvent.EDIT_UPDATETC, currentTcBab));		}		private function onEditPlayPause(e:EditEvent=null):void{			//trace(this.name + " onEditPlayPause " + mediaList[editList[curInst].m].type);			if(babRunning==true){				var tcBab:Number;				if(mediaList[editList[curInst].m].type=="v"){					//flvPB.playing==true ? (flvPB.pause();trace("je pause");) : (flvPB.play();trace("je play"););					if(flvPB.playing==true){						if(allowFlvPB()) flvPB.pause();						editSkin.isPlaying = false;					}else{						savePlay = true;						if(allowFlvPB()) flvPB.play();						editSkin.isPlaying = true;					}				}				else if(mediaList[editList[curInst].m].type=="p" || mediaList[editList[curInst].m].type=="t"){					if(babRunningTimer!=null){						if(babRunningTimer.running==true){							babRunningTimer.stop();							editSkin.isPlaying = false;							//trace("after stop " + babRunningTimer.currentCount + " sur " + babRunningTimer.repeatCount);						}						else{							var newNb:uint = babRunningTimer.repeatCount - babRunningTimer.currentCount;							babRunningTimer = new Timer(250, newNb);							//trace("je reprends " + babRunningTimer.currentCount + " sur " + newNb);							babRunningTimer.addEventListener(TimerEvent.TIMER, onRunningTimer);							babRunningTimer.addEventListener(TimerEvent.TIMER_COMPLETE, completeTimer);							babRunningTimer.start();							editSkin.isPlaying = true;						}					}				}			}		}		//		// Edit events functions		//		public function onEditBack(e:EditEvent=null):void{			//trace("onEditBack");			playBabInst(curInst-1);		}		public function onEditForward(e:EditEvent=null):void{			//trace("onEditForward");			playBabInst(curInst+1);		}		private function onEditVolumeUpdate(e:EditEvent=null):void{			//trace("onEditVolumeUpdate " + e.volume);			flvPB.volume = e.volume;		}				//		// Edit play functions		//		public function startBab():void{			trace("startBab flvPB = " + flvPB);			try{				flvPB.showHideSkin(false);			}			catch(e:*){ trace("flvPB.showHideSkin error"); }			curRatio = babRatio;			//hMin = Math.round(wMin/babRatio) + 24 + 37;			//height = Math.round(width/babRatio) + 24 + 37;			onResize();			tcLabel.text = "[" + convertTC(0, false) + "]";			if(babSkin) { babSkin.visible = true; }			playBabInst(instanceToPlay, false);			onResize();					}		public function stopBab():void{			//trace("stopBab");			textLayer.visible = false;			mcContainer.visible = false;			imageLayer.visible = false;			babRunning = false;			if(babSkin!=null){ babSkin.visible = false; }			flvPB.visible = true;			flvPB.showHideSkin(true);			if(babRunningTimer!=null){				if(babRunningTimer.running==true){					babRunningTimer.stop();				}			}			curInst = -1;		}				public function playBabInst(i:uint, paramPlay:Boolean=true):void{			//if(Global.flv2==name) trace(name + " playBabInst change je passe a " + i + ", curInst = " + curInst + ", paramPlay = " + paramPlay);			if(editList!=null){if(i<editList.length){				// We update the edit player skin				editSkin.isPlaying = paramPlay;				if(curInst!=i || paramPlay==true){					babRunning = true;					instanceToPlay = curInst = i;					if(babRunningTimer!=null){ if(babRunningTimer.running==true){ babRunningTimer.stop(); } }					if(mediaList[editList[curInst].m].type=="v"){						// Video case						textLayer.visible = false;						mcContainer.visible = true;						drawBgCtn(0x000000); // We draw a black background						imageLayer.visible = false;						savePlay = paramPlay || mediaList[editList[curInst].m].content.substr(0,4).toLowerCase()=="rtmp";						var vp:Number = getVp(mediaList[editList[curInst].m].content);						//if(Global.flv2==name) trace(name + " vp = " + vp);						if(flvPB.activeVideoPlayerIndex!=vp){							if(allowFlvPB()) flvPB.pause();							flvPB.activeVideoPlayerIndex = flvPB.visibleVideoPlayerIndex = vp;							flvPB.smoothing = true;						}						if(allowFlvPB()){							// If the video is NOT streamed and savePlay==true, we play it.							if(savePlay==true && mediaList[editList[curInst].m].content.substr(0,4).toLowerCase()!="rtmp") flvPB.play();							// If the video IS streamed and the player is playing, we have to pause it for the seek to work.							if(!flvPB.paused && mediaList[editList[curInst].m].content.substr(0,4).toLowerCase()=="rtmp") flvPB.pause();							flvPB.seek(editList[curInst].tIn);						}						flvPB.visible = true;						// sets the volume to 0 (to avoid a bug) then sets it back to its previous level						var vol:Number = flvPB.volume;						flvPB.volume = 0;						flvPB.volume = vol;					}					else if(mediaList[editList[curInst].m].type=="p"){						// Picture case						textLayer.visible = false;						mcContainer.visible = true;						drawBgCtn(mediaList[editList[curInst].m].color);						imageLayer.visible = true;						flvPB.visible = false;						if(metas.length>0 && allowFlvPB()){ flvPB.pause(); } 						//displayPict( ((mediaList[editList[curInst].m].content.substr(0,9)=="_resource") ? Global.projPath : "") + mediaList[editList[curInst].m].content);						displayPict(mediaList[editList[curInst].m].content);						imageLayer.y = 0;						babRunningTimer = new Timer(250, editList[i].tOut*4);						//trace("je lance un timer sur " + (babAr[i].tOut*4));						babRunningTimer.addEventListener(TimerEvent.TIMER, onRunningTimer);						babRunningTimer.addEventListener(TimerEvent.TIMER_COMPLETE, completeTimer);						babRunningTimer.start();						if(paramPlay==false){ onEditPlayPause(); }					}					else if(mediaList[editList[curInst].m].type=="t"){						// Text case						textLayer.visible = true;						mcContainer.visible = true;						drawBgCtn(mediaList[editList[curInst].m].color);						imageLayer.visible = false;						flvPB.visible = false;						if(metas.length>0 && allowFlvPB()){ flvPB.pause(); }						textLayer.htmlText = mediaList[editList[curInst].m].content;						// If the color is clear the text will be black, if the color is dark the text will be white.						tf.color = (RGB2L(mediaList[editList[curInst].m].color)>(255*3/2)) ? 0x000000 : 0xFFFFFF;	            		textLayer.setTextFormat(tf);						textLayer.height = Math.floor(textLayer.textHeight) + 10;						textLayer.y = ((hMin-37-37)/2) - (textLayer.textHeight/2);						if(babRunningTimer!=null){							if(babRunningTimer.running==true){								babRunningTimer.stop();							}						}						babRunningTimer = new Timer(250, editList[i].tOut*4);						//trace("je lance un timer sur " + (babAr[i].tOut*4));						babRunningTimer.addEventListener(TimerEvent.TIMER, onRunningTimer);						babRunningTimer.addEventListener(TimerEvent.TIMER_COMPLETE, completeTimer);						babRunningTimer.start();						if(paramPlay==false){ onEditPlayPause(); }					}					//if(Global.flv2==name) trace(name + " playBabInst textLayer = " + textLayer.visible + ", mcContainer = " + mcContainer.visible + ", imageLayer = " + imageLayer.visible + ", flvPB = " + flvPB.visible);					//trace("4* tcBab = " + (editList[curInst].eIn*1000));					currentTcBab = editList[curInst].eIn * 1000;					dispatchEvent(new EditEvent(EditEvent.EDIT_UPDATETC, currentTcBab));					tcLabel.text = "[" + convertTC(currentTcBab, false) + "]";				}				// Else we run the current segment from the beginning				else if(curInst==i){					babRunning = true;					if(babRunningTimer!=null){ if(babRunningTimer.running==true){ babRunningTimer.stop(); } }					//if(Global.flv2==name) trace(name + " 2 type m  = " + mediaList[editList[curInst].m].type);					//trace("m " + mediaList[editList[curInst].m].type + ", c = " + mediaList[editList[curInst].m].content + ", col = " + mediaList[editList[curInst].m].color);					if(mediaList[editList[curInst].m].type=="v"){						savePlay = paramPlay;						//if(Global.flv2==name) trace(name + " 2 vp = " + vp);						if(allowFlvPB()){							// If the video is NOT streamed and savePlay==true, we play it.							if(savePlay==true && mediaList[editList[curInst].m].content.substr(0,4).toLowerCase()!="rtmp") flvPB.play();							// If the video IS streamed and the player is playing, we have to pause it for the seek to work.							if(!flvPB.paused && mediaList[editList[curInst].m].content.substr(0,4).toLowerCase()=="rtmp") flvPB.pause();							flvPB.seek(editList[curInst].tIn);						}					}					else if(mediaList[editList[curInst].m].type=="p"){						babRunningTimer = new Timer(250, editList[i].tOut*4);						//trace("je lance un timer sur " + (editList[i].tOut*4));						babRunningTimer.addEventListener(TimerEvent.TIMER, onRunningTimer);						babRunningTimer.addEventListener(TimerEvent.TIMER_COMPLETE, completeTimer);						babRunningTimer.start();						if(paramPlay==false){ onEditPlayPause(); }					}					else if(mediaList[editList[curInst].m].type=="t"){						if(babRunningTimer!=null){							if(babRunningTimer.running==true){								babRunningTimer.stop();							}						}						babRunningTimer = new Timer(250, editList[i].tOut*4);						//trace("je lance un timer sur " + (babAr[i].tOut*4));						babRunningTimer.addEventListener(TimerEvent.TIMER, onRunningTimer);						babRunningTimer.addEventListener(TimerEvent.TIMER_COMPLETE, completeTimer);						babRunningTimer.start();						if(paramPlay==false){ onEditPlayPause(); }					}					//if(Global.flv2==name) trace(name + " playBabInst 2 textLayer = " + textLayer.visible + ", mcContainer = " + mcContainer.visible + ", imageLayer = " + imageLayer.visible + ", flvPB = " + flvPB.visible);					currentTcBab = editList[curInst].eIn * 1000;					dispatchEvent(new EditEvent(EditEvent.EDIT_UPDATETC, currentTcBab));					tcLabel.text = "[" + convertTC(currentTcBab, false) + "]";				}			}			else{				if(metas.length>0 && allowFlvPB()){ flvPB.pause(); }				babRunning = false;			}}			//if(Global.flv2==name) trace(name + " playBabInst 2 textLayer = " + textLayer.visible + ", mcContainer = " + mcContainer.visible + ", imageLayer = " + imageLayer.visible + ", flvPB = " + flvPB.visible);					}		private function drawBgCtn(col:uint):void{						var g:Graphics = bgMcCtn.graphics;			g.clear();			g.beginFill(col);			g.drawRect(0,0,wMin,hMin-39);			g.endFill();		}		//		// Empties the edit arrays		//		public function empty():void{						editList = [];			mediaList = [];			babRunning = false;			curInst = -1;					}		//		// Get luminance from RGB. Luminance is the sum between the 3 values from 0 to 255 of red, green and blue.		//		private function RGB2L(c:uint):uint{						var r:uint = (c >> 16) & 0xFF;			var g:uint = (c >> 8) & 0xFF;			var b:uint = c & 0xFF;			var l:uint = r + g + b;			return l;					}				public function get volume():Number{ return flvPB.volume;}				private function convertTC(monTC:Number, tenth:Boolean=true) : String {        	        // We do this 2 divisions to keep only 1 number after "."	        monTC = Math.floor(monTC/100);	        monTC = (tenth==true) ? monTC/10 : Math.floor(monTC/10);	        var MaHeu:Number = Math.floor(monTC/3600);	        var MaMin:Number = Math.floor(monTC/60)-(60*MaHeu);	        var MaSec:Number = ((monTC*10)%600) / 10; // We have to do that because there is an incomprehensible probleme with %60	        	        var MonTime:String = ((MaHeu<10)?"0":"") + MaHeu + ":" + ((MaMin<10)?"0":"") + MaMin + ":" + ((MaSec<10)?"0":"") + MaSec;	        return MonTime;	        	    }						//		// External Interface functions		//		public function playVideo(e:*=null):Boolean{			if(metas.length>0 && allowFlvPB()){				flvPB.play();				editSkin.isPlaying = true;			}			debugOutput("playVideo e = " + e);			return true;		}		public function pauseVideo(e:*=null):Boolean{			if(metas.length>0 && allowFlvPB()){				flvPB.pause();				editSkin.isPlaying = false;			}			debugOutput("pauseVideo e = " + e);			return true;		}		public function getCurrentTime(e:*=null):Number{			// We send in seconds			var tc:Number = Math.floor(currentTcBab) / 1000;			debugOutput("getCurrentTime e = " + tc);			return tc;		}		public function seekTo(e:*=null):Boolean{			debugOutput("seekTo e = " + e);			return true;		}		public function isMuted(e:*=null):Boolean{			var b:Boolean = (flvPB.volume==0);			debugOutput("isMuted e = " + b);			return b;		}		public function mute(e:*=null):Boolean{			debugOutput("mute e = " + e);			flvPB.volume = 0;			flvPB.volume = 0;			return true;		}		public function unMute(e:*=null):Boolean{			debugOutput("unMute e = " + e);			flvPB.volume = 0;			flvPB.volume = 1;			return true;		}		public function getVolume(e:*=null):Number{			debugOutput("getVolume e = " + volume);			return volume;		}		public function setVolume(e:*=null):Boolean{			flvPB.volume = 0;			flvPB.volume = e;			debugOutput("setVolume e = " + e);			return true;		}		private function debugOutput(s:String):void{			if(debugText) debugText.text = "bab " + s;		}			}}