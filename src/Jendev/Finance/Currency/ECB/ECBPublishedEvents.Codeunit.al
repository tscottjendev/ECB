namespace Jendev.Finance.Currency.ECB;

codeunit 50109 "ECB Published Events"
{

    [IntegrationEvent(false, false)]
    procedure OnBeforeCurrencyExchangeRateExists(var CurrencyCode: Code[10]; var StartingDate: Date; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;
}
