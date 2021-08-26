table 11401 "CBG Statement Line"
{
    Caption = 'CBG Statement Line';
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Employee Ledger Entry" = rimd,
                  TableData "Data Exch. Field" = rimd;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(2; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = "CBG Statement"."No." WHERE("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';

            trigger OnValidate()
            begin
                GenerateDocumentNo;
            end;
        }
        field(7; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
        }
        field(8; "Statement Type"; Option)
        {
            Caption = 'Statement Type';
            Editable = false;
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(9; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            Editable = false;
            TableRelation = IF ("Statement Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Statement Type" = CONST("Bank Account")) "Bank Account"."No.";
        }
        field(10; Date; Date)
        {
            Caption = 'Date';

            trigger OnValidate()
            begin
                TestField(Date);
                if (Date <> xRec.Date) and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolCBGJnl(Rec);

                ValidateApplyRequirements(Rec);
            end;
        }
        field(12; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account,Employee';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account",Employee;

            trigger OnValidate()
            begin
                case xRec."Account Type" of
                    "Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee:
                        DeleteAppliesToID(xRec);
                end;
                Validate("Account No.", '');
            end;
        }
        field(13; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Account Type" = CONST(Customer)) Customer."No."
            ELSE
            IF ("Account Type" = CONST(Vendor)) Vendor."No."
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"."No."
            ELSE
            IF ("Account Type" = CONST(Employee)) Employee."No.";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
                OriginalDescription: Boolean;
                Cust: Record Customer;
                Vend: Record Vendor;
                Employee: Record Employee;
                BankAccount: Record "Bank Account";
            begin
                "Applies-to Doc. Type" := "Applies-to Doc. Type"::" ";
                "Applies-to Doc. No." := '';
                "VAT Bus. Posting Group" := '';
                "VAT Prod. Posting Group" := '';
                "VAT %" := 0;
                "VAT Type" := "VAT Type"::" ";

                OriginalDescription := false;
                case xRec."Account Type" of
                    "Account Type"::"G/L Account":
                        if GLAccount.Get(xRec."Account No.") then
                            OriginalDescription := GLAccount.Name = Description;
                    "Account Type"::Customer:
                        begin
                            if Cust.Get(xRec."Account No.") then
                                OriginalDescription := Cust.Name = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::Vendor:
                        begin
                            if Vend.Get(xRec."Account No.") then
                                OriginalDescription := Vend.Name = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::Employee:
                        begin
                            if Employee.Get(xRec."Account No.") then
                                OriginalDescription := Employee.FullName = Description;
                            DeleteAppliesToID(xRec);
                        end;
                    "Account Type"::"Bank Account":
                        if BankAccount.Get(xRec."Account No.") then
                            OriginalDescription := BankAccount.Name = Description;
                end;

                if "Account No." = '' then begin
                    if OriginalDescription then
                        Description := '';
                    CreateDim(
                      DimManagement.TypeToTableID1("Account Type"), "Account No.",
                      0, '',
                      DATABASE::Job, "Job No.",
                      DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                      DATABASE::Campaign, "Campaign No.");
                    exit;
                end;

                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            GLAccount.Get("Account No.");
                            GLAccount.CheckGLAcc;
                            GLAccount.TestField("Direct Posting", true);
                            if (OriginalDescription or (Description = '')) and
                               (not GLAccount."Omit Default Descr. in Jnl.")
                            then
                                Description := GLAccount.Name
                            else
                                if GLAccount."Omit Default Descr. in Jnl." then
                                    Description := '';
                            GetCBGStatementHeader;
                            JrnlTemplate.Get("Journal Template Name");

                            if JrnlTemplate."Copy VAT Setup to Jnl. Lines" then begin
                                "VAT Bus. Posting Group" := GLAccount."VAT Bus. Posting Group";
                                "VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
                            end;
                            case GLAccount."Gen. Posting Type" of
                                GLAccount."Gen. Posting Type"::" ":
                                    "VAT Type" := "VAT Type"::" ";
                                GLAccount."Gen. Posting Type"::Purchase:
                                    "VAT Type" := "VAT Type"::Purchase;
                                GLAccount."Gen. Posting Type"::Sale:
                                    "VAT Type" := "VAT Type"::Sale;
                                else
                                    GLAccount.FieldError("Gen. Posting Type", Text1000000);
                            end;
                            Validate("VAT Prod. Posting Group");
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            if Cust."Privacy Blocked" then
                                Cust.CustPrivacyBlockedErrorMessage(Cust, false);
                            if Cust.Blocked in [Cust.Blocked::All] then
                                Cust.CustBlockedErrorMessage(Cust, false);
                            if OriginalDescription or (Description = '') then
                                Description := Cust.Name;
                            "Salespers./Purch. Code" := Cust."Salesperson Code";
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            if Vend."Privacy Blocked" then
                                Vend.VendPrivacyBlockedErrorMessage(Vend, false);
                            if Vend.Blocked in [Vend.Blocked::All] then
                                Vend.VendBlockedErrorMessage(Vend, false);
                            if OriginalDescription or (Description = '') then
                                Description := Vend.Name;
                            "Salespers./Purch. Code" := Vend."Purchaser Code";
                        end;
                    "Account Type"::Employee:
                        begin
                            Employee.Get("Account No.");
                            if OriginalDescription or (Description = '') then
                                Description := CopyStr(Employee.FullName, 1, MaxStrLen(Description));
                            "Salespers./Purch. Code" := Employee."Salespers./Purch. Code";
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAccount.Get("Account No.");
                            BankAccount.TestField(Blocked, false);
                            if OriginalDescription or (Description = '') then
                                Description := BankAccount.Name;
                        end;
                end;

                Validate(Amount);
                CreateDim(DimManagement.TypeToTableID1("Account Type"), "Account No.",
                  0, '',
                  DATABASE::Job, "Job No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(14; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(15; Debit; Decimal)
        {
            Caption = 'Debit';

            trigger OnValidate()
            begin
                Correction := Debit < 0;
                Validate(Amount, Debit);
            end;
        }
        field(16; Credit; Decimal)
        {
            Caption = 'Credit';

            trigger OnValidate()
            begin
                Correction := Credit < 0;
                Validate(Amount, -Credit);
            end;
        }
        field(17; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(18; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';

            trigger OnLookup()
            var
                GenJnlLine: Record "Gen. Journal Line" temporary;
            begin
                CreateGenJournalLine(GenJnlLine);
                GenJnlLine."Lookup Applies-to Doc. No.";
                ReadGenJournalLine(GenJnlLine);
            end;

            trigger OnValidate()
            begin
                if not PaymentToleranceMgt.PmtTolCBGJnl(Rec) then
                    exit;
            end;
        }
        field(19; Correction; Boolean)
        {
            Caption = 'Correction';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(20; Amount; Decimal)
        {
            Caption = 'Amount';

            trigger OnValidate()
            begin
                UpdateLineBalance;
                CalculateVAT;
                if (Amount <> xRec.Amount) and (Amount <> 0) then
                    PaymentToleranceMgt.PmtTolCBGJnl(Rec);
            end;
        }
        field(21; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';

            trigger OnValidate()
            var
                CBGStatementln: Record "CBG Statement Line";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeAppliesToIDOnValidate(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Applies-to ID" <> '' then begin
                    CBGStatementln.SetCurrentKey("Journal Template Name", "No.", "Applies-to ID");
                    CBGStatementln.SetRange("Journal Template Name", "Journal Template Name");
                    CBGStatementln.SetRange("No.", "No.");
                    CBGStatementln.SetRange("Applies-to ID", "Applies-to ID");
                    CBGStatementln.SetFilter("Line No.", '<>%1', "Line No.");
                    if CBGStatementln.FindFirst then
                        Error(Text1000001,
                          FieldCaption("Applies-to ID"),
                          "Applies-to ID",
                          CBGStatementln."Journal Template Name",
                          CBGStatementln."No.",
                          CBGStatementln."Line No.");
                end;
            end;
        }
        field(26; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DimManagement.TypeToTableID1("Account Type"), "Account No.",
                  0, '',
                  DATABASE::Job, "Job No.",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(30; "Amount incl. VAT"; Boolean)
        {
            Caption = 'Amount incl. VAT';

            trigger OnValidate()
            begin
                Validate(Amount);
            end;
        }
        field(31; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                CalculateVAT;
            end;
        }
        field(32; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                CalculateVAT;
            end;
        }
        field(33; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
        }
        field(35; "VAT Type"; Option)
        {
            BlankZero = true;
            Caption = 'VAT Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;

            trigger OnValidate()
            begin
                CalculateVAT;
            end;
        }
        field(36; "Debit Incl. VAT"; Decimal)
        {
            Caption = 'Debit Incl. VAT';
            Editable = false;
        }
        field(37; "Credit Incl. VAT"; Decimal)
        {
            Caption = 'Credit Incl. VAT';
        }
        field(38; "Debit VAT"; Decimal)
        {
            Caption = 'Debit VAT';
        }
        field(39; "Credit VAT"; Decimal)
        {
            Caption = 'Credit VAT';
        }
        field(40; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(42; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            Editable = false;
            TableRelation = Job;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Job, "Job No.",
                  DimManagement.TypeToTableID1("Account Type"), "Account No.",
                  0, '',
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code",
                  DATABASE::Campaign, "Campaign No.");
            end;
        }
        field(50; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5050; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;

            trigger OnValidate()
            begin
                CreateDim(
                  DATABASE::Campaign, "Campaign No.",
                  DimManagement.TypeToTableID1("Account Type"), "Account No.",
                  0, '',
                  DATABASE::Job, "Job No.",
                  DATABASE::"Salesperson/Purchaser", "Salespers./Purch. Code");
            end;
        }
        field(11400; "Amount Settled"; Decimal)
        {
            Caption = 'Amount Settled';
        }
        field(11401; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        field(11402; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        field(11000000; Identification; Code[80])
        {
            Caption = 'Identification';

            trigger OnLookup()
            begin
                IdentificationLookup;
            end;

            trigger OnValidate()
            var
                PaymentHistLine: Record "Payment History Line";
                CBGStatementLine: Record "CBG Statement Line";
            begin
                if not (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) or ("Account No." = '')) then begin
                    Identification := '';
                    Message(Text1000002);
                end;

                if Identification <> '' then begin
                    TestField("Statement Type", "Statement Type"::"Bank Account");
                    CBGStatementLine.SetCurrentKey("Statement Type", "Statement No.", Identification);
                    CBGStatementLine.SetRange("Statement Type", "Statement Type");
                    CBGStatementLine.SetRange("Statement No.", "Statement No.");
                    CBGStatementLine.SetRange(Identification, Identification);
                    if CBGStatementLine.Find('-') then
                        repeat
                            if (CBGStatementLine."Journal Template Name" <> "Journal Template Name") or
                               (CBGStatementLine."No." <> CBGStatementLine."No.") or
                               (CBGStatementLine."Line No." <> "Line No.")
                            then
                                Error(
                                  Text1000003 +
                                  Text1000004,
                                  CBGStatementLine.FieldCaption(Identification),
                                  CBGStatementLine.Identification,
                                  CBGStatementLine."Journal Template Name", CBGStatementLine."No.");
                        until CBGStatementLine.Next() = 0;

                    PaymentHistLine.SetCurrentKey("Our Bank", Identification);
                    PaymentHistLine.SetRange("Our Bank", "Statement No.");
                    PaymentHistLine.SetRange(Identification, Identification);
                    PaymentHistLine.FindFirst;

                    GetCBGStatementHeader;
                    CBGStatementLine := Rec;
                    Init;
                    InitRecord(CBGStatementLine);

                    if CBGStatementLine."Account No." = '' then begin
                        case PaymentHistLine."Account Type" of
                            PaymentHistLine."Account Type"::Customer:
                                Validate("Account Type", "Account Type"::Customer);
                            PaymentHistLine."Account Type"::Vendor:
                                Validate("Account Type", "Account Type"::Vendor);
                            PaymentHistLine."Account Type"::Employee:
                                Validate("Account Type", "Account Type"::Employee);
                        end;
                    end else begin
                        case CBGStatementLine."Account Type" of
                            "Account Type"::Customer:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Customer);
                            "Account Type"::Vendor:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Vendor);
                            "Account Type"::Employee:
                                PaymentHistLine.TestField("Account Type", PaymentHistLine."Account Type"::Employee);
                            else
                                Error(AccountTypeErr, CBGStatementLine."Account Type");
                        end;
                        PaymentHistLine.TestField("Account No.", CBGStatementLine."Account No.");
                    end;
                    Validate("Account No.", PaymentHistLine."Account No.");

                    if CBGStatementLine.Description = '' then
                        Validate(Description, PaymentHistLine."Description 1")
                    else
                        Validate(Description, CBGStatementLine.Description);

                    if CBGStatementLine.Date = 0D then
                        Validate(Date, PaymentHistLine.Date)
                    else
                        Validate(Date, CBGStatementLine.Date);

                    if CBGStatement.Currency <> PaymentHistLine."Currency Code" then
                        Error(Text1000006,
                          CBGStatement.Currency, PaymentHistLine."Currency Code");
                    "Amount Settled" := PaymentHistLine.Amount;
                    "Applies-to ID" := "New Applies-to ID";
                    SetApplyCVLedgerEntries(PaymentHistLine);
                    if CBGStatementLine.Amount = 0 then
                        Validate(Amount, PaymentHistLine.Amount)
                    else begin
                        PaymentHistLine.TestField(Amount, CBGStatementLine.Amount);
                        Validate(Amount, CBGStatementLine.Amount)
                    end;
                    Identification := CBGStatementLine.Identification;
                    if CBGStatementLine."Shortcut Dimension 1 Code" <> '' then
                        Validate("Shortcut Dimension 1 Code", CBGStatementLine."Shortcut Dimension 1 Code");
                    if CBGStatementLine."Shortcut Dimension 2 Code" <> '' then
                        Validate("Shortcut Dimension 2 Code", CBGStatementLine."Shortcut Dimension 2 Code");
                    "Dimension Set ID" := PaymentHistLine."Dimension Set ID";
                end;
            end;
        }
        field(11000001; "Reconciliation Status"; Option)
        {
            Caption = 'Reconciliation Status';
            Editable = false;
            OptionCaption = 'Unknown,Changed,Applied';
            OptionMembers = Unknown,Changed,Applied;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Debit, Credit, "Debit Incl. VAT", "Credit Incl. VAT", "Debit VAT", "Credit VAT";
        }
        key(Key2; "Statement Type", "Statement No.", Identification)
        {
        }
        key(Key3; "Journal Template Name", "No.", "Applies-to ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CBGStatementlineDescription: Record "CBG Statement Line Add. Info.";
    begin
        CBGStatementlineDescription.SetCurrentKey("Journal Template Name", "CBG Statement No.", "CBG Statement Line No.", "Line No.");
        CBGStatementlineDescription.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementlineDescription.SetRange("CBG Statement No.", "No.");
        CBGStatementlineDescription.SetRange("CBG Statement Line No.", "Line No.");
        CBGStatementlineDescription.DeleteAll(true);
        DeleteAppliesToID(Rec);
        ClearDataExchEntries;
    end;

    trigger OnInsert()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        GetCBGStatementHeader;

        if (CBGStatement.Type = CBGStatement.Type::Cash) and ("Document No." = '') then
            GenerateDocumentNo;

        JrnlTemplate.Get("Journal Template Name");

        CBGStatementLine.Reset();
        CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
        CBGStatementLine.SetRange("No.", CBGStatement."No.");
        if (CBGStatement.Type = CBGStatement.Type::"Bank/Giro") and CBGStatementLine.IsEmpty and (Date = 0D) then
            Date := CBGStatement.Date;
    end;

    var
        Text1000000: Label 'is not allowed in a Cash or Bank Journal';
        Text1000001: Label '%1 %2 is used before in %2 %4 line %5';
        Text1000002: Label 'The identification is only used with customers, vendors, and employees.';
        Text1000003: Label '%1 %2 is already used in:\';
        Text1000004: Label 'Bank Journal %3 (%4)\';
        AccountTypeErr: Label '%1 must be customer, vendor, or employee.', Comment = '%1 - account type';
        Text1000006: Label 'The currency of the bank journal "%1" and the currency of the payment history line "%2" must be equal.';
        Text1000007: Label 'D';
        Text1000008: Label 'DI';
        Text1000009: Label 'C';
        Text1000010: Label 'CI';
        Text1000011: Label 'NC';
        Text1000012: Label 'NCI';
        Text1000013: Label 'CBI';
        Text1000014: Label 'B';
        Text1000015: Label 'Account No.?';
        Text1000016: Label 'DEFAULT';
        Text1000017: Label 'The posting date is not filled in correctly on bank journal %1 line %2\';
        Text1000018: Label 'The document date is not filled in correctly on cash journal %1 line %2\';
        Text1000019: Label 'Use G/L Account for %1 when you use Full VAT';
        Text1000020: Label 'When %1 = %2  than %3 (%4) must be equal to %5 (%6) from the VAT Posting Setup table';
        Text1000021: Label 'is not supported in the Cash, Bank or Giro Journal';
        Text1000022: Label 'The combination %1-%2 and %3=%4 does not exist in the VAT setup!\';
        Text1000023: Label 'Therefore it is not possible to calculate %5.';
        Text1000024: Label 'To calculate the VAT it is necessary to fill in %1\\';
        Text1000025: Label 'Fill in the fields %2, %3 and %4 in G/L Account %5 and re-enter the line\\';
        Text1000026: Label 'or\\';
        Text1000027: Label 'Use Show Column to display the necessary fields in this form';
        Text1000028: Label 'You can only apply VAT when %1 = G/L Account';
        Currency: Record Currency;
        CBGStatement: Record "CBG Statement";
        JrnlTemplate: Record "Gen. Journal Template";
        DimManagement: Codeunit DimensionManagement;
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        TypeHelper: Codeunit "Type Helper";
        DateParseErr: Label 'Could not read a date from text ''%1'' using format %2.', Comment = '%1=a string representing a date like 081001,%2=a string representing a format like yyMMdd';
        FinancialInterfaceTelebank: Codeunit "Financial Interface Telebank";
        PostingDateEarlierErr: Label 'You cannot apply to an entry with a posting date before the posting date of the entry that you want to apply.';

    [Scope('OnPrem')]
    procedure InitRecord(LastRecord: Record "CBG Statement Line")
    begin
        GetCBGStatementHeader;

        "Statement Type" := CBGStatement."Account Type";
        "Statement No." := CBGStatement."Account No.";
        "VAT Type" := "VAT Type"::" ";

        case CBGStatement.Type of
            CBGStatement.Type::Cash:
                if Date = 0D then
                    Date := WorkDate;
            CBGStatement.Type::"Bank/Giro":
                if Date = 0D then begin
                    if LastRecord.Date = 0D then
                        Date := CBGStatement.Date
                    else
                        Date := LastRecord.Date;
                end;
        end;

        "Account Type" := LastRecord."Account Type";
        "Applies-to Doc. Type" := LastRecord."Applies-to Doc. Type";
        "Amount incl. VAT" := LastRecord."Amount incl. VAT";
    end;

    [Obsolete('Function scope will be changed to OnPrem', '15.1')]
    procedure UpdateLineBalance()
    begin
        if ((Amount > 0) and (not Correction)) or
           ((Amount < 0) and Correction)
        then begin
            Debit := Amount;
            Credit := 0
        end else begin
            Debit := 0;
            Credit := -Amount;
        end;
    end;

    procedure TotalNetChange(DCNC: Code[10]) Tot: Decimal
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
        CBGStatementLine.SetRange("No.", "No.");
        case DCNC of
            Text1000007: // Total debit
                begin
                    CBGStatementLine.CalcSums(Debit);
                    Tot := CBGStatementLine.Debit;
                end;
            Text1000008: // Total Debit Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Debit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT";
                end;
            Text1000009: // Total Credit
                begin
                    CBGStatementLine.CalcSums(Credit);
                    Tot := CBGStatementLine.Credit;
                end;
            Text1000010: // Total Credit Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Credit Incl. VAT");
                    Tot := CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000011: // Total Net Change
                begin
                    CBGStatementLine.CalcSums(Debit, Credit);
                    Tot := CBGStatementLine.Debit - CBGStatementLine.Credit;
                end;
            Text1000012: // Total Net Change Incl. VAT
                begin
                    CBGStatementLine.CalcSums("Debit Incl. VAT", "Credit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT" - CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000013: // Current Net Change Incl. VAT
                begin
                    if "Line No." <> 0 then
                        CBGStatementLine.SetFilter("Line No.", '..%1', "Line No.");
                    CBGStatementLine.CalcSums("Debit Incl. VAT", "Credit Incl. VAT");
                    Tot := CBGStatementLine."Debit Incl. VAT" - CBGStatementLine."Credit Incl. VAT";
                end;
            Text1000014: // Total VAT
                begin
                    CBGStatementLine.CalcSums("Debit VAT", "Credit VAT");
                    Tot := CBGStatementLine."Debit VAT" - CBGStatementLine."Credit VAT";
                end;
        end;
    end;

    procedure GetAccountName() Name: Text[100]
    var
        GLAccount: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                case false of
                    GLAccount.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := GLAccount.Name;
                end;
            "Account Type"::"Bank Account":
                case false of
                    BankAccount.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := BankAccount.Name;
                end;
            "Account Type"::Customer:
                case false of
                    Cust.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Cust.Name;
                end;
            "Account Type"::Vendor:
                case false of
                    Vend.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Vend.Name;
                end;
            "Account Type"::Employee:
                case false of
                    Employee.Get("Account No."):
                        Name := Text1000015;
                    else
                        Name := Employee.FullName;
                end;
        end;
    end;

    procedure CreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CBGStatement: Record "CBG Statement";
    begin
        CheckAccountNo();
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := "Journal Template Name";
        GenJnlLine."Journal Batch Name" := Text1000016;// STRSUBSTNO('%1',"No.");
        GenJnlLine."Line No." := 0;

        GenJnlLine.Validate("Posting Date", Date);
        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                    case "VAT Type" of
                        "VAT Type"::Purchase:
                            if Credit = 0 then
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
                            else
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                        "VAT Type"::Sale:
                            if Debit = 0 then
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
                            else
                                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                    end;
                end;
            "Account Type"::Customer:
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
                    if Debit = 0 then
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
                    else
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
                end;
            "Account Type"::Vendor:
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                    if Credit = 0 then
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment
                    else
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Refund;
                end;
            "Account Type"::Employee:
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                end;
            "Account Type"::"Bank Account":
                begin
                    GenJnlLine."Account Type" := GenJnlLine."Account Type"::"Bank Account";
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                end;
        end;

        GenJnlLine.Validate("Account No.", "Account No.");

        CBGStatement.Get("Journal Template Name", "No.");
        case CBGStatement.Type of
            CBGStatement.Type::"Bank/Giro":
                begin
                    if Date = 0D then
                        Error(Text1000017 +
                          '%3 %4 %5', "No.", "Line No.", GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.Description);
                    GenJnlLine.Validate("Posting Date", Date);
                    GenJnlLine.Validate("Document Date", CBGStatement.Date);
                    GenJnlLine.Validate("Document No.", CBGStatement."Document No.");
                end;
            CBGStatement.Type::Cash:
                begin
                    if Date = 0D then
                        Error(Text1000018 +
                          '%3 %4 %5', "No.", "Line No.", GenJnlLine."Account Type", GenJnlLine."Account No.", GenJnlLine.Description);
                    GenJnlLine.Validate("Posting Date", Date);
                    GenJnlLine.Validate("Document Date", Date);
                    GenJnlLine.Validate("Document No.", "Document No.");
                end;
        end;

        if "Shortcut Dimension 1 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        if "Shortcut Dimension 2 Code" <> '' then
            GenJnlLine.Validate("Shortcut Dimension 2 Code", "Shortcut Dimension 2 Code");
        if "Dimension Set ID" <> 0 then
            GenJnlLine.Validate("Dimension Set ID", "Dimension Set ID");

        GenJnlLine.Validate("Currency Code", CBGStatement.Currency);
        case "VAT Type" of
            "VAT Type"::" ":
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
            "VAT Type"::Purchase:
                begin
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Purchase;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                end;
            "VAT Type"::Sale:
                begin
                    GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::Sale;
                    GenJnlLine."Document Type" := GenJnlLine."Document Type"::Invoice;
                end;
        end;

        GenJnlLine."VAT Bus. Posting Group" := "VAT Bus. Posting Group";
        GenJnlLine.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");

        if Correction then
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";

        GenJnlLine.Description := Description;
        if "Applies-to Doc. No." <> '' then begin
            GenJnlLine.Validate("Applies-to Doc. Type", "Applies-to Doc. Type");
            GenJnlLine.Validate("Applies-to Doc. No.", "Applies-to Doc. No.");
        end else
            if "Applies-to ID" <> '' then
                GenJnlLine.Validate("Applies-to ID", "Applies-to ID");

        if "Debit Incl. VAT" <> 0 then begin
            GenJnlLine.Amount := "Debit Incl. VAT";
            GenJnlLine.Validate("Debit Amount", "Debit Incl. VAT")
        end else begin
            GenJnlLine.Amount := -"Credit Incl. VAT";
            GenJnlLine.Validate("Credit Amount", "Credit Incl. VAT");
        end;

        if GenJnlLine."VAT Calculation Type" <> GenJnlLine."VAT Calculation Type"::"Full VAT" then
            if ("Debit VAT" <> 0) and ("Debit VAT" <> GenJnlLine."VAT Amount") then
                GenJnlLine.Validate("VAT Amount", "Debit VAT")
            else
                if ("Credit VAT" <> 0) and (-"Credit VAT" <> GenJnlLine."VAT Amount") then
                    GenJnlLine.Validate("VAT Amount", -"Credit VAT");

        OnAfterCreateGenJournalLine(GenJnlLine, Rec);
    end;

    local procedure CheckAccountNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountNo(Rec, IsHandled);
        if IsHandled then
            exit;
            
        TestField("Account No.");
    end;

    procedure ReadGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        UseCurrencyFactor: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReadGenJournalLine(Rec, GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GetCBGStatementHeader;
        Correction := GenJnlLine.Correction;
        GetCurrency;

        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) or
           (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) or
           (GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee)
        then begin
            case true of
                CBGStatement.Currency = GenJnlLine."Currency Code":
                    Amount := GenJnlLine.Amount;
                (CBGStatement.Currency = '') and (GenJnlLine."Currency Code" <> ''):
                    begin
                        UseCurrencyFactor := CurrencyExchangeRate.ExchangeRate(Date, GenJnlLine."Currency Code");
                        Amount :=
                          Round(CurrencyExchangeRate.ExchangeAmtFCYToLCY(Date, GenJnlLine."Currency Code", GenJnlLine.Amount, UseCurrencyFactor),
                            Currency."Amount Rounding Precision");
                    end;
                (CBGStatement.Currency <> '') and (GenJnlLine."Currency Code" = ''):
                    begin
                        UseCurrencyFactor := CurrencyExchangeRate.ExchangeRate(Date, CBGStatement.Currency);
                        Amount :=
                          Round(CurrencyExchangeRate.ExchangeAmtLCYToFCY(Date, CBGStatement.Currency, GenJnlLine.Amount, UseCurrencyFactor),
                            Currency."Amount Rounding Precision");
                    end;
                (CBGStatement.Currency <> '') and (GenJnlLine."Currency Code" <> ''):
                    Amount :=
                      Round(CurrencyExchangeRate.ExchangeAmtFCYToFCY(Date, GenJnlLine."Currency Code", CBGStatement.Currency,
                        GenJnlLine.Amount), Currency."Amount Rounding Precision");
            end;
            "Amount Settled" := Amount;
            Validate(Amount);
        end;
        "Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type";
        "Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        Validate("Applies-to ID", GenJnlLine."Applies-to ID");
    end;

    [Scope('OnPrem')]
    procedure OpenAccountCard()
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        Employee: Record Employee;
        BankAcc: Record "Bank Account";
    begin
        TestField("Account No.");

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            "Account Type"::Customer:
                begin
                    Cust."No." := "Account No.";
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            "Account Type"::Vendor:
                begin
                    Vend."No." := "Account No.";
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
            "Account Type"::Employee:
                begin
                    Employee."No." := "Account No.";
                    PAGE.Run(PAGE::"Employee Card", Employee);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure OpenAccountEntries()
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        TestField("Account No.");

        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    GLEntry.SetRange("G/L Account No.", "Account No.");
                    if GLEntry.FindLast then;
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if CustLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    if VendLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
            "Account Type"::Employee:
                begin
                    EmployeeLedgerEntry.SetCurrentKey("Employee No.", "Posting Date");
                    EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                    if EmployeeLedgerEntry.FindLast then;
                    PAGE.Run(PAGE::"Employee Ledger Entries", EmployeeLedgerEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    if BankAccLedgEntry.FindLast then;
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AssistEdit(OldCBGStatementLine: Record "CBG Statement Line"): Boolean
    var
        CBGStatLine: Record "CBG Statement Line";
        JournalTemplate: Record "Gen. Journal Template";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with CBGStatLine do begin
            CBGStatLine := Rec;
            JournalTemplate.Get("Journal Template Name");
            JournalTemplate.TestField("No. Series");
            if NoSeriesMgt.SelectSeries(JournalTemplate."No. Series", OldCBGStatementLine."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("Document No.");
                Rec := CBGStatLine;
                exit(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GenerateDocumentNo()
    var
        JournalTemplate: Record "Gen. Journal Template";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        TestField("Journal Template Name");
        JournalTemplate.Get("Journal Template Name");
        NoSeriesMgt.InitSeries(JournalTemplate."No. Series", xRec."No. Series", Date, "Document No.", "No. Series");
    end;

    local procedure GetCurrency()
    begin
        GetCBGStatementHeader;
        if CBGStatement.Currency = '' then
            Currency.InitRoundingPrecision
        else
            if CBGStatement.Currency <> Currency.Code then begin
                Currency.Get(CBGStatement.Currency);
                Currency.TestField("Amount Rounding Precision");
            end;
    end;

    [Scope('OnPrem')]
    procedure GetCBGStatementHeader()
    begin
        if (CBGStatement."Journal Template Name" <> "Journal Template Name") or
           (CBGStatement."No." <> "No.")
        then
            CBGStatement.Get("Journal Template Name", "No.");
    end;

    [Scope('OnPrem')]
    procedure IdentificationLookup()
    var
        PaymentHistLine: Record "Payment History Line";
        PaymentHistLnSurvey: Page "Payment History Line Overview";
    begin
        if ("Statement Type" = "Statement Type"::"Bank Account") and
           (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::Employee]) or ("Account No." = ''))
        then begin
            PaymentHistLine.FilterGroup(10);
            PaymentHistLine.SetCurrentKey("Our Bank", Identification, Status);
            PaymentHistLine.SetRange("Our Bank", "Statement No.");
            PaymentHistLine.SetFilter(Status, '%1', PaymentHistLine.Status::Transmitted);
            if "Account No." <> '' then
                PaymentHistLine.SetRange("Account No.", "Account No.");
            PaymentHistLine.FilterGroup(0);
            PaymentHistLine."Our Bank" := "Statement No.";
            PaymentHistLine.Identification := Identification;
            PaymentHistLnSurvey.SetRecord(PaymentHistLine);
            PaymentHistLnSurvey.SetTableView(PaymentHistLine);
            PaymentHistLnSurvey.LookupMode(true);
            if PaymentHistLnSurvey.RunModal = ACTION::LookupOK then begin
                PaymentHistLnSurvey.GetRecord(PaymentHistLine);
                Identification := PaymentHistLine.Identification;
                Validate(Identification);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalculateVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        "VAT %" := 0;
        "Debit Incl. VAT" := Debit;
        "Debit VAT" := 0;
        "Credit Incl. VAT" := Credit;
        "Credit VAT" := 0;

        if "Account Type" = "Account Type"::"G/L Account" then begin
            GetCurrency;

            if "VAT Type" in ["VAT Type"::Purchase, "VAT Type"::Sale] then begin
                if VATPostingSetup.Get("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                    case VATPostingSetup."VAT Calculation Type" of
                        VATPostingSetup."VAT Calculation Type"::"Normal VAT":
                            begin
                                "VAT %" := VATPostingSetup."VAT %";
                                if "Amount incl. VAT" then begin
                                    "Debit VAT" := Debit - Round(Debit / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                                    "Debit Incl. VAT" := Debit;
                                    "Credit VAT" := Credit - Round(Credit / (1 + "VAT %" / 100), Currency."Amount Rounding Precision");
                                    "Credit Incl. VAT" := Credit;
                                end else begin
                                    "Debit VAT" := Round(Debit * "VAT %" / 100, Currency."Amount Rounding Precision");
                                    "Debit Incl. VAT" := Debit + "Debit VAT";
                                    "Credit VAT" := Round(Credit * "VAT %" / 100, Currency."Amount Rounding Precision");
                                    "Credit Incl. VAT" := Credit + "Credit VAT";
                                end;
                            end;
                        VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                            begin
                                "VAT %" := 0;
                                "Debit VAT" := 0;
                                "Debit Incl. VAT" := Debit;
                                "Credit VAT" := 0;
                                "Credit Incl. VAT" := Credit;
                            end;
                        VATPostingSetup."VAT Calculation Type"::"Full VAT":
                            begin
                                "VAT %" := 100;
                                "Amount incl. VAT" := true;
                                "Debit Incl. VAT" := Debit;
                                "Debit VAT" := Debit;
                                "Credit Incl. VAT" := Credit;
                                "Credit VAT" := Credit;
                                if "Account Type" <> "Account Type"::"G/L Account" then
                                    Error(Text1000019, FieldCaption("Account Type"));
                                case "VAT Type" of
                                    "VAT Type"::Purchase:
                                        if "Account No." <> VATPostingSetup."Purchase VAT Account" then
                                            Error(
                                              Text1000020,
                                              FieldCaption("VAT Type"),
                                              "VAT Type",
                                              FieldCaption("Account No."),
                                              "Account No.",
                                              VATPostingSetup.FieldCaption("Purchase VAT Account"),
                                              VATPostingSetup."Purchase VAT Account");
                                    "VAT Type"::Sale:
                                        if "Account No." <> VATPostingSetup."Sales VAT Account" then
                                            Error(
                                              Text1000020,
                                              FieldCaption("VAT Type"),
                                              "VAT Type",
                                              FieldCaption("Account No."),
                                              "Account No.",
                                              VATPostingSetup.FieldCaption("Sales VAT Account"),
                                              VATPostingSetup."Sales VAT Account");
                                end;
                            end;
                        else
                            VATPostingSetup.FieldError("VAT Calculation Type",
                              Text1000021);
                    end
                else
                    if "VAT Prod. Posting Group" <> '' then
                        Message(
                          Text1000022 +
                          Text1000023,
                          FieldCaption("VAT Bus. Posting Group"), "VAT Bus. Posting Group",
                          FieldCaption("VAT Prod. Posting Group"), "VAT Prod. Posting Group",
                          FieldCaption("VAT %"));
            end else
                if "VAT Prod. Posting Group" <> '' then
                    Message(Text1000024 +
                      Text1000025 +
                      Text1000026 +
                      Text1000027,
                      FieldCaption("VAT Type"),
                      GLAccount.FieldCaption("Gen. Posting Type"),
                      GLAccount.FieldCaption("VAT Bus. Posting Group"),
                      GLAccount.FieldCaption("VAT Prod. Posting Group"),
                      "Account No.");
        end else
            if ("VAT Type" <> "VAT Type"::" ") or ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '') then
                Error(
                  Text1000028,
                  FieldCaption("Account Type"));
    end;

    [Scope('OnPrem')]
    procedure "New Applies-to ID"() ID: Code[20]
    var
        CBGStatementln: Record "CBG Statement Line";
    begin
        GetCBGStatementHeader;
        case CBGStatement.Type of
            CBGStatement.Type::"Bank/Giro":
                begin
                    CBGStatementln.SetCurrentKey("Journal Template Name", "No.", "Applies-to ID");
                    CBGStatementln.SetRange("Journal Template Name", "Journal Template Name");
                    CBGStatementln.SetRange("No.", "No.");
                    CBGStatementln.SetFilter("Applies-to ID", '<>%1', '');
                    if CBGStatementln.FindLast then
                        ID := IncStr(CBGStatementln."Applies-to ID")
                    else begin
                        if StrLen(CBGStatement."Document No.") > MaxStrLen(ID) - 5 then
                            ID := DelStr(CBGStatement."Document No.", 4, StrLen(CBGStatement."Document No.") - (MaxStrLen(ID) - 5)) + '-0001'
                        else
                            ID := CBGStatement."Document No." + '-0001'
                    end;
                end;
            CBGStatement.Type::Cash:
                ID := "Document No.";
        end;
    end;

    local procedure DeleteAppliesToID(var CBGStatementlineRec: Record "CBG Statement Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        if "Applies-to ID" <> '' then begin
            case CBGStatementlineRec."Account Type" of
                "Account Type"::Customer:
                    begin
                        CustLedgEntry.SetCurrentKey("Customer No.");
                        CustLedgEntry.SetRange("Customer No.", CBGStatementlineRec."Account No.");
                        CustLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetCustomerLedgerEntryFilters(CBGStatementlineRec, CustLedgEntry);
                        if CustLedgEntry.Find('-') then
                            repeat
                                ClearCustApplnEntryFields(CustLedgEntry);
                            until CustLedgEntry.Next() = 0;
                    end;
                "Account Type"::Vendor:
                    begin
                        VendLedgEntry.SetCurrentKey("Vendor No.");
                        VendLedgEntry.SetRange("Vendor No.", CBGStatementlineRec."Account No.");
                        VendLedgEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetVendorLedgerEntryFilters(CBGStatementlineRec, VendLedgEntry);
                        if VendLedgEntry.Find('-') then
                            repeat
                                ClearVendApplnEntryFields(VendLedgEntry);
                            until VendLedgEntry.Next() = 0;
                    end;
                "Account Type"::Employee:
                    begin
                        EmployeeLedgerEntry.SetCurrentKey("Employee No.");
                        EmployeeLedgerEntry.SetRange("Employee No.", CBGStatementlineRec."Account No.");
                        EmployeeLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                        OnDeleteAppliesToIDOnAfterSetEmployeeLedgerEntryFilters(CBGStatementlineRec, EmployeeLedgerEntry);
                        if EmployeeLedgerEntry.Find('-') then
                            repeat
                                ClearEmployeeApplnEntryFields(EmployeeLedgerEntry);
                            until EmployeeLedgerEntry.Next() = 0;
                    end;
            end;
            "Applies-to ID" := '';
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateDim(Type1: Integer; No1: Code[20]; Type2: Integer; No2: Code[20]; Type3: Integer; No3: Code[20]; Type4: Integer; No4: Code[20]; Type5: Integer; No5: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        TableID[1] := Type1;
        No[1] := No1;
        TableID[2] := Type2;
        No[2] := No2;
        TableID[3] := Type3;
        No[3] := No3;
        TableID[4] := Type4;
        No[4] := No4;
        TableID[5] := Type5;
        No[5] := No5;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" := DimManagement.GetDefaultDimID(
            TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
    end;

    [Scope('OnPrem')]
    procedure ValidateShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    [Scope('OnPrem')]
    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        ValidateShortcutDimCode(FieldNo, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimManagement.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure ShowDimensions()
    begin
        "Dimension Set ID" := DimManagement.EditDimensionSet(
            "Dimension Set ID", StrSubstNo('%1 %2 %3', "Journal Template Name", "No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    [Scope('OnPrem')]
    procedure GetDate(String: Text; Position: Integer; Length: Integer; ExpectedFormat: Text) Result: Date
    var
        DateString: Text;
        DateVar: Variant;
    begin
        DateVar := 0D;
        DateString := GetText(String, Position, Length);
        if not TypeHelper.Evaluate(DateVar, DateString, ExpectedFormat, '') then
            Error(DateParseErr, DateString, ExpectedFormat);
        Result := DateVar;
    end;

    [Scope('OnPrem')]
    procedure GetText(String: Text[1024]; Position: Integer; Length: Integer): Text[1024]
    begin
        exit(DelChr(CopyStr(String, Position, Length), '<>'));
    end;

    [Scope('OnPrem')]
    procedure GetDecimal(String: Text[1024]; Position: Integer; Length: Integer; DecimalSeparator: Code[1]) Result: Decimal
    var
        DecimalText: Text[30];
        DecimalTextBeforeComma: Text[30];
        DecimalTextAfterComma: Text[30];
        DecimalBeforeComma: Decimal;
        DecimalAfterComma: Decimal;
        CommaPosition: Integer;
        DecimalVar: Variant;
    begin
        DecimalText := GetText(String, Position, Length);

        Position := 1;
        while DecimalText[Position] in ['0' .. '9', DecimalSeparator[1]] do
            Position := Position + 1;

        DecimalText := CopyStr(DecimalText, 1, Position - 1);
        CommaPosition := StrPos(DecimalText, DecimalSeparator);

        if CommaPosition > 0 then begin
            DecimalTextBeforeComma := CopyStr(DecimalText, 1, CommaPosition - 1);
            DecimalTextAfterComma := DelStr(DecimalText, 1, CommaPosition);
        end else begin
            DecimalTextBeforeComma := DecimalText;
            DecimalTextAfterComma := '0';
        end;

        if DecimalTextAfterComma = '' then
            DecimalTextAfterComma := '0';
        if DecimalTextBeforeComma = '' then
            DecimalTextBeforeComma := '0';

        Evaluate(DecimalBeforeComma, DecimalTextBeforeComma);
        Evaluate(DecimalAfterComma, DecimalTextAfterComma);

        exit(DecimalBeforeComma + Power(0.1, StrLen(DecimalTextAfterComma)) * DecimalAfterComma);
    end;

    local procedure ClearDataExchEntries()
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", "Data Exch. Entry No.");
        DataExchField.SetRange("Line No.", "Data Exch. Line No.");
        DataExchField.DeleteAll();
    end;

    local procedure ClearCustApplnEntryFields(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
        CustLedgerEntry."Accepted Payment Tolerance" := 0;
        CustLedgerEntry."Amount to Apply" := 0;
        CustLedgerEntry."Applies-to ID" := '';
        CustLedgerEntry.Modify();
    end;

    local procedure ClearVendApplnEntryFields(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
        VendorLedgerEntry."Accepted Payment Tolerance" := 0;
        VendorLedgerEntry."Amount to Apply" := 0;
        VendorLedgerEntry."Applies-to ID" := '';
        VendorLedgerEntry.Modify();
    end;

    local procedure ClearEmployeeApplnEntryFields(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry."Amount to Apply" := 0;
        EmployeeLedgerEntry."Applies-to ID" := '';
        EmployeeLedgerEntry.Modify();
    end;

    local procedure SetApplyCVLedgerEntries(PaymentHistLine: Record "Payment History Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplyCVLedgerEntries(Rec, PaymentHistLine, IsHandled);
        if IsHandled then
            exit;

        FinancialInterfaceTelebank.SetApplyCVLedgerEntries(PaymentHistLine, "New Applies-to ID", false, false);
    end;

    procedure ValidateApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    begin
        case CBGStatementLine."Account Type" of
            CBGStatementLine."Account Type"::Customer:
                ValidateCustomerApplyRequirements(CBGStatementLine);
            CBGStatementLine."Account Type"::Vendor:
                ValidateVendorApplyRequirements(CBGStatementLine);
            CBGStatementLine."Account Type"::Employee:
                ValidateEmployeeApplyRequirements(CBGStatementLine);
        end;
    end;

    local procedure ValidateCustomerApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateCustomerApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                CustLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    CustLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> CBGStatementLine."Applies-to Doc. Type"::" " then
                        CustLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        CustLedgEntry.SetRange("Customer No.", CBGStatementLine."Account No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not CustLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    local procedure ValidateVendorApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateVendorApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                VendLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    VendLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> CBGStatementLine."Applies-to Doc. Type"::" " then
                        VendLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        VendLedgEntry.SetRange("Vendor No.", CBGStatementLine."Account No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not VendLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    local procedure ValidateEmployeeApplyRequirements(CBGStatementLine: Record "CBG Statement Line")
    var
        EmplLedgEntry: Record "Employee Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmployeeApplyRequirements(CBGStatementLine, IsHandled);
        if IsHandled then
            exit;

        if (CBGStatementLine."Applies-to ID" = '') and (CBGStatementLine."Applies-to Doc. No." = '') then
            exit;

        case true of
            CBGStatementLine."Applies-to ID" <> '':
                EmplLedgEntry.SetRange("Applies-to ID", CBGStatementLine."Applies-to ID");
            CBGStatementLine."Applies-to Doc. No." <> '':
                begin
                    EmplLedgEntry.SetRange("Document No.", CBGStatementLine."Applies-to Doc. No.");
                    if CBGStatementLine."Applies-to Doc. Type" <> EmplLedgEntry."Applies-to Doc. Type"::" " then
                        EmplLedgEntry.SetRange("Document Type", CBGStatementLine."Applies-to Doc. Type");
                end;
        end;

        EmplLedgEntry.SetRange("Employee No.", CBGStatementLine."Account No.");
        EmplLedgEntry.SetRange(Open, true);
        EmplLedgEntry.SetFilter("Posting Date", '>%1', CBGStatementLine.Date);
        if not EmplLedgEntry.IsEmpty() then
            Error(PostingDateEarlierErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var CBGStatementLine: Record "CBG Statement Line"; CurrentFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; CBGStatementLine: Record "CBG Statement Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAppliesToIDOnValidate(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountNo(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReadGenJournalLine(var CBGStatementLine: Record "CBG Statement Line"; var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplyCVLedgerEntries(var CBGStatementLine: Record "CBG Statement Line"; PaymentHistLine: Record "Payment History Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCustomerApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmployeeApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVendorApplyRequirements(var CBGStatementLine: Record "CBG Statement Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetCustomerLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetEmployeeLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var EmployeeLedgEntry: Record "Employee Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteAppliesToIDOnAfterSetVendorLedgerEntryFilters(var CBGStatementLine: Record "CBG Statement Line"; var VendorLedgEntry: Record "Vendor Ledger Entry");
    begin
    end;
}

