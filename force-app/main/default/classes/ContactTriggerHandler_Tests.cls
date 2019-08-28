@isTest
public with sharing class ContactTriggerHandler_Tests {

  @TestSetup
  static void makeData(){
    Account acct = (Account) TestFactory.createSObject(new Account(name='Codey'), true);
  }

  @isTest
    static void insertTertiaryContactPositive(){
      // Query for data created in the testSetup method.
      // we need create a contact
      Account act1 = [SELECT ID, Name FROM Account WHERE name = 'Codey' LIMIT 1];
      Contact cntctNotPrimary = new Contact(FirstName = 'New', LastName = 'TestContact', LeadSource = 'Web', AccountId = act1.Id);

      Test.startTest();
      insert cntctNotPrimary;
      Test.stopTest();
      
      List<Contact> insertedContact = [SELECT Id, Level__c FROM Contact WHERE LastName = 'TestContact' LIMIT 1];
      System.assertEquals('Tertiary', insertedContact[0].Level__c, 'Expect Tertiary because LeadSource is Web');
    }

  @isTest
  static void insertPrimaryContactNoLeadSourceNEGATIVE(){
    Account act1 = [SELECT ID, Name FROM Account WHERE name = 'Codey' LIMIT 1];
    Contact cntctPrimary = new Contact(FirstName = 'New', LastName = 'TestContact', AccountId = act1.Id);

    Boolean exceptionWasThrown = false;
    Test.startTest();
    try{
        insert cntctPrimary; 
    } catch (DMLException theBestException){
      if(theBestException.getMessage().contains('You must enter a Lead Source.')){
        exceptionWasThrown = true;
      }
    }

    system.assert(exceptionWasThrown, 
    'Expected to get a ContactException, with the message "You must enter a lead source" ');


    // catch(Exception ce){
    //     expectedExceptionThrown = ce.getMessage().contains('You must enter a Lead Source.') ? true : false;
    //     System.AssertEquals(true, expectedExceptionThrown);
    // }
  }
}