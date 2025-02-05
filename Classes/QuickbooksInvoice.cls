/**
 * Defines the structure of the Quickbooks Request body for creating an invoice
 * This the basic structure. There are addtional optional attributes that can be added
 */
public with sharing class QuickbooksInvoice {
    public List<QuickbooksInvoiceLine> Line {get;set;}
    public ProjectRef ProjectRef {get;set;}
    public CustomerRef CustomerRef {get;set;}

    public QuickbooksInvoice(List<QuickbooksInvoiceLine> lines, String customerName, String customerId, String projectId) {
        Line = lines;
        ProjectRef = new ProjectRef(projectId);
        CustomerRef = new CustomerRef(customerName, customerId);
    }

    public class ProjectRef  {
        public String value {get;set;}

        public ProjectRef(String projectId) {
            value = projectId;
        }
    }

    public class CustomerRef {
        public String value {get;set;}
        public String name {get;set;}

        public CustomerRef(String customerName, String customerId) {
            value = customerId;
            name = customerName;
        }
    }
}