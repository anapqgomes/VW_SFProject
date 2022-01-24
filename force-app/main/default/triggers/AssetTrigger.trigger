trigger AssetTrigger on Asset(
  after delete,
  after insert,
  after undelete,
  after update,
  before delete,
  before insert,
  before update
) {
    
  AssetTriggerHandler handler = new AssetTriggerHandler();

  /* After Insert */
  if (Trigger.isInsert && Trigger.isAfter) {
    handler.onAfterInsert(Trigger.newMap, Trigger.oldMap);
  }
}