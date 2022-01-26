public class OrderTriggerHandler {
    
    //perform before update logic
    public void onBeforeUpdate(Map<Id, Order> newObjMap, Map<Id, Order> oldObjMap) {
        checkForActiveOrders(newObjMap, oldObjMap);    
    }
    
    //perform after update logic
    public void onAfterUpdate(Map<Id, Order> newObjMap, Map<Id, Order> oldObjMap) {
        setPriceBook(newObjMap, oldObjMap);
        checkForInactiveOrders(newObjMap, oldObjMap);   
    }
    
    //========================================================= Handler Methods ==========================================================
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //Checks if there are more than one active Order
    //Parameters:
    // Map<Id, Order> newly Updated Records
    // Map<Id, Order> old records
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void checkForActiveOrders(Map<Id, Order> newObjMap, Map<Id, Order> oldObjMap) {
        Set<Id> parentOpportunityIds = new Set<Id>();
        Set<Id> activeOrderIds = new Set<Id>();
        Map<Id, List<Order>> oppByListOrdersMap = new Map<Id, List<Order>>();
        List<Order> activeOrders = new List<Order>();
        
        //only process orders that were just activated
        for(Order orderRecord : newObjMap.values()){
            if(orderRecord.status != oldObjMap.get(orderRecord.Id).status){
                
                //do not let order be activated/deactivated after the Opportunity has been closed
                if(orderRecord.isOpportunityClosed__c){
                    orderRecord.addError(Label.StatusNotChangeAfterClose);
                    
                }else if(orderRecord.status == 'Activated'){  
                    parentOpportunityIds.add(orderRecord.OpportunityID);  
                    activeOrders.add(orderRecord); 
                    activeOrderIds.add(orderrecord.Id);
                }  
            }
        }
        
        //check for existing orders already active in the database
        List<Order> orderList = [select id, OpportunityId from Order where OpportunityId IN:parentOpportunityIds and status = 'Activated'];
        
        //map the existing orders by opportunity id
        for(Order activeOrder : orderList){
            if(!oppByListOrdersMap.containsKey(activeOrder.OpportunityId)){
                oppByListOrdersMap.put(activeOrder.OpportunityId, new List<Order>{activeOrder}); 
                
            }else{
                oppByListOrdersMap.get(activeOrder.OpportunityId).add(activeOrder);
            }  
        }
        
        //validate that only one order must be active
        for(Order orderRecord : activeOrders){
            if(oppByListOrdersMap.containsKey(orderRecord.OpportunityId) && oppByListOrdersMap.get(orderRecord.OpportunityId).size()>0){
                orderRecord.addError(Label.OnlyOneActiveOrder);       
            }   
        }
        
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //When Order is activated, set the Price Book on Opportunity
    //Parameters:
    // Map<Id, Order> newly Updated Records
    // Map<Id, Order> old records
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void setPriceBook(Map<Id, Order> newObjMap, Map<Id, Order> oldObjMap){
        Set<Id> parentOpportunityIds = new Set<Id>();
        Map<Id, Order> activeOrders = new Map<Id, Order>();
        
        for(Order orderRecord : newObjMap.values()){
            if(orderRecord.status != oldObjMap.get(orderRecord.Id).status && orderRecord.status == 'Activated'){
                activeOrders.put(orderRecord.Id, orderRecord);
                parentOpportunityIds.add(orderRecord.OpportunityID);  
            }    
        }
        
        //get the Opportunities related to each order
        List<Opportunity> opportunityList = [select id, Pricebook2Id from Opportunity where id IN:parentOpportunityIds];
        
        //set Order PriceBook on Opportunity
        for(Order ordRecord : activeOrders.values()){
            for(Opportunity opp :opportunityList){
                if(opp.Id == ordRecord.OpportunityId){
                    opp.Pricebook2Id = ordRecord.Pricebook2Id;    
                }  
            }
        }
        
        try{
            //update Opportunities and create Opportunity Products    
            update opportunityList;
            createProducts(activeOrders.keyset());
            
        }catch(exception ex){
            
            System.debug('Exception: ' + ex.getMessage());
            
        }
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //When Order is inactivated, remove products from opportunity
    //Parameters:
    // Map<Id, Opportunity> newly Updated Records
    // Map<Id, Opportunity> old records
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void checkForInactiveOrders(Map<Id, Order> newObjMap, Map<Id, Order> oldObjMap){
        Set<Id> parentOpportunityIds = new Set<Id>();
        Map<Id, Order> inactiveOrders = new Map<Id, Order>();
        
        //check for orders that were inactivated
        for(Order orderRecord : newObjMap.values()){
            if(orderRecord.status != oldObjMap.get(orderRecord.Id).status && orderRecord.status == 'Draft'){
                inactiveOrders.put(orderRecord.Id, orderRecord);
                parentOpportunityIds.add(orderRecord.OpportunityID);  
            }
            
        }
        
        //get the Opportunity products
        List<OpportunityLineItem> oppLineItemsToDelete= [select id from OpportunityLineItem where OpportunityId IN:parentOpportunityIds];
        
        try{
            //delete Opportunity Products from inactivated orders
            delete oppLineItemsToDelete;
            
        }catch(exception ex){
            
            System.debug('Exception: ' + ex.getMessage());
            
        }
        
    }
    
    //========================================================= Utility Methods ==========================================================    
    
    //------------------------------------------------------------------------------------------------------------------------------------
    //Creates Products (line items) on Opportunity for each Order Item
    //Parameters:
    // Set<Id> Ids of the active Order for each Opportunity that entered the trigger (to query order items)
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    public static void createProducts(set<Id> activeOrders){
        
        //get the order items related to each order that was activated
        List<OrderItem> orderItemList = [select id, Order.OpportunityId , Product2Id , TotalPrice, Quantity, UnitPrice from OrderItem where orderID in :activeOrders];
        List<OpportunityLineItem> oppLineItemsToInsert = new List<OpportunityLineItem>();
        
        //for each order item create a new Opportunity Product related to the Opportunity
        for(OrderItem orderRecord : orderItemList){
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = orderRecord.Order.OpportunityId ;
            oli.Product2Id = orderRecord.Product2Id;
            oli.TotalPrice = orderRecord.TotalPrice;
            oli.Quantity = orderRecord.Quantity;
            oppLineItemsToInsert.add(oli);
        }
        
        try{
            
            insert oppLineItemsToInsert; 
            
        } catch(exception ex){
            
            System.debug('Exception: ' + ex.getMessage());
            
        } 
    } 
}