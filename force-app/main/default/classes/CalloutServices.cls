public class CalloutServices {
    
    //------------------------------------------------------------------------------------------------------------------------------------
    // Generic method that receives API inforation and performs GET http request
    // Parameters:
    // String AssetId retrieved from Record Page
    // Returns: String (json response body)
    //------------------------------------------------------------------------------------------------------------------------------------
    public static string  performGetCallout(String endpoint, String clientId, String clientSecret, String correlationId){
        
        Http http= new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        request.setEndpoint(endpoint);
        request.setHeader('Client-id', clientId);
        request.setHeader('Client-secret', clientSecret);
        request.setHeader('correlation-id', correlationId);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod('GET');
        request.setTimeout(120000);  
        response = http.send(request);

        if(response.getStatusCode() == 200){
            return response.getBody();    
        }else{
            return null;
        }
        
    }
    
    
}