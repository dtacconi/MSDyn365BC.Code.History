page 130408 "CAL Test Coverage Map"
{
    Caption = 'CAL Test Coverage Map';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "CAL Test Coverage Map";
    SourceTableView = SORTING("Object Type", "Object ID");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;
                }
                field("Hit by Test Codeunits"; "Hit by Test Codeunits")
                {
                    ApplicationArea = All;
                    Visible = ObjectVisible;

                    trigger OnDrillDown()
                    begin
                        ShowTestCodeunits;
                    end;
                }
                field("Test Codeunit ID"; "Test Codeunit ID")
                {
                    ApplicationArea = All;
                    Visible = TestCodeunitVisible;
                }
                field("Test Codeunit Name"; "Test Codeunit Name")
                {
                    ApplicationArea = All;
                    Visible = TestCodeunitVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportExportTestMap)
            {
                ApplicationArea = All;
                Caption = 'Import/Export';
                Image = ImportExport;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    XMLPORT.Run(XMLPORT::"CAL Test Coverage Map");
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        TestCodeunitVisible := GetFilter("Test Codeunit ID") = '';
        ObjectVisible := (GetFilter("Object ID") = '') and (GetFilter("Object Type") = '');
    end;

    var
        ObjectVisible: Boolean;
        TestCodeunitVisible: Boolean;
}

