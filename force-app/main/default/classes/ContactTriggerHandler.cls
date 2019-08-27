public with sharing class ContactTriggerHandler extends TriggerHandler{
    private Map<Id, Contact> newContactMap;
    private List<Contact> newContactObjects;
    private Map<Id, Contact> oldContactMap;
    @testVisible private Integer count = 0;
    private Map<Id, Boolean> accountOwnerActiveMap = new Map<Id, Boolean>();
    
    public class ContactException extends Exception {}
    
    public ContactTriggerHandler(){
        this.newContactMap = (Map<Id, Contact>) Trigger.newMap;
        this.newContactObjects = Trigger.new;
        this.oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
    }
    
    public override void beforeInsert(){
        accountOwnerActiveMap = verifyAccountOwnerIsActive(newContactObjects);
        setLevelOnInsert(newContactObjects, accountOwnerActiveMap);
    }
    
    public override void afterInsert(){
        insertOpportunity(newContactObjects, oldContactMap);
    }
    
    public override void beforeUpdate(){
        accountOwnerActiveMap = verifyAccountOwnerIsActive(newContactObjects);
        updateLevel(newContactMap, accountOwnerActiveMap);
    }
    
    public override void afterUpdate(){
        insertOpportunity(newContactObjects, oldContactMap);
    }
    
    public Map<Id, Boolean> verifyAccountOwnerIsActive(List<Contact> newContactObjects){
        Map<Id, Boolean> accountOwnerActiveMap = new Map<Id, Boolean>();
        List<Id> contactAccounts = new List<Id>();
        List<Account> accountOwners = new List<Account>();
        for(Contact cntct : newContactObjects){
            contactAccounts.add(cntct.AccountId);
        }
        accountOwners = [SELECT Id, OwnerId, Owner.IsActive FROM Account WHERE Id In : contactAccounts];
        for(Account act : accountOwners){
            // This absolutely could be done without the if/else. I added it purely for our testing purposes.
            if(act.Owner.IsActive == true){
                accountOwnerActiveMap.put(act.Id, true);
            }else if(act.Owner.IsActive == false){
                accountOwnerActiveMap.put(act.Id, false);
            }
        }
        return accountOwnerActiveMap;
    }
    
    public void setLevelOnInsert(List<Contact> newContactObjects, Map<Id, Boolean> accountOwnerActiveMap){
        for(Contact cntct : newContactObjects){
            if(accountOwnerActiveMap.get(cntct.AccountId) == false){
              throw new ContactException('You cannot create a Contact when the Contact\'s Account Owner is inactive. Please make sure the Account has an active Owner and try again.');    
            }
            if(cntct.LeadSource == null){
                throw new ContactException('You must enter a Lead Source.');
            }else if((cntct.LeadSource == 'Web')||(cntct.LeadSource == 'Phone Inquiry')||(cntct.LeadSource == 'Other')){
                cntct.Level__c = 'Tertiary';
            }else if((cntct.LeadSource == 'Partner Referral')||(cntct.LeadSource == 'Public Relations')){
                cntct.Level__c = 'Secondary';
            }else if(cntct.LeadSource == 'Purchased List'){
                cntct.Level__c = 'Primary';
            } 
        }
    }
    
    public void updateLevel(Map<Id, Contact> newContactMap, Map<Id, Boolean> accountOwnerActiveMap){
        List<Contact> contactCases;
        Map<Id, String> casePriority = new Map<Id, String>();
        Map<Id, String> caseStatus = new Map<Id, String>();
        Map<Id, Contact> caseContactMap = new Map<Id, Contact>();
        List<String> priorityList;
        List<String> statusList;
        contactCases = [SELECT Id, AccountId, Level__c, (SELECT Id, Priority, Status FROM Cases) FROM Contact WHERE Id IN : newContactMap.keySet()];
        for(Contact cntct : contactCases){
            if(accountOwnerActiveMap.get(cntct.AccountId) == false){
              throw new ContactException('You cannot update a Contact when the Contact\'s Account Owner is inactive. Please make sure the Account has an active Owner and try again.');    
            }
            for(Case cs : cntct.Cases){
                if(cs != null){
                    caseContactMap.put(cs.Id, cntct);
					casePriority.put(cs.Id, cs.Priority);
                    caseStatus.put(cs.Id, cs.Status);
                }
            }
        }
        if(caseContactMap != null){
            for(Id csId : caseContactMap.keySet()){
                if((casePriority.get(csId) == 'High') && (caseStatus.get(csId) == 'Escalated')){
                    Contact cntct = caseContactMap.get(csId);
                    Contact c = newContactMap.get(cntct.Id);
                    c.Level__c = 'Primary';
                }
            }
        }
    }
    
    public void insertOpportunity(List<Contact> newContactObjects, Map<Id, Contact> oldContactMap){
        Boolean limitReached = false;
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        for(Contact cntct : newContactObjects){
            Date cntctCreatedDate = cntct.CreatedDate.date();
            Date twoWeeksAway = cntctCreatedDate.addDays(14);
            if((oldContactMap == null)&&(cntct.Level__c == 'Primary')){
                Opportunity opp = new Opportunity();
                opp.AccountId = cntct.AccountId;
                opp.Contact__c = cntct.Id;
                opp.Name = cntct.FirstName + ' ' + cntct.LastName + ' - New Primary Contact Opp';
                opp.CloseDate = twoWeeksAway;
                opp.StageName = 'Needs Analysis';
                oppsToInsert.add(opp);
                count++;
            }else if((cntct.Level__c == 'Primary')&&(cntct.Level__c != oldContactMap.get(cntct.Id).Level__c)){
                Opportunity opp = new Opportunity();
                opp.AccountId = cntct.AccountId;
                opp.Contact__c = cntct.Id;
                opp.Name = cntct.FirstName + ' ' + cntct.LastName + ' - New Primary Contact Opp';
                opp.CloseDate = twoWeeksAway;
                opp.StageName = 'Needs Analysis';
                oppsToInsert.add(opp);
                count++;
            }
            if(count > 9999){
                try{
                    Database.insert(oppsToInsert, false);
                    oppsToInsert = new List<Opportunity>();
                    count = 0;
                    limitReached = true;
                    break;    
                }catch(exception e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }
        
        if((limitReached == false) && (!oppsToInsert.isEmpty())){
            try{
                Database.insert(oppsToInsert, false);
            }catch(exception e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }            
        }
    } 
}