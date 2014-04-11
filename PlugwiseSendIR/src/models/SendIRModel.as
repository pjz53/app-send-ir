package models
{
	import flash.data.EncryptedLocalStore;
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	import mx.formatters.DateFormatter;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectProxy;
	import mx.utils.UIDUtil;
	
	import events.EdgeEvent;
	import events.SettingsEvent;
	
	import vos.Edge;
	import vos.Gateway;
	import vos.IRCommand;
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
		
		public var defaultGateways:ArrayCollection = new ArrayCollection([
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
			new IRCommand("off"),
			new IRCommand("high"),
			new IRCommand("low")
		]);
		
		public var selectedGateway:Gateway;
		
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
				
				if (!settings.gatewaysCollection || settings.gatewaysCollection.length != 4) {
					settings.gatewaysCollection = setDefaultGateways();
				}
				
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
					settings.gatewaysCollection = setDefaultGateways();
					

					
					
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
		
		private function setDefaultGateways(ac:ArrayCollection=null):ArrayCollection {
			if (!ac) {
				ac = new ArrayCollection();
			}
			var gateway:Gateway = new Gateway("Airco 1","smile_ir");
			gateway.irCommands = new ArrayCollection();
			gateway.irCommands.addItem(new IRCommand(null, "low"));
			gateway.irCommands.addItem(new IRCommand(null, "high"));
			gateway.irCommands.addItem(new IRCommand(null, "off"));
			ac.addItem(gateway);
			
			gateway = new Gateway("Airco 2","smile_ir");
			gateway.irCommands = new ArrayCollection();
			gateway.irCommands.addItem(new IRCommand(null, "off"));
			gateway.irCommands.addItem(new IRCommand(null, "high"));
			gateway.irCommands.addItem(new IRCommand(null, "low"));
			gateway.irCommands.addItem(new IRCommand(null, "eco"));
			ac.addItem(gateway);
			
			gateway = new Gateway("Airco 3","smile_ir");
			gateway.irCommands = new ArrayCollection();
			gateway.irCommands.addItem(new IRCommand(null, "low"));
			gateway.irCommands.addItem(new IRCommand(null, "high"));
			gateway.irCommands.addItem(new IRCommand(null, "night"));
			gateway.irCommands.addItem(new IRCommand(null, "off"));
			ac.addItem(gateway);
			
			gateway = new Gateway("Airco 4","smile_ir");
			gateway.irCommands = new ArrayCollection();
			gateway.irCommands.addItem(new IRCommand(null, "off"));
			gateway.irCommands.addItem(new IRCommand(null, "low"));
			gateway.irCommands.addItem(new IRCommand(null, "high"));
			ac.addItem(gateway);
			
			return ac;
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
		
		public function getIRCommands(gateway:Gateway, action:String="getIRCommands"):void {
			// ir/slots/
			if (!gateway) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/slots/");
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			service.resultFormat = "e4x";
			service.request = null;
			
			token = service.send();
			token.action = action;
			token.gateway = gateway;
		}
		
		public function deleteIRCommands(gateway:Gateway):void {
			// ir/slots/
			if (!gateway) return;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var req:URLRequest = gateway.getUrlRequest(null, "ir/slots/");
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, deleteIRCommandsHTTPStatusHandler);
			loader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			req.method = URLRequestMethod.DELETE;
			req.contentType = "text/xml";
			/*if (body) {
				req.data = body;
			}*/
			loader.load(req);
		}
		
		public function getSomeIRCommand(gateway:Gateway, irCommandName:String=null, action:String="getSomeIRCommand"):void {
			//ir/slots/someslot
			if (!gateway || !irCommandName) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/slots/" + irCommandName);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			service.resultFormat = "e4x";
			service.request = null;
			
			token = service.send();
			token.action = action;
			token.host = gateway;
			token.irCommandName = irCommandName;
		}
		
		public function deleteSomeIRCommand(gateway:Gateway, irCommandName:String=null, action:String="deleteSomeIRCommand"):void {
			//ir/slots/someslot
			if (!gateway) return;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			var req:URLRequest = gateway.getUrlRequest(null, "ir/slots/" + irCommandName);
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, deleteIRCommandsHTTPStatusHandler);
			loader.addEventListener(Event.COMPLETE, urlLoaderCompleteHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			req.method = URLRequestMethod.DELETE;
			req.contentType = "text/xml";
			/*if (body) {
			req.data = body;
			}*/
			loader.load(req);

		}
		
		public function postSomeIRCommand(gateway:Gateway, irCommandName:String, body:String, action:String="postSomeIRCommand"):void {
			//ir/slots/someslot
			if (!gateway || !irCommandName) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/slots/" + irCommandName);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.POST;
			//service.resultFormat = "e4x";
			service.request = body;//parameters
			
			token = service.send();
			token.action = action;

		}
		
		public function canRecord(gateway:Gateway, action:String="canRecord"):void {
			// ir/canrecord
			if (!gateway) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/canrecord");
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			//service.resultFormat = "e4x";
			service.request = null;//parameters
			
			token = service.send();
			token.action = action;

		}
		
		public function recordSomeIRCommand(gateway:Gateway, irCommandName:String, body:String, action:String="recordSomeIRCommand"):void {
			// ir/record?slot=someslot
			if (!gateway || !irCommandName || !body) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/record?slot=" + irCommandName);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			//service.resultFormat = "e4x";
			service.request = body;//parameters
			
			token = service.send();
			token.action = action;

		}
		
		public function playSomeIRCommand(gateway:Gateway, irCommandName:String, body:String, led:String="up", action:String="playSomeIRCommand"):void {
			// ir/play?slot=someslot & led={up|side}
			if (!gateway || !irCommandName || !body) return;
			
			var token:AsyncToken = new AsyncToken();
			
			service.url = gateway.hostURL(gateway.port, "ir/play?slot=" + irCommandName + "&led=" + led);
			service.requestTimeout = 0;
			service.method = URLRequestMethod.GET;
			//service.resultFormat = "e4x";
			service.request = body;//parameters
			
			token = service.send();
			token.action = action;

		}
		
		public function getSchedule(host:Gateway):void {
			// ir/schedule
				
		}
		
		public function deleteSchedule(host:Gateway):void {
			// ir/schedule
			
		}
		
		
		
		/*protected var schedule:Object = new Object();
		protected function createSchedule(schedule:Object):void {
			schedule.id = schedule.id;
			schedule.name = schedule.name;
			schedule.edges = schedule.edges;//ArrayCollection of class Edge
		}*/		
		
		public function getBeaconForGateway(gateway:Gateway=null):void {
			if (!gateway && selectedGateway) 
			{
				gateway = selectedGateway;
			}
			
			trace("getPortalBeacon ID:"+ gateway.codeSmile);
			
			service.resultFormat = "e4x";
			service.url = "https://beacon.plugwise.net/announce/" + gateway.codeSmile;
			service.useProxy = false;
			service.requestTimeout = 0;
			service.method = "GET";
			var token:AsyncToken = service.send();
			token.action = "getBeaconForGateway";
			token.gateway = gateway;
		}
		
		
		// ...end Requests
		
		private function resultHandler(event:ResultEvent):void{
			var token:AsyncToken = event.token;
			if (!token.action) return;
			
			trace("SendIRModel resultHandler url="+token.url+":");
			if (event.result is ObjectProxy && event.result.error){
				// error
				trace(event.result.error);
				return;
			}
			
			switch (token.action) {
				case "getIRCommands":
					getIRCommandsHandler(event);
					break;
				case "getSomeIRCommand":
					getSomeIRCommandHandler(event);
					break;
				case "postSomeIRCommand":
					postSomeIRCommandHandler(event);
					break;
				case "canRecord":
					canRecordHandler(event);
					break;
				case "recordSomeIRCommand":
					recordSomeIRCommandHandler(event);
					break;
				case "playSomeIRCommand":
					playSomeIRCommandHandler(event);
					break;
				case "getBeaconForGateway":
					getBeaconForGatewayHandler(event);
					break;
					
			}
			
			
			
		}
		
		private function faultHandler(event:FaultEvent):void{
			var token:AsyncToken = event.token;
			trace("SendIRModel faultHandler url="+token.url+":");
			if (event.fault){
				// error
				trace("SendIRModel faultHandler status="+event.statusCode, event.fault.faultCode, event.fault.faultDetail);
				dispatchEvent(new Event("connectionError"));
				
				switch (token.action) {
					case "getIRCommands":
						
						break;
					case "getSomeIRCommand":
						
						break;
					case "postSomeIRCommand":
						
						break;
					case "canRecord":
						
						break;
					case "recordSomeIRCommand":
						
						break;
					case "playSomeIRCommand":
						
						break;
					case "getBeaconForGateway":
						
						break;
					
				}

				
			}
		}
		
		
		// Response Handlers...
		
		
		// HTTPService Handlers...
		
		private function getIRCommandsHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		private function getSomeIRCommandHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				//get the content to fill the IRCommand:
				
				
				
			}
			
		}
		
		private function postSomeIRCommandHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		private function canRecordHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		private function recordSomeIRCommandHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		private function playSomeIRCommandHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				
			}
			
		}
		
		private function getBeaconForGatewayHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;

			if (event && event.result && event.result.length() > 0) {
				var configXML:XML = event.result as XML;
				
				if (configXML == null) {
					return;
				}
				var gateway:Gateway = token.gateway;
				
				gateway.version= configXML.version != "" ? configXML.version : null;
				if (configXML.lan_ip != ""){
					gateway.useLan = true;
					gateway.lanIP 	= String(configXML.lan_ip);
				} else {
					gateway.useLan = false;
					gateway.lanIP 	= null;
				}
				gateway.wifiIP = configXML.wifi_ip != "" ? configXML.wifi_ip : null;
				
				
				
				
			}
			
		}
		
		
		// ...end HTTPService Handlers
		
		// URLLoader Handlers...
		private function deleteIRCommandsHTTPStatusHandler(event:HTTPStatusEvent):void {
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
		
		
		// Utility methods...
		
		public function getGatewayByUUID(uuid:String):Gateway {
			for each (var gateway:Gateway in settings.gatewaysCollection) 
			{
				if (gateway.gatewayUuid == uuid) {
					return gateway;
				}
			}
			return null;
		}
		
		
		// ...end Utility methods
		
		
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