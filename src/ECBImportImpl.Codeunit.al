namespace Jendev.Finance.Currency;

codeunit 50110 "ECB Import Impl."
{
    Access = Internal;
    Permissions =
        tabledata Microsoft.Finance.Currency.Currency = rim,
        tabledata Microsoft.Finance.Currency."Currency Exchange Rate" = rim;

    var
        ECBSetup: Record "ECB Setup";
        SelectedECBProgressHandler: Interface "ECB Progress Handler";
        SelectedECBSummaryHandler: Interface "ECB Summary Handler";

    procedure ImportExchangeRates()
    begin
        ImportExchangeRates(SetProgressHandler(), SetSummaryHandler());
    end;

    procedure ImportExchangeRates(ShowProgress: Boolean)
    begin
        ImportExchangeRates(ShowProgress, ShowProgress);
    end;

    procedure ImportExchangeRates(ShowProgress: Boolean; ShowSummary: Boolean)
    begin
        ImportExchangeRates(SetProgressHandler(ShowProgress), SetSummaryHandler(ShowSummary));
    end;

    procedure ImportExchangeRates(ECBImportUI: Enum "ECB Import UI")
    begin
        ImportExchangeRates(ECBImportUI, ECBImportUI);
    end;

    procedure ImportExchangeRates(ProgressECBImportUI: Enum "ECB Import UI"; SummaryECBImportUI: Enum "ECB Import UI")
    begin
        ImportExchangeRates(ProgressECBImportUI, SummaryECBImportUI);
    end;

    procedure ImportExchangeRates(ECBProgressHandler: Interface "ECB Progress Handler"; ECBSummaryHandler: Interface "ECB Summary Handler")
    var
        TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary;
        TempBlob: Codeunit System.Utilities."Temp Blob";
        DownloadInStream: InStream;
    begin
        OpenUI(ECBProgressHandler, ECBSummaryHandler);

        TestSetup();

        DownloadInStream := TempBlob.CreateInStream();
        DownloadFile(DownloadInStream);

        DecompressFile(TempBlob, DownloadInStream);
        FillECBBuffer(TempECBCSVBuffer, TempBlob);
        if AlreadyImported(TempECBCSVBuffer) then
            exit;

        if ProcessCurrencies(TempECBCSVBuffer) then
            UpdateLastExchangeDateImported(TempECBCSVBuffer);

        CloseUI();
    end;

    local procedure AlreadyImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary): Boolean
    begin
        if IsDateAlreadyImported(TempECBCSVBuffer, GetLastExchangeDateImported()) then begin
            NotifyAlreadyImported(GetLastExchangeDateImported());
            exit(true);
        end;

        exit(false);
    end;

    local procedure AlreadyImportedNotificationId(): Guid
    begin
        exit('55496929-118d-4e3a-89c6-b937452922af');
    end;

    local procedure CloseUI()
    begin
        SelectedECBProgressHandler.CloseProgress();
        SelectedECBSummaryHandler.ShowSummary();
    end;

    local procedure CreateCurrencyAndExchangeRate(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer)
    var
        Line: Integer;
    begin
        if CurrencyCode = '' then
            exit;

        InsertCurrency(CurrencyCode);
        for Line := 2 to TempECBCSVBuffer.GetNumberOfLines() do begin
            SelectedECBSummaryHandler.IncrementRecordsRead();
            CreateCurrencyExchangeRate(TempECBCSVBuffer, CurrencyCode, Column, Line);
        end;
    end;

    local procedure CreateCurrencyExchangeRate(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer; Line: Integer)
    var
        ExchangeRateDate: Date;
        ExchangeRateFactor: Decimal;
    begin
        if not GetExchangeRateDateFromCSV(TempECBCSVBuffer, Line, ExchangeRateDate) then
            exit;
        if ExchangeRateDate <= GetLastExchangeDateImported() then
            exit;
        if not GetExchangeRateFactorFromCSV(TempECBCSVBuffer, Column, Line, ExchangeRateFactor) then
            exit;

        InsertCurrencyExchangeRate(CurrencyCode, ExchangeRateDate, ExchangeRateFactor);
    end;

    local procedure CurrencyExchangeRateExists(var CurrencyCode: Code[10]; var StartingDate: Date): Boolean
    var
        CurrencyExchangeRate: Record Microsoft.Finance.Currency."Currency Exchange Rate";
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

    local procedure DecompressFile(var TempBlob: Codeunit System.Utilities."Temp Blob"; var DownloadInStream: InStream)
    var
        DataCompression: Codeunit System.IO."Data Compression";
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
        DataCompression.CloseZipArchive();
    end;

    local procedure DownloadFile(var InStream: InStream)
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ConnectionErr: Label '%1 Unable to connect to the server.  Ensure the download URL is correct.', Comment = '%1 is the default error text';
        ContentErr: Label '%1 The content was unable to be read.', Comment = '%1 is the default error text';
        ECBDownloadErr: Label 'Failed to download ECB file. ', Comment = 'The space at the end is required.';
        ResponseErr: Label '%1 The server returned an error. Status: %2 %3', Comment = '%1 is the default error text,  %2 is the status code, %3 is the reason phrase';
    begin
        if not HttpClient.Get(GetDownloadURL(), HttpResponseMessage) then
            Error(ConnectionErr, ECBDownloadErr);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            Error(ResponseErr, ECBDownloadErr, HttpResponseMessage.HttpStatusCode, HttpResponseMessage.ReasonPhrase);

        if not HttpResponseMessage.Content.ReadAs(InStream) then
            Error(ContentErr, ECBDownloadErr);
    end;

    local procedure FillECBBuffer(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; var TempBlob: Codeunit System.Utilities."Temp Blob")
    var
        InStream: InStream;
        SeparatorTok: Label ',';
    begin
        TempBlob.CreateInStream(InStream);
        TempECBCSVBuffer.LoadDataFromStream(InStream, SeparatorTok);
    end;

    local procedure GetDownloadURL(): Text
    begin
        ECBSetup.GetRecordOnce();
        exit(ECBSetup."Download URL");
    end;

    local procedure GetExchangeRateDateFromCSV(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; Line: Integer; var ExchangeRateDate: Date): Boolean
    begin
        TempECBCSVBuffer.Get(Line, 1);
        exit(TempECBCSVBuffer.Convert(ExchangeRateDate));
    end;

    local procedure GetExchangeRateFactorFromCSV(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; Column: Integer; Line: Integer; var ExchangeRateAmount: Decimal): Boolean
    begin
        TempECBCSVBuffer.Get(Line, Column);
        exit(TempECBCSVBuffer.Convert(ExchangeRateAmount));
    end;

    local procedure GetLastExchangeDateImported(): Date
    begin
        ECBSetup.GetRecordOnce();
        exit(ECBSetup."Last Exchange Date Imported");
    end;

    local procedure InsertCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Microsoft.Finance.Currency.Currency;
    begin
        if IsLocalCurrency(CurrencyCode) then
            exit;

        Currency.SetLoadFields(Code);
        Currency.SetRange(Code, CurrencyCode);
        if not Currency.IsEmpty() then
            exit;

        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Description := CurrencyCode;
        Currency.Insert(true);
    end;

    local procedure InsertCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; Factor: Decimal)
    var
        CurrencyExchangeRate: Record Microsoft.Finance.Currency."Currency Exchange Rate";
    begin
        if CurrencyExchangeRateExists(CurrencyCode, StartingDate) then
            exit;

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := StartingDate;
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", Factor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", Factor);
        CurrencyExchangeRate.Insert(true);

        SelectedECBSummaryHandler.IncrementRecordsInserted();
    end;

    local procedure IsDateAlreadyImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; LastExchangeDateImported: Date): Boolean
    var
        StartingDate: Date;
    begin
        StartingDate := TempECBCSVBuffer.GetLatestExchangeRateDate();
        exit(StartingDate <= LastExchangeDateImported);
    end;

    local procedure IsLocalCurrency(CurrencyCode: Code[10]): Boolean
    var
        GeneralLedgerSetup: Record Microsoft.Finance.GeneralLedger.Setup."General Ledger Setup";
    begin
        GeneralLedgerSetup.SetLoadFields("LCY Code");
        GeneralLedgerSetup.Get();
        exit(CurrencyCode = GeneralLedgerSetup."LCY Code");
    end;

    local procedure NotifyAlreadyImported(LastImportedExchangeDate: Date)
    var
        AlreadyImportedNotification: Notification;
        AlreadyImportedMsg: Label 'The ECB file has already been imported for %1', Comment = '%1 is the last imported exchange date';
    begin
        AlreadyImportedNotification.Id := AlreadyImportedNotificationId();
        if AlreadyImportedNotification.Recall() then;

        AlreadyImportedNotification.Message(StrSubstNo(AlreadyImportedMsg, LastImportedExchangeDate));
        AlreadyImportedNotification.Send();
    end;

    local procedure OpenUI(var ECBProgressHandler: Interface "ECB Progress Handler"; var ECBSummaryHandler: Interface "ECB Summary Handler")
    begin
        SelectedECBProgressHandler := ECBProgressHandler;
        SelectedECBSummaryHandler := ECBSummaryHandler;
        SelectedECBProgressHandler.OpenProgress();
    end;

    local procedure ProcessCurrencies(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary): Boolean
    var
        CurrencyCode: Code[10];
        Column: Integer;
    begin
        for Column := 2 to TempECBCSVBuffer.GetNumberOfColumns() do begin
            TempECBCSVBuffer.Get(1, Column);
            CurrencyCode := CopyStr(TempECBCSVBuffer.Value, 1, MaxStrLen(CurrencyCode));
            SelectedECBProgressHandler.UpdateProgress(CurrencyCode);
            CreateCurrencyAndExchangeRate(TempECBCSVBuffer, CurrencyCode, Column);
        end;

        exit(true);
    end;

    local procedure SetProgressHandler(): Interface "ECB Progress Handler"
    begin
        exit(SetProgressHandler(GuiAllowed()));
    end;

    local procedure SetProgressHandler(ShowProgress: Boolean): Interface "ECB Progress Handler"
    var
        ECBImportUI: Enum "ECB Import UI";
    begin
        ECBImportUI := ECBImportUI::HideUI;
        if ShowProgress then
            ECBImportUI := ECBImportUI::ShowUI;

        exit(ECBImportUI);
    end;

    local procedure SetSummaryHandler(): Interface "ECB Summary Handler"
    begin
        exit(SetSummaryHandler(GuiAllowed()));
    end;

    local procedure SetSummaryHandler(ShowSummary: Boolean): Interface "ECB Summary Handler"
    var
        ECBImportUI: Enum "ECB Import UI";
    begin
        ECBImportUI := ECBImportUI::HideUI;
        if ShowSummary then
            ECBImportUI := ECBImportUI::ShowUI;

        exit(ECBImportUI);
    end;

    local procedure TestSetup()
    begin
        ECBSetup.GetRecordOnce();
        ECBSetup.TestSetupForImport();
    end;

    local procedure UpdateLastExchangeDateImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary)
    begin
        ECBSetup."Last Exchange Date Imported" := TempECBCSVBuffer.GetLatestExchangeRateDate();
        ECBSetup.Modify(true);
    end;

}