#if not CLEAN18
codeunit 135501 "AccountEntity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Account]
    end;

    var
        ServiceNameTxt: Label 'accounts';
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastDateModified()
    var
        GLAccount: Record "G/L Account";
        AccountNo: Text;
        AccountGUID: Text;
        BlankGuid: Guid;
        BlankDateTime: DateTime;
    begin
        // [SCENARIO] Create an account and verify it has Id and LastDateTimeModified
        // [GIVEN] a modified G/L Account
        Initialize();
        AccountNo := CreateAccount;
        Commit();

        // [WHEN] we retrieve the account from the database
        GLAccount.Reset();
        GLAccount.SetFilter("No.", AccountNo);
        Assert.IsTrue(GLAccount.FindFirst, 'The G/L Account should exist in the table.');
        AccountGUID := GLAccount.SystemId;

        // [THEN] the account should have an integration id and last date time modified
        Assert.AreNotEqual(GLAccount."Last Modified Date Time", BlankDateTime, 'Last Modified Date Time should be initialized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAccounts()
    var
        AccountNo: array[2] of Text;
        AccountJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create accounts and use a GET method to retrieve them
        // [GIVEN] 2 accounts in the G/L Account Table with positive balance
        Initialize();
        AccountNo[1] := CreateAccount;
        AccountNo[2] := CreateAccount;
        Commit();

        // [WHEN] we GET all the accounts from the web service
        ClearLastError;
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Account Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 accounts should exist in the response
        if GetLastErrorText <> '' then
            Assert.ExpectedError('Request failed with error: ' + GetLastErrorText);

        GetAndVerifyIDFromJSON(ResponseText, AccountNo[1], AccountJSON[1]);
        GetAndVerifyIDFromJSON(ResponseText, AccountNo[2], AccountJSON[2]);
    end;

    [Normal]
    local procedure CreateAccount(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Normal]
    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; AccountNo: Text; var AccountJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'number', AccountNo, AccountNo, AccountJSON, AccountJSON),
          'Could not find the account in JSON');
        LibraryGraphMgt.VerifyIDInJson(AccountJSON);
    end;
}
#endif
