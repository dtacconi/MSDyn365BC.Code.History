page 2129 "O365 Export Invoices"
{
    Caption = 'Export Invoices';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(StartDate; StartDate)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the starting date of the time period to export invoices';
                }
                field(EndDate; EndDate)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'End Date';
                    ToolTip = 'Specifies the ending date of the time period to export invoices';
                }
                field(Email; Email)
                {
                    ApplicationArea = Basic, Suite, Invoicing;
                    Caption = 'Email';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email recipients for the exported invoices';

                    trigger OnValidate()
                    begin
                        MailManagement.CheckValidEmailAddress(Email);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        Initialize();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> ACTION::OK then
            exit;
        if Email = '' then
            Error(EmailAddressErr);

        O365ExportInvoicesEmail.ExportInvoicesToExcelandEmail(StartDate, EndDate, Email);
    end;

    var
        MailManagement: Codeunit "Mail Management";
        O365ExportInvoicesEmail: Codeunit "O365 Export Invoices + Email";
        StartDate: Date;
        EndDate: Date;
        Email: Text[80];
        EmailAddressErr: Label 'The email address is required.';

    local procedure Initialize()
    var
        O365EmailSetup: Record "O365 Email Setup";
    begin
        StartDate := CalcDate('<-CM>', WorkDate);
        EndDate := WorkDate;
        if O365EmailSetup.FindLast() then
            Email := O365EmailSetup.Email;
    end;
}

