package vos
{
	import flash.events.EventDispatcher;
	
	import mx.formatters.DateFormatter;
	import mx.utils.UIDUtil;
	
	[Bindable]
	public class Edge extends EventDispatcher
	{
		public var id:String;// Implemented as UUID
		private var _label:String;
		//private var _type:String;
		private var _irCommand:IRCommand;
		//private var _date:Date;
		private var _timeSinceStartOfWeek:int = 0;//time since day 0 (sunday 0:00)
		private var _timeSinceStartOfDay:int;
		private var _dayIndex:int;
		private var _x:Number;
		private var _prenatal:Boolean = false;
		private var _state:String = "";
		private var _diameter:Number;
		private var _timeToSet:String;
		private var _temperatureToSet:Number;
		private var _touchX:Number;
		private var _touchY:Number;
		private var _showTimeAdjust:Boolean = true;
		
		public static const dayMSec:int = 24 * 60 * 60 * 1000;
		
		public function Edge(irCommand:IRCommand,timeSinceStartOfWeek:Number,x:Number=0)
		{
			if (id == null) {
				var myPattern:RegExp = /-/g;
				this.id = UIDUtil.createUID().replace(myPattern,"").toLowerCase();
			} else {
				this.id = id;
			}
			
			this.irCommand = irCommand;
			
			this.timeSinceStartOfWeek = timeSinceStartOfWeek;
			
			this.x = x;
			
		}
		
		public function setWithValues(irCommand:IRCommand,timeSinceStartOfWeek:Number):void {
			this.irCommand = irCommand;
			this.timeSinceStartOfWeek = timeSinceStartOfWeek;
		}

		public function get label():String
		{
			_label = irCommand.toString();
			return _label;
		}
		
		public function set label(value:String):void
		{
			_label = value;
		}

		/*public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}*/

		/*public function get date():Date
		{
			return _date;
		}

		public function set date(value:Date):void
		{
			_date = value;
		}*/

		public function get irCommand():IRCommand
		{
			return _irCommand;
		}

		public function set irCommand(value:IRCommand):void
		{
			_irCommand = value;
		}

		public function get x():Number
		{
			return _x;
		}

		public function set x(value:Number):void
		{
			_x = value;
		}
		
		/**
		 * @return time since Sunday 0:00
		 * this var needs to set the others are calculated from it
		 */		
		public function get timeSinceStartOfWeek():int
		{
			return _timeSinceStartOfWeek;
		}

		public function set timeSinceStartOfWeek(value:int):void
		{
			_timeSinceStartOfWeek = value;
			if (_timeSinceStartOfWeek >= dayMSec) {
				_timeSinceStartOfDay = _timeSinceStartOfWeek % (dayIndex * dayMSec);
			} else {
				_timeSinceStartOfDay = _timeSinceStartOfWeek;
			}
			trace(_timeSinceStartOfDay);
		}

		public function get timeSinceStartOfDay():int
		{
			//_timeSinceStartOfDay = _timeSinceStartOfWeek % (dayIndex * dayMSec);
			return _timeSinceStartOfDay;
		}

		public function set timeSinceStartOfDay(value:int):void
		{
			_timeSinceStartOfDay = value;
		}
		/**
		 * @return index of the day of the week (0 for Sunday, 1 for Monday, and so on)
		 */		
		public function get dayIndex():int
		{
			var dayNumber:int = Math.floor(_timeSinceStartOfWeek / (24 * 60 * 60 * 1000));
			if (dayNumber > 6) {
				dayNumber = 0;
			}
			_dayIndex = dayNumber;
			return _dayIndex;
		}

		public function set dayIndex(value:int):void
		{
			_dayIndex = value;
		}
		
		public function getTimeString():String {
			var dateFromTimeOfDay:Date = new Date();
			dateFromTimeOfDay.setHours(0,0,0,0);
			var dayStart:Date = new Date();
			dayStart.setHours(0,0,0,0);
			dateFromTimeOfDay.time +=this.timeSinceStartOfDay;
			
			var df:DateFormatter = new DateFormatter("HH:NN");
			return df.format(dateFromTimeOfDay);
		}

		public function get prenatal():Boolean
		{
			return _prenatal;
		}

		public function set prenatal(value:Boolean):void
		{
			_prenatal = value;
		}

		public function get state():String
		{
			return _state;
		}

		public function set state(value:String):void
		{
			_state = value;
		}

		public function get diameter():Number
		{
			return _diameter;
		}

		public function set diameter(value:Number):void
		{
			_diameter = value;
		}

		public function get timeToSet():String
		{
			return _timeToSet;
		}

		public function set timeToSet(value:String):void
		{
			_timeToSet = value;
		}

		public function get touchX():Number
		{
			return _touchX;
		}

		public function set touchX(value:Number):void
		{
			_touchX = value;
		}

		public function get touchY():Number
		{
			return _touchY;
		}

		public function set touchY(value:Number):void
		{
			_touchY = value;
		}

		public function get temperatureToSet():Number
		{
			return _temperatureToSet;
		}

		public function set temperatureToSet(value:Number):void
		{
			_temperatureToSet = value;
		}

		public function get showTimeAdjust():Boolean
		{
			return _showTimeAdjust;
		}

		public function set showTimeAdjust(value:Boolean):void
		{
			_showTimeAdjust = value;
		}


	}
}