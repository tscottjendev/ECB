namespace Jendev.Finance.Currency.ECB.UI;

interface "ECB Progress Handler"
{
    procedure CloseProgress()
    procedure OpenProgress()
    procedure UpdateProgress(CurrencyCode: Code[10])
}