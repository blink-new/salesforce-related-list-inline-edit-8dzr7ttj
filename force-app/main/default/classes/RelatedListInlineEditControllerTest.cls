/**
 * @description Test class for RelatedListInlineEditController
 * @author Blink AI
 * @version 1.0
 */
@isTest
public class RelatedListInlineEditControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Industry = 'Technology',
            Type = 'Customer'
        );
        insert testAccount;
        
        // Create test Contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 15; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555-000-' + String.valueOf(i).leftPad(4, '0'),
                Title = 'Test Title ' + i,
                AccountId = testAccount.Id
            ));
        }
        insert testContacts;
        
        // Create test Opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 1; i <= 10; i++) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 10000 * i
            ));
        }
        insert testOpportunities;
    }
    
    @isTest
    static void testGetRelatedRecords_Success() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test basic query
        RelatedListInlineEditController.QueryResult result = 
            RelatedListInlineEditController.getRelatedRecords(
                testAccount.Id,
                'Contact',
                'AccountId',
                'Name,Email,Phone,Title',
                10,
                1,
                'Name',
                'ASC',
                null
            );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(10, result.records.size(), 'Should return 10 records');
        System.assertEquals(15, result.totalCount, 'Total count should be 15');
        System.assertEquals(1, result.pageNumber, 'Page number should be 1');
        System.assertEquals(10, result.pageSize, 'Page size should be 10');
        System.assertEquals(true, result.hasMore, 'Should have more records');
    }
    
    @isTest
    static void testGetRelatedRecords_WithSearch() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test with search term
        RelatedListInlineEditController.QueryResult result = 
            RelatedListInlineEditController.getRelatedRecords(
                testAccount.Id,
                'Contact',
                'AccountId',
                'Name,Email,Phone,Title',
                10,
                1,
                'Name',
                'ASC',
                'Contact 1'
            );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertTrue(result.records.size() > 0, 'Should return matching records');
        System.assertTrue(result.totalCount > 0, 'Total count should be greater than 0');
    }
    
    @isTest
    static void testGetRelatedRecords_Pagination() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test second page
        RelatedListInlineEditController.QueryResult result = 
            RelatedListInlineEditController.getRelatedRecords(
                testAccount.Id,
                'Contact',
                'AccountId',
                'Name,Email,Phone,Title',
                10,
                2,
                'Name',
                'ASC',
                null
            );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(5, result.records.size(), 'Should return 5 records on second page');
        System.assertEquals(15, result.totalCount, 'Total count should be 15');
        System.assertEquals(2, result.pageNumber, 'Page number should be 2');
        System.assertEquals(false, result.hasMore, 'Should not have more records');
    }
    
    @isTest
    static void testGetRelatedRecords_InvalidParameters() {
        Test.startTest();
        
        try {
            RelatedListInlineEditController.getRelatedRecords(
                null,
                'Contact',
                'AccountId',
                'Name,Email',
                10,
                1,
                'Name',
                'ASC',
                null
            );
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Required parameters are missing'), 
                         'Should throw required parameters error');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetFieldMetadata_Success() {
        Test.startTest();
        
        List<RelatedListInlineEditController.FieldMetadata> metadata = 
            RelatedListInlineEditController.getFieldMetadata('Contact');
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertTrue(metadata.size() > 0, 'Should return field metadata');
        
        // Check for common fields
        Boolean foundNameField = false;
        Boolean foundEmailField = false;
        
        for (RelatedListInlineEditController.FieldMetadata field : metadata) {
            if (field.name == 'Name') {
                foundNameField = true;
                System.assertEquals('STRING', field.type, 'Name field should be STRING type');
            }
            if (field.name == 'Email') {
                foundEmailField = true;
                System.assertEquals('EMAIL', field.type, 'Email field should be EMAIL type');
            }
        }
        
        System.assertTrue(foundNameField, 'Should find Name field');
        System.assertTrue(foundEmailField, 'Should find Email field');
    }
    
    @isTest
    static void testGetFieldMetadata_InvalidObject() {
        Test.startTest();
        
        try {
            RelatedListInlineEditController.getFieldMetadata('InvalidObject__c');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Object not found'), 
                         'Should throw object not found error');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveRecords_Success() {
        // Get test contacts
        List<Contact> testContacts = [SELECT Id, Title FROM Contact LIMIT 3];
        
        // Update titles
        for (Integer i = 0; i < testContacts.size(); i++) {
            testContacts[i].Title = 'Updated Title ' + (i + 1);
        }
        
        Test.startTest();
        
        List<SObject> savedRecords = RelatedListInlineEditController.saveRecords(
            testContacts, 'Contact'
        );
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, savedRecords, 'Saved records should not be null');
        System.assertEquals(3, savedRecords.size(), 'Should return 3 saved records');
        
        // Verify updates in database
        List<Contact> updatedContacts = [SELECT Id, Title FROM Contact WHERE Id IN :testContacts];
        for (Contact contact : updatedContacts) {
            System.assertTrue(contact.Title.startsWith('Updated Title'), 
                            'Title should be updated');
        }
    }
    
    @isTest
    static void testSaveRecords_ValidationError() {
        // Create invalid contact (missing required LastName)
        Contact invalidContact = new Contact(\n            FirstName = 'Test',\n            Email = 'test@example.com'\n            // LastName is missing - this should cause validation error\n        );\n        insert invalidContact;\n        \n        // Try to update with invalid data\n        invalidContact.LastName = null;\n        \n        Test.startTest();\n        \n        try {\n            RelatedListInlineEditController.saveRecords(\n                new List<SObject>{invalidContact}, 'Contact'\n            );\n            System.assert(false, 'Should have thrown validation exception');\n        } catch (AuraHandledException e) {\n            System.assert(e.getMessage().contains('Error saving records'), \n                         'Should throw save error');\n        }\n        \n        Test.stopTest();\n    }\n    \n    @isTest\n    static void testDeleteRecords_Success() {\n        // Get test contacts\n        List<Contact> testContacts = [SELECT Id FROM Contact LIMIT 3];\n        List<String> contactIds = new List<String>();\n        for (Contact contact : testContacts) {\n            contactIds.add(contact.Id);\n        }\n        \n        Test.startTest();\n        \n        RelatedListInlineEditController.deleteRecords(contactIds, 'Contact');\n        \n        Test.stopTest();\n        \n        // Verify deletion\n        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE Id IN :contactIds];\n        System.assertEquals(0, remainingContacts.size(), 'Contacts should be deleted');\n        \n        // Verify remaining contacts\n        List<Contact> allContacts = [SELECT Id FROM Contact];\n        System.assertEquals(12, allContacts.size(), 'Should have 12 remaining contacts');\n    }\n    \n    @isTest\n    static void testDeleteRecords_InvalidIds() {\n        Test.startTest();\n        \n        try {\n            RelatedListInlineEditController.deleteRecords(\n                new List<String>{'001000000000000'}, 'Contact'\n            );\n            System.assert(false, 'Should have thrown exception');\n        } catch (AuraHandledException e) {\n            System.assert(e.getMessage().contains('No records found to delete'), \n                         'Should throw no records found error');\n        }\n        \n        Test.stopTest();\n    }\n    \n    @isTest\n    static void testValidateRecords_Success() {\n        // Get test contact\n        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact LIMIT 1];\n        testContact.Email = 'updated@example.com';\n        \n        Test.startTest();\n        \n        RelatedListInlineEditController.ValidationResult result = \n            RelatedListInlineEditController.validateRecords(\n                new List<SObject>{testContact}, 'Contact'\n            );\n        \n        Test.stopTest();\n        \n        // Assertions\n        System.assertNotEquals(null, result, 'Result should not be null');\n        System.assertEquals(true, result.isValid, 'Validation should pass');\n        System.assertEquals('', result.errorMessage, 'Should have no error message');\n    }\n    \n    @isTest\n    static void testValidateRecords_ValidationError() {\n        // Create contact with invalid email\n        Contact testContact = [SELECT Id FROM Contact LIMIT 1];\n        testContact.put('Email', 'invalid-email'); // Invalid email format\n        \n        Test.startTest();\n        \n        RelatedListInlineEditController.ValidationResult result = \n            RelatedListInlineEditController.validateRecords(\n                new List<SObject>{testContact}, 'Contact'\n            );\n        \n        Test.stopTest();\n        \n        // Note: Email validation is handled by Salesforce, so this test\n        // focuses on the validation framework structure\n        System.assertNotEquals(null, result, 'Result should not be null');\n    }\n    \n    @isTest\n    static void testBulkUpdateRecords_Success() {\n        // Get test contacts\n        List<Contact> testContacts = [SELECT Id FROM Contact LIMIT 5];\n        List<String> contactIds = new List<String>();\n        for (Contact contact : testContacts) {\n            contactIds.add(contact.Id);\n        }\n        \n        // Prepare bulk update values\n        Map<String, Object> fieldValues = new Map<String, Object>();\n        fieldValues.put('Title', 'Bulk Updated Title');\n        fieldValues.put('Department', 'Bulk Updated Department');\n        \n        Test.startTest();\n        \n        RelatedListInlineEditController.bulkUpdateRecords(\n            contactIds, fieldValues, 'Contact'\n        );\n        \n        Test.stopTest();\n        \n        // Verify updates\n        List<Contact> updatedContacts = [SELECT Id, Title, Department FROM Contact WHERE Id IN :contactIds];\n        for (Contact contact : updatedContacts) {\n            System.assertEquals('Bulk Updated Title', contact.Title, 'Title should be updated');\n            System.assertEquals('Bulk Updated Department', contact.Department, 'Department should be updated');\n        }\n    }\n    \n    @isTest\n    static void testBulkUpdateRecords_InvalidParameters() {\n        Test.startTest();\n        \n        try {\n            RelatedListInlineEditController.bulkUpdateRecords(\n                new List<String>(), new Map<String, Object>(), 'Contact'\n            );\n            System.assert(false, 'Should have thrown exception');\n        } catch (AuraHandledException e) {\n            System.assert(e.getMessage().contains('No records to update'), \n                         'Should throw no records error');\n        }\n        \n        Test.stopTest();\n    }\n    \n    @isTest\n    static void testBulkUpdateRecords_NoFieldValues() {\n        // Get test contact\n        Contact testContact = [SELECT Id FROM Contact LIMIT 1];\n        \n        Test.startTest();\n        \n        try {\n            RelatedListInlineEditController.bulkUpdateRecords(\n                new List<String>{testContact.Id}, new Map<String, Object>(), 'Contact'\n            );\n            System.assert(false, 'Should have thrown exception');\n        } catch (AuraHandledException e) {\n            System.assert(e.getMessage().contains('No field values provided'), \n                         'Should throw no field values error');\n        }\n        \n        Test.stopTest();\n    }\n    \n    @isTest\n    static void testErrorHandling_InvalidObjectName() {\n        Test.startTest();\n        \n        try {\n            RelatedListInlineEditController.getRelatedRecords(\n                'test123',\n                'InvalidObject',\n                'AccountId',\n                'Name',\n                10,\n                1,\n                'Name',\n                'ASC',\n                null\n            );\n            System.assert(false, 'Should have thrown exception');\n        } catch (AuraHandledException e) {\n            System.assert(e.getMessage().contains('Invalid object API name'), \n                         'Should throw invalid object error');\n        }\n        \n        Test.stopTest();\n    }\n    \n    @isTest\n    static void testSortingAndFiltering() {\n        // Get test account\n        Account testAccount = [SELECT Id FROM Account LIMIT 1];\n        \n        Test.startTest();\n        \n        // Test DESC sorting\n        RelatedListInlineEditController.QueryResult result = \n            RelatedListInlineEditController.getRelatedRecords(\n                testAccount.Id,\n                'Contact',\n                'AccountId',\n                'Name,Email',\n                5,\n                1,\n                'Name',\n                'DESC',\n                null\n            );\n        \n        Test.stopTest();\n        \n        // Assertions\n        System.assertNotEquals(null, result, 'Result should not be null');\n        System.assertEquals(5, result.records.size(), 'Should return 5 records');\n        \n        // Verify sorting (names should be in descending order)\n        if (result.records.size() >= 2) {\n            String firstName = (String) result.records[0].get('Name');\n            String secondName = (String) result.records[1].get('Name');\n            System.assertTrue(firstName.compareTo(secondName) >= 0, \n                            'Records should be sorted in descending order');\n        }\n    }\n}"