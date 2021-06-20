codeunit 138200 "Normal DemoData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Normal]
    end;

    var
        Assert: Codeunit Assert;
        NoPurchHeaderErr: Label 'There is no Purchase Header within the filter.';
        EmptyBlobErr: Label 'BLOB field is empty.';

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The current Company is a Demo Company
        CompanyInformation.Get;
        Assert.IsTrue(CompanyInformation."Demo Company", CompanyInformation.FieldName("Demo Company"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoices()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are no Purchase Invoices to post
        with PurchHeader do begin
            // [WHEN] Post all Invoices
            Reset;
            SetRange("Document Type", "Document Type"::Invoice);
            asserterror FindFirst;
            // [THEN] Error: 'There is no Purchase Header within the filter.'
            Assert.ExpectedError(NoPurchHeaderErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuerySegmentLinesInDemo()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266325] "Tenant Web Service" and "Tenant Web Service OData" contain record for Query "Segment Lines"

        TenantWebService.Get(TenantWebService."Object Type"::Query, 'SegmentLines');
        TenantWebService.TestField("Object ID", QUERY::"Segment Lines");
        TenantWebService.TestField(Published, true);

        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.RecordIsNotEmpty(TenantWebServiceOData);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionGroups()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // [FEATURE] [CRM] [Interaction Group]
        // [SCENARIO 174769] Interaction Group should have 6 groups.
        Assert.RecordCount(InteractionGroup, 8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 15 templates.
        Assert.RecordCount(InteractionTemplate, 40);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingGroupsCount()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [SCENARIO] There are 7 VAT Prod. Posting groups
        Assert.RecordCount(VATProductPostingGroup, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicingEmailMediaResources()
    begin
        // [SCENARIO 213193] Media resources related to invoicing email are imported
        VerifyBLOBMediaResources('INVOICING - SALESMAIL.HTML');
        VerifyBLOBMediaResources('PAYMENT SERVICE - MICROSOFT-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - PAYPAL-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - WORLDPAY-LOGO.PNG');
        VerifyBLOBMediaResources('SOCIAL - FACEBOOK.PNG');
        VerifyBLOBMediaResources('SOCIAL - INSTAGRAM.PNG');
        VerifyBLOBMediaResources('SOCIAL - LINKEDIN.PNG');
        VerifyBLOBMediaResources('SOCIAL - PINTEREST.PNG');
        VerifyBLOBMediaResources('SOCIAL - TWITTER.PNG');
        VerifyBLOBMediaResources('SOCIAL - YELP.PNG');
        VerifyBLOBMediaResources('SOCIAL - YOUTUBE.PNG');
    end;

    local procedure VerifyBLOBMediaResources("Code": Code[50])
    var
        MediaResources: Record "Media Resources";
    begin
        MediaResources.Get(Code);
        MediaResources.CalcFields(Blob);
        Assert.IsTrue(MediaResources.Blob.HasValue, EmptyBlobErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLSetupTaxInvoiceRenamingThreshold()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Tax Invoice Threshold]
        // [SCENARIO 271628] "Tax Invoice Renaming Threshold" is 0.
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.TestField("Tax Invoice Renaming Threshold", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        UsageOption: Option;
    begin
        // [FEATURE] [Electronic Document]
        // [SCENARIO 341241] Electronic document format has setup for PEPPOL BIS3 for all Usage options
        with ElectronicDocumentFormat do
            for UsageOption := Usage::"Sales Invoice" to Usage::"Service Validation" do
                Get('PEPPOL BIS3', UsageOption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobDefaultDimension()
    var
        Job: Record Job;
    begin
        // [FEATURE] [Job] [Dimensions]
        // [SCENARIO 282994] Job default dimensions are the same with bill-to customer default dimensions
        if Job.FindSet then
            repeat
                VerifyJobDefaultDimensions(Job);
            until Job.Next = 0;
    end;

    local procedure VerifyJobDefaultDimensions(Job: Record Job)
    var
        CustDefaultDimension: Record "Default Dimension";
        JobDefaultDimension: Record "Default Dimension";
    begin
        CustDefaultDimension.SetRange("Table ID", DATABASE::Customer);
        CustDefaultDimension.SetRange("No.", Job."Bill-to Customer No.");
        if CustDefaultDimension.FindSet then
            repeat
                JobDefaultDimension.Get(DATABASE::Job, Job."No.", CustDefaultDimension."Dimension Code");
                JobDefaultDimension.TestField("Dimension Value Code", CustDefaultDimension."Dimension Value Code");
            until CustDefaultDimension.Next = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_ReturnPeriodDefaultSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        DummyDateFormula: DateFormula;
    begin
        // [FEATURE] [VAT Return Period]
        // [SCENARIO 258181] TAB 743 "VAT Report Setup" default setup
        with VATReportSetup do begin
            Get;
            TestField("VAT Return Period No. Series");
            TestField("Report Version", '');
            TestField("Period Reminder Calculation", DummyDateFormula);
            TestField("Update Period Job Frequency", "Update Period Job Frequency"::Never);
            TestField("Manual Receive Period CU ID", 0);
            TestField("Receive Submitted Return CU ID", 0);
            TestField("Auto Receive Period CU ID", 0);
        end;
    end;
}

