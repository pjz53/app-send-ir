package models
{
	
	import mx.collections.XMLListCollection;
	
	import vos.Host;
	
	[Bindable]
	public dynamic class Feature
	{
		public var id:String;
		public var name:String;
		/** data_subscription, or other constant */
		public var type:String;
		/** stretch, smile, none */
		public var applicable_vendor_models:XMLListCollection;
		/** P1D, P1W, P1M, P1Y, P10Y */
		public var validity_period:String; 
		public var created_date:Date;
		public var deleted_date:Date;
		public var activation_date:Date;
		public var valid_from:Date;
		public var valid_to:Date;
		public var host:Host;

		public static const FEATURE_DATA_SUBSCRIPTION:String = "data_subscription";
		public static const FEATURE_MERCURY:String = "mercury";
		
		public function Feature(xml:XML, host:Host=null) {
			fill(xml);
			this.host = host;
		}
		
		public function fill(myXML:XML):void {
			
			if (myXML == null || myXML == "" || myXML.elements().length() <= 1) return;
			
			id 	= myXML.attribute('id');
			type = myXML.name();
			
			for each (var item:XML in myXML.elements()) 
			{
				var itemName:String = item.name();
				//trace(item.name());
				switch (itemName) {
					case FEATURE_DATA_SUBSCRIPTION:
					case FEATURE_MERCURY:
						
						break;
					case "name":
					case "description":
					case "validity_period":
						this[itemName] = item.valueOf();
						break;
					case "applicable_vendor_models":
						this[itemName] = new XMLListCollection(XMLList(item..vendor_model));
						break;
					case "created_date":
					case "deleted_date":
					case "activation_date":
					case "valid_from":
					case "valid_to":
						this[itemName] = DateParser.parseToDate(item.valueOf());
						break;
				}
			}
		}

		/**  Number of days until expiration of this feature (negative if expired) */
		public function get days_to_expiry():Number
		{
			var d:Date = new Date();
			return ((valid_to ? valid_to.time : 0) - d.time)/(1000 * 3600 * 24);
		}

		/**  Return false if expired */
		public function get is_active():Boolean
		{
			if (valid_from && valid_to == null) return true; // code activated, but valid forever
			return days_to_expiry < 0 ? false : true;
		}
	}
}