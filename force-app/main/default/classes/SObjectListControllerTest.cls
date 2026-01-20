@IsTest
public class SObjectListControllerTest {

    // Utility method to create test data
    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
        return accounts;
    }

    @isTest
    static void testGetAllSObjects() {
        Test.startTest();
        List<Map<String, String>> allObjects = SObjectListController.getAllSObjects();
        Test.stopTest();

        System.assert(allObjects.size() > 0, 'Should return list of objects');
        System.assert(allObjects[0].containsKey('label'), 'Map should contain label');
        System.assert(allObjects[0].containsKey('apiName'), 'Map should contain apiName');

    }

    @isTest
    static void testGetFieldsForObject() {
        Test.startTest();
        List<Map<String, String>> fields = SObjectListController.getFieldsForObject('Account');
        Test.stopTest();

        System.assert(fields.size() > 0, 'Account should have fields');
        System.assert(fields[0].containsKey('label'), 'Field map should contain label');
        System.assert(fields[0].containsKey('value'), 'Field map should contain value');
        System.assert(fields[0].containsKey('updateable'), 'Field map should contain updateable');
    }

    @isTest
    static void testGetRecordsWithSelectedFields() {
        List<Account> accounts = createTestAccounts(5);
        List<String> fieldNames = new List<String>{'Name'};

        Test.startTest();
        List<Map<String, Object>> records = SObjectListController.getRecordsWithSelectedFields('Account', fieldNames, 10);
        Test.stopTest();

        System.assertEquals(5, records.size(), 'Should return 5 records');
        System.assert(records[0].containsKey('Name'), 'Record should contain Name field');
        System.assert(records[0].containsKey('Id'), 'Record should contain Id field');
    }

    @isTest
    static void testGetRecordsWithSelectedFields_NoFields() {
        Test.startTest();
        List<Map<String, Object>> records = SObjectListController.getRecordsWithSelectedFields('Account', new List<String>(), 10);
        Test.stopTest();
        System.assertEquals(0, records.size(), 'Should return empty list if no fields');
    }

    
    @isTest
    static void checkUpdation(){
        Account acc= new Account(Name='Testing01' , Industry='Education');
        insert acc;
        acc.Name='Testing11';
        
        List<Sobject> records = new List<Sobject>{acc};
               SObjectListController.updateRecords(records);
        Account updatedAcc = [Select Id,Name from Account];
        Assert.areEqual('Testing11',updatedAcc.Name,'both are same means its updated'); 
        
    }


    @isTest
    static void testGetFieldsForInvalidObject() {
        Test.startTest();
        List<Map<String, String>> fields = SObjectListController.getFieldsForObject('NonExistent');
        Test.stopTest();
        Assert.areEqual(0, fields.size(), 'Should return empty list for invalid object');

    }

    @isTest
    static void testGetRecordsWithInvalidObject() {
        Test.startTest();
        List<Map<String, Object>> records = SObjectListController.getRecordsWithSelectedFields('Account', new List<String>(), 10);
        Test.stopTest();
        SObjectListController.getRecordsWithSelectedFields('Account', new List<String>(), 10);


    }

     @isTest
    static void updateDmlTest(){
        List<Account> records2 = new List<Account>();
        for(Integer i=0; i<10;i++){
            records2.add(new Account(Name='Test' + i));
        } 
        
        SObjectListController.updateRecords(records2);
        Assert.areEqual('Failed to update records:' , '','dml error');
    }
}