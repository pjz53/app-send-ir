package events {
	import flash.events.Event;
	
	import vos.Host;
	import vos.Settings;
	
	public class SettingsEvent extends Event {
		
		public var host:Host;
		public var settings:Settings;
		public var updateTabs:Boolean;
		
		public static const SETHOSTS:String = "setHostsEvent";
		public static const SETSETTINGS:String = "setSettingsEvent";
		public static const UPDATEDPLU:String = "updatedPluSettingsEvent";
		public static const UPDATEDP1:String = "updatedP1SettingsEvent";
		public static const UPDATEDSOURCE:String = "updatedSourceSettingsEvent";
		public static const UPDATEDSTRETCH:String = "updatedStretchSettingsEvent";
		public static const UPDATEDSETTINGS:String = "updatedSettingsSettingsEvent";
		public static const ASKFORCODE:String = "askForCodeSettingsEvent";
		public static const CLEARHOSTS:String = "clearHostsEvent";
		public static const CLEARSETTINGS:String = "clearSettingsEvent";
		public static const CLEARPORTALCONNECTIONSETTINGS:String = "clearPortalConnectionSettingsEvent";
		public static const STARTTIMERS:String = "startTimersSettingsEvent";
		public static const STOPTIMERS:String = "stopTimersSettingsEvent";
		
		public static const SHOWSOLARTAB:String = "showSolarTabSettingsEvent";
		public static const SHOWNEWDEVICETAB:String = "showNewDeviceTabSettingsEvent";
		public static const SHOWOVERVIEWTAB:String = "showOverviewTabSettingsEvent";
		public static const SHOWCHARTTAB:String = "showChartTabSettingsEvent";
		public static const SHOWP1TAB:String = "showP1TabSettingsEvent";
		public static const SHOWPLUTAB:String = "showPluTabSettingsEvent";
		public static const SHOWTIPSTAB:String = "showTipsTabSettingsEvent";
		
		public static const HIDESOLARTAB:String = "hideSolarTabSettingsEvent";
		public static const HIDENEWDEVICETAB:String = "hideNewDeviceTabSettingsEvent";
		public static const HIDEOVERVIEWTAB:String = "hideOverviewTabSettingsEvent";
		public static const HIDECHARTTAB:String = "hideChartTabSettingsEvent";
		public static const HIDEP1TAB:String = "hideP1TabSettingsEvent";
		public static const HIDEPLUTAB:String = "hidePluTabSettingsEvent";
		public static const HIDETIPSTAB:String = "hideTipsTabSettingsEvent";
				
		public function SettingsEvent(type:String, bubbles:Boolean, host:Host=null, settings:Settings=null, updateTabs:Boolean=true) {
			super(type, bubbles);
			this.host = host;
			this.settings = settings;
			this.updateTabs = updateTabs;
		}
		
		override public function clone():Event {
			return new SettingsEvent(type, bubbles, host, settings, updateTabs);
		}
		
	}
}