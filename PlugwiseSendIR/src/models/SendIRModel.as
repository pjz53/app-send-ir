package models
{
	import flash.data.EncryptedLocalStore;
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.formatters.DateFormatter;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	import mx.utils.UIDUtil;
	
	import spark.components.RadioButtonGroup;
	
	import events.EdgeEvent;
	import events.SettingsEvent;
	
	import vos.Edge;
	import vos.Host;
	import vos.Settings;
	
	[Bindable]
	public class SendIRModel extends UIComponent
	{
		private static var instance:SendIRModel;
		
		public var hostID:String = "";
		public var hostIp:String = "192.168.1.2";
		
		/*public var commandNameA:String = "Status";
		public var commandNameB:String = "Sensors";
		public var commandNameC:String = "Set temp";
		public var commandNameD:String = "Faults";
		
		public var commandA:String = "/ch_status";
		public var commandB:String = "/sensors";
		public var commandC:String = "/ch_temp";
		public var commandD:String = "/faults";

		public var commandTypeA:String = "POST";
		public var commandTypeB:String = "GET";
		public var commandTypeC:String = "POST";
		public var commandTypeD:String = "GET";*/

		/*public var tempSet:Number = 20;
		public var scheduleTemp:Number = 20; // current schedul temp
		public var scheduleOverruleTemp:Number = 20; // currently overruled schedule temp setting
		public var tempCur:Number = 19.3;
		public var heating:Boolean = false;*/
		//public var darkTheme:Boolean = false;
		/** 0 = schedule
		 * 1 = scenario 1
		 * 2 = scenario 2
		 * etc.
		 * */
		//public var scenarioIndex:int = 0;
		//public var selectedScenarioPreset:Object;
		/** Memory of the last set scenario (> 0) */ 
		//public var scenarioLast:int = 1;
		//public var maxScenario:int = 4;
		/** Set this to indicate current schedule is being overruled by manually set T */
		//public var overruleActive:Boolean = false;
		/** Set this to indicate landscape orientation */
		//public var landscape:Boolean = false;
		
		protected var service:HTTPService;
		
		public var settings:Settings;
		
		public static var httpResponseText:String = "";
		
		public var error:Boolean;
		public var errorText:String;
		public var selectedEdge:Edge;
		
		/**
		 * preset (default) temperatures toggled in home screen
		 */		
		/*public var defaultScenarios:ArrayCollection = new ArrayCollection([
			{icon:ThuisV215x15grijs, temperature:21, name:"Thuis"},
			{icon:Nacht15x15grijs, temperature:18, name:"Slapen"},
			{icon:NietThuisV215x15grijs, temperature:16, name:"Niet thuis"},
			{icon:Vorst15x15grijs, temperature:10, name:"Lang weg"},
			{icon:Vakantie, temperature:6, name:"Vakantie"}
		]);*/
		
		public var defaultDevices:ArrayCollection = new ArrayCollection([
			{name:"Airco 1", activatedPreset:"off"},
			{name:"Airco 2", activatedPreset:"high"},
			{name:"Airco 3", activatedPreset:"low"}
		]);
		
		public var defaultConfigs:ArrayCollection = new ArrayCollection([
			{name:"Airco 1", preset:"off"},
			{name:"Airco 1", preset:"high"},
			{name:"Airco 1", preset:"low"},
			{name:"Airco 2", preset:"off"},
			{name:"Airco 2", preset:"high"},
			{name:"Airco 2", preset:"low"},
			{name:"Airco 3", preset:"off"},
			{name:"Airco 3", preset:"high"},
			{name:"Airco 3", preset:"low"}
		]);
		
		public var defaultPresets:ArrayCollection = new ArrayCollection([
			{name:"off"},
			{name:"high"},
			{name:"low"}
		]);
		
		/*public var profileHousingType:RadioButtonGroup = new RadioButtonGroup();
		public var profileSavingsType:RadioButtonGroup = new RadioButtonGroup();*/
		
		
		public function SendIRModel()
		{
			instance = this;
			
			service = new HTTPService();
			service.requestTimeout = 0;
			service.concurrency = "multiple";
			service.useProxy = false;
			service.addEventListener(ResultEvent.RESULT, resultHandler);
			service.addEventListener(FaultEvent.FAULT, faultHandler);

			
			setSettings();
		}
		
		public static function get sendIRModel():SendIRModel {
			if (instance == null) {
				instance = new SendIRModel();
			}
			return instance;
		}
		
		/*public function setScenario(ind:int = -1):void{
			if (ind < 0){
				ind = scenarioIndex;
			} else if (ind > settings.presetCollection.length){
				ind = 1;	
			}
			scenarioIndex 	= ind;
			tempSet 		= getScenarioTemp(ind);
			if (ind > 0){
				scenarioLast 	= Math.max(1,ind);
				selectedScenarioPreset = settings.presetCollection.getItemAt(scenarioLast-1);
			}
			setSettings();
		}*/
		
		/*public function getScenarioTemp(ind:int = -1):Number{
			var presetTemp:Number;
			if (ind < 0) ind = scenarioIndex;
			if (ind == 0){ // schedule
				presetTemp = scheduleTemp;
			} else { // preset
				presetTemp = Number(settings.presetCollection.getItemAt(ind - 1).temperature)
			}
			return presetTemp;
		}
		
		public function setOverRule():void{
			if (getScenarioTemp() != tempSet){
				overruleActive = true;
			} else {
				overruleActive = false;
			}
		}*/
		
		public function getApplicationVersion():String{
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXML.namespace();
			return appXML.ns::versionNumber;
		}

		public function getOsType():String{
			var os:String = Capabilities.os;
			return os;
		}
		
		public function setSettings(event:SettingsEvent = null, reset:Boolean=false):void {
			if (settings != null && event != null && event.settings != null) {
				// set new settings in memory
				settings = event.settings;
			}
			if (!EncryptedLocalStore.isSupported) {
				return;
			}
			
			var settingsBA:ByteArray;
			try {
				settingsBA = EncryptedLocalStore.getItem("send_ir_settings");
				if (settingsBA) {
					//settings will be read from disk
				} else {
					//settings = null;
				}
			} catch(error:Error) {
				errorText += "\nreading settings from ELS failed!";
			}
			
			if (settingsBA && settings == null && reset == false) { // read from disk
				settings = new Settings();
				settings.readExternal(settingsBA);
				// set runtime variables based on settings
				//setScenario(settings.selectedScenarioIndex);
				
			} else {
				if (settings == null || reset) { // no settings on disk, or in app, so initialize
					settings = new Settings();
					// now fill them with example data:
					settings.language = "nl_NL";
					settings.hostIp = hostIp;
					settings.version = getApplicationVersion();
					settings.registeredAppOnPortal = false;
					settings.savedState = "main";
					//settings.presetCollection = new ArrayCollection(defaultScenarios.source);
					settings.scheduleCollection = new ArrayCollection();//arrayCollection of Edges
					/*new ArrayCollection([{time:0, temperature:21.5},
					{time:10000, temperature:20},{time:20000, temperature:18.5},{time:30000, temperature:21.5},
					{time:40000, temperature:17},{time:50000, temperature:15.5}]);*/
					//setSettings(new SettingsEvent(SettingsEvent.SETSETTINGS,false,null,settings));
				}
				if (settings.appUUID == ""){ 
					if (event != null && event.type == SettingsEvent.CLEARSETTINGS){
						createAppUuid(event, true);
					} else {
						errorText += "\nCreating app uuid...";
						createAppUuid(event);
					}
				}
			}
			
			var dataOut:ByteArray = new ByteArray();
			// set settings
			//settings.selectedScenarioIndex = scenarioIndex;
			settings.version = getApplicationVersion();
			settings.writeExternal(dataOut);
			try
			{
				EncryptedLocalStore.setItem("send_ir_settings", dataOut);
			} 
			catch(error:Error) 
			{
				errorText += "\nsaving ELS failed!";
			}
			
		}
		
		public function setEdgeInScheduleCollection(event:EdgeEvent):void {
			//get index of edge in scheduleCollection:
			if (event.type == EdgeEvent.CREATE) {
				if (event.edge) {
					event.edge.prenatal = false;
					settings.scheduleCollection.addItem(event.edge);
					var e:Event = new Event("scheduleCollectionChanged");
					dispatchEvent(e);
				}
			}
			if (event.type == EdgeEvent.UPDATE) {
				//var index:int = getIndexOfId(event.edge.id, settings.scheduleCollection);
				//if (index != -1) {
					//var edge:Edge = settings.scheduleCollection.getItemAt(index) as Edge;
					//edge.setWithValues(event.edge.temperature, event.edge.timeSinceStartOfWeek);
				//}
			}
			if (event.type == EdgeEvent.DELETE) {
				var index:int;
				if (event.edge) {
					index = getIndexOfId(event.edge.id, settings.scheduleCollection);
				} else if (event.edgeId) {
					index = getIndexOfId(event.edgeId, settings.scheduleCollection);
				}
				if (index != -1) {
					settings.scheduleCollection.removeItemAt(index);
					dispatchEvent(new Event("scheduleCollectionChanged",true));
				}
			}
			
			//save settings.schedulecollection to disk (should be to Smile later on):
			setSettings();
		}
		
		public function createAppUuid(e:Event = null, reset:Boolean=false):void {
			if (settings.appUUID == null || (settings.appUUID != null && settings.appUUID == "") || reset){
				settings.appUUID = generateUuid();
				settings.registeredAppOnPortal = false;
				trace("SettingsModel set appUUID: "+settings.appUUID);
			}
		}
		
		/** Generate a lowercase UUID (without dashes (-)) */
		public function generateUuid():String{
			var dashPattern:RegExp = /-/g;
			return UIDUtil.createUID().replace(dashPattern,"").toLowerCase();
		}
		
		public static function traceHttpResponse(text:String=""):void {
			//return;
			trace(text);
			if (text == null) return;
			var maxLength:int = 20480 - text.length;
			if (httpResponseText.length > maxLength) {
				httpResponseText = "";
			}
			httpResponseText = formatDate(new Date(), "HH:NN:SS") + ": " + text + "\n" + httpResponseText;
		}
		
		public static function formatDate(date:Date, formatString:String=null):String {
			if (formatString == null) {
				formatString = "YYYY-MM-DD";
			}
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = formatString;
			return dateFormatter.format(date);
		}
		
		private function getIndexOfId(id:String, ac:ArrayCollection):int {
			for (var i:int = 0; i < settings.scheduleCollection.length; i++) 
			{
				if (settings.scheduleCollection.getItemAt(i).id == id) {
					return i;
				}
			}
			return -1;
		}
		
		// start Requests...
		
		public function openUrl(url:String):void{
			var req:URLRequest = new URLRequest(url);
			if (url.indexOf('fp://')){
				try{
					navigateToURL(req);
				} catch (e:Error) {
					req.url = "http://m.facebook.com/";
					navigateToURL(req);
				}
			} else {
				navigateToURL(req);
			}
		}
		
		/*
		GET     ir/slots/
		DELETE  ir/slots/
		GET     ir/slots/someslot
		POST    ir/slots/someslot
		DELETE  ir/slots/someslot
		
		GET     ir/schedule
		DELETE  ir/schedule
		PUTPOST ir/schedule?day={mo|tu|...} & time=hh:mm & slot=someslot & led={up|side} & retry=n
		DELETE  ir/schedule?day={mo|tu|...} & time=hh:mm
		
		GET     ir/record?slot=someslot
		
		GET     ir/play?slot=someslot & led={up|side}
			PUTPOST ir/play
		
		GET     ir/canrecord
		
		GET     ir/geslots/
		*/
		
		public function getSlots(host:Host, action:String="getSlots"):void {
			// ir/slots/
			if (!host) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = host.hostURL(host.port, "ir/slots/");
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			service.resultFormat = "e4x";
			service.request = null;
			
			token = service.send();
			token.action = action;
		}
		
		public function deleteSlots(host:Host):void {
			// ir/slots/
			if (!host) return;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var req:URLRequest = host.getUrlRequest(null, "ir/slots/");
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, deleteSlotsHTTPStatusHandler);
			loader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			req.method = URLRequestMethod.DELETE;
			req.contentType = "text/xml";
			/*if (body) {
				req.data = body;
			}*/
			loader.load(req);
		}
		
		public function getSomeSlot(host:Host, slotName:String=null, action:String="getSomeSlot"):void {
			//ir/slots/someslot
			if (!host || !slotName) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = host.hostURL(host.port, "ir/slots/" + slotName);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			service.resultFormat = "e4x";
			service.request = null;
			
			token = service.send();
			token.action = action;

		}
		
		public function deleteSomeSlot(host:Host, slotName:String=null, action:String="deleteSomeSlot"):void {
			//ir/slots/someslot
			if (!host) return;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var req:URLRequest = host.getUrlRequest(null, "ir/slots/" + slotName);
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, deleteSlotsHTTPStatusHandler);
			loader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			req.method = URLRequestMethod.DELETE;
			req.contentType = "text/xml";
			/*if (body) {
			req.data = body;
			}*/
			loader.load(req);

		}
		
		public function postSomeSlot(host:Host, slotName:String, body:String, action:String="postSomeSlot"):void {
			//ir/slots/someslot
			if (!host || !slotName) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = host.hostURL(host.port, "ir/slots/" + slotName);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.POST;
			//service.resultFormat = "e4x";
			service.request = body;//parameters
			
			token = service.send();
			token.action = action;

		}
		
		public function getSchedule(host:Host):void {
			// ir/schedule
				
		}
		
		public function deleteSchedule(host:Host):void {
			// ir/schedule
			
		}
		
		
		
		/*protected var schedule:Object = new Object();
		protected function createSchedule(schedule:Object):void {
			schedule.id = schedule.id;
			schedule.name = schedule.name;
			schedule.edges = schedule.edges;//ArrayCollection of class Edge
		}*/		
		
		
		
		
		// ...end Requests
		
		private function resultHandler(e:ResultEvent):void{
			var token:AsyncToken = e.token;
			if (!token.action) return;
			
			trace("SendIRModel resultHandler url="+token.url+":");
			if (e.result is ObjectProxy && e.result.error){
				// error
				trace(e.result.error);
				return;
			}
			
			switch (token.action) {
				case "getSlots":
					
					break;
				case "getSomeSlot":
					
					break;
					
			}
			
			
			
		}
		
		private function faultHandler(e:FaultEvent):void{
			var token:AsyncToken = e.token;
			trace("SendIRModel faultHandler url="+token.url+":");
			if (e.fault){
				// error
				trace("SendIRModel faultHandler status="+e.statusCode, e.fault.faultCode, e.fault.faultDetail);
				dispatchEvent(new Event("connectionError"));
				
			}
		}
		
		
		// Response Handlers...
		
		
		// HTTPService Handlers...
		
		private function getSomeSlotHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		
		// ...end HTTPService Handlers
		
		// URLLoader Handlers...
		private function deleteSlotsHTTPStatusHandler(event:HTTPStatusEvent):void {
			if (event && event.status == 200){
				
			} else {
				
			}
		}
		
		private function urlLoaderCompleteHandler(event:Event):void {
			trace("PlugwiseModel getDataFromHostCompleteHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
		}
		
		protected function ioErrorHandler(event:IOErrorEvent):void {
			trace("PlugwiseModel ioErrorHandler: " + event);
		}

		//... end URLLoader Handlers
		
		
		

		//...end Response Handlers
		
		
		
		
		
		/*private var udp:DatagramSocket;
		private function initMulticast():void{
			if (DatagramSocket.isSupported){
				udp = new DatagramSocket();
				udp.addEventListener(DatagramSocketDataEvent.DATA, getData);
				udp.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				//udp.connect("224.9.9.1", 4991);
				//udp.receive();
				
				getHostIdViaMulticast(null, "plugwise stretch");
			}
		}
		
		private function getHostIdViaMulticast(e:Event, hostId:String="name=stretch003b4d"):void{
			var ba:ByteArray = new ByteArray();
			ba.writeUTFBytes(hostId);
			var baLen:uint = ba.length;
			trace("ThermoModel getHostIdViaMulticast baLen="+baLen+" ba="+ba.toString());
			//udp.receive();
			udp.send(ba, 0, baLen, "224.9.9.1", 4991); // DOES NOT WORK WITH MULTICAST ADDRESS
		}
		
		private function getData(e:DatagramSocketDataEvent):void{
			trace(">>>>>" + e.data.readUTFBytes( e.data.bytesAvailable ))	
		}
		
		private function onIOError(event:IOErrorEvent):void{
			trace(event.toString());
		}*/
		
	}
}