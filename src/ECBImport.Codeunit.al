codeunit 50100 "ECB Import"
{
    Access = Internal;
    Permissions =
        tabledata Currency = rim,
        tabledata "Currency Exchange Rate" = rim;

    var
        ECBSetup: Record "ECB Setup";

    procedure ImportExchangeRates()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CurrencyCode: Code[10];
        DownloadInStream: InStream;
        Column: Integer;
        DownloadErr: Label 'Failed to download ECB file. \%1', Comment = '%1 is the error message from the HTTP client';
    begin
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
            CreateCurrencyAndExchangeRate(TempCSVBuffer, CurrencyCode, Column);
        end;
    end;

    local procedure CreateCurrencyAndExchangeRate(var TempCSVBuffer: Record "CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer)
    var
        Line: Integer;
    begin
        if CurrencyCode = '' then
            exit;

        InsertCurrency(CurrencyCode);
        for Line := 2 to TempCSVBuffer.GetNumberOfLines() do begin
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

    local procedure DecompressFile(var TempBlob: Codeunit "Temp Blob"; var DownloadInStream: InStream)
    var
        DataCompression: Codeunit "Data Compression";
        LengthOfCSV: Integer;
        NumberOfFilesErr: Label 'Unexpected number of files in zip archive';
        FileList: List of [Text];
        OutStream: OutStream;
    begin
        DataCompression.OpenZipArchive(DownloadInStream, false);
        DataCompression.GetEntryList(FileList);
        if FileList.Count() <> 1 then
            Error(NumberOfFilesErr);

        TempBlob.CreateOutStream(OutStream);
        DataCompression.ExtractEntry(FileList.Get(1), OutStream, LengthOfCSV);
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
        CurrencyExchangeRate.SetLoadFields("Currency Code", "Starting Date");
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", StartingDate);
        if not CurrencyExchangeRate.IsEmpty() then
            exit;

        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := StartingDate;
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Insert(true);
    end;
}