public class OpportunityTriggerHandler {
    public static final Id ASSETRT = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Truck').getRecordTypeId();
    
	//perform after update logic
    public void onAfterUpdate(Map<Id, Opportunity> newObjMap, Map<Id, Opportunity> oldObjMap) {
        handleClosedWonOpportunities(newObjMap, oldObjMap);  
    }
    
    //========================================================= Handler Methods ==========================================================
    
    
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
    

    private static void postDataCore(String servicetoCall, String body, String currentRecord, Id currentRecordId){
        String sReturn;
        
        // MarteServiceRelativeURL__mdt webserviceCalledInfo = getServiceRelativeURLByName(serviceToCall);
        //System.debug('webserviceCalledInfo: ' + webserviceCalledInfo.WebServiceMethod__c);
        Http http= new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        request.setEndpoint('https://eu1.anypoint.mulesoft.com/mocking/api/v1/links/267cf127-5cc9-499d-bb5cfe2d447aa99d/JOINTHEDIGITALHUB/WMAH05ZZZ4B011671');
        request.setHeader('Client-id', 'b903e91e6c6542a3a4a6e800f37f95ea');
        request.setHeader('Client-secret', '4d73e495F84E4c47B8a8E37C8F8B96b3');
        //request.setHeader('correlation-id', '4d73e495F84E4c47B8a8E37C8F8B96b3');
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('GET');
        request.setTimeout(120000);  
        request.setBody(body);
        
        //MarteServiceResponseWrapper.GenericResponse parsedResponseBody = new MarteServiceResponseWrapper.GenericResponse();
        // Map<SObjectField, Object> fieldsBeingUpdated = new Map<SObjectField, Object>();
        
        try {
            System.debug('request: ' + request);
            response = http.send(request);
            
            System.debug('response: ' + response);
            
            sReturn = response.getBody();
            System.debug(sReturn);
            // parsedResponseBody = (MarteServiceResponseWrapper.GenericResponse)json.deserialize(sReturn, MarteServiceResponseWrapper.GenericResponse.class);       
            
            
            
        } catch(Exception genericException) { 
            sReturn = genericException.getMessage();
            system.debug('sReturn: ' + sReturn + ' ' + genericException.getLineNumber());
            system.debug('exception: ' + genericException.getStackTraceString());
        }
        
    }
}