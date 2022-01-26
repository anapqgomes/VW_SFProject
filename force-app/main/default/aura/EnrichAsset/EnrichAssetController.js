({
    callControllerAPI : function(component, event, helper) {
        var action = component.get('c.calloutAssetInfo');
        action.setParams({
            'assetId': component.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": 'Success',
                    "message": 'Asset Updated', 
                    "type": 'success',
                    "mode": "dismissible"
                });
                toastEvent.fire();  
                location.reload();
            }
            
        });
        $A.enqueueAction(action);	
    },

})