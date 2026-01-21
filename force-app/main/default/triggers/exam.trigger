trigger exam on Opportunity (before delete) {
	if(Trigger.isDelete && Trigger.isBefore) {
        //not new for deletion
        exam_opportunity_handler.classhandler(Trigger.old);
}
}