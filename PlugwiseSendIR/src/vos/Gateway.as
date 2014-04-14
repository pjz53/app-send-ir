package vos {
		
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.XMLListCollection;
	import mx.core.FlexGlobals;
	import mx.utils.Base64Encoder;
	import mx.utils.UIDUtil;
	
	import models.Feature;
	import models.SendIRModel;
	
	[Bindable]
	public class Gateway extends EventDispatcher{
		
		private var _label:String;
		private var _type:String;
		private var _hardwareType:String;
		private var _nullPhase:Boolean;
		private var _protocol:String;
		private var _hostIP:String;
		private var _lanIP:String;
		private var _useLan:Boolean;
		private var _wifiIP:String;
		private var _port:String;
		private var _hostURL:String;
		private var _hostWifiURL:String;
		private var _authorizationName:String;
		private var _authorizationPassword:String;
		private var _licenseKey:String;
		private var _macAddressWiFi:String;
		private var _macAddressLan:String;
		private var _codeSmile:String;
		private var _refreshInterval:Number;
		private var _sharedObject:SharedObject;
		private var _hostXML:XML;
		private var _wifiConfigStep:String;
		private var _configSetupState:String;
		private var _lanConfiguration:Boolean;
		private var _dispatchUpdate:Boolean; // if true dispatch update in ThermoModel
		private var _networkSsid:String; // to tell user on which ssid the device should be connected
		private var _version:String; // to tell user on which version of Stretch/Smile is connected
		private var _name:String; // to tell user on which version of Stretch/Smile is connected
		private var _restRoot:String; // to tell user on which root url the rest interface has (plugwise/modules is especially for modules) 
		private var _usingWifi:Boolean; // if true the wifi ip address is used
		private var _configurationComplete:Boolean; // if true getModules has succeeded at least once
		private var _typeName:String; // Name of device based on type
		private var _mercuryURL:String; // URL (from portalModel) for mercury connection
		private var _mercuryChannel:String; // Channel for mercury connection
		private var _mercuryAccessKey:String; // Access key for mercury connection
		private var _mercuryEnabled:Boolean; // Access key for mercury connection
		private var _useMercury:Boolean; // If true, use mercury in stead of direct ip connection
		private var _timeDiff:Number; // difference in time between device and Stretch (not Smile)
		private var _gatewayUuid:String;
		private var _licenseUuid:String;
		private var _setupNetworkVia:String; // Last time the beacon was received from device by portal (server_timestamp)
		
		private var _basicAuthName:String; // set by typeName.toLowercase()
		private var _basicAuthPassword:String;
		private var _lastBeaconDownload:Date; // Last time the beacon was downloaded (time on device when result was received from beacon request)
		private var _lastBeaconUpload:Date; // Last time the beacon was received from device by portal (server_timestamp)
		private var _lastResetDate:Date; // Last time the host was reset f.i. to filter appliances from portal
		private var _licenseCreatedDate:Date; // License created date of gateway
		private var _firstDataDate:Date = new Date(2012,0,1); // First data date of gateway, to load total data (from this date to now)
		/** Features of the gateway and/or license */
		private var _gatewayFeatures:XMLListCollection; 
		/** Runtime variable to represent if the host is connected */
		private var _connected:Boolean = true;
		private var _firmwareUpgradeInProgress:Boolean;
		/** Runtime variable to put the total power in */
		public var totalPower:Number;
		/** Runtime variable to contain license got from gateway */
		public var status:XML;
		private var _license:XML;
		/** Runtime variable to contain adjective for localized gateway name */
		public var the:String = "de";
		/** Runtime variable to contain network name for localized gateway name */
		public var yourNetwork:String = "uw netwerk";
		/** Runtime variable to determine if the real hardwareType of a gatwway is a Smile (for hardwareType = "smile_s0/p0_app", which fills a Stretch gateway, but is physically a Smile) */
		public var isSmile:Boolean = true;
		/** Runtime variable to display the real hardwareType specification of a gateway */
		public var typeSpec:String;
		/** Runtime variable to display if this is the config host or the 'real' host in ThermoModel */
		public var hostConfiguration:Boolean = false; // If true, display this in the trace
		/** Runtime variable to display if /portal contains <ssh_relay active_until="2013-10-28T11:00:00+00:00">enabled</ssh_relay> */
		public var sshRelayOn:Boolean = false; // If true, gateway can be reached by SSH for debugging
		public var sshRelayUntil:Date;
		/** Runtime variable to force the use of Mercury for debugging */
		public var useMercuryNow:Boolean = false;
		public var lastStatusCodeMercury:int;
		
		private var _htmlApiNameSpace:String = "/system/status";
		
		private var _connectionState:String = "NO";
		private var _connectedLan:Boolean = false;
		private var _connectedWifi:Boolean = false;
		private var _connectedWifiNotAP:Boolean = false;
		//private var _connectedWifiAP:Boolean = false;
		private var _connectionMonitorRefreshInterval:Number = 10; // if this is too low, calls will fail!
				
		private var _connectionMode:String = "none";
		private var _connectionLocalAvailable:Boolean = false;
		private var _connectionMercuryAvailable:Boolean = false;
		private var _connectionPortalAvailable:Boolean = false;
		private var _connectionApAvailable:Boolean = false;
		
		public static var referenceCount:int = 0;
		
		public static const SMILE_WITHOUT_GATEWAY_VERSION_CHECK:String = "15.3."; // if this succeeds, 
		public static const STRETCH_WITH_MERCURY_SETTINGS_CHECK:Array = new Array(1,0,42); // Mercury enable/disable option implemented 
		public static const SMILE_WITH_CORE_CHECK:Array = new Array(1,3,0); // Core modules implemented 
		public static const SMILE_WITH_STATUS_CHECK:Array = new Array(1,2,9); // /system/status implemented 
		
		public static const PRODUCT_NAME_UNKNOWN:String = "Gateway";
		public static const PRODUCT_NAME_SMILE:String = "Smile";
		public static const PRODUCT_NAME_STRETCH:String = "Stretch";
		public static const PRODUCT_NAME_SOURCE:String = "Source";
		
		public static const GW_TYPE_UNKNOWN:String = "gateway";
		public static const GW_TYPE_SMILE:String = "p1";
		public static const GW_TYPE_STRETCH:String = "stretch";
		public static const GW_TYPE_SOURCE:String = "source";

		public static const GW_AUTH_NAME_SMILE:String = "smile";
		public static const GW_AUTH_NAME_STRETCH:String = "stretch";
		
		public static const DEFAULTPROTOCOL:String = "http://";
		public static const DEFAULTWIFIIPADDRESS:String = "192.168.40.40";
		public static const CONFIG_LAN_WIFI_NOT_SET:String = "configByLanCableWifiNotSet";
		public static const CONFIG_LAN_WIFI_SET:String = "configByLanCableWifiSet";
		public static const CONFIG_WIFI_WIFI_NOT_SET:String = "configByWifiWifiNotSet";
		public static const CONFIG_WIFI_WIFI_SET:String = "configByWifiWifiSet";
		
		public static const STATE_NO_CONNECTION:String = "stateNoConnection";
		public static const STATE_WIFI_ACCESS_POINT:String = "stateWifiAP";
		public static const STATE_WIFI_USAGE:String = "stateWifiUsage";
		public static const STATE_LAN_CONFIGURATION:String = "stateLanConfiguration";
		public static const STATE_LAN_USAGE:String = "stateLanUsage";
		
		public static const NETWORKWMONITORRESTURLSMILE1_3:String = "/diagnostic/system/version"; //"/configuration/beacon";
		public static const NETWORKWMONITORRESTURLSMILE:String = "/diagnostic/kernel/version"; //"/configuration/beacon";
		public static const NETWORKWMONITORRESTURLSTRETCH:String = "/configuration/beacon"; //"/time";
		public static const NETWORKWMONITORRESTURLSTRETCH2_0:String = "/system/time"; //"/time";
		
		protected var localMonitorLastResponse:Date;		
		protected var localMonitor:URLLoader;		
		protected var localMonitorDelay:int = 1000;		
		protected var localMonitorTimer:Timer = new Timer(localMonitorDelay);		
		protected var mercuryMonitorLastResponse:Date;		
		protected var mercuryMonitor:URLLoader;		
		protected var mercuryMonitorDelay:int = 2000;		
		protected var mercuryMonitorTimer:Timer = new Timer(mercuryMonitorDelay);
		protected var mercuryIoErrorCounter:int = 0;
		protected var portalMonitorLastResponse:Date;		
		protected var portalMonitor:URLLoader;		
		protected var portalMonitorDelay:int = 10000;		
		protected var portalMonitorTimer:Timer = new Timer(portalMonitorDelay);	
		protected var apMonitorLastResponse:Date;		
		protected var apMonitor:URLLoader;		
		protected var apMonitorDelay:int = 3000;		
		protected var apMonitorTimer:Timer = new Timer(apMonitorDelay);	
		
		public var appCurrentlyActive:Boolean = true;
		
		private var _irCommands:ArrayCollection;// arrayCollection of Slot objects
		private var _scheduleCollection:ArrayCollection;// arrayCollection of Slot objects
		
		private var _useLed:String;
		private var _brand:String;
		private var _model:String;
		
		public function Gateway(
			label:String,
			type:String,
			nullPhase:Boolean=true,
			protocol:String=DEFAULTPROTOCOL,
			hostIP:String=null,
			lanIP:String=null,
			useLan:Boolean=false,
			wifiIP:String=null,
			port:String=null,
			authorizationName:String=null,
			authorizationPassword:String=null,
			licenseKey:String=null,
			macAddressWiFi:String=null,
			macAddressLan:String=null,
			codeSmile:String=null,
			refreshInterval:Number=10,
			sharedObject:SharedObject=null,
			hostXML:XML=null,
			wifiConfigStep:String=null,
			configSetupState:String=null,
			dispatchUpdate:Boolean=true,
			networkSsid:String=null,
			version:String=null,
			name:String="de Smile",
			restRoot:String="/",
			configurationComplete:Boolean=false,
			typeName:String="",
			mercuryURL:String=null,
			mercuryChannel:String=null,
			mercuryAccessKey:String=null,
			useMercury:Boolean=false,
			timeDiff:Number=0,
			gatewayUuid:String=null,
			licenseUuid:String=null,
			setupNetworkVia:String=null,
			firmwareUpgradeInProgress:Boolean=false,
			lastResetDate:Date = null,
			licenseCreatedDate:Date = null,
			firstDataDate:Date = null,
			gatewayFeatures:XMLListCollection=null,
			hardwareType:String=null,
			irCommands:ArrayCollection=null,
			scheduleCollection:ArrayCollection=null,
			useLed:String=null,
			brand:String=null,
			model:String=null
		) {
			
			_label = label;
			_type = type;
			_nullPhase = nullPhase;
			_protocol = protocol;
			_hostIP = hostIP;
			_lanIP = lanIP;
			_useLan = useLan;
			_wifiIP = wifiIP;
			_port = port;
			_authorizationName = authorizationName;
			_authorizationPassword = authorizationPassword;
			_licenseKey = licenseKey;
			_macAddressWiFi = macAddressWiFi;
			_macAddressLan = macAddressLan;
			_codeSmile = codeSmile;
			_refreshInterval = refreshInterval;
			_sharedObject = sharedObject;
			_hostXML = hostXML;
			_wifiConfigStep = wifiConfigStep;
			_configSetupState = configSetupState;
			_dispatchUpdate = dispatchUpdate;
			_networkSsid = networkSsid;
			_version = version;
			_name = name;
			_restRoot = restRoot;
			_configurationComplete = configurationComplete;
			_typeName = typeName;
			_mercuryURL = mercuryURL;
			_mercuryChannel = mercuryChannel;
			_mercuryAccessKey = mercuryAccessKey;
			_useMercury = useMercury;
			_timeDiff = timeDiff;
			//_gatewayUuid = gatewayUuid;
			if (gatewayUuid == null) {
				var myPattern:RegExp = /-/g;
				_gatewayUuid = UIDUtil.createUID().replace(myPattern,"").toLowerCase();
			} else {
				_gatewayUuid = gatewayUuid;
			}
			_licenseUuid = licenseUuid;
			_setupNetworkVia = setupNetworkVia;
			_firmwareUpgradeInProgress = firmwareUpgradeInProgress;
			_lastResetDate = lastResetDate;
			_licenseCreatedDate = licenseCreatedDate;
			_firstDataDate = firstDataDate;
			_gatewayFeatures = gatewayFeatures;
			_hardwareType = hardwareType;
			_irCommands = irCommands;
			_scheduleCollection = scheduleCollection;
			_useLed = useLed;
			_brand = brand;
			_model = model;
			
			//now initialize a connectionMonitor or start monitors:
			//if availability changes set the mode
			//addEventListener("connectionModeChanged", setConnectionMode);
			
			addEventListener("configurationCompleteChanged", startApPoller);//start or stop
			//if hostIP changes (re-)start local poller
			addEventListener("hostIPChanged", startLocalPoller);
			addEventListener("wifiIPChanged", startLocalPoller);
			addEventListener("lanIPChanged", startLocalPoller);
			//if mercury access parameters change (re-)start mercury poller
			addEventListener("mercuryURLChanged", startMercuryPoller);
			//addEventListener("mercuryChannelChanged", startMercuryPoller);
			//addEventListener("mercuryAccessKeyChanged", startMercuryPoller);
			//always start pollers
			startLocalPoller();
			//startMercuryPoller();
			startPortalPoller();
			
			referenceCount++;
			
			SendIRModel.traceHttpResponse("Number of Host instances is now: " + referenceCount);
		}
		
		public function fill(obj:Object):void
		{
			for (var i:String in obj)
			{
				if (i != null){
					switch (i) {
						case "schedules":
							scheduleCollection = new ArrayCollection();
							for each (var eObj:Object in obj[i]) 
							{
								// we get edges here with an irCommand and a start time
								var eIRCommand:IRCommand = new IRCommand(eObj.id,eObj.label,eObj.type,eObj.irCommand);
								var edge:Edge = new Edge(eIRCommand, eObj.timeSinceStartOfWeek);
								scheduleCollection.addItem(edge);
							}
							break;
						case "irCommands":
							irCommands = new ArrayCollection();
							for each (var ircObj:Object in obj[i]) 
							{
								// we get edges here with an irCommand and a start time
								var ircIRCommand:IRCommand = new IRCommand(ircObj.id,ircObj.label,ircObj.type,ircObj.irCommand);
								irCommands.addItem(ircIRCommand);
							}
							break;
						default:
							try {
								if (i.indexOf("Date") > -1 && this[i]){
									this[i].time = obj[i] * 1000;
								} else {
									this[i] = obj[i];
								}
							} 
							catch (e:Error){
								// don't crash
							}
					}
				}
			}
		}
		
		//protected var localReq:URLRequest;
		protected function startLocalPoller(event:Event=null):void {
			if (hostIP == null){
				localMonitorTimer.reset();
				return;
			} 
			//poll immediately:
			localMonitorLastResponse = new Date();
			localPoller();
			localMonitorTimer.delay = localMonitorDelay;
			localMonitorTimer.removeEventListener(TimerEvent.TIMER,localPoller);
			localMonitorTimer.addEventListener(TimerEvent.TIMER,localPoller);
			localMonitorTimer.reset();
			localMonitorTimer.start();
			if (localMonitor) {
				localMonitor.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHttpResponseStatusHandler);
				localMonitor.removeEventListener(IOErrorEvent.IO_ERROR, localIoErrorHandler);
			}
			localMonitor = new URLLoader();
			localMonitor.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, localHttpResponseStatusHandler);
			localMonitor.addEventListener(IOErrorEvent.IO_ERROR, localIoErrorHandler);
		}
		protected function localPoller(event:TimerEvent=null):void {
			if (appCurrentlyActive && hostIP){
				var suffix:String = getNetworkMonitorUrl();
				var req:URLRequest 	= getUrlRequest(hostIP, suffix, true);
				try
				{
					var now:Date = new Date();
					if (now.time - localMonitorLastResponse.time > 2 * localMonitorDelay) {
						connectionLocalAvailable = false;
						setConnectionMode();
					}
					if (now.time - localMonitorLastResponse.time > localMonitorDelay || localMonitorDelay < 5000) {
						setLocalMonitorDelay(Math.min(15000, localMonitorDelay + 1000));
					} else {
						setLocalMonitorDelay(Math.max(5000, localMonitorDelay - 1000));
					}
					req.idleTimeout = localMonitorDelay - 500; // 0.5 sec less than monitor delay
					localMonitor.load(req);
					//trace("Host "+typeName+" delay="+delay+"localPoller delay="+localMonitorDelay+" url=" + req.url + " @ "+now.toTimeString());
				} 
				catch(error:Error) 
				{
					connectionLocalAvailable = false;
					setConnectionMode();
				}
			} else {
				connectionLocalAvailable = false;
				setConnectionMode();
			}
		}
		protected function setLocalMonitorDelay(time:Number):void{
			localMonitorDelay = time;
			if (localMonitorTimer) {
				localMonitorTimer.delay = time;
				localMonitorTimer.reset();
				localMonitorTimer.start();
			}
		}
		
		protected function localHttpResponseStatusHandler(event:HTTPStatusEvent):void {
			//trace("HOST localHttpResponseStatusHandler status=" + event.status);
			localMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+localMonitorDelay/1000+"s @ "+localMonitorLastResponse.toTimeString()+" localHttpResponseStatusHandler status=" + event.status);
			var statusArr:Array = new Array(200,202,204,205,206,500);
			var value:Boolean = false;
			if (statusArr.indexOf(event.status) != -1){
				value = true;
			} else {
				value = false;
			}
			if (connectionLocalAvailable != value) {
				connectionLocalAvailable = value;
			}
			setConnectionMode();
		}
		protected function localIoErrorHandler(event:IOErrorEvent):void {
			//trace("HOST CONN localIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			localMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+localMonitorDelay/1000+"s @ "+localMonitorLastResponse.toTimeString()+" localIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			var value:Boolean = false;
			if (connectionLocalAvailable != value) {
				connectionLocalAvailable = value;
			}
			setConnectionMode();
		}
		
		// ***** Access point poller functions (only if not yet configured) ******
		public function startApPoller(event:Event=null):void {
			if (configurationComplete || codeSmile == null){
				apMonitorTimer.reset();
				return;
			}
			//poll immediately:
			apMonitorLastResponse = new Date();
			//apPoller();
			apMonitorTimer.delay = apMonitorDelay;
			apMonitorTimer.removeEventListener(TimerEvent.TIMER,apPoller);
			apMonitorTimer.addEventListener(TimerEvent.TIMER,apPoller);
			apMonitorTimer.reset();
			apMonitorTimer.start();
			if (apMonitor) {
				apMonitor.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, apHttpResponseStatusHandler);
				apMonitor.removeEventListener(IOErrorEvent.IO_ERROR, apIoErrorHandler);
			}
			apMonitor = new URLLoader();
			apMonitor.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, apHttpResponseStatusHandler);
			apMonitor.addEventListener(IOErrorEvent.IO_ERROR, apIoErrorHandler);
		}
		protected var apSuffix:String;
		protected function apPoller(event:TimerEvent=null):void {
			if (!basicAuthName || !basicAuthPassword) {
				return;
			}
			apSuffix = getNetworkMonitorUrl();
			var req:URLRequest 	= getUrlRequest(DEFAULTWIFIIPADDRESS, apSuffix, true);
			try
			{
				var now:Date = new Date();
				if (now.time - apMonitorLastResponse.time > 2 * apMonitorDelay) {
					connectionApAvailable = false;
					setConnectionMode();
				}
				if (now.time - apMonitorLastResponse.time > apMonitorDelay || apMonitorDelay < 5000) {
					setApMonitorDelay(Math.min(15000, apMonitorDelay + 1000));
				} else {
					setApMonitorDelay(Math.max(5000, apMonitorDelay - 1000));
				}
				req.idleTimeout = apMonitorDelay - 500; // 0.5 sec less than monitor delay
				apMonitor.load(req);
				//trace("Host "+typeName+" delay="+delay+"apPoller delay="+apMonitorDelay+" url=" + req.url + " @ "+now.toTimeString());
			} 
			catch(error:Error) 
			{
				connectionApAvailable = false;
				setConnectionMode();
			}
		}
	
		protected function setApMonitorDelay(time:Number):void{
			apMonitorDelay = time;
			if (apMonitorTimer) {
				apMonitorTimer.delay = time;
				apMonitorTimer.reset();
				apMonitorTimer.start();
			}
		}
		
		protected function apHttpResponseStatusHandler(event:HTTPStatusEvent):void {
			//trace("HOST apHttpResponseStatusHandler status=" + event.status);
			apMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+apMonitorDelay/1000+"s @ "+apMonitorLastResponse.toTimeString()+" apHttpResponseStatusHandler status=" + event.status);
			var statusArr:Array = new Array(200,202,204,205,206,500);
			var value:Boolean = false;
			if (statusArr.indexOf(event.status) != -1){
				value = true;
			} else {
				value = false;
				if (event.status == 404) {
					if (type == GW_TYPE_STRETCH) {
						if (getNetworkMonitorUrl().indexOf(NETWORKWMONITORRESTURLSTRETCH) != -1) {
							version = "2";
						} else {
							version = "1";
						}
					} else if (type == GW_TYPE_SMILE) {
						if (getNetworkMonitorUrl().indexOf(NETWORKWMONITORRESTURLSMILE) != -1) {
							version = "1.3";
						} else {
							version = "1";
						}
					}
				}
			}
			connectionApAvailable = value;
			setConnectionMode();
		}
		protected function apIoErrorHandler(event:IOErrorEvent):void {
			//trace("HOST CONN apIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			apMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+apMonitorDelay/1000+"s @ "+apMonitorLastResponse.toTimeString()+" apIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			var value:Boolean = false;
			connectionApAvailable = value;
			setConnectionMode();
		}
		
		// ***** Mercury poller functions ******
		protected function startMercuryPoller(event:Event=null):void {
			if (type != GW_TYPE_STRETCH || mercuryURL == null){
				mercuryMonitorTimer.reset();
				return;
			}
			mercuryMonitorLastResponse = new Date();
			mercuryIoErrorCounter = 0;
			mercuryPoller();
			mercuryMonitorTimer.delay = mercuryMonitorDelay;
			mercuryMonitorTimer.removeEventListener(TimerEvent.TIMER,mercuryPoller);
			mercuryMonitorTimer.addEventListener(TimerEvent.TIMER,mercuryPoller);
			mercuryMonitorTimer.reset();
			mercuryMonitorTimer.start();
			if (mercuryMonitor) {
				mercuryMonitor.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, mercuryHttpResponseStatusHandler);
				mercuryMonitor.removeEventListener(IOErrorEvent.IO_ERROR, mercuryIoErrorHandler);
			}
			mercuryMonitor = new URLLoader();
			mercuryMonitor.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, mercuryHttpResponseStatusHandler);
			//mercuryMonitor.addEventListener(Event.COMPLETE, mercuryCompleteHandler);
			mercuryMonitor.addEventListener(IOErrorEvent.IO_ERROR, mercuryIoErrorHandler);
		}
		protected function mercuryPoller(event:TimerEvent=null):void {
			//use URLLoader, URLMonitor is only port 80
			if (appCurrentlyActive && connectionMode != "local" && mercuryURL && mercuryAccessKey && mercuryChannel && configurationComplete){
				var mercuryPort:String;
				var suffix:String;
				if (isStretchTwoApi()) {
					mercuryPort = "12000";
					suffix = "system/time";// + "?cachefooler="+String(Math.round(Math.random()*10000));
				} else {
					mercuryPort = "8080";
					suffix = "configuration/beacon";// + "?cachefooler="+String(Math.round(Math.random()*10000));
				}
				var req:URLRequest = new URLRequest(mercuryURL + "proxy/access_key/"+mercuryAccessKey+"/channel/"+mercuryChannel+"/port/"+mercuryPort+"/"+suffix);
				//var req:URLRequest = new URLRequest(mercuryURL);
				req.cacheResponse = false;
				req.useCache = false;

				try
				{
					var now:Date = new Date();
					var delayFactor:int = 2;
					var nisName:String;
					nisName = FlexGlobals.topLevelApplication.getMyIPAddress();
					if (nisName.toLowerCase().indexOf("mobile") != -1) {
						delayFactor = 3;
					}
					if (now.time - mercuryMonitorLastResponse.time > delayFactor * mercuryMonitorDelay) {
						connectionMercuryAvailable = false;
						setConnectionMode();
					}
					if (now.time - mercuryMonitorLastResponse.time > mercuryMonitorDelay || mercuryMonitorDelay < 10000) {
						setMercuryMonitorDelay(Math.min(20000, mercuryMonitorDelay + 2000));
					} else {
						setMercuryMonitorDelay(Math.max(10000, mercuryMonitorDelay - 2000));
					}
					req.idleTimeout = mercuryMonitorDelay - 500;
					mercuryMonitor.load(req);
				} 
				catch(error:Error) 
				{
					connectionMercuryAvailable = false;
					setConnectionMode();
				}
			} else {
				if (connectionMode == "local" && mercuryURL && mercuryAccessKey && mercuryChannel && configurationComplete) {
					connectionMercuryAvailable = true;
				} else {
					connectionMercuryAvailable = false;
				}
				setConnectionMode();
			}
		}
		
		protected function setMercuryMonitorDelay(time:Number):void{
			mercuryMonitorDelay = time;
			if (mercuryMonitorTimer) {
				mercuryMonitorTimer.delay = time;
				mercuryMonitorTimer.reset();
				mercuryMonitorTimer.start();
			}
		}
		
		protected function mercuryHttpResponseStatusHandler(event:HTTPStatusEvent):void {
			//trace("HOST mercuryHttpResponseStatusHandler status=" + event.status);
			mercuryMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+mercuryMonitorDelay/1000+"s @ "+mercuryMonitorLastResponse.toTimeString()+" mercuryHttpResponseStatusHandler status=" + event.status);
			var value:Boolean = false;
			var statusArr:Array = new Array(200,202,204,205,206,500);
			if (statusArr.indexOf(event.status) != -1){
				value = true;
				setMercuryMonitorDelay(10000); // 10 sec
			} else {
				value = false;
			}
			mercuryIoErrorCounter = 0;
			lastStatusCodeMercury = event.status;
			connectionMercuryAvailable = value;
			setConnectionMode();
		}
		
		protected function mercuryIoErrorHandler(event:IOErrorEvent):void {
			//trace("HOST mercuryIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			mercuryMonitorLastResponse.time = new Date().time;
			SendIRModel.traceHttpResponse("Host "+typeName+" delay="+mercuryMonitorDelay/1000+"s @ "+mercuryMonitorLastResponse.toTimeString()+" mercuryIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			var nisName:String;
			nisName = FlexGlobals.topLevelApplication.getMyIPAddress();
			if (nisName.toLowerCase().indexOf("mobile") != -1) {
				SendIRModel.traceHttpResponse("HOST: mobile Mercury ioError");
				mercuryIoErrorCounter++;
				if (mercuryIoErrorCounter > 1) {//only set to false the second time
					connectionMercuryAvailable = false;
					mercuryIoErrorCounter = 0;
				}
			} else {
				connectionMercuryAvailable = false;
			}
			setConnectionMode();
		}
		
		protected function startPortalPoller(event:Event=null):void {
			portalMonitorTimer.delay = portalMonitorDelay;
			portalMonitorTimer.removeEventListener(TimerEvent.TIMER,portalPoller);
			portalMonitorTimer.addEventListener(TimerEvent.TIMER,portalPoller);
			portalMonitorTimer.stop();
			portalMonitorTimer.start();
			if (portalMonitor) {
				portalMonitor.removeEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, portalHttpResponseStatusHandler);
				portalMonitor.removeEventListener(IOErrorEvent.IO_ERROR, portalIoErrorHandler);
			}
			portalMonitor = new URLLoader();
			portalMonitor.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, portalHttpResponseStatusHandler);
			//portalMonitor.addEventListener(Event.COMPLETE, portalCompleteHandler);
			portalMonitor.addEventListener(IOErrorEvent.IO_ERROR, portalIoErrorHandler);
			portalMonitorLastResponse = new Date();
		}
		protected function portalPoller(event:TimerEvent):void {
			//use URLLoader, URLMonitor is only port 80
			if (appCurrentlyActive && configurationComplete && fwHasGatewayId()){
				var req:URLRequest = new URLRequest("http://www.google.com");
				req.cacheResponse = false;
				req.useCache = false;

				try
				{
					var now:Date = new Date();
					if (now.time - portalMonitorLastResponse.time > 3 * portalMonitorDelay) {
						connectionPortalAvailable = false;
						setConnectionMode();
					}
					req.idleTimeout = portalMonitorDelay;
					portalMonitor.load(req);
				} 
				catch(error:Error) 
				{
					connectionPortalAvailable = false;
					setConnectionMode();
				}
			} else {
				connectionPortalAvailable = false;
			}
		}
		protected function portalHttpResponseStatusHandler(event:HTTPStatusEvent):void {
			//trace("HOST portalHttpResponseStatusHandler status=" + event.status);
			portalMonitorLastResponse.time = new Date().time;
			//ThermoModel.traceHttpResponse("Host "+typeName+" delay="+portalMonitorDelay/1000+"s @ "+portalMonitorLastResponse.toTimeString()+" portalHttpResponseStatusHandler status=" + event.status);
			var value:Boolean = false;
			var statusArr:Array = new Array(200,202,204,205,206,500);
			if (statusArr.indexOf(event.status) != -1){
				value = true;
			} else {
				value = false;
			}
			connectionPortalAvailable = value;
			setConnectionMode();
		}
		protected function portalIoErrorHandler(event:IOErrorEvent):void {
			//trace("HOST portalIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			portalMonitorLastResponse.time = new Date().time;
			//ThermoModel.traceHttpResponse("Host "+typeName+" delay="+portalMonitorDelay/1000+"s @ "+portalMonitorLastResponse.toTimeString()+" portalIoErrorHandler "+(event ? event.toString()+" data: "+event.target.data : ""));
			var value:Boolean = false;
			connectionPortalAvailable = value;
			setConnectionMode();
		}


		protected function setConnectionMode(event:Event=null):void {
			var connectionModeOld:String = connectionMode;
			var connectionModeNew:String = connectionMode;
			if (useMercuryNow == false && (connectionApAvailable || connectionLocalAvailable)) {
				connectionModeNew = "local";
			} else if (connectionMercuryAvailable) {
				connectionModeNew = "mercury";
			} else if (connectionPortalAvailable) {
				connectionModeNew = "portal";
			} else {
				connectionModeNew = "none";
			}
			if (connectionModeNew != connectionModeOld) {
				connectionMode = connectionModeNew;
				//FlexGlobals.topLevelApplication.changeIcon(new Event("connectionModeChanged"));
				if (!connectionApAvailable) {
					startApPoller();//start or stop
				}
				SendIRModel.traceHttpResponse("Host "+typeName+" setConnectionMode mode from " + connectionModeOld + " to: " + connectionMode);
			}
			// Also update the connection state of the configuration process
			setConnectionState();

			//dispatchEvent(new Event("connectionModeChanged",true));
		}
		
		/** hardwareType of device, set if other than variable 'type'
		 * smile_p1 (type = smile, can have locations only)
		 * smile_s0_loc (has locations, like Smile P1)
		 * smile_so_app (has appliances)
		 * smile_p0_loc (has locations, like Smile P1)
		 * smile_po_app (has appliances) */
		public function get hardwareType():String
		{
			return _hardwareType;
		}

		public function set hardwareType(value:String):void
		{
			setHardwareType(value, "Host set hardwareType "+value);
		}
		
		public function setHardwareType(value:String=null, from:String="Host"):void
		{
			trace("\nHost "+type+" ("+typeName+" "+_codeSmile+") setHardwareType to "+value+(from?" from "+from:""));
			if ((value == null || value == "") && type != null){
				value = type;
			}
			_hardwareType = value;
			switch(_hardwareType){
				case "smile_s0_app":
					type 			= GW_TYPE_STRETCH;
					basicAuthName 	= GW_AUTH_NAME_SMILE;
					typeName 		= PRODUCT_NAME_SMILE;
					typeSpec		= "S0";
					isSmile			= true;
					break;
				case "smile_p0_app":
					type 			= GW_TYPE_STRETCH;
					basicAuthName 	= GW_AUTH_NAME_SMILE;
					typeName 		= PRODUCT_NAME_SMILE;
					typeSpec		= "P0";
					isSmile			= true;
					break;
				case "smile_s0_loc":
					type 			= GW_TYPE_SMILE;
					basicAuthName 	= GW_AUTH_NAME_SMILE;
					typeName 		= PRODUCT_NAME_SMILE;
					typeSpec		= "S0";
					isSmile			= true;
					break;
				case "smile_p0_loc":
					type 			= GW_TYPE_SMILE;
					basicAuthName 	= GW_AUTH_NAME_SMILE;
					typeName 		= PRODUCT_NAME_SMILE;
					typeSpec		= "P0";
					isSmile			= true;
					break;
				case GW_AUTH_NAME_SMILE: // smile
				case GW_TYPE_SMILE: // p1
					type 			= GW_TYPE_SMILE;
					basicAuthName 	= GW_AUTH_NAME_SMILE;
					typeName 		= PRODUCT_NAME_SMILE;
					typeSpec		= "P1";
					isSmile			= true;
					break;
				case GW_TYPE_STRETCH:
					type 			= GW_TYPE_STRETCH;
					basicAuthName 	= GW_AUTH_NAME_STRETCH;
					typeName 		= PRODUCT_NAME_STRETCH;
					isSmile			= false;
					break;
				default:
					type 			= value;
					basicAuthName 	= value;
					typeName		= PRODUCT_NAME_UNKNOWN;
					isSmile			= true;
			}
			trace("Host "+type+" ("+typeName+" "+_codeSmile+") setHardwareType is set to "+_hardwareType+" type="+type+" basicAuthName="+basicAuthName+" isSmile="+isSmile+"\n");
		}
		
		/***
		 * host.type can be: plu (old Smile with appliances), p1, source, stretch
		 **/
		public function get type():String
		{
			return _type;
		}
		
		public function set type(value:String):void
		{
			_type = value;
		}
		
		/** If nullPhase is false, Host is not loaded from shared object, otherwise Host is loaded from within ThermoModel
		 * If initializing at runtime, always use nullPhase = false **/ 
		public function init(type:String, nullPhase:Boolean=true, codeSmile:String=null):void {
			trace("Host init "+type+" nullPhase="+nullPhase+" codeSmile="+codeSmile);
			_type = type;
			_nullPhase = nullPhase;
			_protocol = DEFAULTPROTOCOL;
			_hostIP = null;
			_lanIP = null;
			_useLan = false;
			_wifiIP = null;
			_port = null;
			_authorizationName = null;
			_authorizationPassword = null;
			_licenseKey = null;
			_macAddressWiFi = null;
			_macAddressLan = null;
			_codeSmile = codeSmile;
			_refreshInterval = 5;
			_sharedObject = null;
			_hostXML = null;
			_wifiConfigStep = null;
			_configSetupState = null;
			_dispatchUpdate = true;
			_networkSsid = null;
			_version = null;
			_name = the + " " + PRODUCT_NAME_SMILE;
			_restRoot = "/";
			_configurationComplete = false;
			_typeName = "";
			_mercuryURL = null;
			_mercuryChannel = null;
			_mercuryAccessKey = null;
			_useMercury = false;
			_timeDiff = 0;
			_gatewayUuid = null;
			_licenseUuid = null;
			_setupNetworkVia = null;
			_firmwareUpgradeInProgress = false;
			_lastResetDate = null;
			_licenseCreatedDate = null;
			_firstDataDate = null;
			_gatewayFeatures = null;
			setHardwareType(type, "Host init "+type);
		}
		
		/**
		 * returns true if current host.version >= provided version string  
		 */		
		public function isVersionGreaterThanOrEqualTo(compareVersion:String):Boolean {
			if (version && compareVersion){
				var versionArr:Array = version.split(".");
				var compareVersionArr:Array = compareVersion.split(".");
				if (versionArr.length > 0 && compareVersionArr.length > 0) {
					for (var i:int = 0; i < versionArr.length && i < compareVersionArr.length; i++) 
					{
						if (int(versionArr[i]) > int(compareVersionArr[i])) {
							return true;
						} else if (int(versionArr[i]) < int(compareVersionArr[i])) {
							return false;
						} else if (i + 1 == Math.min(versionArr.length,compareVersionArr.length)) {
							return true;
						}
					}
				}
			}
			return false;
		}
		
		/** Provide true if isStretch AND version is >= 2.0 */ 
		public function isStretchTwoApi():Boolean{
			if (isSmile == false){
				if (version){
					if (isVersionGreaterThanOrEqualTo("2.0.0")){ // if version >= 2.0
						return true
					}
				}
			}
			return false;
		}
		
		/** Provide true if isSmile AND version is >= 1.3 */ 
		public function isSmileWithCore():Boolean{
			if (isSmile){
				if (version){
					var versionArr:Array = version.split(".");
					if (versionArr.length > 0 && ((versionArr[0] == "1" && int(String(versionArr[1]).substr(0,1)) > 2) || int(String(versionArr[0]).substr(0,1)) > 1)){ // if version >= 1.3
						return true
					}
				}
			}
			return false;
		}
		
		/** Provide true if isSmile AND version is > 1.2.8-xcxzfsdf */ 
		public function isSmileWithStatus():Boolean{
			if (isSmile){
				if (version){
					var versionArr:Array = version.split(".");
					if (versionArr.length > 0 && ((versionArr[0] == "1" && int(String(versionArr[1]).substr(0,1)) > 1 && int(String(versionArr[2]).substr(0,1)) > 8) || int(String(versionArr[0]).substr(0,1)) > 1)){ // if version > 1.2.8
						return true
					}
				}
			}
			return false;
		}
		
		
		/**
		 * returns the URL on which to find the Plugwise modules based on type and version (with tailing /)
		 */		
		public function getModulesUrl():String{
			if (isSmileWithCore()){
				return "core/modules/";
			}
			return "modules/";
		}
		
		/**
		 * returns the URL on which to find the smartmeter modules based on type and version 
		 */		
		public function getSmartmeterModulesUrl():String{
			if (isSmileWithCore()){
				return "core/locations";
			}
			return "smartmeter/modules";
		}
		
		/**
		 * returns the URL on which to find the appliances based on type and version 
		 */		
		public function getCoreAppliancesUrl():String{
			if (isSmileWithCore()){ // if version >= 1.3
				return "core/appliances";
			}
			return "appliances";
		}
		
		/**
		 * returns the URL on which to find the gateway based on the type and version 
		 */		
		public function getNetworkMonitorUrl():String{
			if (isSmileWithCore()){
				return NETWORKWMONITORRESTURLSMILE1_3;
			} else if (type == GW_TYPE_SMILE){
				return NETWORKWMONITORRESTURLSMILE;
			}
			if (isStretchTwoApi()) {
				return NETWORKWMONITORRESTURLSTRETCH2_0;
			} else {
				return NETWORKWMONITORRESTURLSTRETCH;
			}
		}
		
		/**
		 * returns false if host.type is Host.GW_TYPE_SMILE AND if host has firmware that has index of SMILE_WITHOUT_GATEWAY_VERSION_CHECK available
		 * returns true otherwise
		 */		
		public function fwHasGatewayId():Boolean {
			if (type == GW_TYPE_SMILE && version && version.indexOf(SMILE_WITHOUT_GATEWAY_VERSION_CHECK) > -1){
				return false;
			}
			return true;
		}
		
		/**
		 * returns false if host.type and version does not have /license option (Stretch has, Smile > 1.1.8 has too)
		 * returns true otherwise
		 */		
		public function fwHasLicenseCall():Boolean {
			if (type == GW_TYPE_SMILE && version){
				var versionNums:Array = version.split(".");
				if (versionNums.length > 2){
					var versionFigure:int = (int(versionNums[0]) * 100 + int(versionNums[1]) * 10 + int(versionNums[2]))
					if (versionFigure > 118)	return true;  // Smile version > 1.1.8		
				}
				return false;
			}
			return true;
		}
		
		/**
		 * returns false if host.type and version does not have /status/xml option (Stretch has, Smile > 1.2.8 has too)
		 * returns true otherwise
		 */		
		public function fwHasStatusCall():Boolean {
			if (isSmileWithStatus()){
				return true;  // Smile version > 1.2.8 	
			} else if (type == GW_TYPE_SMILE){
				return false;
			}
			return true;
		}
		
		/**
		 * returns true if host has Mercury that is able to be switched off and renewed (Stretch > 1.0.41 has this)
		 * returns true otherwise
		 */		
		public function fwHasMercury():Boolean {
			//return true;//delete this line for production
			if (isSmile == false && type == GW_TYPE_STRETCH && version){
				if (gatewayFeatures && gatewayFeatures.length > 0){
					if (featureActive(Feature.FEATURE_MERCURY) && isVersionGreaterThanOrEqualTo(STRETCH_WITH_MERCURY_SETTINGS_CHECK.join("."))) {
						return true;
					}
				} else if (gatewayFeatures == null){ // no features, accept mercury
					return true;
				}
				return false;
			}
			return false;
		}

		/**
		 * returns true if host has data subscription, or if no features are available
		 */		
		public function get hasValidDataSubscription():Boolean {
			if (gatewayFeatures && gatewayFeatures.length > 0){
				if (featureActive(Feature.FEATURE_DATA_SUBSCRIPTION)) {
					return true;
				}
				return false;
			}
			return true;
		}
		
		/**  Check if feature is present and not expired */
		public function featureActive(featureName:String):Boolean
		{
			for each (var fea:XML in gatewayFeatures){
				var feature:Feature = new Feature(fea);
				if (feature.type == featureName){
					if (feature.is_active){
						trace("Host "+typeName+" "+(hostConfiguration?"(config) ":"")+"featureActive "+featureName+" is active and still active for "+feature.days_to_expiry.toFixed(1)+"days")
						return true;
					}
				}
			}
			return false;
		}
		
		/**
		 * returns true if lanIP is not empty and useLan == false
		 */		
		public function get lanConfiguration():Boolean {
			/*if (hostIP && hostIP == lanIP && (!wifiIP || wifiIP == DEFAULTWIFIIPADDRESS)) {
			return true;
			}*/
			if (state() == STATE_LAN_CONFIGURATION) {
				return true;
			}
			return false;
		}
		
		/**
		 * returns true if ip address is set and the cable is connected
		 */		
		public function lanConnection():Boolean {
			if (hostIP && hostIP == lanIP) {
				return true;
			}
			return false;
		}
		
		/** Return the state of preferred connection solely based on IP address
		 * STATE_NO_CONNECTION
		 * STATE_WIFI_ACCESS_POINT
		 * STATE_WIFI_USAGE
		 * STATE_LAN_USAGE 
		 * STATE_LAN_CONFIGURATION (both LAN and WiFi active */ 
		public function state():String {
			if (!lanIP && !wifiIP) {
				return STATE_NO_CONNECTION;
			} else if (!lanIP && (wifiIP && wifiIP == DEFAULTWIFIIPADDRESS)) {
				return STATE_WIFI_ACCESS_POINT;
			} else if (!lanIP && (wifiIP && wifiIP != DEFAULTWIFIIPADDRESS)) {
				//} else if ((!lanIP || !useLan) && (wifiIP && wifiIP != DEFAULTWIFIIPADDRESS)) {
				return STATE_WIFI_USAGE;
			} else if (lanIP && useLan) {
				return STATE_LAN_USAGE;
			} else if (lanIP && !wifiIP) {
				return STATE_LAN_USAGE;
			} else if (lanIP && wifiIP) {
				return STATE_LAN_CONFIGURATION;
			}
			return STATE_NO_CONNECTION;
		}
		
		/** Always up to date ip address where to reach host at
		 * If useMercury == true and mercury url, channel and access key are set, use mercury (via port 8080).
		 * If useMercury == false, optionally provide:
		 * - port (only as a numeric string i.e.: 12000, 80, etc.), default: host.port is used
		 * - suffix (string to put behind url/) */
		public function hostURL(tempPort:String=null, suffix:String=""):String
		{
			var usePort:String;
			usePort = tempPort ? tempPort : port ? port == "80" ? null : port : null;
			
			if (connectionMode == "mercury" && mercuryURL){
				var mercuryPort:String = "8080";
				if (isStretchTwoApi()) {
					mercuryPort = "12000";
				}
				return mercuryURL + "proxy/access_key/"+mercuryAccessKey+"/channel/"+mercuryChannel+"/port/"+mercuryPort+"/"+suffix;
				
			} else if (usePort != null && hostIP) {
				var tempHostIp:String = hostIP;
				var firstSlashIndex:int = tempHostIp.indexOf("/");
				if (firstSlashIndex > -1){
					tempHostIp = tempHostIp.replace("/", ":" + usePort + "/"); // place port before first slash
				} else {
					tempHostIp = hostIP + ":" + usePort;
				}
				return protocol + tempHostIp + restRoot + suffix;
				
			} else if (hostIP) {
				return protocol + hostIP + restRoot + suffix;
			} else {
				return null;
			}
		}
		
		public function getUrlRequest(ip:String=null, restUrl:String=null, addHeaders:Boolean=true):URLRequest{
			var urlReq:URLRequest;
			if (ip == null && restUrl){
				urlReq = new URLRequest(hostURL(port) + restUrl);
				//trace("Host getUrlRequest provided, urlReq.url="+(urlReq?urlReq.url:"null")+", basicAuthorizationString()="+basicAuthorizationString());
			} else if (ip && restUrl){
				urlReq = new URLRequest(getURL(ip) + restUrl);
				//trace("Host getUrlRequest provided, ip="+ip+", restUrl="+restUrl+", basicAuthorizationString()="+basicAuthorizationString());
			} else if (ip && !restUrl) {
				urlReq = new URLRequest(getURL(ip));
			}
			if (addHeaders && basicAuthorizationString()){
				var header1:URLRequestHeader = new URLRequestHeader("AUTHORIZATION", basicAuthorizationString());
				urlReq.requestHeaders.push(header1);
				var header2:URLRequestHeader = new URLRequestHeader("connection", "close");
				urlReq.requestHeaders.push(header2);
				var header3:URLRequestHeader = new URLRequestHeader("x-connection-override", "close"); // for Stretch/Smile REST that leaves connection open by default
				urlReq.requestHeaders.push(header3);
			} else if (addHeaders == false){
				//trace("Host getUrlRequest returned urlReq.url="+(urlReq?urlReq.url:"urlReq == null"));
				return urlReq;
			} else {
				return null;
			}
			//trace("Host getUrlRequest returned urlReq.url="+(urlReq?urlReq.url:"urlReq == null"));
			return urlReq;
		}
		
		public function getURL(ip:String):String
		{
			if (port) {
				return protocol + ip + ":" + port;
			} else {
				return protocol + ip;
				
			}
		}
		
		public function basicAuthorizationString():String{
			if (basicAuthName && basicAuthPassword){
				//trace("Host basicAuthorizationString basicAuthName="+basicAuthName+", basicAuthPassword="+basicAuthPassword);
				var encoder:Base64Encoder = new Base64Encoder();
				encoder.insertNewLines = false;
				encoder.encode(basicAuthName + ":" + basicAuthPassword);
				return "Basic " + encoder.toString();
			}
			trace("Host "+typeName+" "+(hostConfiguration?"(config) ":"")+"NO basicAuthorizationString -> basicAuthName="+basicAuthName+", basicAuthPassword="+basicAuthPassword);
			return null;
		}
		
		public function traceVars(inline:Boolean=false, includeCode:Boolean=true):String {
			var toret:String = "Host traceVars - variables: \n";
			var newLine:String = "\n";
			if (inline) newLine = " ";
			toret += "typeName:        " + _typeName + (includeCode ? " (" + _codeSmile + ")" : "") + newLine;
			toret += "hardwareType:    " + _hardwareType + newLine;
			toret += "version:           " + _version + newLine;
			toret += "state:           " + state() + newLine;
			toret += "connected:       " + _connected + newLine;
			toret += "connectionState: " + _connectionState + newLine;
			toret += "configSetupState:" + _configSetupState + newLine;
			toret += "configComplete:  " + _configurationComplete.toString() + newLine;
			toret += "dispatchUpdate:  " + _dispatchUpdate.toString() + newLine;
			toret += "useLan:          " + _useLan.toString() + newLine;
			toret += "lanConnection:   " + lanConnection().toString() + newLine;
			toret += "usingWifi:       " + _usingWifi.toString() + newLine;
			toret += "lanIp:           " + _lanIP + newLine;
			toret += "wifiIP:          " + _wifiIP + newLine;
			toret += "hostIP:          " + _hostIP + newLine;
			toret += "hostURL:         " + hostURL() + newLine;
			toret += "useMercury:      " + _useMercury.toString() + newLine;
			toret += "setupNetwrkVia:  " + _setupNetworkVia + newLine;
			toret += "fwUpgradeInProgr:" + _firmwareUpgradeInProgress + newLine;
			//toret += "myIPAddress:   " + ThermoModel.myIPAddress + newLine;
			//toret += "conToStrP1APNw:" + ThermoModel.connectedToStretchP1APNetwork + newLine;
			
			if (_codeSmile == null && _basicAuthPassword != null){
				// debug
				var temp:String;
			}
			
			if (inline){ 
				var spacePattern:RegExp = /  /g;
				toret = toret.replace(spacePattern,"");
			}
			return toret;
		}
		
		public function initConnections():void {
			connectedLan = false;
			connectedWifi = false;
			//connectedWifiAP = false;
		}
		
		/**
		 * WiFi access point address: protocol + DEFAULTWIFIIPADDRESS + ":" + port + restRoot
		 */
		public function hostWifiApURL():String
		{
			if (port){
				return protocol + DEFAULTWIFIIPADDRESS + ":" + port + restRoot;
			} else {
				return protocol + DEFAULTWIFIIPADDRESS + restRoot;
			}
		}
		
		/** Variable that should be set to true if configuration should use lan as connection, of false if gateway should try to find WiFi ip in configuration */
		public function get useLan():Boolean
		{
			return _useLan;
		}
		
		public function set useLan(value:Boolean):void
		{
			_useLan = value;
		}
		
		/**
		 * if nullPhase == true load host data from sharedObject, otherwise save to sharedObject
		 * */
		public function get nullPhase():Boolean
		{
			return _nullPhase;
		}
		
		public function set nullPhase(value:Boolean):void
		{
			_nullPhase = value;
		}
		
		public function get codeSmile():String
		{
			return _codeSmile;
		}
		
		public function set codeSmile(value:String):void
		{
			trace("Host "+type+" (typeName="+typeName+") setting codeSmile from "+_codeSmile+" to "+value);
			if (value != _codeSmile && value != null && nullPhase == false){
				init(type, nullPhase, value);
			}
			if (value) startApPoller();
			_codeSmile = value;
		}
		
		/** Amount of seconds to next refresh */
		public function get refreshInterval():Number
		{
			return _refreshInterval;
		}
		
		public function set refreshInterval(value:Number):void
		{
			_refreshInterval = value;
		}
		
		public function get macAddressWiFi():String
		{
			return _macAddressWiFi;
		}
		
		public function set macAddressWiFi(value:String):void
		{
			_macAddressWiFi = value;
		}
		
		public function get macAddressLan():String
		{
			return _macAddressLan;
		}
		
		public function set macAddressLan(value:String):void
		{
			_macAddressLan = value;
		}
		
		public function get licenseKey():String
		{
			return _licenseKey;
		}
		
		public function set licenseKey(value:String):void
		{
			_licenseKey = value;
		}
		
		/** Source webserver password */
		public function get authorizationPassword():String
		{
			return _authorizationPassword;
		}
		
		public function set authorizationPassword(value:String):void
		{
			_authorizationPassword = value;
		}
		
		public function get authorizationName():String
		{
			return _authorizationName;
		}
		
		public function set authorizationName(value:String):void
		{
			_authorizationName = value;
		}
		
		/**
		 * if wifiIp == null, hostWifiURL will be filled with DEFAULTWIFIIPADDRESS
		 * rest is same as hostURL
		 */
		public function get hostWifiURL():String
		{
			var tempHostIp:String = wifiIP;
			if (tempHostIp == null){
				tempHostIp = DEFAULTWIFIIPADDRESS;
			}
			if (port != null) {
				var firstSlashIndex:int = tempHostIp.indexOf("/");
				if (firstSlashIndex > -1){
					tempHostIp = tempHostIp.replace("/", ":" + port + "/"); // place port before first slash
				} else {
					tempHostIp = wifiIP + ":" + port;
				}
				return protocol + tempHostIp + restRoot;
			} else {
				return protocol + tempHostIp + restRoot;
			}
		}
		
		public function get protocol():String
		{
			return _protocol;
		}
		
		public function set protocol(value:String):void
		{
			_protocol = value;
		}
		
		public function get usingWifi():Boolean
		{
			if (!lanIP && useLan == false && wifiIP && wifiIP != DEFAULTWIFIIPADDRESS) {
				return true;
			} else {
				return false;
			}
			//return _hostIP;
		}
		/**
		 * if usingWifi -> wifiIP
		 * if !lanIP && wifiIP && wifiIP == DEFAULTWIFIIPADDRESS -> DEFAULTWIFIIPADDRESS
		 * else -> lanIP is set; the network cable is connected
		 */
		[Bindable(event="hostIPChanged")]
		public function get hostIP():String
		{
			if (usingWifi && wifiIP) {
				//hostIP = wifiIP;
				return wifiIP;
			} else if (!lanIP && wifiIP && wifiIP == DEFAULTWIFIIPADDRESS) {
				return DEFAULTWIFIIPADDRESS;
				//hostIP = DEFAULTWIFIIPADDRESS;
			} else if (lanIP){
				return lanIP;
				//hostIP = lanIP;
			}
			trace("Host "+type+" (typeName="+typeName+" "+codeSmile+") hostIP = null!!");
			//hostIP = null;
			return null;
			//return _hostIP;
		}
		
		public function set hostIP(value:String):void
		{
			if (_hostIP != value) {
				_hostIP = value;
				var e:Event = new Event("hostIPChanged");
				dispatchEvent(e);
			}
		}
		
		[Bindable(event="lanIPChanged")]
		public function get lanIP():String
		{
			return _lanIP;
		}
		
		public function set lanIP(value:String):void
		{
			if (_lanIP != value) {
				_lanIP = value;
				var e:Event = new Event("lanIPChanged");
				dispatchEvent(e);
			}
		}
		
		[Bindable(event="wifiIPChanged")]
		public function get wifiIP():String
		{
			return _wifiIP;
		}
		
		public function set wifiIP(value:String):void
		{
			if (_wifiIP != value) {
				_wifiIP = value;
				var e:Event = new Event("wifiIPChanged");
				dispatchEvent(e);
			}
		}
		
		public function get port():String
		{
			return _port;
		}
		
		public function set port(value:String):void
		{
			_port = value;
		}
		
		public function get sharedObject():SharedObject
		{
			return _sharedObject;
		}
		
		public function set sharedObject(value:SharedObject):void
		{
			_sharedObject = value;
		}
		
		public function get hostXML():XML
		{
			return _hostXML;
		}
		
		public function set hostXML(value:XML):void
		{
			_hostXML = value;
		}
		
		public function get wifiConfigStep():String
		{
			return _wifiConfigStep;
		}
		
		public function set wifiConfigStep(value:String):void
		{
			_wifiConfigStep = value;
		}
		
		public function get configSetupState():String
		{
			return _configSetupState;
		}
		
		public function set configSetupState(value:String):void
		{
			_configSetupState = value;
		}
		
		public function get dispatchUpdate():Boolean
		{
			return _dispatchUpdate;
		}
		
		public function set dispatchUpdate(value:Boolean):void
		{
			_dispatchUpdate = value;
		}
		
		public function get networkSsid():String
		{
			if (_networkSsid) {
				return _networkSsid;
			} else {
				return yourNetwork;
			}
		}
		
		public function set networkSsid(value:String):void
		{
			_networkSsid = value;
		}
		
		//[Bindable(event="versionChanged")]
		public function get version():String
		{
			return _version;
		}
		
		public function set version(value:String):void
		{
			if (value == null){
				// do nothing
				var checkError:Boolean;
			} else if (_version != value){
				//lastVersion = _version;
				_version = value;
				/*if (value) {
					var e:Event = new Event("versionChanged");
					dispatchEvent(e);
				}*/
			}
		}
		
		/**
		 * Device name incl. localozed lidwoord i.e.: 'het apparaat', 'de Stretch'
		 */
		public function get name():String
		{
			if (isSmile){
				return the + " " +PRODUCT_NAME_SMILE;
			}
			switch(type){
				case "plu":
				case GW_TYPE_STRETCH:
					return the + " " +PRODUCT_NAME_STRETCH;
				case GW_TYPE_SMILE:
					return the + " " +PRODUCT_NAME_SMILE;
				case "source":
					return PRODUCT_NAME_SOURCE;
				default:
					return PRODUCT_NAME_UNKNOWN;
			}
		}
		
		public function set name(value:String):void
		{
			_name = value;
		}
		
		public function get restRoot():String
		{
			return _restRoot;
		}
		
		public function set restRoot(value:String):void
		{
			_restRoot = value;
		}
		
		[Bindable(event="configurationCompleteChanged")]
		public function get configurationComplete():Boolean
		{
			if (_configurationComplete){
				hostConfiguration = false;
			} 
			return _configurationComplete;
		}
		
		public function set configurationComplete(value:Boolean):void
		{
			if (_configurationComplete != value) {
				_configurationComplete = value;
				dispatchEvent(new Event("configurationCompleteChanged"));
			}
			// if a code Smile available, start access point poller (define in function startApPoller if timer should start or stop, based on configurationComplete)
			
		}
		
		public function get typeName():String
		{
			if (_typeName == null || _typeName == "" ||  _typeName == PRODUCT_NAME_UNKNOWN){
				switch(type){
					case "plu":
					case GW_TYPE_STRETCH:
						_typeName = PRODUCT_NAME_STRETCH;
						break;
					case GW_TYPE_SMILE:
						_typeName = PRODUCT_NAME_SMILE;
						break;
					case GW_TYPE_SOURCE:
						_typeName = PRODUCT_NAME_SOURCE;
						break;
					default:
						trace("\n\nHost PRODUCT_NAME_UNKNOWN: "+type+"\n\n");
						_typeName = PRODUCT_NAME_UNKNOWN;
				}
			}
			return _typeName;
		}
		
		public function set typeName(value:String):void
		{
			_typeName = value;
		}
		
		/** URL from Mercury server (from PortalModel) */
		[Bindable(event="mercuryURLChanged")]
		public function get mercuryURL():String
		{
			return _mercuryURL;
		}
		
		public function set mercuryURL(value:String):void
		{
			if (_mercuryURL != value) {
				_mercuryURL = value;
				dispatchEvent(new Event("mercuryURLChanged"));
			}
		}
		
		/** Channel for mercury connection
		 * If device has no connection to hostIp, use this to connect */
		[Bindable(event="mercuryChannelChanged")]
		public function get mercuryChannel():String
		{
			return _mercuryChannel;
		}
		
		public function set mercuryChannel(value:String):void
		{
			if (_mercuryChannel != value) {
				_mercuryChannel = value;
				dispatchEvent(new Event("mercuryChannelChanged"));
			}
		}
		
		/** Access key for mercury connection */
		[Bindable(event="mercuryAccessKeyChanged")]
		public function get mercuryAccessKey():String
		{
			return _mercuryAccessKey;
		}
		
		public function set mercuryAccessKey(value:String):void
		{
			if (_mercuryAccessKey != value) {
				_mercuryAccessKey = value;
				dispatchEvent(new Event("mercuryAccessKeyChanged"));
			}
		}
		
		/** If true, use mercury in stead of direct ip connection */
		public function get useMercury():Boolean
		{
			return _useMercury;
		}
		
		public function set useMercury(value:Boolean):void
		{
			if (!value && !connectionLocalAvailable && connectionMercuryAvailable) {
				_useMercury = true;
			} else {
				_useMercury = value;
			}
			SendIRModel.traceHttpResponse("useMercury set to: " + value);
		}
		
		/** miliseconds of time difference between app and host (appNowDate.time - hostNowDate.time)
		 * Substract this value from the current app time to compare with host time */
		public function get timeDiff():Number
		{
			return _timeDiff;
		}
		
		public function set timeDiff(value:Number):void
		{
			_timeDiff = value;
		}
		
		/** UUID of the gateway (Smile/Stretch) on the ODS/DWH portal */
		public function get gatewayUuid():String
		{
			return _gatewayUuid;
		}
		
		public function set gatewayUuid(value:String):void
		{
			_gatewayUuid = value;
		}
		
		/** Basic authorization gateway password */
		public function get basicAuthName():String
		{
			if (_basicAuthName == null) _basicAuthName = typeName.toLowerCase();
			return _basicAuthName;
		}
		
		public function set basicAuthName(value:String):void
		{
			_basicAuthName = value;
		}
		
		public function get basicAuthPassword():String
		{
			if (_basicAuthPassword == null || _basicAuthPassword == "" || _basicAuthPassword != codeSmile){
				_basicAuthPassword = codeSmile;
			}
			return _basicAuthPassword; 
		}
		
		public function set basicAuthPassword(value:String):void
		{
			_basicAuthPassword = value;
		}
		
		/** UUID of the license on the ODS/DWH portal */
		public function get licenseUuid():String
		{
			return _licenseUuid;
		}
		
		public function set licenseUuid(value:String):void
		{
			_licenseUuid = value;
		}
		
		public function get lastBeaconDownload():Date
		{
			return _lastBeaconDownload;
		}
		
		public function set lastBeaconDownload(value:Date):void
		{
			_lastBeaconDownload = value;
		}
		
		public function get lastBeaconUpload():Date
		{
			return _lastBeaconUpload;
		}
		
		public function set lastBeaconUpload(value:Date):void
		{
			_lastBeaconUpload = value;
		}
		
		public function getBeaconTimeOutSecs():Number{
			if (lastBeaconUpload){
				var now:Date = new Date();
				return Math.max(0, ((now.time - timeDiff) - lastBeaconUpload.time)/1000);
			}
			return 0;
		}
		
		[Bindable(event="connectionStateChanged")]
		public function get connectionState():String
		{
			
			return _connectionState;
		}
		
		public function set connectionState(value:String):void
		{
			if (_connectionState != value){
				_connectionState = value;
				var e:Event = new Event("connectionStateChanged");
				dispatchEvent(e);
			}
		}
		
		public function get connectedLan():Boolean
		{
			return _connectedLan;
		}
		
		public function set connectedLan(value:Boolean):void
		{
			_connectedLan = value;
			//setConnectionState();
		}
		
		public function get connectedWifi():Boolean
		{
			return _connectedWifi;
		}
		
		public function set connectedWifi(value:Boolean):void
		{
			_connectedWifi = value;
			//setConnectionState();
		}
		
		protected function setConnectionState():void {
			var tempConnectionState:String = connectionState;
			if ((connectionLocalAvailable || connectionMercuryAvailable) && state() == STATE_LAN_USAGE && connectionApAvailable) {
				connectionState = "LAN+WIFIAP";
				connectedLan = true;
				connectedWifi = false;
				connected = true;
			} else if ((connectionLocalAvailable || connectionMercuryAvailable) && connectionApAvailable) {
				connectionState = "LAN+WIFI+WIFIAP";
				connectedLan = true;
				connectedWifi = true;
				connected = true;
			} else if (connectionApAvailable) {
				connectionState = "WIFIAP";
				connectedLan = false;
				connectedWifi = false;
				connected = true;
			} else if ((connectionLocalAvailable || connectionMercuryAvailable) && state() == STATE_LAN_USAGE) {
				connectionState = "LAN";
				connectedLan = true;
				connectedWifi = false;
				connected = true;
			} else if ((connectionLocalAvailable || connectionMercuryAvailable) && state() == STATE_WIFI_USAGE) {
				connectionState = "WIFI";
				connectedLan = false;
				connectedWifi = true;
				connected = true;
			} else if ((connectionLocalAvailable || connectionMercuryAvailable) && state() == STATE_LAN_CONFIGURATION) {
				connectionState = "LAN+WIFI";
				connectedLan = true;
				connectedWifi = true;
				connected = true;
			} else {
				if (!connectionLocalAvailable && !connectionMercuryAvailable) {
					connectionState = "NO";
					connectedLan = false;
					connectedWifi = false;
					connected = false;
				} else {
					// do not change current connection
				}
			}
			if (connectedWifi){
				if (connectionApAvailable) {
					_connectedWifiNotAP = false;
				} else {
					_connectedWifiNotAP = true;
				}
			}
			if (tempConnectionState != connectionState){
				trace("Host "+typeName+" "+(hostConfiguration?"(config) ":"")+"setConnectionState changed to: " + connectionState + " connected="+connected);
			}
		}
		
		/** Runtime variable to check if there is a (live) connection available for this host
		 * can be set by monitor */
		[Bindable(event="connectedChanged")]
		public function get connected():Boolean
		{
			if (type == GW_TYPE_STRETCH && configurationComplete) {
				return (connectionLocalAvailable || connectionMercuryAvailable);
			} else {
				return _connected;
			}
		}
		
		/**
		 * @private
		 */
		public function set connected(value:Boolean):void
		{
			/*if (!value && (connectionLocalAvailable || connectionMercuryAvailable)) {
				value = true;
			}*/
			if (_connected != value){
				trace("Host "+typeName+" "+(hostConfiguration?"(config) ":"")+"connected set to: " + value);
				if (value == false){
					trace("Stop for debugging");
					var x:String="stop";
				}
				_connected = value;
				SendIRModel.traceHttpResponse("Host "+typeName+" connected set to: " + value);
				var e:Event = new Event("connectedChanged");
				dispatchEvent(e);
			}
		}
		
		/** Variable used for setting how to set up Host
		 * Values can be: lan, wifi, wifiap **/
		public function get setupNetworkVia():String
		{
			return _setupNetworkVia;
		}
		
		public function set setupNetworkVia(value:String):void
		{
			_setupNetworkVia = value;
			if (value == "lan" || value == "wifi"){
				useLan = true;
			} else if (value == "wifiap"){
				useLan = false;
			}
		}
		
		public function get connectionMonitorRefreshInterval():Number
		{
			return _connectionMonitorRefreshInterval;
		}
		
		public function set connectionMonitorRefreshInterval(value:Number):void
		{
			_connectionMonitorRefreshInterval = value;
		}
		
		/** Boolean to tell that feedback still has to be given on the firmware upgrade process */
		public function get firmwareUpgradeInProgress():Boolean
		{
			return _firmwareUpgradeInProgress;
		}
		
		/**
		 * @private
		 */
		public function set firmwareUpgradeInProgress(value:Boolean):void
		{
			_firmwareUpgradeInProgress = value;
		}
		
		public function get connectedWifiNotAP():Boolean
		{
			return _connectedWifiNotAP;
		}
		
		public function set connectedWifiNotAP(value:Boolean):void
		{
			_connectedWifiNotAP = value;
		}
		
		public function get lastResetDate():Date
		{
			return _lastResetDate;
		}
		
		public function set lastResetDate(value:Date):void
		{
			_lastResetDate = value;
		}
		
		public function get licenseCreatedDate():Date
		{
			if (_licenseCreatedDate == null) _licenseCreatedDate = new Date(2010,0,1);
			return _licenseCreatedDate;
		}
		
		public function set licenseCreatedDate(value:Date):void
		{
			_licenseCreatedDate = value;
		}
		
		/** true if mercuryAccessKey and mercuryChannel != null 
		 * Set to false to initialize mercuryAccessKey, mercuryChannel, mercuryURL */
		public function get mercuryEnabled():Boolean
		{
			if (mercuryAccessKey && mercuryChannel){
				_mercuryEnabled = true
			} else {
				_mercuryEnabled = false;
			}
			return _mercuryEnabled;
		}
		
		/** Set to false to initialize mercuryAccessKey, mercuryChannel, mercuryURL */
		public function set mercuryEnabled(value:Boolean):void
		{
			if (value == false){ // initialize Mercury
				_mercuryAccessKey= null;
				_mercuryChannel	 = null;
			}
			_mercuryEnabled = value;
		}
		
		public function get gatewayFeatures():XMLListCollection
		{
			return _gatewayFeatures;
		}
		
		public function set gatewayFeatures(value:XMLListCollection):void
		{
			_gatewayFeatures = value;
		}
		
		public function get firstDataDate():Date
		{
			if (_firstDataDate == null) _firstDataDate = new Date(2012,0,1);
			return _firstDataDate;
		}
		
		public function set firstDataDate(value:Date):void
		{
			_firstDataDate = value;
		}

		/** Runtime variable to contain status XML got from system/status/xml */
		public function get license():XML
		{
			return _license;
		}

		/**
		 * @private
		 */
		public function set license(value:XML):void
		{
			_license = value;
		}

		public function get htmlApiNameSpace():String
		{
			if (isStretchTwoApi()) {
				return "";
			} else {
				return _htmlApiNameSpace;
			}
		}

		public function set htmlApiNameSpace(value:String):void
		{
			_htmlApiNameSpace = value;
		}

		/** contains: none, local, mercury or portal	 */
		[Bindable(event="connectionModeChanged")]
		public function get connectionMode():String
		{
			return _connectionMode;
		}

		/**
		 * @private
		 */
		public function set connectionMode(value:String):void
		{
			if (_connectionMode != value){
				_connectionMode = value;
				var e:Event = new Event("connectionModeChanged", true);
				dispatchEvent(e);
			}
		}

		//[Bindable(event="connectionModeChanged")]
		/** true is a direct connection to this host is available */
		public function get connectionLocalAvailable():Boolean
		{
			return _connectionLocalAvailable;
		}
		public function set connectionLocalAvailable(value:Boolean):void
		{
			if (_connectionLocalAvailable != value){
				_connectionLocalAvailable = value;
				/*var e:Event = new Event("connectionModeChanged", true);
				dispatchEvent(e);*/
			}
		}

		//[Bindable(event="connectionMercuryAvailableChanged")]
		public function get connectionMercuryAvailable():Boolean
		{
			return _connectionMercuryAvailable;
		}
		public function set connectionMercuryAvailable(value:Boolean):void
		{
			if (_connectionMercuryAvailable != value){
				_connectionMercuryAvailable = value;
				/*var e:Event = new Event("connectionMercuryAvailableChanged", true);
				dispatchEvent(e);*/
			}
		}

		//[Bindable(event="connectionModeChanged")]
		public function get connectionPortalAvailable():Boolean
		{
			return _connectionPortalAvailable;
		}
		public function set connectionPortalAvailable(value:Boolean):void
		{
			if (_connectionPortalAvailable != value){
				_connectionPortalAvailable = value;
				/*var e:Event = new Event("connectionModeChanged", true);
				dispatchEvent(e);*/
			}
		}

		public function get connectionApAvailable():Boolean
		{
			return _connectionApAvailable;
		}

		public function set connectionApAvailable(value:Boolean):void
		{
			if (_connectionApAvailable != value){
				_connectionApAvailable = value;
			}
			//connectedWifiAP = _connectionApAvailable;
		}

		public function get irCommands():ArrayCollection
		{
			return _irCommands;
		}

		public function set irCommands(value:ArrayCollection):void
		{
			_irCommands = value;
		}

		public function get label():String
		{
			return _label;
		}

		public function set label(value:String):void
		{
			_label = value;
		}

		public function get scheduleCollection():ArrayCollection
		{
			return _scheduleCollection;
		}

		public function set scheduleCollection(value:ArrayCollection):void
		{
			_scheduleCollection = value;
		}

		public function get useLed():String
		{
			return _useLed;
		}

		public function set useLed(value:String):void
		{
			_useLed = value;
		}

		public function get brand():String
		{
			return _brand;
		}

		public function set brand(value:String):void
		{
			_brand = value;
		}

		public function get model():String
		{
			return _model;
		}

		public function set model(value:String):void
		{
			_model = value;
		}
		
		
	}
}