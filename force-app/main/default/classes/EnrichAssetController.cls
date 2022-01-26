public class EnrichAssetController {
    
    //------------------------------------------------------------------------------------------------------------------------------------
    // Performs callout to retrieve Asset information and updates Asset
    // Parameters:
    // String AssetId retrieved from Record Page
    // Returns: void
    //------------------------------------------------------------------------------------------------------------------------------------
    @AuraEnabled
    public static void calloutAssetInfo(String assetId){
        try{
        API_Info_Meta__mdt metadataAPIInfo = [select id, DeveloperName, Endpoint__c, Client_Id__c, Client_Secret__c, Correlation_Id__c from API_Info_Meta__mdt where DeveloperName = 'Asset_Update'];
        
        Asset assetRecord = [select id, Model_Range__c, Manufacturer__c, Country__c, VIN__c, Vehicle_Number__c from Asset where id = :assetId];
            
        String responseBody = CalloutServices.performGetCallout(metadataAPIInfo.Endpoint__c, metadataAPIInfo.Client_Id__c, metadataAPIInfo.client_Secret__c, metadataAPIInfo.correlation_Id__c);
        AssetWrapper wrapper = AssetWrapper.parse(responseBody);
        assetRecord.Model_Range__c = wrapper.modelRange;
        assetRecord.Manufacturer__c = wrapper.manufacturer;
        assetRecord.Country__c = wrapper.regNumCountryKey;
        assetRecord.VIN__c = wrapper.vin;
        assetRecord.Vehicle_Number__c = wrapper.vehicleNum;
        assetRecord.Vehicle_Type__c = wrapper.vehicleType;
        assetRecord.Type_Variant__c = wrapper.typeVariant;
        assetRecord.Wheel_Base__c = Integer.valueof(wrapper.wheelBase);
        assetRecord.Overhang__c = Integer.valueof(wrapper.overhang);
        assetRecord.Suspension__c = wrapper.suspension;
        assetRecord.Vehicle_Text_Data__c = wrapper.vehicleTextData.informationText.textLine;
        update assetRecord;
        
        }catch (exception ex){
            System.debug('Exception: ' + ex.getMessage());
        }
    }
    
}