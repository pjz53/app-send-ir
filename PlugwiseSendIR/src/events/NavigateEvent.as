package events
{
	import flash.events.Event;
	
	public class NavigateEvent extends Event
	{
		public static const OPENTHERMOSTAT:String = "openThermostatEvent";
		/** Open the (graphical) schedule view */
		public static const OPENSCHEDULE:String = "openScheduleEvent";
		public static const OPENSCHEDULEDETAILS:String = "openScheduleDetailsEvent";
		public static const OPENSETTINGS:String = "openSettingsEvent";
		public static const OPENSETTINGSPROFILE:String = "openSettingsProfileEvent";
		public static const OPENSETTINGSUSER:String = "openSettingsUserEvent";
		public static const OPENSETTINGSGATEWAY:String = "openSettingsGatewayEvent";
		/** Open the schedule settings view */
		public static const OPENSETTINGSSCHEDULE:String = "openSettingsScheduleEvent";
		public static const OPENSETTINGSTHERMOSTAT:String = "openSettingsThermostatEvent";
		public static const OPENACHIEVEMENTS:String = "openAchievementsEvent";
		public static const OPENHELP:String = "openHelpEvent";
		public static const CLOSEVIEW:String = "closeViewEvent";
		
		public function NavigateEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}