page 5493 "Cash Flow Statement Entity"
{
    Caption = 'cashFlowStatement', Locked = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTable = "Acc. Schedule Line Entity";
#if not CLEAN18
    PageType = API;
    EntityName = 'cashFlowStatement';
    EntitySetName = 'cashFlowStatement';
    DelayedInsert = true;
#else
    ObsoleteState = Pending;
    ObsoleteReason = 'API version beta will be deprecated. This page will be changed to List type.';
    ObsoleteTag = '18.0';
    PageType = List;
#endif    
    SourceTableTemporary = true;


    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(lineNumber; "Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line No..';
                    Caption = 'LineNumber', Locked = true;
                }
                field(display; Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Description.';
                    Caption = 'Description', Locked = true;
                }
                field(netChange; "Net Change")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Net Change.';
                    AutoFormatType = 0;
                    BlankZero = true;
                    Caption = 'NetChange', Locked = true;
                }
                field(lineType; "Line Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Line Type.';
                    Caption = 'LineType', Locked = true;
                }
                field(indentation; Indentation)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Indentation.';
                    Caption = 'Indentation', Locked = true;
                }
                field(dateFilter; "Date Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Date Filter.';
                    Caption = 'DateFilter', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GraphMgtReports: Codeunit "Graph Mgt - Reports";
        RecVariant: Variant;
        ReportAPIType: Option "Balance Sheet","Income Statement","Trial Balance","CashFlow Statement","Aged Accounts Payable","Aged Accounts Receivable","Retained Earnings";
    begin
        RecVariant := Rec;
        GraphMgtReports.SetUpAccountScheduleBaseAPIDataWrapper(RecVariant, ReportAPIType::"CashFlow Statement");
    end;
}
