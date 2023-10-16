namespace Jendev.Finance.Currency;

using System.IO;

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
        TempCSVBuffer: Record System.IO."CSV Buffer" temporary;
        TempBlob: Codeunit System.Utilities."Temp Blob";
        DownloadInStream: InStream;
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
        if ProcessCurrencies(TempCSVBuffer) then
            UpdateLastExchangeDateImported(TempCSVBuffer);

        SelectedECBProgressHandler.CloseProgress();
        SelectedECBSummaryHandler.ShowSummary();
    end;

    local procedure AlreadyImported(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary; LastExchangeDateImported: Date): Boolean
    var
        StartingDate: Date;
    begin
        TempCSVBuffer.Get(2, 1);
        if not ConvertToDate(StartingDate, TempCSVBuffer.Value) then
            exit(true);

        exit(StartingDate <= LastExchangeDateImported);
    end;

    local procedure AlreadyImportedNotificationId(): Guid
    begin
        exit('55496929-118d-4e3a-89c6-b937452922af');
    end;

    local procedure ConvertToDate(var StartingDate: Date; Value: Text[250]): Boolean
    begin
        exit(Evaluate(StartingDate, Value, 9));
    end;

    local procedure ConvertToDecimal(var ExchangeRateAmount: Decimal; Value: Text[250]): Boolean
    begin
        exit(Evaluate(ExchangeRateAmount, Value, 9));

    end;

    local procedure CreateCurrencyAndExchangeRate(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer)
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

    local procedure CreateCurrencyExchangeRate(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer; Line: Integer)
    var
        StartingDate: Date;
        ExchangeRateAmount: Decimal;
    begin
        TempCSVBuffer.Get(Line, 1);
        if not ConvertToDate(StartingDate, TempCSVBuffer.Value) then
            exit;

        if StartingDate <= ECBSetup."Last Exchange Date Imported" then
            exit;

        TempCSVBuffer.Get(Line, Column);
        if not ConvertToDecimal(ExchangeRateAmount, TempCSVBuffer.Value) then
            exit;

        InsertCurrencyExchangeRate(CurrencyCode, StartingDate, ExchangeRateAmount);
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

    local procedure FillCSVBuffer(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary; var TempBlob: Codeunit System.Utilities."Temp Blob")
    var
        InStream: InStream;
        SeparatorTok: Label ',';
    begin
        TempBlob.CreateInStream(InStream);
        TempCSVBuffer.LoadDataFromStream(InStream, SeparatorTok);
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

    local procedure InsertCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record Microsoft.Finance.Currency."Currency Exchange Rate";
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

    local procedure ProcessCurrencies(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary): Boolean
    var
        CurrencyCode: Code[10];
        Column: Integer;
    begin
        if AlreadyImported(TempCSVBuffer, ECBSetup."Last Exchange Date Imported") then begin
            NotifyAlreadyImported(ECBSetup."Last Exchange Date Imported");
            exit(false);
        end;

        for Column := 2 to TempCSVBuffer.GetNumberOfColumns() do begin
            TempCSVBuffer.Get(1, Column);
            CurrencyCode := CopyStr(TempCSVBuffer.Value, 1, MaxStrLen(CurrencyCode));
            SelectedECBProgressHandler.UpdateProgress(CurrencyCode);
            CreateCurrencyAndExchangeRate(TempCSVBuffer, CurrencyCode, Column);
        end;

        exit(true);
    end;

    local procedure UpdateLastExchangeDateImported(var TempCSVBuffer: Record System.IO."CSV Buffer" temporary)
    begin
        TempCSVBuffer.Get(2, 1);
        ConvertToDate(ECBSetup."Last Exchange Date Imported", TempCSVBuffer.Value);
        ECBSetup.Modify(true);
    end;

}