@isTest
public with sharing class ContactTriggerHandler_Tests {

  @TestSetup
  static void createData(){
    TestFactory.createSObject(New Account(name='AwesomeAccount'), true);
  }

  // POSITIVE Tests
  // Positive tests are those that expect or assert a known value when known good data is input into the unit

    @isTest
    static void setLevelOnInsertTertiaryContact(){
        Id acct1 = [SELECT ID FROM ACCOUNT WHERE Name = 'AwesomeAccount' LIMIT 1].id;
        Test.startTest();
        Contact testContact = (Contact) TestFactory.createSObject(
          new contact(
            FirstName = 'New', 
            LastName = 'TestContact', 
            LeadSource = 'Web', 
            AccountId = acct1
          ), true
        );
        Test.stopTest();
        Contact insertedContact = [SELECT Id, Level__c FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        
        System.assertEquals('Tertiary', insertedContact.Level__c, 'expected to find Tertiary');
    } 
    
    @isTest
    static void insertSecondaryContact(){
        Id acct1 = [SELECT ID FROM ACCOUNT WHERE Name = 'AwesomeAccount' LIMIT 1].id;
        Contact cntctNotPrimary = new Contact(FirstName = 'New', LastName = 'TestContact', LeadSource = 'Partner Referral', AccountId = acct1);
        insert cntctNotPrimary;
        
        List<Contact> insertedContact = [SELECT Id, Level__c FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        
        System.assertEquals('Secondary', insertedContact[0].Level__c);
    }

    @isTest
    static void insertPrimaryContact(){
        Id acct1 = [SELECT ID FROM ACCOUNT WHERE Name = 'AwesomeAccount' LIMIT 1].id;
        Contact cntctPrimary = new Contact(FirstName = 'New', LastName = 'TestContact', LeadSource = 'Purchased List', AccountId = acct1);
        insert cntctPrimary;
        
        List<Contact> insertedContact = [SELECT Id, Level__c FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
        
        System.assertEquals('Primary', insertedContact[0].Level__c);
    }

  // NEGATIVE TESTS
  // Negative Tests are those that expect a specific exception to occur when bad data is put into the unit


    
}