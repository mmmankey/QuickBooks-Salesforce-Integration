/**
 * Defines the structure of the individual invoice lines that can be added to the Invoice JSON body
 * This the basic structure. There are addtional optional attributes that can be added
 */
public with sharing class QuickbooksInvoiceLine {
    private final static String SALES_ITEM_LINE_DETAIL = 'SalesItemLineDetail';

    public String DetailType {get;set;}
    public String Description {get;set;}
    public SalesItemLineDetail SalesItemLineDetail {get;set;}
    public Decimal Amount {get;set;}

    public QuickbooksInvoiceLine() {
        DetailType = SALES_ITEM_LINE_DETAIL;
    }

    public QuickbooksInvoiceLine(SalesItemLineDetail lineSummary, String description) {
        this();
        SalesItemLineDetail = lineSummary;
        this.Description = description;
        Amount = lineSummary.Qty * lineSummary.UnitPrice;
    }

    public class SalesItemLineDetail {
        public QuickbooksInvoiceLine.ItemRef ItemRef {get;set;}
        public Decimal Qty {get;set;}
        public Decimal UnitPrice {get;set;}

        public SalesItemLineDetail(Decimal quantity, Decimal rate, String productName, String qbProductId) {
            Qty = quantity;
            UnitPrice = rate;
            ItemRef = new ItemRef(productName, qbProductId);
        }
    }

    public class ItemRef  {
        public String name;
        public String value;

        public ItemRef(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }
}