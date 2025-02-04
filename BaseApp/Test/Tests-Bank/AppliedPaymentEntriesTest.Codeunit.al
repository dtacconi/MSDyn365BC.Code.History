codeunit 134264 "Applied Payment Entries Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application] [Applied Payment Entry]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [HandlerFunctions('MessageHandler,SelectFirstRowPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure AutomaticApplyToEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        TotalAppliedAmount: Variant;
        TotalRemainingAmount: Variant;
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables;
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify Amount is correctly applied
        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        LibraryVariableStorage.Dequeue(TotalAppliedAmount);
        LibraryVariableStorage.Dequeue(TotalRemainingAmount);
        Assert.AreEqual(Amount, TotalAppliedAmount, 'Wrong amount applied.');
        Assert.AreEqual(0, TotalRemainingAmount, 'Amount left to apply is incorrect.');
        PaymentReconciliationJournal.Close;

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,RejectApplicationPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure RejectApplication()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        ClosePage: Boolean;
        RejectFromPaymentApplication: Boolean;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables;
        ClosePage := false;
        LibraryVariableStorage.Enqueue(ClosePage);
        LibraryVariableStorage.Enqueue(Amount);
        RejectFromPaymentApplication := true;
        LibraryVariableStorage.Enqueue(RejectFromPaymentApplication);
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify application reject functionality
        VerifyNoAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        Assert.AreEqual(
          Format(BankAccReconciliationLine."Match Confidence"::None),
          PaymentReconciliationJournal."Match Confidence".Value,
          'Unexpected match confidence after rejecting the application');

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,RejectApplicationPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure RejectApplicationFromPaymentJournal()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        RejectFromPaymentApplication: Boolean;
        ClosePage: Boolean;
    begin
        // [SCENARIO 372024] After Application Reject from Payment Journal field "Account No." is empty.
        Initialize();

        // [GIVEN] Customer, Cust. Ledger Entry and Bank Account Reconciliation Line.
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // [GIVEN] Applied Payment to Cust. Ledger Entry.
        ClosePage := true;
        LibraryVariableStorage.Enqueue(ClosePage);
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // [WHEN] Reject Applied Payment.
        LibraryLowerPermissions.AddAccountReceivables;
        PaymentReconciliationJournal.Reject.Invoke;
        ClosePage := false;
        LibraryVariableStorage.Enqueue(ClosePage);
        LibraryVariableStorage.Enqueue(Amount);
        RejectFromPaymentApplication := false;
        LibraryVariableStorage.Enqueue(RejectFromPaymentApplication);
        LibraryVariableStorage.Enqueue(CustLedgEntry."Entry No.");
        PaymentReconciliationJournal.ApplyEntries.Invoke;

        // [THEN] No Applied Payment Entry exist.
        VerifyNoAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);
        // [THEN] Bank Account Reconciliation Line field "Match Confidence" = None
        PaymentReconciliationJournal."Match Confidence".AssertEquals(Format(BankAccReconciliationLine."Match Confidence"::None));
        // [THEN] Bank Account Reconciliation Line field "Account No." is empty
        PaymentReconciliationJournal."Account No.".AssertEquals('');
        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SetAppliedPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure UnapplyApplication()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        Applied: Boolean;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        Applied := false;
        LibraryVariableStorage.Enqueue(Applied);
        LibraryLowerPermissions.AddAccountReceivables;
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify
        VerifyNoAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        Assert.AreEqual(
          Format(BankAccReconciliationLine."Match Confidence"::None),
          PaymentReconciliationJournal."Match Confidence".Value,
          'Unexpected match confidence after rejecting the application');
        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ChangeAppliedAmountPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure UnapplyByApplyingZeroAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(0);
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify
        VerifyNoAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        Assert.AreEqual(
          Format(BankAccReconciliationLine."Match Confidence"::None),
          PaymentReconciliationJournal."Match Confidence".Value,
          'Unexpected match confidence after rejecting the application');

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SetAppliedPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure ReapplyUnappliedApplication()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        Applied: Boolean;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        Applied := false;
        LibraryVariableStorage.Enqueue(Applied);
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify
        LibraryVariableStorage.Enqueue(Amount);
        Applied := true;
        LibraryVariableStorage.Enqueue(Applied);
        LibraryVariableStorage.Enqueue(CustLedgEntry."Entry No.");
        PaymentReconciliationJournal.ApplyEntries.Invoke;

        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AcceptApplicationPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure AcceptApplication()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        ClosePage: Boolean;
    begin
        Initialize();

        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        ClosePage := false;
        LibraryVariableStorage.Enqueue(ClosePage);

        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify
        Assert.AreEqual(
          Format(BankAccReconciliationLine."Match Confidence"::Accepted),
          PaymentReconciliationJournal."Match Confidence".Value,
          'Unexpecbted match confidence after accepting the application');

        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,AcceptApplicationPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure AcceptApplicationFromPaymentJournal()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        ClosePage: Boolean;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        ClosePage := true;
        LibraryVariableStorage.Enqueue(ClosePage);

        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");
        PaymentReconciliationJournal.Accept.Invoke;

        // Verify
        Assert.AreEqual(
          Format(BankAccReconciliationLine."Match Confidence"::Accepted),
          PaymentReconciliationJournal."Match Confidence".Value,
          'Unexpecbted match confidence after accepting the application');

        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", Amount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ChangeAppliedAmountPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure ChangeAmountToApply()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        ChangedAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        ChangedAmount := Amount - LibraryRandom.RandDecInDecimalRange(0.1, Amount / 2, 2);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(ChangedAmount);
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        // Verify
        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", ChangedAmount);

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyToMultipleEntriesPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure ApplyToMultipleEntries()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        AmountDelta: Decimal;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        AmountDelta := Amount - LibraryRandom.RandDecInDecimalRange(0.1, Amount / 2, 2);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", AmountDelta);
        InsertCustLedgerEntry(CustLedgEntry2, Cust."No.", Amount - AmountDelta);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(Amount);
        LibraryVariableStorage.Enqueue(Amount - AmountDelta);
        LibraryVariableStorage.Enqueue(CustLedgEntry2."Entry No.");
        InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry."Customer No.", AmountDelta);
        VerifyAppliedPaymentEntry(BankAccRecon, ExpectedMatchedLineNo, CustLedgEntry2."Entry No.",
          CustLedgEntry."Bal. Account Type"::Customer, CustLedgEntry2."Customer No.", Amount - AmountDelta);

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ApplyToDifferentEntryPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure ApplyToDifferentEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        CustLedgEntry3: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        ExpectAmtVariant: Variant;
        StmtAmt: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ExpectedMatchedLineNo: Integer;
        ExpectAmt: Decimal;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, StmtAmt);
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Round(StmtAmt / 2));
        InsertCustLedgerEntry(CustLedgEntry2, Cust."No.", StmtAmt);
        InsertCustLedgerEntry(CustLedgEntry3, Cust."No.", StmtAmt * 2);

        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        ExpectedMatchedLineNo :=
          CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, StmtAmt);

        // Exercise
        InvokeAutoApply(BankAccRecon, PaymentReconciliationJournal);

        CustLedgEntry.SetRange("Entry No.", CustLedgEntry."Entry No.", CustLedgEntry3."Entry No.");
        if CustLedgEntry.FindSet() then
            repeat
                LibraryVariableStorage.Enqueue(CustLedgEntry."Entry No.");
                LibraryVariableStorage.Enqueue(StmtAmt);
                PaymentReconciliationJournal.ApplyEntries.Invoke;
                LibraryVariableStorage.Dequeue(ExpectAmtVariant);
                ExpectAmt := ExpectAmtVariant;

                VerifyAppliedPaymentEntry(
                  BankAccRecon,
                  ExpectedMatchedLineNo,
                  CustLedgEntry."Entry No.",
                  CustLedgEntry."Bal. Account Type"::Customer,
                  CustLedgEntry."Customer No.",
                  ExpectAmt);
            until CustLedgEntry.Next = 0;

        PaymentReconciliationJournal.Close;
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WrongApplicationAmountPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure UnableToApplyAmountWithDifferentSign()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ChangedAmount: Decimal;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        ChangedAmount := Amount * -1;
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(ChangedAmount);
        asserterror InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,WrongApplicationAmountPaymentApplicationHandler')]
    [Scope('OnPrem')]
    procedure UnableToApplyMoreThanRemainingAmount()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
        ChangedAmount: Decimal;
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        ChangedAmount := Amount + 1;
        CreateCustomer(Cust);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);

        // Exercise
        LibraryVariableStorage.Enqueue(ChangedAmount);
        asserterror InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon, PaymentReconciliationJournal, CustLedgEntry."Entry No.");

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountNameOnPaymentReconciliationJournal()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Cust: Record Customer;
        Cust2: Record Customer;
        BankAccRecon: Record "Bank Acc. Reconciliation";
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
        Amount: Decimal;
        PostingDate: Date;
        BankAccNo: Code[20];
        StatementNo: Code[20];
    begin
        Initialize();
        // Setup
        CreateInputData(PostingDate, BankAccNo, StatementNo, Amount);
        CreateCustomer(Cust);
        CreateCustomer(Cust2);
        InsertCustLedgerEntry(CustLedgEntry, Cust."No.", Amount);
        InsertCustLedgerEntry(CustLedgEntry2, Cust2."No.", Amount * 2);
        CreateBankAccRec(BankAccRecon, BankAccNo, StatementNo);
        CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry."Document No." + Cust.Name, Amount);
        CreateBankAccRecLine(BankAccRecon, PostingDate, CustLedgEntry2."Document No." + Cust2.Name, Amount * 2);

        // Exercise
        LibraryLowerPermissions.AddAccountReceivables;
        InvokeAutoApply(BankAccRecon, PaymentReconciliationJournal);

        // Verify Account Name is displayed and you cann drill down on it
        PaymentReconciliationJournal.Last;
        VerifyAccountNameField(Cust2, PaymentReconciliationJournal);
        PaymentReconciliationJournal.First;
        VerifyAccountNameField(Cust, PaymentReconciliationJournal);
        Assert.AreEqual(Cust.Name, PaymentReconciliationJournal.AccountName.Value, 'Unexpected Account Name shown');
        PaymentReconciliationJournal.Close;
    end;

    local procedure InvokeAutoApplyAndOpenPaymentApplicationsPage(BankAccRecon: Record "Bank Acc. Reconciliation"; var PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal"; EntryNo: Integer)
    begin
        InvokeAutoApply(BankAccRecon, PaymentReconciliationJournal);
        LibraryVariableStorage.Enqueue(EntryNo);
        PaymentReconciliationJournal.ApplyEntries.Invoke;
    end;

    local procedure InvokeAutoApply(BankAccRecon: Record "Bank Acc. Reconciliation"; var PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal")
    var
        PmtReconciliationJournals: TestPage "Pmt. Reconciliation Journals";
    begin
        PmtReconciliationJournals.OpenView;
        PmtReconciliationJournals.GotoRecord(BankAccRecon);
        PaymentReconciliationJournal.Trap;
        PmtReconciliationJournals.EditJournal.Invoke;

        PaymentReconciliationJournal.ApplyAutomatically.Invoke;
        PaymentReconciliationJournal.First;
    end;

    local procedure CreateBankAccRec(var BankAccRecon: Record "Bank Acc. Reconciliation"; BankAccNo: Code[20]; StatementNo: Code[20])
    begin
        with BankAccRecon do begin
            Init;
            "Bank Account No." := BankAccNo;
            "Statement No." := StatementNo;
            "Statement Date" := WorkDate;
            "Statement Type" := "Statement Type"::"Payment Application";
            Insert;
        end;
    end;

    local procedure CreateBankAccRecLine(var BankAccRecon: Record "Bank Acc. Reconciliation"; TransactionDate: Date; TransactionText: Text[140]; Amount: Decimal): Integer
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
    begin
        FillInCommonBankAccRecLineFields(BankAccReconLine, BankAccRecon, TransactionDate, Amount);
        BankAccReconLine."Transaction Text" := TransactionText;
        BankAccReconLine.Insert();
        exit(BankAccReconLine."Statement Line No.");
    end;

    local procedure FillInCommonBankAccRecLineFields(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; BankAccRecon: Record "Bank Acc. Reconciliation"; TransactionDate: Date; Amount: Decimal)
    begin
        with BankAccReconLine do begin
            SetRange("Statement Type", BankAccRecon."Statement Type");
            SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
            SetRange("Statement No.", BankAccRecon."Statement No.");
            if FindLast() then
                Reset;

            Init;
            "Bank Account No." := BankAccRecon."Bank Account No.";
            "Statement Type" := BankAccRecon."Statement Type";
            "Statement No." := BankAccRecon."Statement No.";
            "Statement Line No." += 10000;
            "Transaction Date" := TransactionDate;
            "Statement Amount" := Amount;
            Difference := Amount;
            Type := Type::"Bank Account Ledger Entry";
        end;
    end;

    local procedure CreateInputData(var PostingDate: Date; var BankAccNo: Code[20]; var StatementNo: Code[20]; var Amount: Decimal)
    var
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        BankAcc: Record "Bank Account";
    begin
        Amount := LibraryRandom.RandDec(1000, 2);
        PostingDate := WorkDate + LibraryRandom.RandInt(10);

        BankAccNo :=
          LibraryUtility.GenerateRandomCode(
            BankAccReconLine.FieldNo("Bank Account No."), DATABASE::"Bank Acc. Reconciliation Line");

        with BankAcc do begin
            Init;
            "No." := BankAccNo;
            "Currency Code" := LibraryERM.GetLCYCode;
            Insert;
        end;

        StatementNo :=
          LibraryUtility.GenerateRandomCode(
            BankAccReconLine.FieldNo("Statement No."), DATABASE::"Bank Acc. Reconciliation Line");
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Applied Payment Entries Test");
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();
        CloseExistingEntries;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Applied Payment Entries Test");
    end;

    local procedure InsertCustLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20]; Amt: Decimal)
    var
        LastEntryNo: Integer;
    begin
        with CustLedgEntry do begin
            FindLast();
            LastEntryNo := "Entry No.";
            InsertDetailedCustLedgerEntry(LastEntryNo + 1, Amt);
            Init;
            "Entry No." := LastEntryNo + 1;
            "Posting Date" := WorkDate;
            "Customer No." := CustNo;
            "Document No." := CopyStr(CreateGuid, 1, 20);
            Open := true;
            Insert;
            CalcFields("Remaining Amount");
        end;
    end;

    local procedure InsertDetailedCustLedgerEntry(CustLedgerEntryNo: Integer; Amt: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastEntryNo: Integer;
    begin
        with DetailedCustLedgEntry do begin
            FindLast();
            LastEntryNo := "Entry No.";
            Init;
            "Entry No." := LastEntryNo + 1;
            "Cust. Ledger Entry No." := CustLedgerEntryNo;
            Amount := Amt;
            "Amount (LCY)" := Amt;
            Insert;
        end;
    end;

    local procedure CreateCustomer(var Cust: Record Customer)
    begin
        with Cust do begin
            Init;
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::Customer);
            Name := CopyStr(CreateGuid, 1, 50);
            "Payment Terms Code" := CreatePaymentTerms;
            "Payment Method Code" := CreatePaymentMethod;
            City := LibraryUtility.GenerateGUID();
            Address := LibraryUtility.GenerateGUID();
            Insert(true);
        end;
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        with PaymentTerms do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Payment Terms");
            Insert;
            exit(Code);
        end;
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        with PaymentMethod do begin
            Init;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Payment Method");
            Insert;
            exit(Code);
        end;
    end;

    [Normal]
    local procedure CloseExistingEntries()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.ModifyAll(Open, false);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.ModifyAll(Open, false);
    end;

    local procedure VerifyAccountNameField(Customer: Record Customer; PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal")
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Assert.AreEqual(Customer.Name, PaymentReconciliationJournal.AccountName.Value, 'Unexpected Account Name shown');
        CustomerCard.Trap;
        PaymentReconciliationJournal.AccountName.DrillDown;
        Assert.AreEqual(Customer."No.", CustomerCard."No.".Value, 'Unexpected customer shown after drilldown on Account Name');
        CustomerCard.Close;
    end;

    local procedure VerifyAppliedPaymentEntryCount(BankAccRecon: Record "Bank Acc. Reconciliation"; ExpectedMatchedLineNo: Integer; ExpectedMatchedEntryNo: Integer; ExpectedMatchedAccType: Enum "Gen. Journal Account Type"; ExpectedMatchedAccNo: Code[50]; ExpectedAppliedAmount: Decimal; ExpectedCount: Integer)
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        with AppliedPmtEntry do begin
            SetRange("Statement No.", BankAccRecon."Statement No.");
            SetRange("Statement Line No.", ExpectedMatchedLineNo);
            SetRange("Statement Type", "Statement Type"::"Payment Application");
            SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
            SetRange("Account Type", ExpectedMatchedAccType);
            SetRange("Account No.", ExpectedMatchedAccNo);
            SetRange("Applies-to Entry No.", ExpectedMatchedEntryNo);
            if ExpectedAppliedAmount <> 0 then
                SetRange("Applied Amount", ExpectedAppliedAmount);
            Assert.AreEqual(ExpectedCount, Count, 'Unexpected applied payment entry count.');
        end;
    end;

    local procedure VerifyAppliedPaymentEntry(BankAccRecon: Record "Bank Acc. Reconciliation"; BankAccReconLineNo: Integer; ExpectedMatchedEntryNo: Integer; ExpectedMatchedAccType: Enum "Gen. Journal Account Type"; ExpectedMatchedAccNo: Code[50]; ExpectedAppliedAmount: Decimal)
    begin
        VerifyAppliedPaymentEntryCount(
          BankAccRecon, BankAccReconLineNo,
          ExpectedMatchedEntryNo, ExpectedMatchedAccType, ExpectedMatchedAccNo, ExpectedAppliedAmount, 1);
    end;

    local procedure VerifyNoAppliedPaymentEntry(BankAccRecon: Record "Bank Acc. Reconciliation"; BankAccReconLineNo: Integer; ExpectedMatchedEntryNo: Integer; ExpectedMatchedAccType: Enum "Gen. Journal Account Type"; ExpectedMatchedAccNo: Code[50]; ExpectedMatchedAmount: Decimal)
    begin
        VerifyAppliedPaymentEntryCount(
          BankAccRecon, BankAccReconLineNo,
          ExpectedMatchedEntryNo, ExpectedMatchedAccType, ExpectedMatchedAccNo, ExpectedMatchedAmount, 0);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectFirstRowPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);
        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);
        LibraryVariableStorage.Enqueue(PaymentApplication.TotalAppliedAmount.AsDEcimal);
        LibraryVariableStorage.Enqueue(PaymentApplication.TotalRemainingAmount.AsDEcimal);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RejectApplicationPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        Amount: Variant;
        ClosePageVariant: Variant;
        RejectVariant: Variant;
        MatchConfidenceBeforeRejecting: Variant;
        Reject: Boolean;
        ClosePage: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ClosePageVariant);
        ClosePage := ClosePageVariant;
        if ClosePage then begin
            LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);
            exit;
        end;

        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(RejectVariant);
        Reject := RejectVariant;
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);

        if Reject then begin
            MatchConfidenceBeforeRejecting := PaymentApplication.Control2.MatchConfidence.Value;
            PaymentApplication.Reject.Invoke;
            Assert.AreEqual(
              MatchConfidenceBeforeRejecting,
              PaymentApplication.Control2.MatchConfidence.Value,
              'Unexpected match confidence after rejecting the application');
        end;

        Assert.IsFalse(PaymentApplication.Applied.AsBoolean, 'Applied not set to false when rejecting application.');
        Assert.AreEqual(PaymentApplication.AppliedAmount.AsDEcimal, 0, 'Amount not un-applied.');
        Assert.AreEqual(PaymentApplication.RemainingAmountAfterPosting.AsDEcimal, Amount, 'Amount left to apply is incorrect.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AcceptApplicationPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        ClosePageVariant: Variant;
        ClosePage: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ClosePageVariant);
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);

        ClosePage := ClosePageVariant;
        if ClosePage then
            exit;

        PaymentApplication.Accept.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAppliedPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        Amount: Variant;
        MatchConfidenceBeforeChange: Variant;
        AppliedVariant: Variant;
        Applied: Boolean;
        ExpectedAppliedAmount: Decimal;
        ExpectedRemainingAmount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Amount);
        LibraryVariableStorage.Dequeue(AppliedVariant);
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);
        Applied := AppliedVariant;

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);

        Assert.AreNotEqual(Applied, PaymentApplication.Applied.Value, 'Value is already set');
        MatchConfidenceBeforeChange := PaymentApplication.Control2.MatchConfidence.Value;

        PaymentApplication.Applied.SetValue(Applied);

        ExpectedAppliedAmount := Amount;
        ExpectedRemainingAmount := Amount;

        if Applied then
            ExpectedRemainingAmount := 0
        else
            ExpectedAppliedAmount := 0;

        Assert.AreEqual(PaymentApplication.AppliedAmount.AsDEcimal, ExpectedAppliedAmount, 'Amount not un-applied.');
        Assert.AreEqual(
          PaymentApplication.RemainingAmountAfterPosting.AsDEcimal, ExpectedRemainingAmount, 'Amount left to apply is incorrect.');
        Assert.AreEqual(
          MatchConfidenceBeforeChange,
          PaymentApplication.Control2.MatchConfidence.Value,
          'Match Confidence should not be changed');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeAppliedAmountPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        AmountVariant: Variant;
        NewAmountVariant: Variant;
        MatchConfidenceBeforeUnapplying: Variant;
        Amount: Decimal;
        NewAmount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(AmountVariant);
        LibraryVariableStorage.Dequeue(NewAmountVariant);
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);

        NewAmount := NewAmountVariant;
        Amount := AmountVariant;

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);
        MatchConfidenceBeforeUnapplying := PaymentApplication.Control2.MatchConfidence.Value;
        PaymentApplication.AppliedAmount.SetValue(NewAmount);

        Assert.AreEqual(NewAmount <> 0, PaymentApplication.Applied.AsBoolean, 'Applied is not set correctly.');
        Assert.AreEqual(NewAmount, PaymentApplication.AppliedAmount.AsDEcimal, 'Applied Amount is not set correctly.');
        Assert.AreEqual(Amount - NewAmount, PaymentApplication.RemainingAmountAfterPosting.AsDEcimal, 'Remaining Amount is incorrect.');
        Assert.AreEqual(
          MatchConfidenceBeforeUnapplying,
          PaymentApplication.Control2.MatchConfidence.Value,
          'Unexpected match confidence after rejecting the application');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WrongApplicationAmountPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        NewAmountVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewAmountVariant);
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);
        asserterror PaymentApplication.AppliedAmount.SetValue(NewAmountVariant);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToMultipleEntriesPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        AmountVariant: Variant;
        NewAmountVariant: Variant;
        MatchConfidenceBeforeApplying: Variant;
        CustomerLedgerEntryNo2: Variant;
        Amount: Decimal;
        NewAmount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(AmountVariant);
        LibraryVariableStorage.Dequeue(NewAmountVariant);
        Amount := AmountVariant;
        NewAmount := NewAmountVariant;
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo2);
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo2);
        MatchConfidenceBeforeApplying := PaymentApplication.Control2.MatchConfidence.Value;

        PaymentApplication.AppliedAmount.SetValue(NewAmountVariant);

        Assert.AreEqual(NewAmount <> 0, PaymentApplication.Applied.AsBoolean, 'Applied is not set correctly.');
        Assert.AreEqual(NewAmount, PaymentApplication.AppliedAmount.AsDEcimal, 'Applied Amount is not set correctly.');
        Assert.AreEqual(
          MatchConfidenceBeforeApplying,
          PaymentApplication.Control2.MatchConfidence.Value,
          'Unexpected match confidence after rejecting the application');

        Assert.AreEqual(PaymentApplication.TotalAppliedAmount.AsDEcimal, Amount, 'Total applied amount should match the original amount');
        Assert.AreEqual(PaymentApplication.TotalRemainingAmount.AsDEcimal, 0, 'Total remaining amount should be zero');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToDifferentEntryPaymentApplicationHandler(var PaymentApplication: TestPage "Payment Application")
    var
        CustomerLedgerEntryNo: Variant;
        StmtAmtVariant: Variant;
        StmtAmt: Decimal;
        ExpectAmt: Decimal;
    begin
        LibraryVariableStorage.Dequeue(CustomerLedgerEntryNo);
        LibraryVariableStorage.Dequeue(StmtAmtVariant);
        StmtAmt := StmtAmtVariant;

        PaymentApplication.Applied.SetValue(false);

        PaymentApplication.FindFirstField("Applies-to Entry No.", CustomerLedgerEntryNo);

        if Abs(StmtAmt) > Abs(PaymentApplication.RemainingAmountAfterPosting.AsDEcimal) then
            ExpectAmt := PaymentApplication.RemainingAmountAfterPosting.AsDEcimal
        else
            ExpectAmt := StmtAmt;

        PaymentApplication.Applied.SetValue(true);

        Assert.AreEqual(ExpectAmt, PaymentApplication.TotalAppliedAmount.AsDEcimal, 'Amount incorrectly applied.');
        Assert.AreEqual(StmtAmt - ExpectAmt, PaymentApplication.TotalRemainingAmount.AsDEcimal, 'Amount left to apply is incorrect.');

        LibraryVariableStorage.Enqueue(ExpectAmt);
    end;
}

