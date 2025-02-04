﻿codeunit 1220 "SEPA CT-Export File"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        BankAccount: Record "Bank Account";
        ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
    begin
        LockTable();
        BankAccount.Get("Bal. Account No.");
        if Export(Rec, BankAccount.GetPaymentExportXMLPortID) then
            ExpUserFeedbackGenJnl.SetExportFlagOnGenJnlLine(Rec);
    end;

    var
        ExportToServerFile: Boolean;

    procedure Export(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer) Result: Boolean
    var
        CreditTransferRegister: Record "Credit Transfer Register";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        OutStr: OutStream;
        UseCommonDialog: Boolean;
        FileCreated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExtport(GenJnlLine, XMLPortID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempBlob.CreateOutStream(OutStr);
        XMLPORT.Export(XMLPortID, OutStr, GenJnlLine);

        CreditTransferRegister.FindLast();
        UseCommonDialog := not ExportToServerFile;
        OnBeforeBLOBExport(TempBlob, CreditTransferRegister, UseCommonDialog, FileCreated, IsHandled);
        if not IsHandled then
            FileCreated :=
              FileManagement.BLOBExport(TempBlob, StrSubstNo('%1.XML', CreditTransferRegister.Identifier), UseCommonDialog) <> '';
        if FileCreated then
            SetCreditTransferRegisterToFileCreated(CreditTransferRegister, TempBlob);

        exit(CreditTransferRegister.Status = CreditTransferRegister.Status::"File Created");
    end;

    local procedure SetCreditTransferRegisterToFileCreated(var CreditTransferRegister: Record "Credit Transfer Register"; var TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        CreditTransferRegister.Status := CreditTransferRegister.Status::"File Created";
        RecordRef.GetTable(CreditTransferRegister);
        TempBlob.ToRecordRef(RecordRef, CreditTransferRegister.FieldNo("Exported File"));
        RecordRef.SetTable(CreditTransferRegister);
        CreditTransferRegister.Modify();
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBLOBExport(var TempBlob: Codeunit "Temp Blob"; CreditTransferRegister: Record "Credit Transfer Register"; UseComonDialog: Boolean; var FieldCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExtport(var GenJnlLine: Record "Gen. Journal Line"; XMLPortID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

