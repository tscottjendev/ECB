namespace Jendev.Finance.Currency.ECB;

codeunit 50100 "ECB Import"
{
    Access = Public;

    var
    /// <summary>
    /// Import exchange rates from the European Central Bank.  Using default UI experience based on whether or not GUI is allowed.
    /// If GUI is allowed, then the progress and summary dialogs will be shown.  Otherwise, they will be hidden.
    /// </summary>
    procedure ImportExchangeRates()
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates();
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.
    /// </summary>
    /// <param name="ShowUI">Whether or not to show the progress and summary dialogs.</param>
    procedure ImportExchangeRates(ShowUI: Boolean)
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ShowUI);
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.
    /// </summary>
    /// <param name="ShowProgress">Whether or not to show the progress dialog.</param>
    /// <param name="ShowSummary">Whether or not to show the summary dialog.</param>
    procedure ImportExchangeRates(ShowProgress: Boolean; ShowSummary: Boolean)
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ShowProgress, ShowSummary);
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.
    /// </summary>
    /// <param name="ECBImportUI">The progress and summary dialog to use.</param>
    procedure ImportExchangeRates(ECBImportUI: Enum Jendev.Finance.Currency.ECB.UI."ECB Import UI")
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ECBImportUI);
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.
    /// </summary>
    /// <param name="ProgressECBImportUI">The progress dialog to use.</param>
    /// <param name="SummaryECBImportUI">The summary dialog to use.</param>
    procedure ImportExchangeRates(ProgressECBImportUI: Enum Jendev.Finance.Currency.ECB.UI."ECB Import UI"; SummaryECBImportUI: Enum Jendev.Finance.Currency.ECB.UI."ECB Import UI")
    begin
        ImportExchangeRates(ProgressECBImportUI, SummaryECBImportUI);
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.
    /// </summary>
    /// <param name="ECBProgressHandler">The progress dialog to use.</param>
    /// <param name="ECBSummaryHandler">The summary dialog to use.</param>
    procedure ImportExchangeRates(ECBProgressHandler: Interface Jendev.Finance.Currency.ECB.UI."ECB Progress Handler"; ECBSummaryHandler: Interface Jendev.Finance.Currency.ECB.UI."ECB Summary Handler")
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ECBProgressHandler, ECBSummaryHandler);
    end;
}