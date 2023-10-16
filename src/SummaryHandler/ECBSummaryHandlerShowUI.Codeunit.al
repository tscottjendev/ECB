namespace Jendev.Finance.Currency;

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

    procedure ShowSummary();
    var
        SummaryNotification: Notification;
        SummaryMsg: Label 'ECB Import complete. %1 records read. %2 records inserted.', Comment = '%1 number of records read and %2 number of records inserted';
    begin
        if (RecordsRead = 0)
            and (RecordsInserted = 0)
        then
            exit;

        SummaryNotification.Id := SummaryNotificationId();
        if SummaryNotification.Recall() then;

        SummaryNotification.Message(StrSubstNo(SummaryMsg, RecordsRead, RecordsInserted));
        SummaryNotification.Send();
    end;

    local procedure SummaryNotificationId(): Guid
    begin
        exit('2420bbdb-4496-42fc-ba13-26fa10cedb0e');
    end;

}