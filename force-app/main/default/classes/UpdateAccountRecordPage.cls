public class UpdateAccountRecordPage {

    public static HttpResponse addPhoneFormulaToFlexiPage() {
        String flexiPageName = 'Account_Record_Page';

        // payload
        // Adjust "regions" and "components" to match your actual page structure
        String body = '{' +
            '"metadata": {' +
                '"fullName": "' + flexiPageName + '",' +
                '"type": "FlexiPage",' +
                '"regions": [' +
                    '{' +
                        '"name": "main",' +
                        '"components": [' +
                            '{' +
                                '"componentName": "force:recordField",' +
                                '"fieldInstance": {"fieldName": "Phone_Formula__c","visible":true}' +
                            '}' +
                        ']' +
                    '}' +
                ']' +
            '},' +
            '"apiVersion": 62.0' +
        '}';

        // Prepare HTTP request using Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MetadataAPI/flexipages/' + flexiPageName);
        req.setMethod('PATCH'); // update existing page
        req.setHeader('Content-Type','application/json');
        req.setBody(body);

        Http http = new Http();
        HttpResponse resp = http.send(req);
        System.debug('Deploy Response: ' + resp.getBody());

        return resp;
    }
}