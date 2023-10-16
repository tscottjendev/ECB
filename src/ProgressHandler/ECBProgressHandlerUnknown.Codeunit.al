namespace Jendev.Finance.Currency;

codeunit 50102 "ECB Progress Handler Unknown" implements "ECB Progress Handler"
{
    var
        UnsupportedEnumValueErr: Label 'Unsupported Enum ''ECB Import UI'' Value';

    procedure CloseProgress()
    begin
        Error(UnsupportedEnumValueErr);
    end;

    procedure OpenProgress()
    begin
        Error(UnsupportedEnumValueErr);
    end;

    procedure UpdateProgress(CurrencyCode: Code[10])
    begin
        Error(UnsupportedEnumValueErr);
    end;
}