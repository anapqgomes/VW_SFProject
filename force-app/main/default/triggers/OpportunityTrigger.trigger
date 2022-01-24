trigger OpportunityTrigger on Opportunity(
  after delete,
  after insert,
  after undelete,
  after update,
  before delete,
  before insert,
  before update
) {
    
  OpportunityTriggerHandler handler = new OpportunityTriggerHandler();

  /* After Update */
  if (Trigger.isUpdate && Trigger.isAfter) {
    handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
  }
}