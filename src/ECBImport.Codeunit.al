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
    /// Import exchange rates from the European Central Bank.  Using default UI experience based on whether or not GUI is allowed.
    /// </summary>
    /// <param name="ShowProgress">Whether or not to show the progress and summary dialogs.</param>
    procedure ImportExchangeRates(ShowProgress: Boolean)
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ShowProgress, ShowProgress);
    end;

    /// <summary>
    /// Import exchange rates from the European Central Bank.  Using default UI experience based on whether or not GUI is allowed.
    /// </summary>
    /// <param name="ShowProgress">Whether or not to show the progress dialog.</param>
    /// <param name="ShowSummary">Whether or not to show the summary dialog.</param>
    procedure ImportExchangeRates(ShowProgress: Boolean; ShowSummary: Boolean)
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ShowProgress, ShowSummary);
    end;

    procedure ImportExchangeRates(ECBImportUI: Enum "ECB Import UI")
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ECBImportUI);
    end;

    procedure ImportExchangeRates(ECBProgressHandler: Interface "ECB Progress Handler"; ECBSummaryHandler: Interface "ECB Summary Handler")
    var
        ECBImportImpl: Codeunit "ECB Import Impl.";
    begin
        ECBImportImpl.ImportExchangeRates(ECBProgressHandler, ECBSummaryHandler);
    end;
}