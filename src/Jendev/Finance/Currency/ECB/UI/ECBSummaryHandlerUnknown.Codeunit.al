namespace Jendev.Finance.Currency.ECB.UI;

codeunit 50106 "ECB Summary Handler Unknown" implements "ECB Summary Handler"
{
    var
        UnsupportedEnumValueErr: Label 'Unsupported Enum ''ECB Import UI'' Value';

    procedure IncrementRecordsInserted()
    begin
        Error(UnsupportedEnumValueErr);
    end;

    procedure IncrementRecordsRead()
    begin
        Error(UnsupportedEnumValueErr);
    end;

    procedure ShowSummary()
    begin
        Error(UnsupportedEnumValueErr);
    end;

}