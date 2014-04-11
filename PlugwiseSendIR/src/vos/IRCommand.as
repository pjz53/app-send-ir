package vos
{
	import flash.events.EventDispatcher;
	
	import mx.utils.UIDUtil;
	
	/**
	 * 
	 * @author pjz
	 * used to save slot by name and retrieve ir command string
	 * stored used in arrayCollection "irCommands" of gateway
	 */	
	[Bindable]
	public class IRCommand extends EventDispatcher
	{
		public var id:String;// Implemented as UUID
		private var _label:String;
		private var _type:String;
		private var _irCommand:String;// the string that can be sent to the IR device
		private var _date:Date = new Date();
		
		public function IRCommand(id:String=null, label:String=null, type:String="smile_ir", irCommand:String=null)
		{
			if (id == null) {
				var myPattern:RegExp = /-/g;
				this.id = UIDUtil.createUID().replace(myPattern,"").toLowerCase();
			} else {
				this.id = id;
			}
			
			_label = label;
		}
		
		public function get label():String
		{
			return _label;
		}
		
		public function set label(value:String):void
		{
			_label = value;
		}

		public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type = value;
		}

		public function get date():Date
		{
			return _date;
		}

		public function set date(value:Date):void
		{
			_date = value;
		}

		public function get irCommand():String
		{
			return _irCommand;
		}

		public function set irCommand(value:String):void
		{
			_irCommand = value;
		}
		

	}
}