table 99000779 "Production BOM Version"
{
    Caption = 'Production BOM Version';
    DataCaptionFields = "Production BOM No.", "Version Code", Description;
    DrillDownPageID = "Prod. BOM Version List";
    LookupPageID = "Prod. BOM Version List";

    fields
    {
        field(1; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            NotBlank = true;
            TableRelation = "Production BOM Header";
        }
        field(2; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(21; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                ItemUnitOfMeasure: Record "Item Unit of Measure";
            begin
                if (Status = Status::Certified) and ("Unit of Measure Code" <> xRec."Unit of Measure Code") then
                    FieldError(Status);
                Item.SetRange("Production BOM No.", "Production BOM No.");
                if Item.FindSet() then
                    repeat
                        ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code");
                    until Item.Next() = 0;
            end;
        }
        field(22; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(45; Status; Enum "BOM Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
                PlanningAssignment: Record "Planning Assignment";
                ProdBOMCheck: Codeunit "Production BOM-Check";
                SkipCommit: Boolean;
            begin
                if (Status <> xRec.Status) and (Status = Status::Certified) then begin
                    ProdBOMCheck.ProdBOMLineCheck("Production BOM No.", "Version Code");
                    TestField("Unit of Measure Code");
                    ProdBOMHeader.Get("Production BOM No.");
                    ProdBOMHeader."Low-Level Code" := 0;
                    ProdBOMCheck.Code(ProdBOMHeader, "Version Code");
                    PlanningAssignment.NewBOM("Production BOM No.");
                end;
                OnValidateStatusBeforeModify(Rec, xRec, CurrFieldNo);
                Modify(true);
                SkipCommit := false;
                OnValidateStatusBeforeCommit(Rec, SkipCommit);
                if not SkipCommit then
                    Commit();
            end;
        }
        field(50; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Production BOM No.", "Version Code")
        {
            Clustered = true;
        }
        key(Key2; "Production BOM No.", "Starting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.SetRange("Production BOM No.", "Production BOM No.");
        ProdBOMLine.SetRange("Version Code", "Version Code");
        ProdBOMLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        ProdBOMHeader.Get("Production BOM No.");
        if "Version Code" = '' then begin
            ProdBOMHeader.TestField("Version Nos.");
            NoSeriesMgt.InitSeries(ProdBOMHeader."Version Nos.", xRec."No. Series", 0D, "Version Code", "No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        if Status = Status::Certified then
            Error(Text001, TableCaption, FieldCaption(Status), Format(Status));
    end;

    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text001: Label 'You cannot rename the %1 when %2 is %3.';

    procedure AssistEdit(OldProdBOMVersion: Record "Production BOM Version"): Boolean
    begin
        with ProdBOMVersion do begin
            ProdBOMVersion := Rec;
            ProdBOMHeader.Get("Production BOM No.");
            ProdBOMHeader.TestField("Version Nos.");
            if NoSeriesMgt.SelectSeries(ProdBOMHeader."Version Nos.", OldProdBOMVersion."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("Version Code");
                Rec := ProdBOMVersion;
                exit(true);
            end;
        end;
    end;

    procedure Caption(): Text
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdBOMHeader.Get("Production BOM No.") then
            exit('');

        exit(
          CopyStr(StrSubstNo('%1 %2 %3',
            "Production BOM No.", ProdBOMHeader.Description, "Version Code"), 1, 100));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusBeforeModify(var ProductionBOMVersion: Record "Production BOM Version"; var xProductionBOMVersion: Record "Production BOM Version"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusBeforeCommit(var ProductionBOMVersion: Record "Production BOM Version"; var SkipCommit: Boolean)
    begin
    end;
}

