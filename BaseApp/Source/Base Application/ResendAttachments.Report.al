report 5183 "Resend Attachments"
{
    Caption = 'Resend Attachments';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Interaction Log Entry"; "Interaction Log Entry")
        {
            DataItemTableView = SORTING("Logged Segment Entry No.") WHERE(Postponed = CONST(false));
            RequestFilterFields = "Logged Segment Entry No.", "Entry No.", "Delivery Status", "Correspondence Type", "Contact No.", "Campaign No.";

            trigger OnAfterGetRecord()
            var
                Attachment: Record Attachment;
                InteractionLogEntryNew: Record "Interaction Log Entry";
                SegLine: Record "Segment Line";
                InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
                SegManagement: Codeunit SegManagement;
                NewEntryNo: Integer;
            begin
                if not Attachment.Get("Attachment No.") then
                    CurrReport.Skip();
                if Attachment."Storage Type" = Attachment."Storage Type"::"Exchange Storage" then
                    CurrReport.Skip();
                if CorrespondenceType = CorrespondenceType::"Same as Entry" then
                    TestField("Correspondence Type");

                if UpdateMergeFields then begin
                    if DeliveryBufferTemp.Get("Entry No.") then
                        CurrReport.Skip();
                    InteractionLogEntryNew.TransferFields("Interaction Log Entry", false);
                    InteractionLogEntryNew.Validate(Date, WorkDate);
                    InteractionLogEntryNew.Validate("Time of Interaction", Time);
                    if StrPos(Description, Text003) <> 1 then begin
                        if StrLen(Description) + StrLen(Text003) <= MaxStrLen(InteractionLogEntryNew.Description) then
                            InteractionLogEntryNew.Validate(Description, Text003 + Description)
                        else
                            InteractionLogEntryNew.Validate(Description, CopyStr(
                                Text003 + Description, 1, MaxStrLen(InteractionLogEntryNew.Description)))
                    end;
                    if CorrespondenceType <> CorrespondenceType::"Same as Entry" then
                        InteractionLogEntryNew."Correspondence Type" := AttachmentManagement.ConvertCorrespondenceType(CorrespondenceType);
                    SegLine.CopyFromInteractLogEntry(InteractionLogEntryNew);
                    InterLogEntryCommentLine.SetRange("Entry No.", "Entry No.");
                    if InterLogEntryCommentLine.FindFirst() then;
                    Attachment.CalcFields("Attachment File");
                    Clear(Attachment."Merge Source");
                    NewEntryNo := SegManagement.LogInteraction(SegLine, Attachment, InterLogEntryCommentLine, false, false);
                    InteractionLogEntryNew.Get(NewEntryNo);
                    InteractionLogEntryNew.Validate("Logged Segment Entry No.", "Logged Segment Entry No.");
                    InteractionLogEntryNew.Validate("Delivery Status", "Delivery Status"::"In Progress");
                    InteractionLogEntryNew.Validate("E-Mail Logged", false);
                    InteractionLogEntryNew.Modify(true);
                end else begin
                    if CorrespondenceType <> CorrespondenceType::"Same as Entry" then
                        "Correspondence Type" := AttachmentManagement.ConvertCorrespondenceType(CorrespondenceType);
                    "Delivery Status" := "Delivery Status"::"In Progress";
                    "E-Mail Logged" := false;
                    Modify;
                end;

                DeliveryBufferTemp.Init();
                if UpdateMergeFields then begin
                    DeliveryBufferTemp."No." := NewEntryNo;
                    DeliveryBufferTemp."Attachment No." := InteractionLogEntryNew."Attachment No.";
                    DeliveryBufferTemp."Correspondence Type" := InteractionLogEntryNew."Correspondence Type"
                end else begin
                    DeliveryBufferTemp."No." := "Entry No.";
                    DeliveryBufferTemp."Attachment No." := "Attachment No.";
                    DeliveryBufferTemp."Correspondence Type" := "Correspondence Type"
                end;
                DeliveryBufferTemp.Subject := Subject;
                DeliveryBufferTemp."Send Word Docs. as Attmt." := "Send Word Docs. as Attmt.";
                DeliveryBufferTemp."Language Code" := "Interaction Language Code";
                DeliveryBufferTemp.Insert();
            end;

            trigger OnPostDataItem()
            begin
                if DeliveryBufferTemp.Count = 0 then
                    Error(Text002);

                Commit();
                AttachmentManagement.Send(DeliveryBufferTemp);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CorrespondenceType; CorrespondenceType)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Correspondence Type';
                        OptionCaption = 'Same as Entry,Hard Copy,Email,Fax';
                        ToolTip = 'Specifies a correspondence type to specify how you want the program to resend the attachment.';
                    }
                    field("Update Merge Fields"; UpdateMergeFields)
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Update Merge Fields';
                        ToolTip = 'Specifies if you want to refresh the information in your Word document merge.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        LoggedSeg: Record "Logged Segment";
    begin
        if "Interaction Log Entry".GetFilter("Logged Segment Entry No.") = '' then
            Error(Text000, "Interaction Log Entry".FieldCaption("Logged Segment Entry No."));

        if "Interaction Log Entry".GetFilter("Logged Segment Entry No.") <> '0' then begin
            LoggedSeg.SetFilter("Entry No.", "Interaction Log Entry".GetFilter("Logged Segment Entry No."));
            if LoggedSeg.Count <> 1 then
                Error(
                  Text001, LoggedSeg.TableCaption);
        end;
    end;

    var
        Text000: Label '%1 must be specified.';
        Text001: Label 'The interaction log entries must always be from the same %1.';
        Text002: Label 'There is nothing to send.\\Only Microsoft Word documents can be resent.';
        DeliveryBufferTemp: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
        CorrespondenceType: Option "Same as Entry","Hard Copy",Email,Fax;
        UpdateMergeFields: Boolean;
        Text003: Label 'Resend:';
}

