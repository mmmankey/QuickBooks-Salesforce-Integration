/**
 * Class defined to be invoked by a screen flow
 * This class will generate an invoice object and serialize it to send to Quickbooks
 * This class is kept as generalized and using placeholder values
 * A data model should be created around populating the invoice data to send to Quickbooks
 * This class will not compile as is
 * An apex test class should be developed and tailored the specific data model
 * A http mock class will need to be developed in order to test the request and response in the apex test context
 */
public with sharing class QuickbooksGenerateInvoice {
    public static final String QB_METADATA_SETTING = 'Quickbooks_Sandbox';

    public static String quickbooksCompanyId {
        get {
            if(String.isBlank(quickbooksCompanyId)) {
                quickbooksCompanyId = [SELECT Id, Company_ID__c FROM Quickbooks_Setting__mdt WHERE DeveloperName = :QB_METADATA_SETTING LIMIT 1].Company_ID__c;
            }

            return quickbooksCompanyId;
        }
        set;
    }

    public static String standardPricebookId {
        get {
            if(String.isBlank(standardPricebookId)) {
                if(!Test.isRunningTest()) {
                    standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true].Id;
                }
                else {
                    standardPricebookId = Test.getStandardPricebookId();
                }
            }

            return standardPricebookId;
        }
        set;
    }

    public QuickbooksGenerateInvoice() {
    }

    @InvocableMethod(Label='Generate Invoice in Quickbooks')
    public static List<FlowOutput> generateQuickbooksInvoice(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        FlowInput input = inputs[0];
        FlowOutput output;

        output = generateQuickbooksInvoice(input.invoicePeriodId);
        outputs.add(output);
        return outputs;
    }

    public static FlowOutput generateQuickbooksInvoice(Id invoicePeriodId) {
        String invoiceJSON = generateInvoiceJSON(invoicePeriodId);
        HttpResponse response;
        FlowOutput output = new FlowOutput();

        try {
            System.debug(invoiceJSON);
            response = sendInvoiceRequest(invoiceJSON);
            output.statusCode = response.getStatusCode();
            output.status = response.getStatus();
            output.message = response.getBody();
        }
        catch(Exception e) {
            System.debug(e.getMessage());
            output.message = e.getMessage();
            throw new CalloutException(e);
        }
        finally {
            if(response.getStatusCode() == 200) {
                invoicePeriod.Invoice_Generated__c = DateTime.Now();
                List<SObject> recordsToUpdate = new List<SObject>{invoicePeriod};
                recordsToUpdate.addAll(timesheetEntries);
                
                update recordsToUpdate;
            }
            else {
                System.debug(response.getStatusCode());
                System.debug(response.getStatus());
                System.debug(response.getBody());
            }

        }

        return output;
    }

    /**
     * Largely data model dependent. 
     * The idea is to get all related data each resource that needs to be in the invoice and summarize the number of hours in each timesheet entry
     * Add parameters to method as needed.
     */
    public static String generateInvoiceJSON() {
        getDataForInvoice();

        //Begin summarizing entries in to one invoice line
        List<QuickbooksInvoiceLine> invoiceLines = new List<QuickbooksInvoiceLine>();

        for(/*iterate over resources */) {
            Decimal hours = 0;
            String description;
            Decimal billableRate;
            Product2 billingProduct;

            for(/*iterate over timesheet entries related to resource */) {
                hours += entry.Hours__c;
            }

            QuickbooksInvoiceLine.SalesItemLineDetail lineSummary = 
                new QuickbooksInvoiceLine.SalesItemLineDetail(hours, billableRate, billingProduct.Name, billingProduct.Quickbooks_Product_Id__c);

            QuickbooksInvoiceLine invoiceLine = new QuickbooksInvoiceLine(lineSummary, description);
            invoiceLines.add(invoiceLine);
        }

        QuickbooksInvoice qbInvoice = 
            new QuickbooksInvoice(invoiceLines, CLIENT_NAME, 
                                  QB_CLIENT_ACCOUNT_ID, QB_PROJECT_ID);
            
        String invoiceJSON = JSON.serialize(qbInvoice);

        return invoiceJSON;
    }

    /**
     * Used for getting all related data for populating the invoice. 
     * This will be very data model dependent
     * Ideally there will be a billing product related to each resource to determine billable rate
     * Timesheets would be related to each individual resource
     * Each resource would then be related to a project that defines the client 
     * Add parameters as needed
     */
    private static void getDataForInvoice() {
        Map<Id, PricebookEntry> mapProductIdToPricebookEntry;

        for(/*iterate over resources assigned to project and collect product2 */) {
            mapProductIdToPricebookEntry.put(assignment.Product__c, null);
        }

        List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, UnitPrice
                                                 FROM PricebookEntry 
                                                 WHERE Pricebook2Id = :standardPricebookId AND Product2Id IN :mapProductIdToPricebookEntry.keySet()];

        for(PricebookEntry pbe : pricebookEntries) {
            mapProductIdToPricebookEntry.put(pbe.Product2Id, pbe);
        }

        //Mapping timesheet entries to Team Members because we need to summarize each timesheet in to one invoice line   
        Map<Id, Timesheet_Object__c> mapTeamMemberIdToTimesheetEntries;                                          
        for(/*iterate over a timesheet object to associate each timesheet to a resource */) {
            Id teamMemberId;

            if(!mapTeamMemberIdToTimesheetEntries.containsKey(teamMemberId)) {
                mapTeamMemberIdToTimesheetEntries.put(teamMemberId, new List<Timesheet_Object__c>{entry});
            }
            else {
                mapTeamMemberIdToTimesheetEntries.get(teamMemberId).add(entry);
            }
        }
    }

    private static HttpResponse sendInvoiceRequest(String invoiceJSON) {
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(invoiceJSON);
        req.setEndpoint('callout:legacy_named_credential' + '/v3/company/' + quickbooksCompanyId + '/invoice?minorversion=73');

        Http http = new Http();
        HttpResponse resp = http.send(req);
        System.debug(resp.getBody());

        return resp;
    }

    public class FlowInput {
        @InvocableVariable(Required=true)
        public String invoicePeriodId;
    }

    public class FlowOutput {
        @InvocableVariable(Required=true)
        public Integer statusCode;

        @InvocableVariable(Required=true)
        public String status;
        
        @InvocableVariable(Required=false)
        public String message;
    }
}