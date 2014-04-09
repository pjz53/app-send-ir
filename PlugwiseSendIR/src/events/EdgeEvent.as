package events {
	import flash.events.Event;
	
	import vos.Edge;
	
	public class EdgeEvent extends Event {
		
		public var edge:Edge;
		public var edgeId:String;
		
		public static const CREATENEW:String = "edgeCreateNewEvent";
		public static const CREATE:String = "edgeCreateEvent";
		public static const UPDATE:String = "edgeUpdateEvent";
		public static const DELETE:String = "edgeDeleteEvent";
		public static const DELETEQUESTION:String = "edgeDeleteQuestionEvent";
		public static const SELECT:String = "edgeSelectEvent";
		public static const COLLECTIONCHANGE:String = "edgeCollectionChangeEvent";
		public static const MOVESTART:String = "edgeMoveStartEvent";
		public static const MOVE:String = "edgeMoveEvent";
		public static const MOVESTOP:String = "edgeMoveStopEvent";
		
		public function EdgeEvent(type:String, bubbles:Boolean, edge:Edge=null, edgeId:String=null) {
			super(type, bubbles);
			this.edge = edge;
			this.edgeId = edgeId;
		}
		
		override public function clone():Event {
			return new EdgeEvent(type, bubbles, edge, edgeId);
		}
		
	}
}