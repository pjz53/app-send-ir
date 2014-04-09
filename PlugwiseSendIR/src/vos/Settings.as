package vos
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	import mx.collections.ArrayCollection;
	
	[Bindable]
	public class Settings extends EventDispatcher implements IExternalizable
	{
		
		private var _appUUID:String;
		private var _registeredAppOnPortal:Boolean;
		private var _introExplanationSeen:Boolean;
		private var _version:String;
		private var _language:String;
		private var _savedState:String;
		private var _presetCollection:ArrayCollection;
		private var _scheduleCollection:ArrayCollection;
		private var _gatewaysCollection:ArrayCollection;
		private var _hostIp:String;
		private var _useCloudBackground:Boolean;
		private var _savingsProfileIndex:int = 1;
		private var _selectedScenarioIndex:int = 1;
		
		private var _weekGetUpTime:int = 7 * 60 * 60 * 1000;
		private var _weekWorkFromTime:int = 9 * 60 * 60 * 1000;
		private var _weekWorkToTime:int = 18 * 60 * 60 * 1000;
		private var _weekSleepFromTime:int = 23 * 60 * 60 * 1000;
		private var _weekendGetUpTime:int = 9 * 60 * 60 * 1000;
		private var _weekendSleepFromTime:int = 0 * 60 * 60 * 1000;
		
		private var _weekGetUpTemp:Number = 18;
		private var _weekWorkFromTemp:Number = 16;
		private var _weekWorkToTemp:Number = 20;
		private var _weekSleepFromTemp:Number = 14;
		private var _weekendGetUpTemp:Number = 22;
		private var _weekendSleepFromTemp:Number = 15;
		
		public function Settings(
			appUUID:String="",
			registeredAppOnPortal:Boolean=false,
			version:String="",
			language:String="",
			savedState:String="",
			presetCollection:ArrayCollection=null,
			scheduleCollection:ArrayCollection=null,
			gatewaysCollection:ArrayCollection=null,
			introExplanationSeen:Boolean=false,
			hostIp:String="",
			useCloudBackground:Boolean=false,
			savingsProfileIndex:int=1,
			selectedScenarioIndex:int=1
		) {
			_appUUID = appUUID;
			_registeredAppOnPortal = registeredAppOnPortal;
			_version = version;
			_language = language;
			_savedState = savedState;
			_presetCollection = presetCollection;
			_scheduleCollection = scheduleCollection;
			_gatewaysCollection = gatewaysCollection;
			_introExplanationSeen = introExplanationSeen;
			_hostIp = hostIp;
			_useCloudBackground = useCloudBackground;
			_savingsProfileIndex = savingsProfileIndex;
			_selectedScenarioIndex = selectedScenarioIndex;
		}
		
		public function writeExternal(output:IDataOutput):void {
			
			output.writeUTF(appUUID);
			output.writeBoolean(registeredAppOnPortal);
			output.writeUTF(version);
			output.writeUTF(language);
			output.writeUTF(savedState);
			output.writeObject(presetCollection);
			output.writeObject(scheduleCollection);
			output.writeObject(gatewaysCollection);
			output.writeBoolean(introExplanationSeen);
			output.writeUTF(hostIp);
			
			output.writeInt(weekGetUpTime);
			output.writeInt(weekWorkFromTime);
			output.writeInt(weekWorkToTime);
			output.writeInt(weekSleepFromTime);
			output.writeInt(weekendGetUpTime);
			output.writeInt(weekendSleepFromTime);
			
			output.writeInt(weekGetUpTemp);
			output.writeInt(weekWorkFromTemp);
			output.writeInt(weekWorkToTemp);
			output.writeInt(weekSleepFromTemp);
			output.writeInt(weekendGetUpTemp);
			output.writeInt(weekendSleepFromTemp);

			//output.writeBoolean(useCloudBackground);
			//output.writeInt(savingsProfileIndex);
			//output.writeInt(selectedScenarioIndex);
		}
		
		public function readExternal(input:IDataInput):void {
			
			try
			{
				appUUID = input.readUTF();
				registeredAppOnPortal = input.readBoolean();
				version = input.readUTF();
				language = input.readUTF();
				savedState = input.readUTF();
				presetCollection = input.readObject();
				var tempScheduleCollection:ArrayCollection;
				tempScheduleCollection = input.readObject();
				gatewaysCollection = input.readObject();
				introExplanationSeen = input.readBoolean();
				hostIp = input.readUTF();
				
				weekGetUpTime = input.readInt();
				weekWorkFromTime = input.readInt();
				weekWorkToTime = input.readInt();
				weekSleepFromTime = input.readInt();
				weekendGetUpTime = input.readInt();
				weekendSleepFromTime = input.readInt();
				
				weekGetUpTemp = input.readInt();
				weekWorkFromTemp = input.readInt();
				weekWorkToTemp = input.readInt();
				weekSleepFromTemp = input.readInt();
				weekendGetUpTemp = input.readInt();
				weekendSleepFromTemp = input.readInt();

				//useCloudBackground = input.readBoolean();
				//savingsProfileIndex = input.readInt();
				//selectedScenarioIndex = input.readInt();
				
				//make general objects into Edge objects:
				scheduleCollection = new ArrayCollection();
				for each (var obj:Object in tempScheduleCollection) 
				{
					var edge:Edge = new Edge(obj.temperature, obj.timeSinceStartOfWeek);
					scheduleCollection.addItem(edge);
				}
				
				
			} 
			catch(error:Error) 
			{
				// Catch for instance eof error
			}
		}
		
		public function get version():String
		{
			return _version;
		}

		public function set version(value:String):void
		{
			_version = value;
		}

		public function get registeredAppOnPortal():Boolean
		{
			return _registeredAppOnPortal;
		}

		public function set registeredAppOnPortal(value:Boolean):void
		{
			_registeredAppOnPortal = value;
		}

		public function get appUUID():String
		{
			return _appUUID;
		}

		public function set appUUID(value:String):void
		{
			_appUUID = value;
		}

		/** Language string en_US,nl_NL,de_DE,da_DK,fr_FR,es_ES,ja_JP */
		public function get language():String
		{
			return _language;
		}

		public function set language(value:String):void
		{
			if (value == null || value == "null" || value == ""){
				value = "en_US";				
			}
			_language = value;
		}

		/** Menu state that is selected in the app */
		public function get savedState():String
		{
			return _savedState;
		}

		public function set savedState(value:String):void
		{
			_savedState = value;
		}

		public function get presetCollection():ArrayCollection
		{
			return _presetCollection;
		}

		public function set presetCollection(value:ArrayCollection):void
		{
			_presetCollection = value;
		}
		
		[Bindable(event="scheduleCollectionChanged")]
		public function get scheduleCollection():ArrayCollection
		{
			return _scheduleCollection;
		}

		public function set scheduleCollection(value:ArrayCollection):void
		{
			_scheduleCollection = value;
			var e:Event = new Event("scheduleCollectionChanged");
			dispatchEvent(e);
		}

		public function get introExplanationSeen():Boolean
		{
			return _introExplanationSeen;
		}

		public function set introExplanationSeen(value:Boolean):void
		{
			_introExplanationSeen = value;
		}

		public function get weekGetUpTime():int
		{
			return _weekGetUpTime;
		}

		public function set weekGetUpTime(value:int):void
		{
			_weekGetUpTime = value;
		}

		public function get weekWorkFromTime():int
		{
			return _weekWorkFromTime;
		}

		public function set weekWorkFromTime(value:int):void
		{
			_weekWorkFromTime = value;
		}

		public function get weekWorkToTime():int
		{
			return _weekWorkToTime;
		}

		public function set weekWorkToTime(value:int):void
		{
			_weekWorkToTime = value;
		}

		public function get weekSleepFromTime():int
		{
			return _weekSleepFromTime;
		}

		public function set weekSleepFromTime(value:int):void
		{
			_weekSleepFromTime = value;
		}

		public function get weekendGetUpTime():int
		{
			return _weekendGetUpTime;
		}

		public function set weekendGetUpTime(value:int):void
		{
			_weekendGetUpTime = value;
		}

		public function get weekendSleepFromTime():int
		{
			return _weekendSleepFromTime;
		}

		public function set weekendSleepFromTime(value:int):void
		{
			_weekendSleepFromTime = value;
		}

		public function get hostIp():String
		{
			return _hostIp;
		}

		public function set hostIp(value:String):void
		{
			_hostIp = value;
		}

		public function get weekGetUpTemp():Number
		{
			return _weekGetUpTemp;
		}

		public function set weekGetUpTemp(value:Number):void
		{
			_weekGetUpTemp = value;
		}

		public function get weekWorkFromTemp():Number
		{
			return _weekWorkFromTemp;
		}

		public function set weekWorkFromTemp(value:Number):void
		{
			_weekWorkFromTemp = value;
		}

		public function get weekWorkToTemp():Number
		{
			return _weekWorkToTemp;
		}

		public function set weekWorkToTemp(value:Number):void
		{
			_weekWorkToTemp = value;
		}

		public function get weekSleepFromTemp():Number
		{
			return _weekSleepFromTemp;
		}

		public function set weekSleepFromTemp(value:Number):void
		{
			_weekSleepFromTemp = value;
		}

		public function get weekendGetUpTemp():Number
		{
			return _weekendGetUpTemp;
		}

		public function set weekendGetUpTemp(value:Number):void
		{
			_weekendGetUpTemp = value;
		}

		public function get weekendSleepFromTemp():Number
		{
			return _weekendSleepFromTemp;
		}

		public function set weekendSleepFromTemp(value:Number):void
		{
			_weekendSleepFromTemp = value;
		}

		public function get useCloudBackground():Boolean
		{
			return _useCloudBackground;
		}

		public function set useCloudBackground(value:Boolean):void
		{
			_useCloudBackground = value;
		}

		public function get savingsProfileIndex():int
		{
			return _savingsProfileIndex;
		}

		public function set savingsProfileIndex(value:int):void
		{
			_savingsProfileIndex = value;
		}

		public function get selectedScenarioIndex():int
		{
			return _selectedScenarioIndex;
		}

		public function set selectedScenarioIndex(value:int):void
		{
			_selectedScenarioIndex = value;
		}

		public function get gatewaysCollection():ArrayCollection
		{
			return _gatewaysCollection;
		}

		public function set gatewaysCollection(value:ArrayCollection):void
		{
			_gatewaysCollection = value;
		}

		
	}
}