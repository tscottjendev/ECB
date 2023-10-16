codeunit 50110 "ECB Import Impl."
{
    Access = Internal;
    Permissions =
        tabledata Currency = rim,
        tabledata "Currency Exchange Rate" = rim;

    var
        ECBSetup: Record "ECB Setup";
        SelectedECBProgressHandler: Interface "ECB Progress Handler";
        SelectedECBSummaryHandler: Interface "ECB Summary Handler";

    procedure ImportExchangeRates()
    var
        ECBImportUI: Enum "ECB Import UI";
        ECBProgressHandler: Interface "ECB Progress Handler";
        ECBSummaryHandler: Interface "ECB Summary Handler";
    begin
        ECBImportUI := ECBImportUI::HideUI;
        if GuiAllowed() then
            ECBImportUI := ECBImportUI::ShowUI;

        ECBProgressHandler := ECBImportUI;
        ECBSummaryHandler := ECBImportUI;

        ImportExchangeRates(ECBProgressHandler, ECBSummaryHandler);
    end;

    procedure ImportExchangeRates(ShowProgress: Boolean)
    begin
        ImportExchangeRates(ShowProgress, ShowProgress);
    end;

    procedure ImportExchangeRates(ShowProgress: Boolean; ShowSummary: Boolean)
    var
        ECBImportUI: Enum "ECB Import UI";
    begin
        if ShowProgress then
            ECBImportUI := ECBImportUI::ShowUI;

        ImportExchangeRates(ECBImportUI);
    end;

    procedure ImportExchangeRates(ECBImportUI: Enum "ECB Import UI")
    var
        ECBProgressHandler: Interface "ECB Progress Handler";
        ECBSummaryHandler: Interface "ECB Summary Handler";
    begin
        ECBProgressHandler := ECBImportUI;
        ECBSummaryHandler := ECBImportUI;

        ImportExchangeRates(ECBProgressHandler, ECBSummaryHandler);
    end;

    procedure ImportExchangeRates(ECBProgressHandler: Interface "ECB Progress Handler"; ECBSummaryHandler: Interface "ECB Summary Handler")
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CurrencyCode: Code[10];
        DownloadInStream: InStream;
        Column: Integer;
        DownloadErr: Label 'Failed to download ECB file. \%1', Comment = '%1 is the error message from the HTTP client';
    begin
        SelectedECBProgressHandler := ECBProgressHandler;
        SelectedECBSummaryHandler := ECBSummaryHandler;

        SelectedECBProgressHandler.OpenProgress();

        ECBSetup.GetRecordOnce();
        ECBSetup.TestSetupForImport();

        TempBlob.CreateInStream(DownloadInStream);
        if not DownloadFile(DownloadInStream) then
            Error(DownloadErr, GetLastErrorText());

        DecompressFile(TempBlob, DownloadInStream);
        FillCSVBuffer(TempCSVBuffer, TempBlob);
        for Column := 2 to TempCSVBuffer.GetNumberOfColumns() do begin
            TempCSVBuffer.Get(1, Column);
            CurrencyCode := CopyStr(TempCSVBuffer.Value, 1, MaxStrLen(CurrencyCode));
            SelectedECBProgressHandler.UpdateProgress(CurrencyCode);
            CreateCurrencyAndExchangeRate(TempCSVBuffer, CurrencyCode, Column);
        end;

        SelectedECBProgressHandler.CloseProgress();
        SelectedECBSummaryHandler.ShowSummary();
    end;

    local procedure CreateCurrencyAndExchangeRate(var TempCSVBuffer: Record "CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer)
    var
        Line: Integer;
    begin
        if CurrencyCode = '' then
            exit;

        InsertCurrency(CurrencyCode);
        for Line := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            SelectedECBSummaryHandler.IncrementRecordsRead();
            CreateCurrencyExchangeRate(TempCSVBuffer, CurrencyCode, Column, Line);
        end;
    end;

    local procedure CreateCurrencyExchangeRate(var TempCSVBuffer: Record "CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer; Line: Integer)
    var
        StartingDate: Date;
        ExchangeRateAmount: Decimal;
    begin
        TempCSVBuffer.Get(Line, 1);
        if not Evaluate(StartingDate, TempCSVBuffer.Value, 9) then
            exit;

        TempCSVBuffer.Get(Line, Column);
        if not Evaluate(ExchangeRateAmount, TempCSVBuffer.Value, 9) then
            exit;

        InsertCurrencyExchangeRate(CurrencyCode, StartingDate, ExchangeRateAmount);
    end;

    local procedure CurrencyExchangeRateExists(var CurrencyCode: Code[10]; var StartingDate: Date): Boolean
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ECBPublishedEvents: Codeunit "ECB Published Events";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        ECBPublishedEvents.OnBeforeCurrencyExchangeRateExists(CurrencyCode, StartingDate, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        CurrencyExchangeRate.SetLoadFields("Currency Code", "Starting Date");
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", StartingDate);
        exit(not CurrencyExchangeRate.IsEmpty());

    end;

    local procedure DecompressFile(var TempBlob: Codeunit "Temp Blob"; var DownloadInStream: InStream)
    var
        DataCompression: Codeunit "Data Compression";
        NumberOfFilesErr: Label 'Unexpected number of files in zip archive';
        FileList: List of [Text];
        OutStream: OutStream;
    begin
        DataCompression.OpenZipArchive(DownloadInStream, false);
        DataCompression.GetEntryList(FileList);
        if FileList.Count() <> 1 then
            Error(NumberOfFilesErr);

        TempBlob.CreateOutStream(OutStream);
        DataCompression.ExtractEntry(FileList.Get(1), OutStream);
    end;

    local procedure DownloadFile(var InStream: InStream): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
    begin
        if not HttpClient.Get(ECBSetup."Download URL", HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        exit(HttpResponseMessage.Content.ReadAs(InStream));
    end;

    local procedure FillCSVBuffer(var TempCSVBuffer: Record "CSV Buffer" temporary; var TempBlob: Codeunit "Temp Blob")
    var
        InStream: InStream;
        SeparatorTok: Label ',';
    begin
        TempBlob.CreateInStream(InStream);
        TempCSVBuffer.LoadDataFromStream(InStream, SeparatorTok);
    end;

    local procedure InsertCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.SetLoadFields(Code);
        Currency.SetRange(Code, CurrencyCode);
        if not Currency.IsEmpty() then
            exit;

        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Description := CurrencyCode;
        Currency.Insert(true);
    end;

    local procedure InsertCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyExchangeRateExists(CurrencyCode, StartingDate) then
            exit;

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := StartingDate;
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", ExchangeRateAmount);
        CurrencyExchangeRate.Insert(true);

        SelectedECBSummaryHandler.IncrementRecordsInserted();
    end;

}