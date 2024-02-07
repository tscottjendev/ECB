namespace Jendev.Finance.Currency.ECB.UI;

codeunit 50108 "ECB Summary Handler Show UI" implements "ECB Summary Handler"
{
    var
        RecordsInserted: Integer;
        RecordsRead: Integer;

    procedure IncrementRecordsInserted()
    begin
        RecordsInserted += 1;
    end;

    procedure IncrementRecordsRead()
    begin
        RecordsRead += 1;
    end;

    procedure ShowSummary()
    var
        SummaryNotification: Notification;
        NothingInsertedMsg: Label 'There were no new records to insert.';
        SummaryMsg: Label 'ECB Import complete. %1 records read. %2 records inserted.', Comment = '%1 number of records read and %2 number of records inserted';
    begin
        SummaryNotification.Id := SummaryNotificationId();
        if SummaryNotification.Recall() then;

        SummaryNotification.Message(StrSubstNo(NothingInsertedMsg));
        if (RecordsRead <> 0)
            or (RecordsInserted <> 0)
        then
            SummaryNotification.Message(StrSubstNo(SummaryMsg, RecordsRead, RecordsInserted));

        SummaryNotification.Send();
    end;

    local procedure SummaryNotificationId(): Guid
    begin
        exit('2420bbdb-4496-42fc-ba13-26fa10cedb0e');
    end;

}