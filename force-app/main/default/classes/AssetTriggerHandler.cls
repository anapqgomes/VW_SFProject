public class AssetTriggerHandler {
    public static final Id ASSETRT = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Truck').getRecordTypeId();
    public static final Id SUBSCRIPTIONRT = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Subscription').getRecordTypeId();
    
    //perform after insert logic
    public void onAfterInsert(Map<Id, Asset> newObjMap, Map<Id, Asset> oldObjMap) {
        createChildAssets(newObjMap); 
        
    }
    
    //========================================================= Handler Methods ==========================================================
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //Creates child Assets representing subscriptions
    //Parameters:
    // Map<Id, Asset> created Updated Records
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void createChildAssets(Map<Id, Asset> assetsToProcess){
        List<Asset> assetsToInsert = new List<Asset>();
        
        //for bundled assets (with subscriptions) create child asset with subscription Record type to represent the subscription attached and it's price
        for(Asset parent : assetsToProcess.Values()){
            //check for record type to prevent the new assets to enter this logic again
            if(parent.ProductFamily == 'Trucks with Subscriptions' && parent.recordTypeId == ASSETRT){
                Asset assetRecord = new Asset();
                assetRecord.ContactId = parent.ContactId;
                assetRecord.ParentId = parent.Id;
                assetRecord.Product2Id = parent.Product2Id;
                assetRecord.Name = 'Subscription';
                assetRecord.Quantity = parent.Quantity;
                System.debug('assetRecord.subscription_Ammount__c: ' + assetRecord.subscription_Ammount__c);
                assetRecord.Price = (parent.Price * parent.subscription_Ammount__c) / (100 + parent.subscription_Ammount__c);
                assetRecord.PurchaseDate = system.today();
                assetRecord.Status = 'Purchased';
                assetRecord.recordtypeId = SUBSCRIPTIONRT;
                assetsToInsert.add(assetRecord);     
            }
        }
        
        try{
            insert assetsToInsert;    
        }catch(exception ex){
            
            System.debug('Exception: ' + ex.getMessage());
            
        } 
    }
    
}