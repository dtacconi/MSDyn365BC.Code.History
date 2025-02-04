page 1356 "Posted Service Inv. - Update"
{
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    ShowFilter = false;
    SourceTable = "Service Invoice Header";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for the document.';
                }
            }
            group(Payment)
            {
                Caption = 'Payment';
                field("Payment Method Code"; "Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the customer must pay for products on the service document, such as with bank transfer, cash, or check.';
                }
                field("Payment Reference"; "Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment of the service invoice.';
                }
                field("Company Bank Account Code"; "Company Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        xServiceInvoiceHeader := Rec;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            if RecordChanged() then
                CODEUNIT.Run(CODEUNIT::"Service Inv. Header - Edit", Rec);
    end;

    var
        xServiceInvoiceHeader: Record "Service Invoice Header";

    local procedure RecordChanged() IsChanged: Boolean
    begin
        IsChanged := (Rec."Payment Method Code" <> xServiceInvoiceHeader."Payment Method Code") or
          (Rec."Payment Reference" <> xServiceInvoiceHeader."Payment Reference") or
          (Rec."Company Bank Account Code" <> xServiceInvoiceHeader."Company Bank Account Code");

        OnAfterRecordChanged(Rec, xServiceInvoiceHeader, IsChanged);
    end;

    [Scope('OnPrem')]
    procedure SetRec(ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        Rec := ServiceInvoiceHeader;
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
    end;
}

