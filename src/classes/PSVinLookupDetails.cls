global class PSVinLookupDetails {
    public static String MANUFACTURER_NAME = 'Manufacturer Name';
    public static String MANUFACTURER_ID = 'Manufacturer Id';
    public static String MAKE = 'Make';
    public static String MODEL = 'Model';
    public static String YEAR = 'Model Year';
    public static String TRIM = 'Trim';
    public static String SERIES = 'Series';
    public static String PLANT_COUNTRY = 'Plant Country';
    public static String PLANT_CITY = 'Plant City';
    public static String VEHICLE_TYPE = 'Vehicle Type';
    public static String FUEL_TYPE = 'Fuel Type - Primary';
    public static String BODY_CLASS = 'Body Class';
    public static String ENGINE_BRAKE_HP = 'Engine Brake (hp)';
    public static String DISPLACEMENT_CC = 'Displacement (CC)';
    public static String DOORS = 'Doors';
    public static String NOTE = 'Note';


    //////////////////////////////////////////////////////////////////////////
    // method to get the VIN details from the NHTSA VIN decode REST service //
    //   - the API is documented here:  https://vpic.nhtsa.dot.gov/api/     //
    //////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    global static String getVINDetails(String vin)
    {
        try
        {
            /////////////////////////////////////////////////
            // call NHTSA VIN REST service for car details //
            /////////////////////////////////////////////////
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            // use a Named Credential for callout; eventually could add security
            request.setEndpoint('callout:NHTSA_Vin_Decode/api/vehicles/decodevin/' + vin  + '?format=json');
             //request.setEndpoint('https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/' + vin  + '?format=json');
            request.setMethod('GET');
            HttpResponse response = http.send(request);

            /////////////////.///////////
            // parse VIN REST response //
            /////////////////////////////
            Map<String, String> output = new Map<String, String>();

            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) {
                System.debug('response=' + response.getBody());

                VINResponse resp = (VINResponse)JSON.deserialize(response.getBody(), VINResponse.class);
                resp.mapParams();
                System.debug('resp=' + JSON.serializePretty(resp));

                output.put(NOTE, resp.getParamValue(NOTE));
                output.put(DISPLACEMENT_CC, resp.getParamValue(DISPLACEMENT_CC));
                output.put(DOORS, resp.getParamValue(DOORS));
                output.put(ENGINE_BRAKE_HP, resp.getParamValue(ENGINE_BRAKE_HP));
                output.put(BODY_CLASS, resp.getParamValue(BODY_CLASS));
                output.put(FUEL_TYPE, resp.getParamValue(FUEL_TYPE));
                output.put(VEHICLE_TYPE, resp.getParamValue(VEHICLE_TYPE));
                output.put(PLANT_COUNTRY, resp.getParamValue(PLANT_COUNTRY));
                output.put(SERIES, resp.getParamValue(SERIES));
                output.put(TRIM, resp.getParamValue(TRIM));
                output.put(YEAR, resp.getParamValue(YEAR));
                output.put(MODEL, resp.getParamValue(MODEL));
                output.put(MAKE, resp.getParamValue(MAKE));
                output.put(MANUFACTURER_ID, resp.getParamValue(MANUFACTURER_ID));
                output.put(MANUFACTURER_NAME, resp.getParamValue(MANUFACTURER_NAME));

            }
            else {
              String err = 'StatusCode:  ' + response.getStatusCode();
              System.debug(err);
              throw new  AuraHandledException(err);
            }

            System.debug('resp=' + JSON.serializePretty(output));

            return JSON.serializePretty(output);
        }
        catch (Exception e) {
            String err = e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']';
            System.debug(err);
            throw new  AuraHandledException(err);
        }
    }

    ////////////////////////////////////////////////////////////////////////
    // method to get VIN number from field of specified record id         //
    //   - to be used on component initialization to autoload VIN details //       
    ////////////////////////////////////////////////////////////////////////
    @AuraEnabled
    global static String getRecordVIN(String recId, String fieldName)
    {
        try
        {
          // get object name based on record id
          Id myId = Id.valueOf(recId);
          String sObjName = myId.getSObjectType().getDescribe().getName();

          // dyanmically query for VIN number from specified fieldName and recordId
          String sql = 'SELECT ' + fieldName + ' FROM ' + sObjName + ' WHERE Id=\'' + recId + '\'';
          List<sObject> sobjList = Database.query(sql);
          if (sobjList != null && sobjList.size() == 1)
          {
             return (String)sobjList[0].get(fieldName);
          }
          else {
              return null;
          }

        }
         catch (Exception e) {
            String err = e.getTypeName() + ' - ' + e.getMessage() + ' [Line: ' + e.getLineNumber() + ']';
            System.debug(err);
            throw new  AuraHandledException(err);
        }
    }

    /////////////////////////////////////////////////////////////////////
    // class to support easy parsing of the NHTSA VIN Decode response  //
    //   - could also use service like https://json2apex.herokuapp.com //
    //////////////////////////////////////////////////////////////////////
    private class VINResponse
    {
        Integer Count;
        String Message;
        String SearchCriteria;
        List<VINResponseParam> Results;
        Map<String, String> paramValueMap;

        private void mapParams()
        {
            paramValueMap = new Map<String, String>();

            if (Results != null)
            {
                for (VINResponseParam p : Results)
                {
                    if (p.Variable != null && p.Value != null)
                    {
                        paramValueMap.put(p.Variable, p.Value);
                    }
                }
            }
        }

        private String getParamValue(String param)
        {
            if (paramValueMap.containsKey(param))
            {
                return paramValueMap.get(param);
            }
            else {
                return '';
            }
        }
    }

    private class VINResponseParam
    {
        String Value;
        String ValueId;
        String Variable;
        Integer VariableId;
    }
}