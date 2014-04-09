package models
{
	import mx.formatters.DateFormatter;
	
	public class DateParser
	{
		public function DateParser()
		{
		}
		
		public static function parseToDate(ds:String):Date {
			if (!ds) return null;
			var toRet:Date = new Date();
			toRet.fullYear = int(ds.substr(0,4));
			toRet.month = int(ds.substr(5,2)) - 1;
			toRet.date = int(ds.substr(8,2));
			toRet.hours = int(ds.substr(11,2));
			toRet.minutes = int(ds.substr(14,2));
			toRet.seconds = 0;
			toRet.milliseconds = 0;
			var tzs:String = ds.substr(-6);
			var sign:int = int(tzs.substr(0,1) + "1");
			var hoursMinutes:int = int(tzs.substr(1,2)) * 60;
			var minutes:int = int(tzs.substr(4,2));
			var timeZoneOffset:int = sign * (hoursMinutes + minutes);//offset in minutes
			var now:Date = new Date();
			var timeZoneDiff:int = now.timezoneOffset - timeZoneOffset;//difference in minutes
			toRet.time -= timeZoneDiff * 60 * 1000;
			
			return toRet;
		}
		
		public static function parseUTCDate(ds:String):Date {
			if (!ds) return null;
			var toRet:Date = new Date();
			toRet.setUTCFullYear(int(ds.substr(0,4)));
			toRet.setUTCMonth(int(ds.substr(5,2)) - 1);
			toRet.setUTCDate(int(ds.substr(8,2)));
			toRet.setUTCHours(int(ds.substr(11,2)));
			toRet.setUTCMinutes(int(ds.substr(14,2)));
			toRet.setUTCSeconds(0,0);
			var tzs:String = ds.substr(-6);
			var sign:int = int(tzs.substr(0,1) + "1");
			var hoursMinutes:int = int(tzs.substr(1,2)) * 60;
			var minutes:int = int(tzs.substr(4,2));
			var timeZoneOffset:int = sign * (hoursMinutes + minutes);//offset in minutes
			toRet.time -= timeZoneOffset * 60 * 1000;
			
			return toRet;
		}
		
		public static function formatDate(date:Date, formatString:String=null):String {
			if (formatString == null) {
				formatString = "YYYY-MM-DD";
			}
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = formatString;
			return dateFormatter.format(date);
		}
		
		public static function formatUTCDate(date:Date, formatString:String=null):String {
			if (formatString == null) {
				formatString = "YYYY-MM-DD";
			}
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = formatString;
			var utcDate:Date = new Date(date.fullYearUTC,date.monthUTC,date.dateUTC,date.hoursUTC,date.minutesUTC,date.secondsUTC,date.millisecondsUTC);
			
			return dateFormatter.format(utcDate);
		}
		
		public static function formatIsoDate(date:Date):String {
			var toRet:String;
			var formatString1:String = "YYYY-MM-DDTHH:NN:SS";
			//var formatString2:String = "HH:mm:ss";
			var tzStr:String;
			var sign:String = date.timezoneOffset <= 0 ? "+" : "-";
			
			//var dateFormatter:DateTimeFormatter = new DateTimeFormatter();
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = formatString1;
			//trace(dateFormatter.lastOperationStatus);
			toRet = dateFormatter.format(date);
			//dateFormatter.dateTimePattern = formatString2;
			//trace(dateFormatter.lastOperationStatus);
			//toRet += "T" + dateFormatter.format(date);
			//trace(dateFormatter.lastOperationStatus);
			var tzHours:String = "0" + String(Math.abs(Math.floor(date.timezoneOffset / 60)));
			tzStr = sign + tzHours.substr(0,2);
			var tzMins:String = "0" + String(date.timezoneOffset % 60);
			tzMins = tzMins.substr(0,2);
			tzStr += ":" + tzMins;
			toRet += tzStr;
			return toRet;
		}
		
		public static function formatSimpleDate(date:Date, formatString:String=null):String {
			if (formatString == null) {
				formatString = "YYYYMMDDHHNNSS";
			}
			date = makeUTCDate(date);
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = formatString;
			var utcSimpleDate:Date = new Date(date.fullYearUTC,date.monthUTC,date.dateUTC,date.hoursUTC,date.minutesUTC,date.secondsUTC,date.millisecondsUTC);
			
			return dateFormatter.format(utcSimpleDate);
		}
		
		public static function makeUTCDate(date:Date):Date {
			if (date.hoursUTC != 0) {
				date.time += date.timezoneOffset * 60000;
			}
			return date;
		}
		
		
	}
}