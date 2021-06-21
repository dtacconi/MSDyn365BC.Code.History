codeunit 144009 "ERM Cash Bank Giro Journal"
{
    //  // [FEATURE] [Bank Giro Journal]
    // 
    //  1 - 2: Verify Document Date on Cash Journal line with Single and Multiple Line.
    //  3 - 4: Verify that correct Journal Page opened when selected from respective General Journal Batches Page.
    //  5 - 6: Verify that correct entries posted when Cash/ Bank Giro Journal created from Cash/ Bank Giro Journal Template Page.
    //  7 - 8: Verify that correct data is present on Cash/ Bank Giro Journal Page Fact Boxes.
    //  9 - 10: Verify correct date updated on Bank Journal Line when Update Date confirmation is accepted/ not accepted.
    // 11 - 14: Verify correct Full Amount and Partial Amount Applied posted for Vendor and Customer from Bank Giro Journal.
    // 15: Verify correct Payment Discount Amount on Vendor Ledger Entry created from Bank Giro Journal.
    // 16: Check Line No. on Error message when Bank journal posted with Credit Amount using Applies to Doc No.
    // 17: Verify CBG Statement Line is recognized and applied with new 10 character Bank Account No.
    // 18: Verify payment is not applied to Invoice when several lines with error and Enable Update on Posting
    // 19: Verify CBG Statement Line set Reconciliation Status as Unknown if system doesn't find any matched record.
    // 20: Verify CBG Statement Line is recognized and applied when IBAN Code contains more than 20 characters.
    // 
    // Covers Test Cases: 342658
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // DocumentDateOnCashJournalLine, DocumentDateOnMultipleCashJournalLines                  152582
    // BankJournalFromBankJournalBatch, BankJournalFromBankJournalTemplate             173114,173115
    // CashJournalFromCashJournalBatch, CashJournalFromCashJournalTemplate             173116,173117
    // FactBoxOnBankJournal, FactBoxOnCashJournal                                      254254,254256
    // 
    // Covers Test Cases: 341890
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // DateChangeYesOnBankJournal, DateChangeNoOnBankJournal                           155389,155390
    // 
    // Covers Test Cases: 343317
    // ---------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ---------------------------------------------------------------------------------------------
    // BankGiroJournalPostAndApplyVendorAmountFully                                           171410
    // BankGiroJournalPostAndApplyVendorAmountPartial                                         171411
    // BankGiroJournalPostAndApplyCustomerAmountFully                                         171412
    // BankGiroJournalPostAndApplyCustomerAmountPartial                                       171413
    // PaymentDiscountCalculationOnBankGiroJournal                                            257379
    // 
    // Covers Test Cases For Bug Id : 52021
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // LineNoOnErrorWhilePostingBankJournal
    // 
    // Covers Test Cases For Bug Id : 66303
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // NumberOfLinesOnCBGPostingTest
    // 
    // Covers Test Cases For Bug Id : 352101
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineRecognizeBankAccountNo
    // 
    // BankGiroWithEnableUpdateOnPosting                                                      352099
    // 
    // Covers Test Cases For Bug Id : 103375
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineNotRecognizeBankAccountNo                                          103375
    // 
    // Covers Test Cases For Bug Id : 104012
    // ------------------------------------------------------------------------------------------------
    // Test Function Name                                                                 TFS ID
    // ------------------------------------------------------------------------------------------------
    // CBGStatementLineRecognizeBankAccountNoWithLongIBAN                                  104012

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryJournals: Codeunit "Library - Journals";
        AssertFailMsg: Label '%1 must be %2 in %3.', Comment = '%1: Fieldcaption;%2: Value;%3: Tablecaption';
        DateQst: Label 'You have modified Date';
        FilePathTxt: Label '.\%1.txt';
        OpeningBalanceQst: Label 'The opening balance';
        PostingQst: Label 'Do you want to';
        SwiftCodeTxt: Label '9G8U6H';
        VATStatusTxt: Label 'Sale %1%';
        PositiveMustBeYesErr: Label 'Positive must be equal to ''Yes''';
        WrongRowNumberErr: Label 'Wrong number of rows, Not Applied = %1, Applied = %2';
        CBGStatementLineUnknownErr: Label 'Reconciliation Status should be Unknown if system does not find any matched record in CBG Statement Line';
        CBGStatementLineAppliedErr: Label 'Reconciliation Status should be Applied if system matches record in CBG Statement Line';
        CBGStatementLineAmountErr: Label 'Wrong amount in CBG Statement Line after application.';
        WrongTemplateFilterErr: Label 'Wrong Gen. Journal Template filter';
        isInitialized: Boolean;
        EarlierPostingDateErr: Label 'You cannot apply to an entry with a posting date before the posting date of the entry that you want to apply.';
        EmptyDateErr: Label 'Date must have a value in CBG Statement Line: Journal Template Name=%1, No.=%2, Line No.=%3. It cannot be zero or empty.';
        ProposalLinesProcessedMsg: Label 'The proposal lines were processed.';

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateOnCashJournalLine()
    var
        CashJournal: TestPage "Cash Journal";
    begin
        // [SCENARIO] Check that Document Date is auto - filled on Cash Journal Line when no Date is entered in Cash Journal Line.

        // Setup.
        Initialize;
        OpenCashJournalListPage;

        // Exercise: Fill Values on Cash Journal Line without filling Document Date.
        OpenCashJournalPage(CashJournal, LibraryERM.CreateGLAccountNo);

        // Verify: Verify that Document Date field is autofilled with Work date.
        CashJournal.Subform."Document Date".AssertEquals(WorkDate);

        // Tear Down: Close Cash Journal Page.
        CashJournal.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateOnMultipleCashJournalLines()
    var
        CashJournal: TestPage "Cash Journal";
    begin
        // [SCENARIO] Check that Document Date is correct when multiple Cash Journal Lines present on Cash Journal.

        // Setup: Open Cash Journal List Page, Create Cash Journal Line without entering Document Date.
        Initialize;
        OpenCashJournalListPage;
        OpenCashJournalPage(CashJournal, LibraryERM.CreateGLAccountNo);
        CashJournal.Subform.Next;  // Go to next line.
        FillValuesOnCashJournalLine(CashJournal, LibraryERM.CreateGLAccountNo);

        // Exercise: Fill Document Date on next line, take Date greater than work date.
        CashJournal.Subform."Document Date".SetValue(CalcDate('<1D>', WorkDate));

        // Verify: Verify that Document Date field contains correct value.
        CashJournal.Subform."Document Date".AssertEquals(CalcDate('<1D>', WorkDate));

        // Tear Down: Close Cash Journal.
        CashJournal.Close;
    end;

    [Test]
    [HandlerFunctions('CashJournalPageHandler')]
    [Scope('OnPrem')]
    procedure CashJournalFromCashJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO] Verify that correct Journal Page (Cash Journal) opened from General Journal Batches Page.
        CBGJournalFromJournalBatches(
          GenJournalTemplate.Type::Cash, GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo);
    end;

    [Test]
    [HandlerFunctions('BankGiroJournalPageHandler')]
    [Scope('OnPrem')]
    procedure BankJournalFromBankJournalBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO] Verify that correct Journal Page (Bank Giro Journal) opened from General Journal Batches Page.
        CBGJournalFromJournalBatches(
          GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CashJournalFromCashJournalTemplate()
    var
        GLEntry: Record "G/L Entry";
        CashJournal: TestPage "Cash Journal";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct entries posted when Cash Journal created from Cash Journal Template Page.

        // Setup: Create Cash Journal using Cash Journal Template Page.
        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        GLAccountNo := LibraryERM.CreateGLAccountNo;
        OpenCashJournalListPage;
        OpenCashJournalPage(CashJournal, GLAccountNo);
        CashJournal.Subform.Credit.SetValue(Amount);
        DocumentNo := CashJournal.Subform."Document No.".Value;

        // Exercise.
        CashJournal.Post.Invoke;

        // Verify: Verify Amount on General Ledger Entry.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AssertFailMsg, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankJournalFromBankJournalTemplate()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct entries posted when Bank Giro Journal created from Bank Giro Journal Template Page.

        // Setup: Create Cash Journal using Bank Giro Journal Template Page.
        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount);
        OpenBankGiroJournalPage(
          BankGiroJournal, CBGStatementLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, Amount, false);

        // Exercise.
        BankGiroJournal.Post.Invoke;

        // Verify: Verify Amount on Bank Ledger Entry.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst;
        Assert.AreNearlyEqual(
          Amount, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), Amount, BankAccountLedgerEntry.TableCaption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxOnCashJournal()
    var
        GLAccount: Record "G/L Account";
        CashJournal: TestPage "Cash Journal";
        VATPct: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        // [SCENARIO] Verify that correct data is present on Cash Journal's Fact Box.

        // Setup: Create Cash Journal through page.
        Initialize;
        VATPct := CreateGLAccountWithPostingSetup(GLAccount);
        OpenCashJournalListPage;
        OpenCashJournalPage(CashJournal, GLAccount."No.");
        CashJournal.Subform.Credit.SetValue(LibraryRandom.RandDec(100, 2));  // Set Random Amount.
        Amount := CashJournal.Subform.Credit.AsDEcimal;
        VATAmount := Amount * VATPct / 100;
        CashJournal.Subform.Next;

        // Exercise: Move cursor to first created line.
        CashJournal.Subform.Previous();

        // Verify: Verify Data on Cash Journal's Fact Box.
        CashJournal.Control1903886207.AccountName.AssertEquals(GLAccount.Name);
        CashJournal.Control1903886207.VATStatus.AssertEquals(StrSubstNo(VATStatusTxt, VATPct));
        CashJournal.Control1903886207.TotalBalance2.AssertEquals(Amount + VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FactBoxOnBankJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GLAccount: Record "G/L Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        Amount: Decimal;
        VATAmount: Decimal;
        VATPct: Decimal;
    begin
        // [SCENARIO] Verify that correct data is present on Bank Giro Journal's Fact Box.

        // Setup: Create Bank Giro Journal through page.
        Initialize;
        VATPct := CreateGLAccountWithPostingSetup(GLAccount);
        Amount := LibraryRandom.RandDec(100, 2);  // Take Random Amount.
        VATAmount := Amount * VATPct / 100;
        OpenBankGiroJournalListPage(CreateBankAccount);
        OpenBankGiroJournalPage(BankGiroJournal, CBGStatementLine."Account Type"::"G/L Account", GLAccount."No.", Amount, false);
        BankGiroJournal.Subform.Next;

        // Exercise: Move cursor to first created line.
        BankGiroJournal.Subform.Previous();

        // Verify: Verify Data on Bank Giro Journal's Fact Box.
        BankGiroJournal.Control1903886207.AccountName.AssertEquals(GLAccount.Name);
        BankGiroJournal.Control1903886207.VATStatus.AssertEquals(StrSubstNo(VATStatusTxt, VATPct));
        BankGiroJournal.Control1903886207.TotalBalance2.AssertEquals(Amount + VATAmount);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateChangeYesOnBankJournal()
    begin
        // [SCENARIO] Verify correct date updated on Bank Journal Line when Update Date confirmation is accepted.
        DocumentDateOnBankGiroJournal(CalcDate('<1D>', WorkDate));
    end;

    [Test]
    [HandlerFunctions('NoConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateChangeNoOnBankJournal()
    begin
        // [SCENARIO] Verify correct date updated on Bank Journal Line when Update Date confirmation is not accepted.
        DocumentDateOnBankGiroJournal(WorkDate);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyVendorAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CBGStatementLine."Account Type"::Vendor,
          CreateVendor, -Amount, -Amount, false);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyVendorAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CBGStatementLine."Account Type"::Vendor,
          CreateVendor, -Amount, -Amount / 2, false);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyEmployeeAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Employee.

        // Setup: Create Employee and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Employee, CBGStatementLine."Account Type"::Employee,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount, Amount, Amount, true);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyEmployeeAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Vendor.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Employee, CBGStatementLine."Account Type"::Employee,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount, Amount, Amount / 2, true);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyCustomerAmountFully()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied and posted from Bank Giro Journal for Customer.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CBGStatementLine."Account Type"::Customer,
          CreateCustomer, Amount, Amount, false);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostAndApplyCustomerAmountPartial()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Partial Amount Applied and posted from Bank Giro Journal for Customer.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);  // Take large Random Amount.
        ApplyAndPostBankGiroJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CBGStatementLine."Account Type"::Customer,
          CreateCustomer, Amount, Amount / 2, false);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDEmployeeModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        EmployeeNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied.

        // Setup: Create Employee and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount;

        // Exercise.
        CreateGeneralJournal(GenJournalLine, EmployeeNo, GenJournalLine."Account Type"::Employee, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Employee, EmployeeNo,
          CBGStatementLine."Applies-to Doc. Type"::" ", '', 0);
        CBGStatementLineApplyEntries(CBGStatementLine, EmployeeNo, GenJournalLine."Document No.");

        // Verify field Amount is updated.
        Assert.AreEqual(-Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        CustNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Full Amount Applied.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        CustNo := CreateCustomer;

        // Exercise.
        CreateGeneralJournal(GenJournalLine, CustNo, GenJournalLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, '', 0);
        CBGStatementLineApplyEntries(CBGStatementLine, CustNo, GenJournalLine."Document No.");

        // Verify field Amount is updated.
        Assert.AreEqual(-Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDGLAccount()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO] Verify that correct Amount field in Bank/Giro Journal is not updated if Account type is G/L Account.

        // Setup: Create Vendor and Bank Giro Journal.
        Initialize;
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        GLAccountNo := LibraryERM.CreateGLAccountNo;

        // Exercise.
        CreateGeneralJournal(GenJournalLine, GLAccountNo, GenJournalLine."Account Type"::"G/L Account", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::"G/L Account", GLAccountNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, GenJournalLine."Document No.", Amount);
        CBGStatementLineApplyToDocNoLookup(CBGStatementLine, GLAccountNo);

        // Verify field Amount is not updated.
        Assert.AreEqual(Amount, CBGStatementLine.Amount, CBGStatementLineAmountErr);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure PaymentDiscountCalculationOnBankGiroJournal()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO] Test to Verify correct Payment Discount Amount on Vendor Ledger Entry created when Bank Giro Journal created from Bank Giro Journal Template Page.

        // Setup: Create Bank Account, Create and post Purchase Invoice and Get Entries on Telebank Proposal Page.
        Initialize;
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        ProcessAndExportPaymentTelebank(VendorBankAccount, BankAccountNo);
        OpenBankGiroJournalListPage(VendorBankAccount."Bank Account No.");
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, VendorBankAccount."Bank Account No.", WorkDate);

        // Exercise.
        BankGiroJournal.Post.Invoke;

        // Verify: Verify Payment Amount after Discount on Vendor Ledger Entry.
        VerifyOriginalPaymentAmountAfterDiscount(VendorBankAccount."Vendor No.");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure LineNoOnErrorWhilePostingBankJournal()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Error message when Bank journal posted with Credit Amount and applied to Credit Memo.

        // Setup: Create and post Sales Credit Memo and Update CBG Statement Line with Credit Amount using Applies to Doc No.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        PostedDocumentNo :=
          CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", Customer."No.", WorkDate);
        CreateAndUpdateCBGStatementLine(CBGStatementLine, SalesLine, PostedDocumentNo);
        CBGStatement.Get(CBGStatementLine."Journal Template Name", CBGStatementLine."No.");

        // Exercise: Post CBG Statement.
        asserterror CBGStatement.ProcessStatementASGenJournal;

        // Verify: Error message "Positive must be equal to 'Yes'"
        Assert.ExpectedError(PositiveMustBeYesErr);
    end;

    [Test]
    [HandlerFunctions('CBGPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NumberOfLinesOnCBGPostingTest()
    var
        CBGStatementLine: Record "CBG Statement Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        CustomerNo: Code[20];
        VendorNo: Code[20];
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        PostedDocumentNo: Code[20];
        NotAppliedSalesDocCount: Integer;
        AppliedSalesDocCount: Integer;
        NotAppliedPurchaseDocCount: Integer;
        AppliedPurchaseDocCount: Integer;
        NotAppliedExpenseDocCount: Integer;
        AppliedExpenseDocCount: Integer;
        Index: Integer;
    begin
        // [SCENARIO] Verify the number of lines in the Report CBG Posting - Test when Show Applied Entries flag is FALSE.
        // TODO: Add employee expenses as well.
        // Initialize.
        Initialize;
        CustomerNo := CreateCustomer;
        VendorNo := CreateVendor;
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount;
        GLAccountNo := CreateBalanceSheetAccount;
        CreateCBGStatement(CBGStatement);
        NotAppliedSalesDocCount := LibraryRandom.RandInt(10);
        AppliedSalesDocCount := LibraryRandom.RandInt(10);
        NotAppliedPurchaseDocCount := LibraryRandom.RandInt(10);
        AppliedPurchaseDocCount := LibraryRandom.RandInt(10);
        NotAppliedExpenseDocCount := LibraryRandom.RandInt(10);
        AppliedExpenseDocCount := LibraryRandom.RandInt(10);

        // Excercise.
        // Create and Post Sales Documents
        for Index := 1 to NotAppliedSalesDocCount do
            CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, WorkDate);

        // Create, Post and Apply Sales Documents
        for Index := 1 to AppliedSalesDocCount do begin
            PostedDocumentNo :=
              CreateAndPostSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, WorkDate);
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Customer,
              SalesLine."Sell-to Customer No.",
              SalesLine."Document Type",
              SalesLine."Amount Including VAT");
        end;

        // Create and Post Purchase Documents
        for Index := 1 to NotAppliedPurchaseDocCount do
            CreateAndPostPurchaseDocument(
              PurchaseLine,
              PurchaseLine."Document Type"::Invoice,
              LibraryRandom.RandDec(10, 2),
              LibraryRandom.RandDec(10, 2),
              VendorNo,
              WorkDate);

        // Create, Post and Apply Purchase Documents
        for Index := 1 to AppliedPurchaseDocCount do begin
            PostedDocumentNo :=
              CreateAndPostPurchaseDocument(
                PurchaseLine,
                PurchaseLine."Document Type"::Invoice,
                LibraryRandom.RandDec(10, 2),
                LibraryRandom.RandDec(10, 2),
                VendorNo,
                WorkDate);
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Vendor,
              PurchaseLine."Buy-from Vendor No.",
              PurchaseLine."Document Type",
              PurchaseLine."Amount Including VAT");
        end;

        // Create and Post Expense Documents
        for Index := 1 to NotAppliedExpenseDocCount do
            CreateAndPostEmployeeExpense(
              LibraryRandom.RandDec(10, 2),
              EmployeeNo,
              GLAccountNo,
              GenJournalLine);

        // Create, Post and Apply Expense Documents
        for Index := 1 to AppliedExpenseDocCount do begin
            PostedDocumentNo :=
              CreateAndPostEmployeeExpense(
                LibraryRandom.RandDec(10, 2),
                EmployeeNo,
                GLAccountNo,
                GenJournalLine);
            CreateCBGLine(
              CBGStatementLine,
              CBGStatement,
              PostedDocumentNo,
              CBGStatementLine."Account Type"::Employee,
              GenJournalLine."Bal. Account No.",
              GenJournalLine."Document Type",
              GenJournalLine.Amount);
        end;

        Commit;

        LibraryVariableStorage.Enqueue(CBGStatement."Journal Template Name");
        LibraryVariableStorage.Enqueue(CBGStatement."No.");
        LibraryVariableStorage.Enqueue(true);

        REPORT.Run(REPORT::"CBG Posting - Test");

        // Verify.
        VerifyNumberOfRowsOnCBGReport(
          NotAppliedSalesDocCount + NotAppliedPurchaseDocCount + NotAppliedExpenseDocCount,
          AppliedSalesDocCount + AppliedPurchaseDocCount + AppliedExpenseDocCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeBankAccountNo()
    var
        BankAccountType: Option IBAN,"Local Bank Account";
    begin
        TestBankAccountReconciliation(BankAccountType::"Local Bank Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeIBAN()
    var
        BankAccountType: Option IBAN,"Local Bank Account";
    begin
        TestBankAccountReconciliation(BankAccountType::IBAN);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLinePaymentDiscount()
    var
        Customer: Record Customer;
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        // [SCENARIO 375661] CBG Statement Line is recognized and applied with Cust. Ledger Entry with payment discount.
        Initialize;

        // [GIVEN] Customer "X" and Posted Sales Invoice "Y" with payment discount.
        CreateCustomerWithPmtDisc(Customer);
        CreateAndPostSalesInvoice(Customer, CustLedgEntry);

        // [GIVEN] CBG Statement with "Account No." = "X".
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(
          CBGStatement, CBGStatementLine, 0,
          CustLedgEntry."Remaining Amount" - CustLedgEntry."Remaining Pmt. Disc. Possible",
          'P00' + Format(LibraryRandom.RandIntInRange(1000000, 9999999)));
        CBGStatementLine.Validate("Account Type", CBGStatementLine."Account Type"::Customer);
        CBGStatementLine.Validate("Account No.", Customer."No.");
        CBGStatementLine.Modify(true);

        // [WHEN] Run Reconciliation.
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);
        CBGStatementLine.Find;

        // [THEN] CBG Statement Line has Reconciliation Status = Applied and "Applied-to DocNo." = "Y"."Document No.".
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
        CBGStatementLine.TestField("Applies-to Doc. No.", CustLedgEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('BankGiroPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure BankGiroWithEnableUpdateOnPosting()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        GenJnlLine: Record "Gen. Journal Line";
        BankGiroJournalPage: Page "Bank/Giro Journal";
        CustNo: Code[20];
        Amount: Decimal;
    begin
        Initialize;
        EnableUpdateOnPosting;
        Amount := LibraryRandom.RandDec(100, 2);
        CustNo := CreateCustomer;

        // Create and Post Customer Invoice
        CreateGeneralJournal(GenJnlLine, CustNo, GenJnlLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // Create CBG Statement with 2 lines
        CreateCBGStatement(CBGStatement);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::Customer, CustNo,
          CBGStatementLine."Applies-to Doc. Type"::Invoice, GenJnlLine."Document No.", -Amount);
        CreateCBGStatementLineWithApplyToDoc(
          CBGStatement, CBGStatementLine."Account Type"::"G/L Account",
          CreateGLAccountWithEmptyGenPostingType, 0, '', Amount);

        // Post CBG Statement with expecting an error
        BankGiroJournalPage.SetRecord(CBGStatement);
        asserterror BankGiroJournalPage.Run;

        // Verify Customer Invoice is not apllied with Payment from CBG Statement
        VerifyCustInvoiceRemainingAmount(CustNo, GenJnlLine."Document No.", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementLineNotRecognizeBankAccountNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CompanyInformation: Record "Company Information";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        AccountNumber: Text[50];
    begin
        // [SCENARIO] Verify CBG Statement Line set Reconciliation Status as Unknown if system doesn't find any matched record.

        // Setup: Create and Post Sales Invoice with Bank Account defined for Customer.
        Initialize;
        CompanyInformation.Get;
        AccountNumber := CompanyInformation.IBAN;
        CreateAndPostSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomerWithBankAccountIBAN(AccountNumber), WorkDate);

        // Add CBG Statement Line and CBG Statement Line Add. Info..
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, LibraryRandom.RandDec(100, 2), '');

        // Exercise: Run Match CBG Statement function
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // Verify: Verify Reconciliation Status is Unknown for last CBG Statement Line since system doesn't find any matched record.
        CBGStatementLine.Find;
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Unknown), Format(CBGStatementLine."Reconciliation Status"),
          CBGStatementLineUnknownErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CBGStatementLineRecognizeBankAccountNoWithLongIBAN()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        AccountNumber: Code[50];
    begin
        // [SCENARIO] Verify CBG Statement Line is recognized and applied when IBAN Code contains more than 20 characters.

        // Setup: Create and Post Sales Invoice with Bank Account defined for Customer. IBAN code is more than 20 characters.
        Initialize;
        AccountNumber := 'FR1420041010050500013M' + Format(LibraryRandom.RandIntInRange(10, 99));
        CreateAndPostSalesDocument(
          SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomerWithBankAccountIBAN(AccountNumber), WorkDate);

        // Add CBG Statement Line and CBG Statement Line Add. Info..
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);

        // Exercise: Run Match CBG Statement function
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // Verify: Verify Reconciliation Status is Applied for CBG Statement Line.
        CBGStatementLine.Find;
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Applied), Format(CBGStatementLine."Reconciliation Status"),
          CBGStatementLineAppliedErr);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesFromLookupModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementAppliedToDocPaymentTolAmtChangeFromZero()
    var
        CBGStatement: Record "CBG Statement";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        CustNo: Code[20];
        Amount: Decimal;
        MaxPaymentToleranceAmt: Decimal;
    begin
        // [Feature] [Cash Management]
        // [SCENARIO 119460] In Bank/Grio Journal the payment tolerance amount should not be ignored when you change the amount from zero
        // [GIVEN] Max Payment Tolerance Amount setup
        Initialize;
        MaxPaymentToleranceAmt := LibraryRandom.RandInt(10);
        SetMaxPaymentToleranceAmt(MaxPaymentToleranceAmt);
        // [GIVEN] Posted Sales Invoice
        Amount := LibraryRandom.RandDecInRange(MaxPaymentToleranceAmt, 100, 2);
        CustNo := CreateCustomer;
        CreateGeneralJournal(GenJnlLine, CustNo, GenJnlLine."Account Type"::Customer, Amount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [GIVEN] CBG Statement with Document Date later then Pmt Discount Date
        CreateCBGStatement(CBGStatement);
        CBGStatement.Validate(Date, CalcDate('<1M>', CBGStatement.Date));
        CBGStatement.Modify(true);
        // [GIVEN] CBG Statement Line applied to Invoice, Amount changed to zero then to Payment Tolerance Amount
        OpenBankGiroJournalPageLookupAppliesTo(
          CBGStatement, BankGiroJournal, CBGStatementLine."Account Type"::Customer, CustNo,
          Amount - LibraryRandom.RandDecInRange(0, MaxPaymentToleranceAmt, 2));
        // [WHEN] User posts CBG Statement
        CBGStatement.ProcessStatementASGenJournal;
        // [THEN] Cust. Ledger Entry for Invoice is closed taking Payment tolerance into account
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, GenJnlLine."Document No.");
        Assert.IsFalse(
          CustLedgerEntry.Open,
          StrSubstNo(AssertFailMsg, CustLedgerEntry.FieldCaption(Open), Format(false), CustLedgerEntry.TableCaption));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MatchCBGStatementLineFuncVariablesCheck()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DummyPaymentHistoryLine: Record "Payment History Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
    begin
        // [FEATURE] [CBG Statement] [UT]
        // [SCENARIO 363706] Identification field of CBG Statement Line table of 80 symbols should cause no errors in "CBG Statement Reconciliation" codeunit

        // [GIVEN] New CBG Statement created
        CreateCBGStatement(CBGStatement);

        // [GIVEN] CBG Statement Line created for previously created CBG Statement
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.",
          LibraryRandom.RandDec(100, 1),
          LibraryRandom.RandDec(100, 1));

        // [GIVEN] CBG Statement Line Add. Info with 80 symbols Description created for previously created CBG Statement Line
        AddCBGStatementLineAddInfo(
          CBGStatementLine, CBGStatementLineAddInfo, '',
          CBGStatementLineAddInfo."Information Type"::"Payment Identification");
        CBGStatementLineAddInfo.Description :=
          UpperCase(LibraryUtility.GenerateRandomText(MaxStrLen(CBGStatementLine.Identification)));
        CBGStatementLineAddInfo.Modify;

        CreatePaymentHistoryLine(
          CBGStatementLine, CBGStatementLineAddInfo.Description, DummyPaymentHistoryLine."Account Type"::Customer, '');

        // [WHEN] MatchCBGStatementLine function of "CBG Statement Reconciliation" codeunit is called for created CBG Statement
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);

        // [THEN] Description is successfuly transmitted from CBG Statement Line Add. Info to CBG Statement Line.Identification
        Assert.AreEqual(CBGStatementLine.Identification, CBGStatementLineAddInfo.Description, '');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementLineInheritDimensionFromPurchInv()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Purchase] [Dimension] [Telebank]
        // [SCENARIO 363509] Dimension Set ID is inherited from Purchase Invoice to Bank Giro Journal with Payment Telebank

        Initialize;
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        // [GIVEN] Processed Purchase Invoice with "Dimension Set ID" = "X" with Payment Telebank
        ProcessAndExportPurchPaymentTelebankWithDim(VendorBankAccount, DimSetID, BankAccountNo);
        OpenBankGiroJournalListPage(BankAccountNo);

        // [WHEN] Insert Payment History in Bank Giro Journal
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);

        // [THEN] Dimension Set ID in Bank Giro Journal Line = "X"
        VerifyDimSetIDOnCBGStatementLine(
          CBGStatementLine."Account Type"::Vendor, VendorBankAccount."Vendor No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('GetSalesProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CBGStatementLineInheritDimensionFromSalesInv()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Sales] [Dimension] [Telebank]
        // [SCENARIO 363509] Dimension Set ID is inherited from Sales Invoice to Bank Giro Journal with Payment Telebank

        Initialize;
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        // [GIVEN] Processed Sales Invoice with "Dimension Set ID" = "X" with Payment Telebank
        ProcessAndExportSalesPaymentTelebankWithDim(CustomerBankAccount, DimSetID, BankAccountNo);
        OpenBankGiroJournalListPage(BankAccountNo);

        // [WHEN] Insert Payment History in Bank Giro Journal
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);

        // [THEN] Dimension Set ID in Bank Giro Journal Line = "X"
        VerifyDimSetIDOnCBGStatementLine(
          CBGStatementLine."Account Type"::Customer, CustomerBankAccount."Customer No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure BankGiroJournalPostInvoiceCreditMemoWithPaymentDiscount()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
        RemainingAmount: Decimal;
        ExportProtocolCode: Code[20];
    begin
        // [FEATURE] [Payment Discount]
        // [SCENARIO 364591] Bank Giro Journal posted for Credit Memo and Invoice with Payment Discount
        Initialize;

        // [GIVEN] Posted Purchase Invoice (Amount = X, Payment Discount Amount = D) and Credit Memo with Payment Discount
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        PostPurchaseDocumentWithVendorBankAccount(VendorBankAccount, true, ExportProtocolCode, BankAccountNo, true);
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          CalcDate('<1M>', WorkDate), CalcDate('<1M>', WorkDate), ExportProtocolCode);

        // [GIVEN] Bank Giro Journal with suggested Payment History Lines
        OpenBankGiroJournalListPage(BankAccountNo);
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);

        // [WHEN] Bank Giro Journal posted
        BankGiroJournal.Post.Invoke;

        // [THEN] Vendor Ledger Entries for Invoice and Credit Memo are closed and "Remaining Pmt. Disc. Possible" = 0
        VendorLedgerEntry.SetRange("Vendor No.", VendorBankAccount."Vendor No.");
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, false, 0, 0);
        RemainingAmount := -VendorLedgerEntry."Original Pmt. Disc. Possible";
        asserterror VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", false, 0, 0);
        Assert.KnownFailure('Open', 252156);

        // [THEN] Vendor Ledger Entries for Payment is Opened. "Remaining Amount" = D.
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, true, 0, RemainingAmount);
    end;

    [Test]
    [HandlerFunctions('VerifyBatchOnCBGPostingTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestReportOpenFromGenJournaBatchesPageForBankTemplate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 377173] The CBG Posting - Test report can be opened from General Journal Batches page with Template Type = Bank
        Initialize;

        // [GIVEN] Gen. Journal Batch "X" and Template "B" with Type = BANK
        CreateJournalBatch(
          GenJournalBatch, GenJournalTemplate.Type::Bank,
          GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo);

        // [GIVEN] Page General Journal Batches opened for Gen. Journal Batch "X"
        OpenGeneralJournalBatchesPage(GenJournalBatch, GeneralJournalBatches);
        Commit;
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");

        // [WHEN] Test Report action pressed
        GeneralJournalBatches.TestReport.Invoke;

        // [THEN] Report CBG Posting - Test is opened and Filter on "Gen. Journal Batch" DataItem is set to "Journal Template Name" = "B"
        // Verified in VerifyBatchOnCBGPostingTestRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorCreateWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount is updated with apply-fields when payment in created on Giro Journal
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [WHEN] Insert Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType, VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);

        // [THEN] Invoice Vendor Ledger Entry is updated with "Accepted Pmt. Disc. Tolerance" = Yes,
        // [THEN] "Applies-to ID" and "Amount to Apply" fields match to CBG Statement Line fields
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
        CBGStatementLine.SetRange("Account No.", VendorBankAccount."Vendor No.");
        CBGStatementLine.FindFirst;
        VendorLedgerEntry.TestField("Applies-to ID", CBGStatementLine."Applies-to ID");
        VendorLedgerEntry.TestField("Amount to Apply", -CBGStatementLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorDeleteWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount apply-fields are crealed when payment in deleted on Giro Journal
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType, VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);

        // [WHEN] Delete CBG Statement Line
        CBGStatementLine.SetRange("Account No.", VendorBankAccount."Vendor No.");
        CBGStatementLine.FindFirst;
        CBGStatementLine.Delete(true);

        // [THEN] Invoice Vendor Ledger Entry has field "Accepted Pmt. Disc. Tolerance" = No,
        // [THEN] "Applies-to ID" and "Amount to Apply" are empty
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VendorLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
        VendorLedgerEntry.TestField("Applies-to ID", '');
        VendorLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineVendorPostWhenPmtToleranceInGracePeriod()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Vendor Ledger Entry with Pmt. Discount is closed after payment in Giro Journal is posted
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Purchase Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitVendorForExport(VendorBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetVendorAccountType, VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.",
          -LibraryRandom.RandDecInRange(10, 100, 2),
          ComputePaymentDiscountDate(VendorBankAccount."Vendor No."), BalAccountNo, ExportProtocolCode);
        PaymentNo := BankGiroJournal."Document No.".Value;

        // [WHEN] Bank Giro Journal posted
        BankGiroJournal.Post.Invoke;

        // [THEN] Vendor Ledger Entries for Invoice and Payment are closed and "Remaining Pmt. Disc. Possible" = 0
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, false, 0, 0);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyVLEPaymentDisc(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerCreateWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount is updated with apply-fields when payment in created on Giro Journal
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [WHEN] Insert Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType, CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);

        // [THEN] Invoice Customer Ledger Entry is updated with "Accepted Pmt. Disc. Tolerance" = Yes,
        // [THEN] "Applies-to ID" and "Amount to Apply" fields match to CBG Statement Line fields
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
        CBGStatementLine.SetRange("Account No.", CustLedgerEntry."Customer No.");
        CBGStatementLine.FindFirst;
        CustLedgerEntry.TestField("Applies-to ID", CBGStatementLine."Applies-to ID");
        CustLedgerEntry.TestField("Amount to Apply", -CBGStatementLine.Amount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerDeleteWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount apply-fields are crealed when payment in deleted on Giro Journal
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType, CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);

        // [WHEN] Delete CBG Statement Line
        CBGStatementLine.SetRange("Account No.", CustomerBankAccount."Customer No.");
        CBGStatementLine.FindFirst;
        CBGStatementLine.Delete(true);

        // [THEN] Invoice Customer Ledger Entry has field "Accepted Pmt. Disc. Tolerance" = No,
        // [THEN] "Applies-to ID" and "Amount to Apply" are empty
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
        CustLedgerEntry.TestField("Applies-to ID", '');
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,PaymentHistoryListModalPageHandler,PaymentDiscToleranceWarningHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure CGBStmtLineCustomerPostWhenPmtToleranceInGracePeriod()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ExportProtocolCode: Code[20];
        BalAccountNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Payment Discount] [Grace Period]
        // [SCENARIO 380069] Invoice Customer Ledger Entry with Pmt. Discount is closed after payment in Giro Journal is posted
        Initialize;

        // [GIVEN] General Ledger Setup for Pmt. Disc. Tolerance with Grace Period = 3D
        // [GIVEN] Sales Invoice posted on 20-01-18 with Due Date = 28-01-18
        InitCustomerForExport(CustomerBankAccount, ExportProtocolCode, BalAccountNo);

        // [GIVEN] Inserted Payment History Line on 30-01-18
        ScenarioOfPmtToleranceGracePeriod(
          BankGiroJournal, InvoiceNo,
          GetCustomerAccountType, CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.",
          LibraryRandom.RandDecInRange(10, 100, 2),
          ComputeCustPaymentDiscountDate(CustomerBankAccount."Customer No."), BalAccountNo, ExportProtocolCode);
        PaymentNo := BankGiroJournal."Document No.".Value;

        // [WHEN] Bank Giro Journal posted
        BankGiroJournal.Post.Invoke;

        // [THEN] Customer Ledger Entries for Invoice and Payment are closed and "Remaining Pmt. Disc. Possible" = 0
        CustLedgerEntry.SetRange("Customer No.", CustomerBankAccount."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VerifyCLEPaymentDisc(CustLedgerEntry, false, 0, 0);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        VerifyCLEPaymentDisc(CustLedgerEntry, false, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Customer Ledger Entry Posting Date.
        Initialize;

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Customer and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine, CreateCustomer, GenJournalLine."Account Type"::Customer, LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Customer Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Customer, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Customer Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDVendorModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateVendor()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Vendor Ledger Entry Posting Date.
        Initialize;

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Vendor and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine, CreateVendor, GenJournalLine."Account Type"::Vendor, -LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Vendor Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Vendor, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Vendor Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [HandlerFunctions('ApplyToIDEmployeeModalPageHandler')]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToIDEarlierPostingDateEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Employee Ledger Entry Posting Date.
        Initialize;

        // [GIVEN] Create and Post General Journal Line with "Account Type" = Employee and "Posting Date" = 02-01-2020.
        CreateGeneralJournal(
          GenJournalLine,
          LibraryHumanResource.CreateEmployeeNoWithBankAccount,
          GenJournalLine."Account Type"::Employee,
          LibraryRandom.RandDecInRange(1, 100, 2));
        GenJournalLine.Validate("Posting Date", WorkDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Employee Ledger Entry.
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Employee, GenJournalLine."Account No.");
        CBGStatementLineApplyEntries(CBGStatementLine, GenJournalLine."Account No.", GenJournalLine."Document No.");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateCustomer()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Sales Document Posting Date.
        Initialize;

        // [GIVEN] Create and Post Sales Document with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine,
            SalesLine."Document Type"::Invoice,
            CreateCustomer,
            WorkDate);

        // [GIVEN] Create Bank Giro Journal applied to created Sales Document.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.",
          SalesLine."Document Type",
          SalesLine."Amount Including VAT");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, WorkDate - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Customer Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateVendor()
    var
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatement: Record "CBG Statement";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Purchase Document Posting Date.
        Initialize;

        // [GIVEN] Create and Post Purchase Document with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine,
            PurchaseLine."Document Type"::Invoice,
            LibraryRandom.RandDec(10, 2),
            LibraryRandom.RandDec(10, 2),
            CreateVendor,
            WorkDate);

        // [GIVEN] Create Bank Giro Journal applied to created Purchase Document.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Vendor,
          PurchaseLine."Buy-from Vendor No.",
          PurchaseLine."Document Type",
          PurchaseLine."Amount Including VAT");

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, WorkDate - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Vendor Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalApplyToDocNoEarlierPostingDateEmployee()
    var
        CBGStatementLine: Record "CBG Statement Line";
        GenJournalLine: Record "Gen. Journal Line";
        CBGStatement: Record "CBG Statement";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 264931] Applied Bank Giro Journal Line Posting Date cannot be earlier than Employee Expense Posting Date.
        Initialize;

        // [GIVEN] Create and Post Employee Expense with "Posting Date" = 02-01-2020.
        PostedDocumentNo :=
          CreateAndPostEmployeeExpense(
            LibraryRandom.RandDec(10, 2),
            LibraryHumanResource.CreateEmployeeNoWithBankAccount,
            CreateBalanceSheetAccount,
            GenJournalLine);

        // [GIVEN] Create Bank Giro Journal applied to created Employee Expense.
        CreateCBGStatement(CBGStatement);
        CreateCBGLine(
          CBGStatementLine,
          CBGStatement,
          PostedDocumentNo,
          CBGStatementLine."Account Type"::Employee,
          GenJournalLine."Bal. Account No.",
          GenJournalLine."Document Type",
          GenJournalLine.Amount);

        // [WHEN] Set Bank Giro Journal Line Date = 01-01-2020.
        asserterror CBGStatementLine.Validate(Date, GenJournalLine."Posting Date" - 1);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedError(EarlierPostingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankGiroJournalNotEmptyPostingDate()
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 264931] Bank/Giro Journal Line "Posting Date" should not be empty.
        Initialize;

        // [GIVEN] Create Bank/Giro Journal Line.
        CBGStatementLine.Init;

        // [WHEN] Set Bank Giro Journal Line Date = 0D.
        asserterror CBGStatementLine.Validate(Date, 0D);

        // [THEN] Bank Giro Journal Line Date cannot be earlier than Employee Ledger Entry Date.
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(EmptyDateErr, CBGStatementLine."Journal Template Name", CBGStatementLine."No.", CBGStatementLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertVendorPaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        VendorNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo1: Code[20];
        InvNo3: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several purchase invoices
        Initialize;

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        // [GIVEN] Vendors "V1", "V2", "V3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        PostPurchaseInvoicesWithVendorBankAccount(VendorNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          VendorNo, BankAccountNo, CalcDate('<5M>', WorkDate), CalcDate('<5M>', WorkDate), ExportProtocolCode);

        // [GIVEN] Posted payment for "V1" and "V3" invoice
        InvNo1 := CreatePostVendPaymentAppliedToEntry(VendorNo[1]);
        InvNo3 := CreatePostVendPaymentAppliedToEntry(VendorNo[3]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst;
        ErrorMessages.Trap;

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal;

        // [THEN] Error messages window opened with description about invoices are not open for vendors "V1" and "V3".
        Assert.ExpectedMessage(InvNo1, ErrorMessages.Description.Value);
        ErrorMessages.Next;
        Assert.ExpectedMessage(InvNo3, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next, '');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertEmployeePaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        EmployeeNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo1: Code[20];
        InvNo2: Code[20];
    begin
        // [FEATURE] [Employee] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several employee invoices
        Initialize;

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;
        // [GIVEN] Employees "E1", "E2", "E3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        PostEmployeeInvoicesWithBankAccount(EmployeeNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          EmployeeNo, BankAccountNo, CalcDate('<5M>', WorkDate), CalcDate('<5M>', WorkDate), ExportProtocolCode);

        // [GIVEN] Posted payment for "E1" and "E2" invoice
        InvNo1 := CreatePostEmployeePaymentAppliedToEntry(EmployeeNo[1]);
        InvNo2 := CreatePostEmployeePaymentAppliedToEntry(EmployeeNo[2]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst;
        ErrorMessages.Trap;

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal;

        // [THEN] Error messages window opened with description about invoices are not open for employees "E1" and "E2".
        Assert.ExpectedMessage(InvNo1, ErrorMessages.Description.Value);
        ErrorMessages.Next;
        Assert.ExpectedMessage(InvNo2, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next, '');
    end;

    [Test]
    [HandlerFunctions('GetSalesProposalEntriesRequestPageHandler,ConfirmHandlerTrue,VerifyMessageHandler,PaymentHistoryListModalPageHandler,RequestPageHandlerExportSEPAISO20022')]
    [Scope('OnPrem')]
    procedure InsertCustomerPaymentHistoryWithOneInvoiceApplied()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        ErrorMessages: TestPage "Error Messages";
        CustomerNo: array[3] of Code[20];
        BankAccountNo: Code[20];
        ExportProtocolCode: Code[20];
        InvNo2: Code[20];
        InvNo3: Code[20];
    begin
        // [FEATURE] [Sales] [Payment History]
        // [SCENARIO 273767] Paid invoice is skipped when insert payment history with several sales invoices
        Initialize;

        // [GIVEN] Bank Account with General Journal
        BankAccountNo := CreateAndPostGenJournalLineForBankAccountBalance;

        // [GIVEN] Customers "C1", "C2", "C3" with posted invoices
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        PostSalesInvoicesWithCustomerBankAccount(CustomerNo, ExportProtocolCode, BankAccountNo);

        // [GIVEN] Export telebank proposal for 3 invoices
        ExportPaymentTelebankForSeveralAccounts(
          CustomerNo, BankAccountNo, CalcDate('<5M>', WorkDate), CalcDate('<5M>', WorkDate), ExportProtocolCode);

        // [GIVEN] Posted payment for "C2" and "C3" invoice
        InvNo2 := CreatePostCustPaymentAppliedToEntry(CustomerNo[2]);
        InvNo3 := CreatePostCustPaymentAppliedToEntry(CustomerNo[3]);

        // [GIVEN] Open Bank Giro Journal for bank BANK
        OpenBankGiroJournalListPage(BankAccountNo);

        // [GIVEN] Insert Payment History action generated 3 lines
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(BankGiroJournal, BankAccountNo, WorkDate);
        CBGStatementLine.SetFilter("Statement No.", BankAccountNo);
        Assert.RecordCount(CBGStatementLine, 3);

        CBGStatement.SetRange("Account No.", BankAccountNo);
        CBGStatement.FindFirst;
        ErrorMessages.Trap;

        // [WHEN] Run Post action on CBG Statement
        asserterror CBGStatement.ProcessStatementASGenJournal;

        // [THEN] Error messages window opened with description about invoices are not open for customers "C1" and "C2".
        Assert.ExpectedMessage(InvNo2, ErrorMessages.Description.Value);
        ErrorMessages.Next;
        Assert.ExpectedMessage(InvNo3, ErrorMessages.Description.Value);
        Assert.IsFalse(ErrorMessages.Next, '');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationCustomerInvoiceLineApllies();
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        Iban: Text[50];
        CustomerNo: Code[20];
        CustomerLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Sales]
        // [SCENARIO 315824] CBG Statement Line of a customer's invoice is applied when reconciliation is invoked.
        Initialize;

        // [GIVEN] Customer ledger entry for invoice.
        Iban := LibraryUtility.GenerateGUID;
        CustomerNo := CreateCustomerWithBankAccountIBAN(Iban);
        CustomerLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, CustLedgerEntry."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo,
          CustomerLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of customer's bank account.
        CreateCBGStatementLineAndInfoForCredit(
          CBGStatement, CBGStatementLine, 0, CustomerLedgerEntryAmount,CustomerLedgerEntryAmount, Iban);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find;
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationCustomerCreditMemoLineApllies();
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        Iban: Text[50];
        CustomerNo: Code[20];
        CustomerLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Sales]
        // [SCENARIO 315824] CBG Statement Line of a customer's credit memo is applied when reconciliation is invoked.
        Initialize;

        // [GIVEN] Customer ledger entry for credit memo.
        Iban := LibraryUtility.GenerateGUID;
        CustomerNo := CreateCustomerWithBankAccountIBAN(Iban);
        CustomerLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, CustLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, CustomerNo,
          -CustomerLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of customer's bank account.
        CreateCBGStatementLineAndInfoForCredit(
          CBGStatement, CBGStatementLine, CustomerLedgerEntryAmount, 0, CustomerLedgerEntryAmount, Iban);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find;
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationVendorInvoiceLineApllies();
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        VendorLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Purchase]
        // [SCENARIO 315824] CBG Statement Line of a vendor's invoice is applied when reconciliation is invoked.
        Initialize;

        // [GIVEN] Vendor ledger entry for invoice.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID;
        VendorBankAccount.Modify(true);
        VendorLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, VendorLedgerEntry."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorBankAccount."Vendor No.", -VendorLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of vendor's bank account.
        CreateCBGStatementLineAndInfoForDebit(
          CBGStatement, CBGStatementLine, VendorLedgerEntryAmount, 0, VendorLedgerEntryAmount, VendorBankAccount.IBAN);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find;
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CBGStatementReconciliationVendorCreditMemoLineApllies();
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        VendorLedgerEntryAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [Purchase]
        // [SCENARIO 315824] CBG Statement Line of a vendor's credit memo is applied when reconciliation is invoked.
        Initialize;

        // [GIVEN] Vendor ledger entry for credit memo.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID;
        VendorBankAccount.Modify(true);
        VendorLedgerEntryAmount := LibraryRandom.RandDec(1000, 2);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, VendorLedgerEntry."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          VendorBankAccount."Vendor No.", VendorLedgerEntryAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] CBG Statement Line with Description is IBAN of vendor's bank account.
        CreateCBGStatementLineAndInfoForDebit(
          CBGStatement, CBGStatementLine, VendorLedgerEntryAmount, 0, VendorLedgerEntryAmount, VendorBankAccount.IBAN);

        // [WHEN] Invoke reconciliation at Bank/Giro Journal page.
        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        // [THEN] Reconciliation status of CBG Statement Line is Applied.
        CBGStatementLine.Find;
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchCBGStatementLineAmountSettledIsSetWhenPaymentIdentification()
    var
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
        DummyPaymentHistoryLine: Record "Payment History Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [CBG Statement] [UT]
        // [SCENARIO 328711] "Amount Settled" of CBG Statement line is set during reconciliation process in case Information Type = "Payment Identification".

        // [GIVEN] CBG Statement. CBG Statement Line with Debit amount 150.
        PaymentAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        CreateCBGStatement(CBGStatement);
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", PaymentAmount, 0);

        // [GIVEN] CBG Statement Line Add. Info with Information Type = "Payment Identification" and Description "D1".
        // [GIVEN] Payment History Line with Amount = 150, Identification = "D1".
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo, CBGStatement."Journal Template Name", CBGStatement."No.", CBGStatementLine."Line No.",
          CBGStatementLineAddInfo."Information Type"::"Payment Identification", LibraryUtility.GenerateGUID);
        CreatePaymentHistoryLine(
          CBGStatementLine, CBGStatementLineAddInfo.Description,
          DummyPaymentHistoryLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo);

        // [WHEN] Run MatchCBGStatementLine function of "CBG Statement Reconciliation" codeunit.
        CBGStatementReconciliation.MatchCBGStatementLine(CBGStatement, CBGStatementLine);

        // [THEN] "Amount Settled" of CBG Statement line has value 150.
        CBGStatementLine.TestField("Amount Settled", PaymentAmount);
        CBGStatementLine.TestField("Reconciliation Status", CBGStatementLine."Reconciliation Status"::Applied);
    end;

    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");
        LibraryVariableStorage.Clear;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        GenJournalTemplate.DeleteAll;
        GenJournalBatch.DeleteAll;
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");

        LibraryNLLocalization.CreateFreelyTransferableMaximum('NL', '');
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Cash Bank Giro Journal");
    end;

    local procedure CBGJournalFromJournalBatches(Type: Option; BalAccountType: Option; BalAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // Setup: Create CBG Journal Template then create Journal Batch for it.
        Initialize;
        CreateJournalBatch(GenJournalBatch, Type, BalAccountType, BalAccountNo);
        OpenGeneralJournalBatchesPage(GenJournalBatch, GeneralJournalBatches);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Bal. Account No.");  // Enqueue value for CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Exercise.
        GeneralJournalBatches.EditJournal.Invoke;  // Invokes CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Verify: Verification Done in CashJournalPageHandler/ BankGiroJournalPageHandler.

        // Tear Down: Close General Journal Batches Page.
        GeneralJournalBatches.Close;
    end;

    local procedure DocumentDateOnBankGiroJournal(Date: Date)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        // Setup: Create Bank Journal after creating Bank Journal Template.
        Initialize;
        CreateBankJournalLine(
          CBGStatementLine, CBGStatementLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo);

        // Exercise.
        UpdateDocumentDateOnBankGiroJournal(CBGStatementLine."Statement No.");

        // Verify: Verify correct date updated on Bank Giro Journal Line.
        CBGStatementLine.Find;
        Assert.AreEqual(
          Date, CBGStatementLine.Date, StrSubstNo(AssertFailMsg, CBGStatementLine.FieldCaption(Date), Date, CBGStatementLine.TableCaption));
    end;

    local procedure ApplyAndPostBankGiroJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; BankGiroJournalAccountType: Option; AccountNo: Code[20]; Amount: Decimal; Amount2: Decimal; Debit: Boolean)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankGiroJournal: TestPage "Bank/Giro Journal";
        BankAccountNo: Code[20];
    begin
        // Create Journal Lines according to the options selected and post them.
        CreateGeneralJournal(GenJournalLine, AccountNo, AccountType, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BankAccountNo := OpenBankGiroJournalListPage(CreateBankAccount);
        OpenBankGiroJournalPage(BankGiroJournal, BankGiroJournalAccountType, AccountNo, Amount2, Debit);
        BankGiroJournal.Subform.Next;
        BankGiroJournal.Subform.Previous();

        // Exercise: Apply Vendor Entries and Customer Entries as per the option selected.
        BankGiroJournal.Subform.ApplyEntries.Invoke;  // Open ApplyCustomerEntriesModalPageHandler and ApplyVendorEntriesModalPageHandler.
        BankGiroJournal.Post.Invoke;

        // Verify: Verify Amount on Bank Ledger Entry.
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindFirst;
        if Debit then
            Assert.AreNearlyEqual(
              -Amount2, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
              StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), -Amount2, BankAccountLedgerEntry.TableCaption))
        else
            Assert.AreNearlyEqual(
              Amount2, BankAccountLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision,
              StrSubstNo(AssertFailMsg, BankAccountLedgerEntry.FieldCaption(Amount), Amount2, BankAccountLedgerEntry.TableCaption));
    end;

    local procedure CBGStatementLineApplyEntries(var CBGStatementLine: Record "CBG Statement Line"; AccountNo: Code[20]; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(CBGStatementLine, GenJournalLine, AccountNo);
        GenJournalLine."Applies-to ID" := DocNo;
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
        CBGStatementLine.ReadGenJournalLine(GenJournalLine);
    end;

    local procedure CBGStatementLineApplyToDocNoLookup(var CBGStatementLine: Record "CBG Statement Line"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJournalLine(CBGStatementLine, GenJournalLine, AccountNo);
        GenJournalLine."Lookup Applies-to Doc. No.";
        CBGStatementLine.ReadGenJournalLine(GenJournalLine);
    end;

    local procedure CreateCBGStatementLineAndInfoForDebit(var CBGStatement : Record "CBG Statement"; var CBGStatementLine : Record "CBG Statement Line"; DebitAmount : Decimal; CreditAmount : Decimal; NewDebitAmount : Decimal; Iban : Code[50]);
    var
        CBGStatementLineAddInfo : Record "CBG Statement Line Add. Info.";
    begin
        CreateCBGStatement(CBGStatement);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine,CBGStatement."Journal Template Name",CBGStatement."No.",CBGStatement."Account Type",
          CBGStatement."Account No.",CBGStatementLine."Account Type"::"G/L Account",CBGStatementLine."Account No.",
          DebitAmount,CreditAmount);
        CBGStatementLine.Validate(Debit,NewDebitAmount);
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo,CBGStatement."Journal Template Name",CBGStatement."No.",
        CBGStatementLine."Line No.",CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account",Iban);
        CBGStatementLine.Validate(
          Description,CopyStr(CBGStatementLineAddInfo.Description,1,STRLEN(CBGStatementLine.Description)));
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateCBGStatementLineAndInfoForCredit(var CBGStatement : Record "CBG Statement"; var CBGStatementLine : Record "CBG Statement Line"; DebitAmount : Decimal; CreditAmount : Decimal; NewCreditAmount : Decimal; Iban : Code[50]);
    var
        CBGStatementLineAddInfo : Record "CBG Statement Line Add. Info.";
    begin
        CreateCBGStatement(CBGStatement);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine,CBGStatement."Journal Template Name",CBGStatement."No.",CBGStatement."Account Type",
          CBGStatement."Account No.",CBGStatementLine."Account Type"::"G/L Account",CBGStatementLine."Account No.",
          DebitAmount,CreditAmount);
        CBGStatementLine.Validate(Credit,NewCreditAmount);
        CreateCBGStatementLineAddInfo(
          CBGStatementLineAddInfo,CBGStatement."Journal Template Name",CBGStatement."No.",
        CBGStatementLine."Line No.",CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account",Iban);
        CBGStatementLine.Validate(
          Description,CopyStr(CBGStatementLineAddInfo.Description,1,STRLEN(CBGStatementLine.Description)));
        CBGStatementLine.Modify(true);
    end;

    local procedure CreateGenJournalLine(var CBGStatementLine: Record "CBG Statement Line"; var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    begin
        CBGStatementLine.SetRange("Account No.", AccountNo);
        CBGStatementLine.FindFirst;
        CBGStatementLine.CreateGenJournalLine(GenJournalLine);
    end;

    local procedure TestBankAccountReconciliation(BankAccountType: Option IBAN,"Local Bank Account")
    var
        CustomerBankAccount: Record "Customer Bank Account";
        Customer: Record Customer;
        CBGStatement: Record "CBG Statement";
        CBGStatementLine: Record "CBG Statement Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CBGStatementReconciliation: Codeunit "CBG Statement Reconciliation";
        AccountNumber: Text[30];
    begin
        // Verify CBG Statement Line is recognized and applied with IBAN or 10 character Bank Account No.
        Initialize;
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        case BankAccountType of
            BankAccountType::IBAN:
                begin
                    AccountNumber := 'NL07ABNA0644244461';
                    CustomerBankAccount.IBAN := AccountNumber;
                end;
            BankAccountType::"Local Bank Account":
                begin
                    AccountNumber := 'P00' + Format(LibraryRandom.RandIntInRange(1000000, 9999999));
                    CustomerBankAccount."Bank Account No." := AccountNumber;
                end;
        end;
        CustomerBankAccount.Modify;

        CreateAndPostSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", WorkDate);

        CreateCBGStatement(CBGStatement);
        AddCBGStatementLineAndCBGStatementLineAddInfo(CBGStatement, CBGStatementLine, 0, SalesLine."Amount Including VAT", AccountNumber);

        CBGStatementReconciliation.SetHideMessages(true);
        CBGStatementReconciliation.MatchCBGStatement(CBGStatement);

        CBGStatementLine.Find;

        // Verify
        Assert.AreEqual(
          Format(CBGStatementLine."Reconciliation Status"::Applied),
          Format(CBGStatementLine."Reconciliation Status"),
          StrSubstNo(
            AssertFailMsg,
            Format(CBGStatementLine."Reconciliation Status"),
            Format(CBGStatementLine."Reconciliation Status"::Applied),
            CBGStatementLine.TableCaption))
    end;

    local procedure AddCBGStatementLineAndCBGStatementLineAddInfo(var CBGStatement: Record "CBG Statement"; var CBGStatementLine: Record "CBG Statement Line"; CBGDebit: Decimal; CBGCredit: Decimal; Comment: Text)
    var
        CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info.";
    begin
        AddCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", CBGDebit, CBGCredit);
        AddCBGStatementLineAddInfo(
          CBGStatementLine, CBGStatementLineAddInfo, Comment, CBGStatementLineAddInfo."Information Type"::"Account No. Balancing Account");
    end;

    local procedure ComputePaymentDiscountDate(VendorNo: Code[20]): Date
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        PaymentTerms.Get(Vendor."Payment Terms Code");
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate));
    end;

    local procedure ComputeCustPaymentDiscountDate(CustomerNo: Code[20]): Date
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        PaymentTerms.Get(Customer."Payment Terms Code");
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate));
    end;

    local procedure CreateCBGStatementLineAddInfo(var CBGStatementLineAddInfo: Record 11000006; GenJournalTemplateName: Code[10]; CBGStatementNo: Integer; CBGStatementLineNo: Integer; InformationType: Option; Description: Text[80]);
    begin
        CBGStatementLineAddInfo.Init;
        CBGStatementLineAddInfo.Validate("Journal Template Name", GenJournalTemplateName);
        CBGStatementLineAddInfo.Validate("CBG Statement No.", CBGStatementNo);
        CBGStatementLineAddInfo.Validate("CBG Statement Line No.", CBGStatementLineNo);
        CBGStatementLineAddInfo.Validate("Information Type", InformationType);
        CBGStatementLineAddInfo.Validate(Description, Description);
        CBGStatementLineAddInfo.Insert;
    end;

    local procedure CreateCBGStatementLineWithApplyToDoc(CBGStatement: Record "CBG Statement"; AccountType: Option; AccountNo: Code[20]; ApplyToDocType: Option; ApplyToDocNo: Code[20]; PayAmount: Decimal)
    var
        CBGStatementLine: Record "CBG Statement Line";
        RecRef: RecordRef;
    begin
        with CBGStatementLine do begin
            Init;
            "Journal Template Name" := CBGStatement."Journal Template Name";
            "No." := CBGStatement."No.";
            RecRef.GetTable(CBGStatementLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));
            Date := WorkDate;
            "Account Type" := AccountType;
            "Account No." := AccountNo;
            Description := "Account No.";
            "Applies-to Doc. Type" := ApplyToDocType;
            "Applies-to Doc. No." := ApplyToDocNo;
            Validate(Amount, PayAmount);
            Insert;
        end;
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Option; CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountType: Option; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        if AccountType = GenJournalLine."Account Type"::Employee then
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              AccountType, AccountNo, Amount)
        else
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
              AccountType, AccountNo, Amount);
    end;

    local procedure CreateAndPostPurchInvWithVendAndPurchaserDim(VendNo: Code[20]): Integer
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseLine."Dimension Set ID");
    end;

    local procedure CreateAndPostSalesInvWithVendAndPurchaserDim(CustNo: Code[20]): Integer
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Dimension Set ID");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; Quantity: Decimal; DirectUnitCost: Decimal; VendorNo: Code[20]; PostingDate: Date): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity); // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);  // Using random value for Unit Cost.
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange("Document No.", LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.FindFirst;
        CustLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateAndPostEmployeeExpense(Amount: Decimal; EmployeeNo: Code[20]; GLAccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::Employee, EmployeeNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostVendPaymentAppliedToEntry(VendorNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(
          VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.",
          -VendorLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", VendorLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(VendorLedgerEntry."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostCustPaymentAppliedToEntry(CustomerNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, CustomerNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          -CustLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(CustLedgerEntry."Document No.");
    end;

    [Scope('OnPrem')]
    procedure CreatePostEmployeePaymentAppliedToEntry(EmployeeNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::" ", EmployeeNo);
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Employee, EmployeeLedgerEntry."Employee No.",
          -EmployeeLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.Validate("Applies-to Doc. No.", EmployeeLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(EmployeeLedgerEntry."Document No.");
    end;

    local procedure CreateAndSetupGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; TemplateName: Code[10])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, TemplateName);
        GenJournalBatch.SetupNewBatch;
    end;

    local procedure CreateAndUpdateExportProtocol(): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        LibraryNLLocalization.CreateExportProtocol(ExportProtocol);
        ExportProtocol.Validate("Check ID", CODEUNIT::"Check SEPA ISO20022");
        ExportProtocol.Validate("Export ID", REPORT::"Export SEPA ISO20022");
        ExportProtocol.Validate("Docket ID", REPORT::"Export BTL91-RABO");
        ExportProtocol.Validate("Default File Names", StrSubstNo(FilePathTxt, LibraryUtility.GenerateGUID));  // Generate random file name.
        ExportProtocol.Modify(true);
        exit(ExportProtocol.Code);
    end;

    local procedure CreateAndUpdateVendTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor);
        TransactionMode.Validate(Order, TransactionMode.Order::Debit);
        TransactionMode.Modify(true);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure CreateAndUpdateCustTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer);
        TransactionMode.Validate(Order, TransactionMode.Order::Credit);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure CreateAndUpdateEmployeeTransactionMode(var TransactionMode: Record "Transaction Mode"; ExportProtocol: Code[20]; OurBank: Code[20])
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, TransactionMode."Account Type"::Employee);
        TransactionMode.Validate(Order, TransactionMode.Order::Debit);
        UpdateTransactionMode(TransactionMode, OurBank, ExportProtocol);
    end;

    local procedure UpdateTransactionMode(var TransactionMode: Record "Transaction Mode"; OurBank: Code[20]; ExportProtocol: Code[20])
    var
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        TransactionMode.Validate("Our Bank", OurBank);
        TransactionMode.Validate("Export Protocol", ExportProtocol);
        TransactionMode.Validate("Identification No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        TransactionMode.Validate("Run No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", CreateGLAccountUsingDirectPostingFalse);
        TransactionMode.Validate("Posting No. Series", LibraryERM.CreateNoSeriesCode);
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Modify(true);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndPostGenJournalLineForBankAccountBalance() BalAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        BalAccountNo := CreateBankAccountWithDetails;
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournal(
          GenJournalLine, LibraryERM.CreateGLAccountNo, GenJournalLine."Account Type"::"G/L Account",
          -LibraryRandom.RandDecInDecimalRange(10000, 50000, 1));  // Using Random for Amount, Using Large Value for Credit Limit.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccountWithDetails(): Code[20]
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Bank Account No.", FindBankAccountNo);
        BankAccount.Validate(IBAN, CompanyInformation.IBAN);
        BankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        BankAccount.Validate("Min. Balance", -LibraryRandom.RandDecInRange(500, 1000, 2));  // Using random value greater than 500 for Min. Balance. Value is important for test.
        BankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder Name", BankAccount.Name);  // Taking Bank Account Name as Account Holder Name. Value is not important for test.
        BankAccount.Validate("Account Holder Address", BankAccount.Name);  // Taking Bank Account Name as Account Holder Address. Value is not important for test.
        BankAccount.Validate("Account Holder Post Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder City", CompanyInformation."Country/Region Code");
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankJournalLine(var CBGStatementLine: Record "CBG Statement Line"; AccountType: Option; AccountNo: Code[20])
    var
        CBGStatement: Record "CBG Statement";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount);
        LibraryNLLocalization.CreateCBGStatement(CBGStatement, GenJournalTemplate.Name);
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, GenJournalTemplate.Name, CBGStatement."No.", CBGStatement."Account Type", CBGStatement."Account No.",
          AccountType, AccountNo, 0, 0);  // O for Debit and Credit Amount.
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", '');
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithBankAccountIBAN(AccountNumber: Code[50]) CustomerNo: Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerNo := CreateCustomer;
        FindCustomerBankAccount(CustomerBankAccount, CustomerNo);
        UpdateCustomerBankAccountIBAN(CustomerBankAccount, AccountNumber);
        exit(CustomerNo);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; BankAccountNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        CustomerBankAccount.Validate("Account Holder City", CompanyInformation.City);
        CustomerBankAccount.Validate("Acc. Hold. Country/Region Code", CompanyInformation."Country/Region Code");
        CustomerBankAccount.Validate("Bank Account No.", BankAccountNo);
        CustomerBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        CustomerBankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        CustomerBankAccount.Modify(true);
    end;

    local procedure CreateCustomerWithPmtDisc(var Customer: Record Customer)
    var
        PmtTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Customer.Validate("Payment Terms Code", PmtTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerBankAccountAndUpdateCustomer(var CustomerBankAccount: Record "Customer Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        TransactionMode: Record "Transaction Mode";
        Customer: Record Customer;
    begin
        CreateAndUpdateCustTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, CalcPmtDiscOnCrMemos);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", TransactionMode."Our Bank");
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
    end;

    local procedure CreateSalesPersonPurchaserWithGlobalDim2Code(GlobalDim2Code: Code[20]): Code[10]
    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateSalesperson(SalesPersonPurchaser);
        SalesPersonPurchaser.Validate("Global Dimension 2 Code", GlobalDim2Code);
        SalesPersonPurchaser.Modify(true);
        exit(SalesPersonPurchaser.Code);
    end;

    local procedure CreateGLAccountUsingDirectPostingFalse(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Validate("Direct Posting", false);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithPostingSetup(var GLAccount: Record "G/L Account"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        exit(VATPostingSetup."VAT %");
    end;

    local procedure CreateGLAccountWithEmptyGenPostingType(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccountWithPostingSetup(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::" ");
        GLAccount.Modify;
        exit(GLAccount."No.");
    end;

    local procedure CreateJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Option; BalAccountType: Option; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(GenJournalTemplate, Type, BalAccountType, AccountNo);
        CreateAndSetupGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateJournalTemplate(var GenJournalTemplate: Record "Gen. Journal Template"; Type: Option; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Validate("Bal. Account Type", BalAccountType);
        GenJournalTemplate.Validate("Bal. Account No.", BalAccountNo);
        GenJournalTemplate.Validate("No. Series", LibraryERM.CreateNoSeriesCode);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        VendorBankAccount.Validate("Account Holder City", CompanyInformation.City);
        VendorBankAccount.Validate("Acc. Hold. Country/Region Code", CompanyInformation."Country/Region Code");
        VendorBankAccount.Validate("Bank Account No.", BankAccountNo);
        VendorBankAccount.Validate(IBAN, CompanyInformation.IBAN);
        VendorBankAccount.Validate("SWIFT Code", SwiftCodeTxt);  // fixed format.
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateVendorBankAccountAndUpdateVendor(var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PaymentTerms: Record "Payment Terms";
        TransactionMode: Record "Transaction Mode";
        Vendor: Record Vendor;
    begin
        CreateAndUpdateVendTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, CalcPmtDiscOnCrMemos);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TransactionMode."Our Bank");
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateVendWithBankAccAndDim(var VendorBankAccount: Record "Vendor Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        Vendor: Record Vendor;
        DimValue: Record "Dimension Value";
    begin
        CreateAndUpdateVendTransactionMode(TransactionMode, ExportProtocol, OurBank);
        GLSetup.Get;
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 1 Code");
        Vendor.Validate("Global Dimension 1 Code", DimValue.Code);
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", TransactionMode."Our Bank");
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 2 Code");
        Vendor.Validate("Purchaser Code", CreateSalesPersonPurchaserWithGlobalDim2Code(DimValue.Code));
        Vendor.Modify(true);
    end;

    local procedure CreateCustWithBankAccAndDim(var CustomerBankAccount: Record "Customer Bank Account"; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
        Customer: Record Customer;
        DimValue: Record "Dimension Value";
    begin
        CreateAndUpdateCustTransactionMode(TransactionMode, ExportProtocol, OurBank);
        GLSetup.Get;
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 1 Code");
        Customer.Validate("Global Dimension 1 Code", DimValue.Code);
        CreateCustomerBankAccount(CustomerBankAccount, Customer."No.", TransactionMode."Our Bank");
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        LibraryDimension.FindDimensionValue(DimValue, GLSetup."Global Dimension 2 Code");
        Customer.Validate("Salesperson Code", CreateSalesPersonPurchaserWithGlobalDim2Code(DimValue.Code));
        Customer.Modify(true);
    end;

    local procedure CreateAndUpdateCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; SalesLine: Record "Sales Line"; AppliesToDocNo: Code[20])
    begin
        CreateBankJournalLine(CBGStatementLine, CBGStatementLine."Account Type"::Customer, SalesLine."Sell-to Customer No.");
        with CBGStatementLine do begin
            Validate("Applies-to Doc. Type", SalesLine."Document Type");
            Validate("Applies-to Doc. No.", AppliesToDocNo);
            Validate(Credit, SalesLine.Amount);
            Modify(true);
        end;
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

    local procedure CreateEmployeeWithTransactionMode(ExportProtocol: Code[20]; OurBank: Code[20]): Code[20]
    var
        TransactionMode: Record "Transaction Mode";
        Employee: Record Employee;
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
    begin
        CreateAndUpdateEmployeeTransactionMode(TransactionMode, ExportProtocol, OurBank);
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        LibraryERM.CreatePostCode(PostCode);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("SEPA Allowed", true);
        CountryRegion.Modify(true);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CountryRegion.Code, '');
        Employee.Validate("Transaction Mode Code", TransactionMode.Code);
        Employee.Validate("Post Code", PostCode.Code);
        Employee.Validate("Country/Region Code", CountryRegion.Code);
        Employee.Modify(true);
        exit(Employee."No.");
    end;

    local procedure FillValuesOnCashJournalLine(var CashJournal: TestPage "Cash Journal"; AccountNo: Code[20])
    begin
        CashJournal.Subform."Account Type".SetValue(CashJournal.Subform."Account Type".GetOption(1));  // Using 1 for Option Value: G/L Account.
        CashJournal.Subform."Account No.".SetValue(AccountNo);
    end;

    local procedure FindBankAccountNo(): Text[30]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst;
        exit(BankAccount."Bank Account No.");
    end;

    local procedure FindCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20])
    begin
        CustomerBankAccount.SetRange("Customer No.", CustomerNo);
        CustomerBankAccount.FindFirst;
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Option; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.FindFirst;
        VendorLedgerEntry.CalcFields("Original Amount");
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Option; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst;
    end;

    local procedure FindEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; DocumentType: Option; EmployeeNo: Code[20])
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange("Document Type", DocumentType);
        EmployeeLedgerEntry.FindFirst;
    end;

    local procedure GetEntriesOnTelebankProposal(var TelebankProposal: TestPage "Telebank Proposal"; BankAccFilter: Code[30])
    begin
        TelebankProposal.OpenEdit;
        TelebankProposal.BankAccFilter.SetValue(BankAccFilter);
        TelebankProposal.GetEntries.Invoke;
    end;

    local procedure GetVendorAccountType(): Integer
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        exit(DummyGenJournalLine."Account Type"::Vendor)
    end;

    local procedure GetCustomerAccountType(): Integer
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
    begin
        exit(DummyGenJournalLine."Account Type"::Customer)
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", '');  // To avoid Document No. mismatch.
        GenJournalBatch.Modify(true);
    end;

    local procedure ExportPaymentTelebank(AccountNo: Code[20]; BankAccountNo: Code[30]; CurrencyDate: Date; PaymentDiscountDate: Date; ExportProtocolCode: Code[20])
    begin
        Commit;
        LibraryVariableStorage.Enqueue(AccountNo);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(CurrencyDate);
        LibraryVariableStorage.Enqueue(PaymentDiscountDate);  // Enqueue for GetProposalEntriesRequestPageHandler.
        HandleTelebankExport(AccountNo, BankAccountNo, ExportProtocolCode);
    end;

    local procedure ExportPaymentTelebankForSeveralAccounts(AccountNo: array[3] of Code[20]; BankAccountNo: Code[30]; CurrencyDate: Date; PaymentDiscountDate: Date; ExportProtocolCode: Code[20])
    var
        AccountNoFilter: Text;
    begin
        Commit;
        AccountNoFilter := StrSubstNo('%1..%2', AccountNo[1], AccountNo[3]);
        LibraryVariableStorage.Enqueue(AccountNoFilter);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(CurrencyDate);
        LibraryVariableStorage.Enqueue(PaymentDiscountDate);  // Enqueue for GetProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(ProposalLinesProcessedMsg);
        HandleTelebankExportForSeveralAccounts(AccountNo, BankAccountNo, ExportProtocolCode);
    end;

    local procedure InitCustomerForExport(var CustomerBankAccount: Record "Customer Bank Account"; var ExportProtocolCode: Code[20]; var BalAccountNo: Code[20])
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        BalAccountNo := CreateBankAccountWithDetails;
        CreateCustomerBankAccountAndUpdateCustomer(CustomerBankAccount, ExportProtocolCode, BalAccountNo, false);
    end;

    local procedure InitVendorForExport(var VendorBankAccount: Record "Vendor Bank Account"; var ExportProtocolCode: Code[20]; var BalAccountNo: Code[20])
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        BalAccountNo := CreateBankAccountWithDetails;
        CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocolCode, BalAccountNo, false);
    end;

    local procedure ProcessAndExportPaymentTelebank(var VendorBankAccount: Record "Vendor Bank Account"; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
        PaymentDiscountDate: Date;
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        PostPurchaseDocumentWithVendorBankAccount(VendorBankAccount, true, ExportProtocolCode, BankAccountNo, false);
        PaymentDiscountDate := ComputePaymentDiscountDate(VendorBankAccount."Vendor No.");
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", WorkDate, PaymentDiscountDate, ExportProtocolCode);
    end;

    local procedure ProcessAndExportPurchPaymentTelebankWithDim(var VendorBankAccount: Record "Vendor Bank Account"; var DimSetID: Integer; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        UpdateSEPAAllowedOnCountryRegion(true);
        CreateVendWithBankAccAndDim(VendorBankAccount, ExportProtocolCode, BankAccountNo);
        DimSetID := CreateAndPostPurchInvWithVendAndPurchaserDim(VendorBankAccount."Vendor No.");
        ExportPaymentTelebank(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", WorkDate, WorkDate, ExportProtocolCode);
    end;

    local procedure ProcessAndExportSalesPaymentTelebankWithDim(var CustomerBankAccount: Record "Customer Bank Account"; var DimSetID: Integer; BankAccountNo: Code[20])
    var
        ExportProtocolCode: Code[20];
    begin
        ExportProtocolCode := CreateAndUpdateExportProtocol;
        UpdateSEPAAllowedOnCountryRegion(true);
        CreateCustWithBankAccAndDim(CustomerBankAccount, ExportProtocolCode, BankAccountNo);
        DimSetID := CreateAndPostSalesInvWithVendAndPurchaserDim(CustomerBankAccount."Customer No.");
        Commit;
        LibraryVariableStorage.Enqueue(CustomerBankAccount."Customer No.");  // Enqueue for GetSalesProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate);  // Enqueue for GetSalesProposalEntriesRequestPageHandler.
        LibraryVariableStorage.Enqueue(WorkDate);
        HandleTelebankExport(CustomerBankAccount."Customer No.", BankAccountNo, ExportProtocolCode);
    end;

    local procedure HandleTelebankExportForSeveralAccounts(AccountNo: array[3] of Code[20]; BankAccountCode: Code[30]; ExportProtocolCode: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
        i: Integer;
    begin
        GetEntriesOnTelebankProposal(TelebankProposal, BankAccountCode);
        for i := 1 to ArrayLen(AccountNo) do
            UpdateProposalLine(
              ProposalLine, BankAccountCode, AccountNo[i],
              ProposalLine."Nature of the Payment"::Goods);
        TelebankProposal.Process.Invoke;
        OpenAndExportPaymentHistoryCard(ExportProtocolCode, BankAccountCode);
    end;

    local procedure HandleTelebankExport(AccountNo: Code[20]; BankAccountCode: Code[30]; ExportProtocolCode: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        GetEntriesOnTelebankProposal(TelebankProposal, BankAccountCode);
        UpdateProposalLine(
          ProposalLine, BankAccountCode, AccountNo,
          ProposalLine."Nature of the Payment"::Goods);
        TelebankProposal.Process.Invoke;
        OpenAndExportPaymentHistoryCard(ExportProtocolCode, BankAccountCode);
    end;

    local procedure OpenBankGiroJournalListPage(BankAccount: Code[20]): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankGiroJournalList: TestPage "Bank/Giro Journal List";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", BankAccount);
        BankGiroJournalList.OpenEdit;
        BankGiroJournalList.New;
        BankGiroJournalList."Journal Template Name".SetValue(GenJournalTemplate.Name);
        BankGiroJournalList.OK.Invoke;
        exit(GenJournalTemplate."Bal. Account No.");
    end;

    local procedure OpenBankGiroJournalPage(var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; Debit: Boolean)
    begin
        BankGiroJournal.OpenEdit;
        BankGiroJournal.Subform."Account Type".SetValue(AccountType);
        BankGiroJournal.Subform."Account No.".SetValue(AccountNo);
        if Debit then // TODO: Should we do this?
            BankGiroJournal.Subform.Debit.SetValue(Amount)
        else
            BankGiroJournal.Subform.Credit.SetValue(Amount);
    end;

    local procedure OpenBankGiroJournalPageLookupAppliesTo(var CBGStatement: Record "CBG Statement"; var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountType: Option; AccountNo: Code[20]; Amount: Decimal)
    begin
        BankGiroJournal.OpenEdit;
        BankGiroJournal.GotoRecord(CBGStatement);
        BankGiroJournal.Subform."Account Type".SetValue(
          AccountType);
        BankGiroJournal.Subform."Account No.".SetValue(AccountNo);
        BankGiroJournal.Subform."Applies-to Doc. No.".Lookup;
        BankGiroJournal.Subform.Credit.SetValue(0);
        BankGiroJournal.Subform.Next;
        BankGiroJournal.Subform.Previous();
        BankGiroJournal.Subform.Credit.SetValue(Amount);
        BankGiroJournal.OK.Invoke;
    end;

    local procedure OpenBankGiroJournalAndInvokeInsertPaymentHistory(var BankGiroJournal: TestPage "Bank/Giro Journal"; AccountNo: Code[30]; DocumentDate: Date)
    begin
        BankGiroJournal.OpenEdit;
        BankGiroJournal.FILTER.SetFilter("Account No.", AccountNo);
        BankGiroJournal."Document Date".SetValue(DocumentDate);
        BankGiroJournal.InsertPaymentHistory.Invoke;
    end;

    local procedure OpenCashJournalListPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        CashJournalList: TestPage "Cash Journal List";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Cash,
          GenJournalTemplate."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo);
        CashJournalList.OpenEdit;
        CashJournalList.New;
        CashJournalList."Journal Template Name".SetValue(GenJournalTemplate.Name);
        CashJournalList.OK.Invoke;
    end;

    local procedure OpenCashJournalPage(var CashJournal: TestPage "Cash Journal"; AccountNo: Code[20]): Code[20]
    begin
        CashJournal.OpenEdit;
        FillValuesOnCashJournalLine(CashJournal, AccountNo);
        exit(CashJournal.Subform."Document No.".Value);
    end;

    local procedure OpenAndExportPaymentHistoryCard(ExportProtocol: Code[20]; OurBank: Code[30])
    var
        PaymentHistoryCard: TestPage "Payment History Card";
    begin
        PaymentHistoryCard.OpenEdit;
        PaymentHistoryCard.FILTER.SetFilter("Our Bank", OurBank);
        PaymentHistoryCard.FILTER.SetFilter("Export Protocol", ExportProtocol);
        Commit;  // Commit Required.
        PaymentHistoryCard.Export.Invoke;
        PaymentHistoryCard.Close;
    end;

    local procedure OpenGeneralJournalBatchesPage(GenJournalBatch: Record "Gen. Journal Batch"; var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OpenEdit;
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.FILTER.SetFilter(Name, GenJournalBatch.Name);
    end;

    local procedure PostPurchaseDocumentWithVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; SEPAAllowed: Boolean; ExportProtocol: Code[20]; OurBank: Code[20]; CalcPmtDiscOnCrMemos: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        UpdateSEPAAllowedOnCountryRegion(SEPAAllowed);
        CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocol, OurBank, CalcPmtDiscOnCrMemos);
        Quantity := LibraryRandom.RandDecInRange(10, 100, 2);  // Take Random Quantity.
        DirectUnitCost := LibraryRandom.RandDec(100, 2);  // Take Random Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, Quantity, DirectUnitCost, VendorBankAccount."Vendor No.", WorkDate);
        CreateAndPostPurchaseDocument(
          PurchaseLine,
          PurchaseHeader."Document Type"::"Credit Memo",
          Quantity / 2,
          DirectUnitCost,
          VendorBankAccount."Vendor No.",
          WorkDate);
    end;

    local procedure PostPurchaseInvoicesWithVendorBankAccount(var VendorNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(VendorNo) do begin
            CreateVendorBankAccountAndUpdateVendor(VendorBankAccount, ExportProtocol, OurBank, false);
            VendorNo[i] := VendorBankAccount."Vendor No.";
            CreateAndPostPurchaseDocument(
              PurchaseLine, PurchaseHeader."Document Type"::Invoice,
              LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDec(100, 2), VendorNo[i], WorkDate);
        end;
    end;

    local procedure PostSalesInvoicesWithCustomerBankAccount(var CustomerNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        CustomerBankAccount: Record "Customer Bank Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(CustomerNo) do begin
            CreateCustomerBankAccountAndUpdateCustomer(CustomerBankAccount, ExportProtocol, OurBank, true);
            CustomerNo[i] := CustomerBankAccount."Customer No.";
            CreateAndPostSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo[i], WorkDate);
        end;
    end;

    local procedure PostEmployeeInvoicesWithBankAccount(var EmployeeNo: array[3] of Code[20]; ExportProtocol: Code[20]; OurBank: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        UpdateSEPAAllowedOnCountryRegion(true);
        for i := 1 to ArrayLen(EmployeeNo) do begin
            EmployeeNo[i] := CreateEmployeeWithTransactionMode(ExportProtocol, OurBank);
            CreateAndPostEmployeeExpense(
              LibraryRandom.RandDecInRange(1000, 2000, 2), EmployeeNo[i], LibraryERM.CreateGLAccountNo, GenJournalLine);
        end;
    end;

    local procedure ScenarioOfPmtToleranceGracePeriod(var BankGiroJournal: TestPage "Bank/Giro Journal"; var InvoiceNo: Code[20]; AccountType: Integer; AccountNo: Code[20]; BankAccountNo: Code[30]; Amount: Decimal; PmtDiscDate: Date; BalAccountNo: Code[20]; ExportProtocolCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // General Ledger Setup for Pmt. Disc. Tolerance with Grace Period
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Discount Accounts");
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(2, 5)));
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);

        // Posted Invoice
        CreateGeneralJournal(GenJournalLine, AccountNo, AccountType, Amount);
        GenJournalLine.Validate("Due Date", PmtDiscDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        InvoiceNo := GenJournalLine."Document No.";

        // Bank Giro Journal with suggested Payment History Lines for the Invoce
        ExportPaymentTelebank(
          AccountNo, BankAccountNo, GenJournalLine."Due Date", GenJournalLine."Due Date", ExportProtocolCode);
        OpenBankGiroJournalListPage(BalAccountNo);
        OpenBankGiroJournalAndInvokeInsertPaymentHistory(
          BankGiroJournal, BalAccountNo, CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", GenJournalLine."Due Date"));
    end;

    local procedure UpdateCustomerBankAccountIBAN(CustomerBankAccount: Record "Customer Bank Account"; IBANNumber: Code[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        CustomerBankAccount.Validate(IBAN, IBANNumber);
        CustomerBankAccount.Modify(true);
    end;

    local procedure UpdateDocumentDateOnBankGiroJournal(AccountNo: Code[20])
    var
        BankGiroJournal: TestPage "Bank/Giro Journal";
    begin
        BankGiroJournal.OpenEdit;
        BankGiroJournal.FILTER.SetFilter("Account No.", AccountNo);
        BankGiroJournal."Document Date".SetValue(CalcDate('<1D>', WorkDate));  // Update Date greater than Workdate.
        BankGiroJournal.Close;
    end;

    local procedure UpdateProposalLine(var ProposalLine: Record "Proposal Line"; OurBankNo: Code[30]; AccountNo: Code[20]; NatureOfThePayment: Option)
    begin
        ProposalLine.SetRange("Our Bank No.", OurBankNo);
        ProposalLine.SetRange("Account No.", AccountNo);
        ProposalLine.FindFirst;
        ProposalLine.Validate("Nature of the Payment", NatureOfThePayment);
        ProposalLine.Modify(true);
    end;

    local procedure UpdateSEPAAllowedOnCountryRegion(SEPAAllowed: Boolean)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get;
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("SEPA Allowed", SEPAAllowed);
        CountryRegion.Modify(true);
    end;

    local procedure EnableUpdateOnPosting()
    var
        AnalysisView: Record "Analysis View";
    begin
        with AnalysisView do begin
            SetRange("Account Source", "Account Source"::"G/L Account");
            FindFirst;
            "Update on Posting" := true;
            Modify;
        end;
    end;

    local procedure CreatePaymentHistoryLine(CBGStatementLine: Record "CBG Statement Line"; Identification: Code[80]; AccountType: Option; AccountNo: Code[20])
    var
        PaymentHistoryLine: Record "Payment History Line";
    begin
        PaymentHistoryLine.Init;
        PaymentHistoryLine."Our Bank" := CBGStatementLine."Statement No.";
        PaymentHistoryLine.Amount := CBGStatementLine.Amount;
        PaymentHistoryLine."Account Type" := AccountType;
        PaymentHistoryLine."Account No." := AccountNo;
        PaymentHistoryLine.Status := PaymentHistoryLine.Status::Transmitted;
        PaymentHistoryLine.Identification := Identification;
        PaymentHistoryLine.Insert;
    end;

    local procedure VerifyOriginalPaymentAmountAfterDiscount(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CreditMemoAmount: Decimal;
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, VendorNo);
        InvoiceAmount := VendorLedgerEntry."Original Amount" - VendorLedgerEntry."Original Pmt. Disc. Possible";
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::"Credit Memo", VendorNo);
        CreditMemoAmount := VendorLedgerEntry."Original Amount";
        PaymentAmount := InvoiceAmount + CreditMemoAmount;
        FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, VendorNo);
        Assert.AreNearlyEqual(
          -PaymentAmount, VendorLedgerEntry."Original Amount", LibraryERM.GetAmountRoundingPrecision,
          StrSubstNo(AssertFailMsg, VendorLedgerEntry.FieldCaption("Original Amount"), PaymentAmount, VendorLedgerEntry.TableCaption));
    end;

    local procedure VerifyNumberOfRowsOnCBGReport(NotAppliedDocCount: Integer; AppliedDocCount: Integer)
    begin
        LibraryReportDataset.LoadDataSetFile;
        // For each applied document dataset will contain 3 rows
        Assert.AreEqual(
          AppliedDocCount * 3,
          LibraryReportDataset.RowCount,
          StrSubstNo(WrongRowNumberErr, NotAppliedDocCount, AppliedDocCount));
    end;

    local procedure VerifyCustInvoiceRemainingAmount(CustNo: Code[20]; DocNo: Code[20]; ExpAmt: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        with CustLedgEntry do begin
            SetRange("Customer No.", CustNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("Document No.", DocNo);
            FindFirst;
            CalcFields("Remaining Amt. (LCY)");
            Assert.AreEqual(ExpAmt, "Remaining Amt. (LCY)", '');
        end;
    end;

    local procedure SetMaxPaymentToleranceAmt(NewMaxPaymentToleranceAmt: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get;
            Validate("Max. Payment Tolerance Amount", NewMaxPaymentToleranceAmt);
            Modify(true);
        end;
    end;

    local procedure VerifyVLEPaymentDisc(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Option; VendLedgerEntryIsOpen: Boolean; RemPaymentDiscPossible: Decimal; RemainingAmount: Decimal)
    begin
        with VendorLedgerEntry do begin
            SetRange("Document Type", DocType);
            FindFirst;
            Assert.AreEqual(VendLedgerEntryIsOpen, Open, FieldCaption(Open));
            Assert.AreEqual(
              RemPaymentDiscPossible, "Remaining Pmt. Disc. Possible",
              FieldCaption("Remaining Pmt. Disc. Possible"));
            CalcFields("Remaining Amount");
            Assert.AreEqual(RemainingAmount, "Remaining Amount", FieldCaption("Remaining Amount"));
        end;
    end;

    local procedure VerifyCLEPaymentDisc(var CustLedgerEntry: Record "Cust. Ledger Entry"; IsOpen: Boolean; RemPaymentDiscPossible: Decimal; RemainingAmount: Decimal)
    begin
        with CustLedgerEntry do begin
            TestField(Open, IsOpen);
            TestField("Remaining Pmt. Disc. Possible", RemPaymentDiscPossible);
            CalcFields("Remaining Amount");
            TestField("Remaining Amount", RemainingAmount);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDVendorModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke;
        ApplyVendorEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyToIDEmployeeModalPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke;
        ApplyEmployeeEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesFromLookupModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.First;
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesModalPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankGiroJournalPageHandler(var BankGiroJournal: TestPage "Bank/Giro Journal")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        BankGiroJournal."Account No.".AssertEquals(AccountNo);
        BankGiroJournal.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CashJournalPageHandler(var CashJournal: TestPage "Cash Journal")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        CashJournal."Account No.".AssertEquals(AccountNo);
        CashJournal.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentHistoryListModalPageHandler(var PaymentHistoryList: TestPage "Payment History List")
    begin
        PaymentHistoryList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        PmtDiscountDate: Variant;
        VendorNo: Variant;
        CurrencyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(CurrencyDate);
        LibraryVariableStorage.Dequeue(PmtDiscountDate);
        GetProposalEntries.CurrencyDate.SetValue(CurrencyDate);
        GetProposalEntries.PmtDiscountDate.SetValue(PmtDiscountDate);
        GetProposalEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        GetProposalEntries.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        PmtDiscountDate: Variant;
        CustomerNo: Variant;
        CurrencyDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        LibraryVariableStorage.Dequeue(CurrencyDate);
        LibraryVariableStorage.Dequeue(PmtDiscountDate);
        GetProposalEntries.CurrencyDate.SetValue(WorkDate);
        GetProposalEntries.PmtDiscountDate.SetValue(PmtDiscountDate);
        GetProposalEntries."Cust. Ledger Entry".SetFilter("Customer No.", CustomerNo);
        GetProposalEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscToleranceWarningHandler(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    begin
        PaymentDiscToleranceWarning.Posting.SetValue(PaymentDiscToleranceWarning.Posting.GetOption(1));
        PaymentDiscToleranceWarning.Yes.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if (StrPos(Question, OpeningBalanceQst) > 0) or (StrPos(Question, PostingQst) > 0) or (StrPos(Question, DateQst) > 0) then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure NoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if StrPos(Question, DateQst) > 0 then
            Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VerifyMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CBGPostingTestRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    var
        No: Variant;
        ShowAppliedEntries: Variant;
        TemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(ShowAppliedEntries);

        CBGPostingTest."Show Applied Entries".SetValue(ShowAppliedEntries);
        CBGPostingTest."CBG Statement".SetFilter("Journal Template Name", Format(TemplateName));
        CBGPostingTest."CBG Statement".SetFilter("No.", Format(No));
        CBGPostingTest.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BankGiroPageHandler(var BankGiroPage: TestPage "Bank/Giro Journal")
    begin
        BankGiroPage.Post.Invoke;
    end;

    local procedure CreateCBGStatement(var CBGStatement: Record "CBG Statement")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateJournalTemplate(
          GenJournalTemplate, GenJournalTemplate.Type::Bank, GenJournalTemplate."Bal. Account Type"::"Bank Account", CreateBankAccount);
        LibraryNLLocalization.CreateCBGStatement(CBGStatement, GenJournalTemplate.Name);
    end;

    local procedure CreateCBGLine(var CBGStatementLine: Record "CBG Statement Line"; var CBGStatement: Record "CBG Statement"; AppliesToDocNo: Code[20]; AccountType: Option; AccountNo: Code[20]; DocumentType: Option; AmountIncludingVAT: Decimal)
    begin
        LibraryNLLocalization.CreateCBGStatementLine(
          CBGStatementLine, CBGStatement."Journal Template Name", CBGStatement."No.",
          CBGStatement."Account Type", CBGStatement."Account No.", AccountType, AccountNo, 0, 0);  // O for Debit and Credit Amount.
        with CBGStatementLine do begin
            Validate("Applies-to Doc. Type", DocumentType);
            Validate("Applies-to Doc. No.", AppliesToDocNo);
            Validate(Credit, AmountIncludingVAT);
            Modify(true);
        end;
    end;

    local procedure AddCBGStatementLineAddInfo(CBGStatementLine: Record "CBG Statement Line"; var CBGStatementLineAddInfo: Record "CBG Statement Line Add. Info."; Comment: Text; Type: Option)
    begin
        with CBGStatementLineAddInfo do begin
            "Journal Template Name" := CBGStatementLine."Journal Template Name";
            "CBG Statement No." := CBGStatementLine."No.";
            "CBG Statement Line No." := CBGStatementLine."Line No.";
            "Line No." := "Line No." + 10000;
            Init;
            Description := Comment;
            "Information Type" := Type;
            Insert(true);
        end;

        CBGStatementLine.Description := CopyStr(Comment, 1, MaxStrLen(CBGStatementLine.Description));
        CBGStatementLine.Modify(true);
    end;

    local procedure AddCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; JournalTemplateName: Code[10]; No: Integer; StatementType: Option; StatementNo: Code[20]; CBGDebit: Decimal; CBGCredit: Decimal)
    var
        RecRef: RecordRef;
    begin
        // This function is used to simulate Import Statement of RABO MUT.ASC protocol file
        with CBGStatementLine do begin
            Init;
            Validate("Journal Template Name", JournalTemplateName);
            Validate("No.", No);
            RecRef.GetTable(CBGStatementLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Insert(true);
            Validate("Statement Type", StatementType);
            Validate("Statement No.", StatementNo);
            Validate(Date, WorkDate);
            Validate(Amount, CBGDebit - CBGCredit);
            Modify(true);
        end;
    end;

    local procedure VerifyDimSetIDOnCBGStatementLine(AccountType: Option; AccountNo: Code[20]; DimSetID: Integer)
    var
        CBGStatementLine: Record "CBG Statement Line";
    begin
        CBGStatementLine.SetRange("Account Type", AccountType);
        CBGStatementLine.SetRange("Account No.", AccountNo);
        CBGStatementLine.FindFirst;
        Assert.AreEqual(
          DimSetID, CBGStatementLine."Dimension Set ID", CBGStatementLine.FieldCaption("Dimension Set ID"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VerifyBatchOnCBGPostingTestRequestPageHandler(var CBGPostingTest: TestRequestPage "CBG Posting - Test")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText,
          CBGPostingTest."Gen. Journal Batch".GetFilter("Journal Template Name"),
          WrongTemplateFilterErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerExportSEPAISO20022(var ExportSEPAISO20022: TestRequestPage "Export SEPA ISO20022")
    begin
        ExportSEPAISO20022.OK.Invoke;
    end;
}

