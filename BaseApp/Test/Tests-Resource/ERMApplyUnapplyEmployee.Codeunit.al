﻿codeunit 134114 "ERM Apply Unapply Employee"
{
    Permissions = TableData "Employee Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Employee Payments]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        TotalAmountErr: Label 'Total Amount must be %1 in %2 table for %3 field : %4.', Locked = true;
        UnappliedErr: Label '%1 must be %2 in %3.', Locked = true;
        MessageDoNotMatchErr: Label 'Error Message must be same.';
        ApplicationEntryErr: Label 'Employee ledger entry number %1 does not have an application entry.', Comment = '%1 = FIELD Caption, %2 = FIELD Value';
        UnapplyErr: Label '%1 must be equal to ''Application''  in %2: %3=%4. Current value is ''Initial Entry''.', Comment = '%1 = FIELD Caption, %2 = Table Caption,%3 = Field Caption,%4 = Field Value';
        DetailedEmployeeLedgerErr: Label 'Detailed Employee Ledger Entry Must Found.';
        NoEntriesAppliedErr: Label 'Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyEmployeePayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoOfLines: Integer;
        Amount: Decimal;
    begin
        // Verify Additional Currency, Remaining Amount and Entries unapplied after Applying and then Unapplying Payment Entries for Employee.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.SetOutsideO365Scope();
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := -100 * LibraryRandom.RandInt(10);

        ApplyUnapplyEmployeeEntries(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, NoOfLines, Amount,
          -Amount / NoOfLines);

        // Verify: Verify Remaining Amount, Unapplied Entries and Additional Currency Amount after unapplying entries.
        VerifyRemainingAmount(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");
        VerifyUnappliedEntries(GenJournalLine."Document No.", GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyUnapplyApplyEmployeePayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Additional Currency Amount, Detailed Employee Ledger Entry after Unapplying, Applying Payment Entries Again for Employee.

        // Setup: Update General Ledger Setup and take Random Amount greater than 100 (Standard Value)
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        ApplyUnapplySeveralEmployeeEntries(
          -1, GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment);

        // Verify: Verify Detailed Ledger Entries and Additional Currency Amount after Re-applying Entries.
        VerifyDetailedLedgerEntry(GenJournalLine."Document No.", GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentCheckSourceCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test that correct Source Code updated on Detailed Employee Ledger Entry after Unapply Payment from Employee Ledger Entry.
        // Use Random Number Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        ApplyUnapplyAndCheckSourceCode(
          GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, -LibraryRandom.RandDec(100, 2));
    end;

    local procedure ApplyUnapplyAndCheckSourceCode(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        SourceCode: Record "Source Code";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Source Code, update Source Code Setup, create and post General Journal Lines.
        LibraryERM.CreateSourceCode(SourceCode);
        SetUnapplPurchEntryApplnSourceCode(SourceCode.Code);
        ApplyUnapplyEmployeeEntries(GenJournalLine, DocumentType, DocumentType2, 1, Amount, -Amount);

        // Verify: Verify correct Source Code updated on Detailed Employee Ledger Entry.
        VerifySourceCodeDtldCustLedger(DocumentType2, GenJournalLine."Document No.", SourceCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDocumentNoUnapplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Document No can be change when Unapply Payment from Employee Ledger Entry.
        // Use Random Nunber Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        ChangeDocumentNoAndUnapply(
          GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, -LibraryRandom.RandInt(500));
    end;

    local procedure ChangeDocumentNoAndUnapply(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        GenJournalLine: Record "Gen. Journal Line";
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post General Journal Lines.
        CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, Amount, WorkDate);
        FindDetailedLedgerEntry(
          DetailedEmployeeLedgEntry, DetailedEmployeeLedgEntry."Entry Type"::Application, GenJournalLine."Document No.",
          GenJournalLine."Account No.");
        DocumentNo := GenJournalLine."Account No.";

        // Exercise: Change Document No and Unapply Payment/Refund from Employee Ledger Entry.
        ApplyUnapplyParameters."Document No." := GenJournalLine."Account No.";
        ApplyUnapplyParameters."Posting Date" := GenJournalLine."Posting Date";
        EmplEntryApplyPostedEntries.PostUnApplyEmployee(DetailedEmployeeLedgEntry, ApplyUnapplyParameters);

        // Verify: Check Detailed Employee Ledger Entry with updated Document No exist after Unapply.
        FindDetailedLedgerEntry(DetailedEmployeeLedgEntry, DetailedEmployeeLedgEntry."Entry Type"::Application, DocumentNo, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvFromEmployeeLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Employee Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UnapplyFromEmployeeLedger(GenJournalLine."Document Type"::" ", -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentEmployeeLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Employee Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UnapplyFromEmployeeLedger(GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromEmployeeLedger(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        // Setup: Create Employee, Create and post General Journal  Line.
        CreateEmployee(Employee);
        CreateAndPostGenJournalLine(GenJournalLine, Employee."No.", DocumentType, Amount, WorkDate);
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, GenJournalLine."Document No.");

        // Exercise: Unapply Document from Employee Ledger Entry.
        asserterror EmplEntryApplyPostedEntries.UnApplyEmplLedgEntry(EmployeeLedgerEntry."Entry No.");

        // Verify: Verify error when Unapplying Document from Employee Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(ApplicationEntryErr, EmployeeLedgerEntry."Entry No."), GetLastErrorText, MessageDoNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyInvDtldEmployeeLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Invoice from Detailed Employee Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UnapplyFromDtldEmployeeLedger(GenJournalLine."Document Type"::" ", -LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentDtldEmployeeLedger()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Unapply Payment from Detailed Employee Ledger Entry and verify error message.
        // Use Random Number Generator for Amount.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        UnapplyFromDtldEmployeeLedger(GenJournalLine."Document Type"::Payment, LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyFromDtldEmployeeLedger(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        // Setup: Create Employee, Create and post General Journal  Line.
        CreateEmployee(Employee);
        CreateAndPostGenJournalLine(GenJournalLine, Employee."No.", DocumentType, Amount, WorkDate);
        FindDetailedLedgerEntry(
          DetailedEmployeeLedgEntry, DetailedEmployeeLedgEntry."Entry Type"::"Initial Entry", GenJournalLine."Document No.",
          GenJournalLine."Account No.");

        // Exercise: Unapply Document from Detailed Employee Ledger Entry.
        asserterror EmplEntryApplyPostedEntries.UnApplyDtldEmplLedgEntry(DetailedEmployeeLedgEntry);

        // Verify: Verify error when Unapplying Document from Detailed Employee Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(
            UnapplyErr, DetailedEmployeeLedgEntry.FieldCaption("Entry Type"), DetailedEmployeeLedgEntry.TableCaption,
            DetailedEmployeeLedgEntry.FieldCaption("Entry No."), DetailedEmployeeLedgEntry."Entry No."), GetLastErrorText,
          MessageDoNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingAmtOnEmployeeLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
        ExpenseAccNo: Code[20];
    begin
        // Check Remaining Amount on Employee Ledger Entry after Creating and Posting expense for an employee without Currency and Apply with Partial Payment.

        // Setup: Create and Post Purchase Invoice, Create a Employee Payment and apply it to posted Invoice.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateEmployee(Employee);
        ExpenseAccNo := CreateBalanceSheetAccount;
        PostedDocumentNo := CreateAndPostEmplExpense(Employee, ExpenseAccNo, LibraryRandom.RandInt(100));
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", PostedDocumentNo);
        EmployeeLedgerEntry.CalcFields(Amount);
        Amount := LibraryRandom.RandDec(EmployeeLedgerEntry.Amount, 2);
        CreateGeneralJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::Payment, Amount);  // Taken 1 and 0 to create only one General Journal line with zero amount.
        GenJournalLine."Applies-to Doc. No." := PostedDocumentNo;
        GenJournalLine.Modify();

        // Exericse.
        LibraryLowerPermissions.AddO365HREdit;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Remaining Amount on Employee Ledger Entry.
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", PostedDocumentNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        EmployeeLedgerEntry.CalcFields("Original Amount");
        EmployeeLedgerEntry.TestField("Remaining Amount", EmployeeLedgerEntry."Original Amount" + Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocumentUsingApplicationMethodApplyToOldest()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        ExpenseAccNo: Code[20];
        Amount: Decimal;
    begin
        // Check General Ledger, Employee Ledger and Detailed Employee ledger entries after posting Purchase documents with Currency and Apply to Oldest Application Method.

        // Setup: Modify General Ledger setup for Appln. Rounding Precision and Create Employee with Currency and with Apply to Oldest Application Method, Create and post Purchase Invoice with Random Quantity and Direct Unit Cost.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateEmployee(Employee);
        Employee.Validate("Application Method", Employee."Application Method"::"Apply to Oldest");
        Employee.Modify(true);
        ExpenseAccNo := CreateBalanceSheetAccount;
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo := CreateAndPostEmplExpense(Employee, ExpenseAccNo, Amount);

        // Exercise: Create and post Purchase Credit Memo.
        CreateGeneralJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::Payment, Amount);
        DocumentNo2 := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify GL, Employee and Detailed Employee ledger entries.
        VerifyEntriesAfterPostingPurchaseDocument(GenJournalLine."Document Type", DocumentNo, DocumentNo2, Employee."No.");
    end;

    [Test]
    [HandlerFunctions('ApplyingEmployeeEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountOnApplyEmployeeEntriesPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
        DummyGeneralJournal: TestPage "General Journal";
        ExpenseAccNo: Code[20];
    begin
        // Verify that Apply Employee Entry Page Shows Correct value when payment is applied.

        // Setup: Create and post Gen journal line for two Invoice and two Credit Memo. and Create One Payment Line.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateEmployee(Employee);
        ExpenseAccNo := CreateBalanceSheetAccount;
        CreateAndPostEmplExpense(Employee, ExpenseAccNo, -LibraryRandom.RandIntInRange(100, 200));

        CreateAndPostEmplExpense(Employee, ExpenseAccNo, -LibraryRandom.RandIntInRange(100, 200));

        CreateGeneralJournalLine(GenJournalLine, 1, Employee."No.", GenJournalLine."Document Type"::Payment,
          -GetTotalAppliedAmount(Employee."No.", WorkDate));
        ModifyGenJournalLine(GenJournalLine);

        // Exercise: Apply Set Applies To ID and Amount Apply.
        LibraryLowerPermissions.SetO365HREdit;
        SetAppliesToIDAndAmountToApply(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Verification done in ApplyingEmployeeEntriesPageHandler.
        OpenGenJournalPage(DummyGeneralJournal, GenJournalLine."Document No.", GenJournalLine."Document Type");
        DummyGeneralJournal."Apply Entries".Invoke;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageOnApplyWithoutAppliesToID()
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        Employee: Record Employee;
        EmplLedgerEntry: Record "Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
        Amount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 380040] During application, if there is no "Applies-to ID", then "The application could not be posted, because no entry
        // [SCENARIO] has been selected to be applied / for none of the open entries the "Applies-to ID" has been specfied." error message should appear

        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] Employee VVV
        // [GIVEN] Gen. Journal Batch GJB with two lines
        // [GIVEN] Gen. Journal Line JL1: an expense for Employee VVV with "Document No" = 123 and "Amount" = -1000
        // [GIVEN] Gen. Journal Line JL2: a payment for Employee VVV with "Document No" = 123 (same as JL1) and "Amount" = 1000
        // [GIVEN] Batch GJB posted
        Amount := LibraryRandom.RandDec(1000, 2);
        CreateEmployee(Employee);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, GenJournalLine."Bal. Account Type"::Employee,
          Employee."No.", Amount);
        DocNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, GenJournalLine."Bal. Account Type"::Employee,
          Employee."No.", -Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply Payment to Invoice
        LibraryERM.FindEmployeeLedgerEntry(EmplLedgerEntry, EmplLedgerEntry."Document Type"::Payment, DocNo);
        ApplyUnapplyParameters."Document No." := DocNo;
        ApplyUnapplyParameters."Posting Date" := WorkDate();
        asserterror EmplEntryApplyPostedEntries.Apply(EmplLedgerEntry, ApplyUnapplyParameters);

        // [THEN] The following message appears: Cannot post because you did not specify which entry to apply. You must specify an entry in the Applies-to ID field for one or more open entries.
        Assert.ExpectedError(NoEntriesAppliedErr);
    end;

    local procedure Initialize()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        Employee: Record Employee;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Unapply Employee");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        EmployeePostingGroup.DeleteAll();
        Employee.DeleteAll();
        CreateEmployeePostingGroup(LibraryERM.CreateGLAccountNoWithDirectPosting);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Employee");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERM.SetJournalTemplateNameMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Unapply Employee");
    end;

    local procedure ApplyUnapplyEmployeeEntries(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; NoOfLines: Integer; Amount: Decimal; Amount2: Decimal) DocumentNo: Code[20]
    var
        Employee: Record Employee;
    begin
        CreateEmployee(Employee);

        // Create Journal Lines according to the options selected and post them.
        CreateGeneralJournalLine(GenJournalLine, 1, Employee."No.", DocumentType, Amount);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateGeneralJournalLine(GenJournalLine, NoOfLines, GenJournalLine."Account No.", DocumentType2, Amount2);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Unapply Employee Entries as per the option selected.
        ApplyEmployeeLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
        UnapplyEmployeeLedgerEntry(DocumentType2, GenJournalLine."Document No.");
    end;

    local procedure ApplyUnapplySeveralEmployeeEntries(Sign: Integer; var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        NoOfLines: Integer;
        Amount: Integer;
    begin
        Initialize();
        NoOfLines := 2 * LibraryRandom.RandInt(2);
        Amount := Sign * 100 * LibraryRandom.RandInt(10);

        ApplyUnapplyEmployeeEntries(GenJournalLine, DocumentType, DocumentType2, NoOfLines, Amount, -Amount / NoOfLines);
    end;

    local procedure ApplyEmployeeLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyEmployeeEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Remaining Amount");
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry2, DocumentType2, DocumentNo2);
        EmployeeLedgerEntry2.FindSet();
        repeat
            EmployeeLedgerEntry2.CalcFields("Remaining Amount");
            EmployeeLedgerEntry2.Validate("Amount to Apply", EmployeeLedgerEntry2."Remaining Amount");
            EmployeeLedgerEntry2.Modify(true);
        until EmployeeLedgerEntry2.Next = 0;
        SetAppliesToIDAndPostEntry(EmployeeLedgerEntry2, EmployeeLedgerEntry);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; NoOfLine: Integer; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        SelectGenJournalBatch(GenJournalBatch);
        for Counter := 1 to NoOfLine do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
              GenJournalLine."Account Type"::Employee, EmployeeNo, Amount);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    begin
        // Apply and Unapply General Journal Lines for Payment and Invoice. Take a Random Amount greater than 100 (Standard Value).
        CreateGeneralJournalLine(GenJournalLine, 1, EmployeeNo, DocumentType, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetUnapplPurchEntryApplnSourceCode(UnappliedPurchEntryAppln: Code[10])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup.Validate("Unapplied Purch. Entry Appln.", UnappliedPurchEntryAppln);
        SourceCodeSetup.Modify(true);
    end;

    local procedure CreatePostApplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; PostingDate: Date)
    var
        Employee: Record Employee;
        DocumentNo: Code[20];
    begin
        CreateEmployee(Employee);
        CreateAndPostGenJournalLine(GenJournalLine, Employee."No.", DocumentType, Amount, PostingDate);
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJournalLine(GenJournalLine, Employee."No.", DocumentType2, -Amount, PostingDate);
        ApplyEmployeeLedgerEntry(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.FindFirst();
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Validate("Application Method", Employee."Application Method"::Manual);
        Employee.Modify(true);
    end;

    local procedure FindDetailedLedgerEntry(var DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry"; EntryType: Option; DocumentNo: Code[20]; EmployeeNo: Code[20])
    begin
        DetailedEmployeeLedgEntry.SetRange("Entry Type", EntryType);
        DetailedEmployeeLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgEntry.SetRange("Employee No.", EmployeeNo);
        DetailedEmployeeLedgEntry.FindSet();
    end;

    local procedure FindGLEntries(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
    end;

    local procedure GetTotalAppliedAmount(EmployeeNo: Code[20]; PostingDate: Date): Decimal
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        TotalAmount: Decimal;
    begin
        with EmployeeLedgerEntry do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Posting Date", PostingDate);
            FindSet();
            repeat
                CalcFields(Amount);
                TotalAmount += Amount;
            until Next = 0;
            exit(TotalAmount);
        end;
    end;

    local procedure ModifyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do begin
            Validate("Document No.", IncStr("Document No."));
            Validate("External Document No.", "Document No.");
            Validate("Posting Date", CalcDate('<1Y>', WorkDate));
            Modify(true);
        end;
    end;

    local procedure OpenGenJournalPage(DummyGeneralJournal: TestPage "General Journal"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        DummyGeneralJournal.OpenEdit;
        DummyGeneralJournal.FILTER.SetFilter("Document No.", DocumentNo);
        DummyGeneralJournal.FILTER.SetFilter("Document Type", Format(DocumentType));
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure SetAppliesToIDAndPostEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeLedgerEntry2: Record "Employee Ledger Entry")
    begin
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry);
        LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry2);
    end;

    local procedure SetAppliesToIDAndAmountToApply(EmployeeNo: Code[20]; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        with EmployeeLedgerEntry do begin
            SetRange("Employee No.", EmployeeNo);
            SetRange("Applying Entry", false);
            FindSet();
            repeat
                Validate("Applies-to ID", DocumentNo);
                CalcFields("Remaining Amount");
                Validate("Amount to Apply", "Remaining Amount");
                Modify(true);
            until Next = 0;
        end;
    end;

    local procedure UnapplyEmployeeLedgerEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        EmployeeLedgerEntry.SetRange(Open, false);
        EmployeeLedgerEntry.FindLast();
        LibraryERM.UnapplyEmployeeLedgerEntry(EmployeeLedgerEntry);
    end;

    local procedure VerifyEntriesAfterPostingPurchaseDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20]; EmployeeNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", DocumentNo);
        EmployeeLedgerEntry.TestField(Open, false);
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo2);
        EmployeeLedgerEntry.TestField(Open, false);
        VerifyGLEntries(DocumentNo2);
        VerifyDetailedLedgerEntry(DocumentNo2, EmployeeNo);
    end;

    local procedure VerifyRemainingAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, DocumentNo);
        repeat
            EmployeeLedgerEntry.CalcFields("Remaining Amount", Amount);
            EmployeeLedgerEntry.TestField("Remaining Amount", EmployeeLedgerEntry.Amount);
        until EmployeeLedgerEntry.Next = 0;
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; EmployeeNo: Code[20])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        TotalAmount: Decimal;
    begin
        FindDetailedLedgerEntry(DetailedEmployeeLedgEntry, DetailedEmployeeLedgEntry."Entry Type"::Application, DocumentNo, EmployeeNo);
        repeat
            TotalAmount += DetailedEmployeeLedgEntry.Amount;
        until DetailedEmployeeLedgEntry.Next = 0;
        Assert.AreEqual(
          0, TotalAmount,
          StrSubstNo(
            TotalAmountErr, 0, DetailedEmployeeLedgEntry.TableCaption, DetailedEmployeeLedgEntry.FieldCaption("Entry Type"),
            DetailedEmployeeLedgEntry."Entry Type"));
    end;

    local procedure VerifyUnappliedEntries(DocumentNo: Code[20]; EmployeeNo: Code[20])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        FindDetailedLedgerEntry(DetailedEmployeeLedgEntry, DetailedEmployeeLedgEntry."Entry Type"::Application, DocumentNo, EmployeeNo);
        repeat
            Assert.IsTrue(
              DetailedEmployeeLedgEntry.Unapplied,
              StrSubstNo(
                UnappliedErr, DetailedEmployeeLedgEntry.FieldCaption(Unapplied), DetailedEmployeeLedgEntry.Unapplied,
                DetailedEmployeeLedgEntry.TableCaption));
        until DetailedEmployeeLedgEntry.Next = 0;
    end;

    local procedure VerifySourceCodeDtldCustLedger(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; SourceCode: Code[10])
    var
        DetailedEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
    begin
        DetailedEmployeeLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedEmployeeLedgEntry.SetRange("Document Type", DocumentType);
        DetailedEmployeeLedgEntry.SetRange("Source Code", SourceCode);
        Assert.IsTrue(DetailedEmployeeLedgEntry.FindFirst, DetailedEmployeeLedgerErr);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        FindGLEntries(GLEntry, DocumentNo);
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next = 0;
        Assert.AreEqual(
          0, TotalAmount, StrSubstNo(TotalAmountErr, 0, GLEntry.TableCaption, GLEntry.FieldCaption("Document No."), GLEntry."Document No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyingEmployeeEntriesPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ControlBalance.AssertEquals(0);
    end;

    local procedure CreateBalanceSheetAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate(Blocked, false);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateAndPostEmplExpense(Employee: Record Employee; GLAccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::Employee, Employee."No.", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateEmployeePostingGroup(ExpenseAccNo: Code[20]): Code[20]
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", ExpenseAccNo);
        EmployeePostingGroup.Insert(true);
        exit(EmployeePostingGroup.Code);
    end;
}

