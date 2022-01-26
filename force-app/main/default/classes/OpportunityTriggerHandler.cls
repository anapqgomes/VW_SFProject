public class OpportunityTriggerHandler {
    public static final Id ASSETRT = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Truck').getRecordTypeId();
    
	//perform after update logic
    public void onAfterUpdate(Map<Id, Opportunity> newObjMap, Map<Id, Opportunity> oldObjMap) {
        handleClosedWonOpportunities(newObjMap, oldObjMap);  
    }
    
    //========================================================= Handler Methods ==========================================================
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //Handle logic for when an opportunity is changed to Won (validations and creation of assets)
    //Parameters:
    // Map<Id, Opportunity> newly Updated Records
    // Map<Id, Opportunity> old records
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void handleClosedWonOpportunities(Map<Id, Opportunity> newObjMap, Map<Id, Opportunity> oldObjMap) {
        Map<Id, Opportunity> wonOppoRecordsMap = new Map<Id, Opportunity>();
        
        //check if Opportunities were just won
        for(Opportunity opp : newObjMap.values()){
            if(opp.stageName != oldObjMap.get(opp.Id).stageName && opp.StageName == 'Closed Won'){
                wonOppoRecordsMap.put(opp.Id, opp);   
            }
        }
        
        //get the Orders and Order Items
        List<Order> oppActiveOrders = [select id, status ,OpportunityId, AccountId, ShipToContactId,
                                       (select id, Product2Id, Product2.Name, Quantity, OrderId, TotalPrice, subscription_percent__c from OrderItems) 
                                       from Order where OpportunityId IN:wonOppoRecordsMap.keyset() and status = 'Activated']; 
        
        //validate existing orders to make sure we have one active
        validateActiveOrderUponConversion(wonOppoRecordsMap.values(), oppActiveOrders);
        
        
		//create Assets for each order Item for converted Opportunities
        List<Asset> assetsToInsert = createAssetsForConvertedOpportunities(oppActiveOrders);    
        
        try{
            
        insert assetsToInsert;
            
        }catch(exception ex){
            
            System.debug('Exception: ' + ex.getMessage());
            
        } 
    }
    
    //========================================================= Handler Methods ==========================================================
    
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //validates if the Opportunity has an active Order
    //Parameters:
    // List<Opportunity> newly won Records
    // Lst<Order> related Orders
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void validateActiveOrderUponConversion(List<Opportunity> wonOpportunities, List<Order> linkedOrderRecords){
        
        //for each Opportunity check if there are active Orders
        for(Opportunity wonOpp : wonOpportunities){
            Boolean hasActiveOrder = false;
            for(Order ord : linkedOrderRecords){
                if(ord.OpportunityId == wonOpp.Id){
                    hasActiveOrder = true;   
                }  
            }
            
            //if there are no active orders throw an error
            if(!hasActiveOrder){
                wonOpp.addError(Label.MustActivateOrder);
            }
        } 
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //When Opportunity is won ans passes the validations, create Assets for each Order Item
    //Parameters:
    // List<Order> oders to loop through and corresponding order Items retrieved via inner query
    // Returns: List<Asset> to be inserted
    //------------------------------------------------------------------------------------------------------------------------------------
    public static List<Asset> createAssetsForConvertedOpportunities(List<Order> ordersToProcess){
        
        //for each Order and Order Item, create an Asset to link after conversion
        List<Asset> assetsToInsert = new List<Asset>();
        for(Order ord : ordersToProcess){
            for(OrderItem ordItem : ord.OrderItems){
                Asset assetRecord = new Asset();
                assetRecord.ContactId = ord.ShipToContactId;
                assetRecord.AccountId = ord.AccountId;
                assetRecord.Product2Id = ordItem.Product2Id;
                assetRecord.Name = ordItem.Product2.Name;
                assetRecord.Quantity = ordItem.Quantity;
                assetRecord.Price = ordItem.TotalPrice;
                assetRecord.PurchaseDate = system.today();
                assetRecord.Status = 'Purchased';
                assetRecord.recordtypeId = ASSETRT;
                assetRecord.subscription_Ammount__c = ordItem.Subscription_Percent__c;
                assetsToInsert.add(assetRecord);    
            }
        }
        return assetsToInsert;
  
    }
}