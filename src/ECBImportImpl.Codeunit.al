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
        TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary;
        TempBlob: Codeunit System.Utilities."Temp Blob";
        DownloadInStream: InStream;
    begin
        SelectedECBProgressHandler := ECBProgressHandler;
        SelectedECBSummaryHandler := ECBSummaryHandler;

        SelectedECBProgressHandler.OpenProgress();

        ECBSetup.GetRecordOnce();
        ECBSetup.TestSetupForImport();

        DownloadInStream := TempBlob.CreateInStream();
        DownloadFile(DownloadInStream);

        DecompressFile(TempBlob, DownloadInStream);
        FillECBBuffer(TempECBCSVBuffer, TempBlob);
        if not AlreadyImported(TempECBCSVBuffer) then
            if ProcessCurrencies(TempECBCSVBuffer) then
                UpdateLastExchangeDateImported(TempECBCSVBuffer);

        SelectedECBProgressHandler.CloseProgress();
        SelectedECBSummaryHandler.ShowSummary();
    end;

    local procedure AlreadyImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary): Boolean
    begin
        if AlreadyImported(TempECBCSVBuffer, ECBSetup."Last Exchange Date Imported") then begin
            NotifyAlreadyImported(ECBSetup."Last Exchange Date Imported");
            exit(true);
        end;

        exit(false);
    end;

    local procedure AlreadyImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; LastExchangeDateImported: Date): Boolean
    var
        StartingDate: Date;
    begin
        StartingDate := TempECBCSVBuffer.GetLatestExchangeRateDate();
        exit(StartingDate <= LastExchangeDateImported);
    end;

    local procedure AlreadyImportedNotificationId(): Guid
    begin
        exit('55496929-118d-4e3a-89c6-b937452922af');
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
        if not GetExchangeRateDate(TempECBCSVBuffer, Line, ExchangeRateDate) then
            exit;
        if ExchangeRateDate <= ECBSetup."Last Exchange Date Imported" then
            exit;

        if not GetExchangeRateFactor(TempECBCSVBuffer, Column, Line, ExchangeRateFactor) then
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
        if not HttpClient.Get(ECBSetup."Download URL", HttpResponseMessage) then
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

    local procedure GetExchangeRateDate(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; Line: Integer; var ExchangeRateDate: Date): Boolean
    begin
        TempECBCSVBuffer.Get(Line, 1);
        exit(TempECBCSVBuffer.Convert(ExchangeRateDate));
    end;

    local procedure GetExchangeRateFactor(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary; Column: Integer; Line: Integer; var ExchangeRateAmount: Decimal): Boolean
    begin
        TempECBCSVBuffer.Get(Line, Column);
        exit(TempECBCSVBuffer.Convert(ExchangeRateAmount));
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

    local procedure UpdateLastExchangeDateImported(var TempECBCSVBuffer: Record System.IO."CSV Buffer" temporary)
    begin
        ECBSetup."Last Exchange Date Imported" := TempECBCSVBuffer.GetLatestExchangeRateDate();
        ECBSetup.Modify(true);
    end;

}