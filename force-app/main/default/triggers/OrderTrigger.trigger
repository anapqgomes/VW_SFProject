trigger OrderTrigger on Order(
  after delete,
  after insert,
  after undelete,
  after update,
  before delete,
  before insert,
  before update
) {
    
  OrderTriggerHandler handler = new OrderTriggerHandler();

  /* Before Update */
  if (Trigger.isBefore && Trigger.isUpdate) {
    handler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
  }
    /* After Update */
  if (Trigger.isAfter && Trigger.isUpdate) {
    handler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
  }
}