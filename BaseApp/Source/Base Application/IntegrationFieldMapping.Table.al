table 5336 "Integration Field Mapping"
{
    Caption = 'Integration Field Mapping';

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Integration Table Field No."; Integer)
        {
            Caption = 'Integration Table Field No.';
        }
        field(6; Direction; Option)
        {
            Caption = 'Direction';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;

            trigger OnValidate()
            var
                "Field": Record "Field";
                IntegrationTableMapping: Record "Integration Table Mapping";
                CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
                JobQueueEntry: Record "Job Queue Entry";
                CRMIntegrationManagement: Codeunit "CRM Integration Management";
            begin
                if CRMIntegrationManagement.IsOptionMappingEnabled() then begin
                    IntegrationTableMapping.Get("Integration Table Mapping Name");
                    if IntegrationTableMapping."Int. Table UID Field Type" = Field.Type::Option then
                        if Direction = Direction::Bidirectional then
                            Error(OptionMappingCannotBeBidirectionalErr)
                        else begin
                            IntegrationTableMapping.Direction := Direction;
                            IntegrationTableMapping.Modify();

                            if CRMFullSynchReviewLine.Get("Integration Table Mapping Name") then
                                if CRMFullSynchReviewLine.Direction <> Direction then begin
                                    CRMFullSynchReviewLine.Direction := Direction;
                                    CRMFullSynchReviewLine.Modify();
                                end;

                            if Direction = Direction::ToIntegrationTable then begin
                                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
                                JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
                                JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                                if JobQueueEntry.FindFirst() then
                                    if JobQueueEntry.Status = JobQueueEntry.Status::Ready then begin
                                        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
                                        JobQueueEntry.Modify();
                                    end;
                            end;
                        end;
                end;
            end;
        }
        field(7; "Constant Value"; Text[100])
        {
            Caption = 'Constant Value';
        }
        field(8; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
        }
        field(9; "Validate Integration Table Fld"; Boolean)
        {
            Caption = 'Validate Integration Table Fld';
        }
        field(10; "Clear Value on Failed Sync"; Boolean)
        {
            Caption = 'Clear Value on Failed Sync';

            trigger OnValidate()
            begin
                TestField("Not Null", false)
            end;
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
        }
        field(12; "Not Null"; Boolean)
        {
            Caption = 'Not Null';

            trigger OnValidate()
            begin
                TestField("Clear Value on Failed Sync", false);
                if not IsGUIDField then
                    Error(NotNullIsApplicableForGUIDErr);
            end;
        }
        field(13; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            DataClassification = SystemMetadata;
            TableRelation = "Transformation Rule";
        }
        field(14; "Transformation Direction"; Enum "CDS Transformation Direction")
        {
            Caption = 'Transformation Direction';

            trigger OnValidate()
            begin
                PutTransferDirection();
            end;
        }
        field(15; "Use For Match-Based Coupling"; Boolean)
        {
            Caption = 'Use For Match-Based Coupling';
        }
        field(16; "Case-Sensitive Matching"; Boolean)
        {
            Caption = 'Case-Sensitive Matching';
        }
        field(17; "Match Priority"; Integer)
        {
            MinValue = 0;
            BlankZero = true;
            Caption = 'Match Priority';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Integration Table Mapping Name")
        {
        }
        key(Key3; "Match Priority")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NotNullIsApplicableForGUIDErr: Label 'The Not Null value is applicable for GUID fields only.';
        OptionMappingCannotBeBidirectionalErr: Label 'Option mappings can only synchronize from integration table or to integration table.';

    trigger OnInsert()
    begin
        PutTransferDirection();
    end;

    trigger OnModify()
    begin
        PutTransferDirection();
    end;

    procedure CreateRecord(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    begin
        Init;
        "No." := 0;
        "Integration Table Mapping Name" := IntegrationTableMappingName;
        "Field No." := TableFieldNo;
        "Integration Table Field No." := IntegrationTableFieldNo;
        Direction := SynchDirection;
        "Constant Value" := CopyStr(ConstValue, 1, MaxStrLen("Constant Value"));
        "Validate Field" := ValidateField;
        "Validate Integration Table Fld" := ValidateIntegrationTableField;
        Insert;
    end;

    local procedure IsGUIDField(): Boolean
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        TypeHelper: Codeunit "Type Helper";
    begin
        IntegrationTableMapping.Get("Integration Table Mapping Name");
        if TypeHelper.GetField(IntegrationTableMapping."Integration Table ID", "Integration Table Field No.", Field) then
            exit(Field.Type = Field.Type::GUID);
    end;

    local procedure PutTransferDirection()
    begin
        if Direction <> Direction::Bidirectional then
            case Direction of
                Direction::ToIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::ToIntegrationTable;
                Direction::FromIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::FromIntegrationTable;
            end;
    end;
}

