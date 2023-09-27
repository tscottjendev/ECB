pageextension 50100 "ECB Currencies" extends Currencies
{
    actions
    {
        addfirst(processing)
        {
            action("ECB Import")
            {
                ApplicationArea = all;
                Caption = 'Import from ECB';
                Image = CurrencyExchangeRates;
                ToolTip = 'Import EUR exchange rates from ECB';

                trigger OnAction()
                begin
                    ECBImport();
                end;
            }
        }
    }

    local procedure CreateCurrencyAndExchagneRate(var TempCSVBuffer: Record "CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer)
    var
        Line: Integer;
    begin
        if CurrencyCode = '' then
            exit;

        CreateCurrencyCode(CurrencyCode);
        for Line := 2 to TempCSVBuffer.GetNumberOfLines() do begin
            CreateCurrencyExchangeRate(TempCSVBuffer, CurrencyCode, Column, Line);
        end;
    end;

    local procedure CreateCurrencyCode(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.SetLoadFields(Code);
        Currency.SetRange(Code, CurrencyCode);
        if not Currency.IsEmpty() then
            exit;

        InsertCurrency(CurrencyCode);
    end;

    local procedure CreateCurrencyExchangeRate(var TempCSVBuffer: Record "CSV Buffer" temporary; CurrencyCode: Code[10]; Column: Integer; Line: Integer)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        StartingDate: Date;
        ExchangeRateAmount: Decimal;
    begin
        TempCSVBuffer.Get(Line, 1);
        if not Evaluate(StartingDate, TempCSVBuffer.Value, 9) then
            exit;

        TempCSVBuffer.Get(Line, Column);
        if not Evaluate(ExchangeRateAmount, TempCSVBuffer.Value, 9) then
            exit;

        CurrencyExchangeRate.SetLoadFields("Currency Code", "Starting Date");
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.SetRange("Starting Date", StartingDate);
        if not CurrencyExchangeRate.IsEmpty() then
            exit;

        InsertCurrencyExchangeRate(CurrencyCode, StartingDate, ExchangeRateAmount);
    end;

    local procedure DecompressFile(var TempBlob: Codeunit "Temp Blob")
    var
        DataCompression: Codeunit "Data Compression";
        InStream: InStream;
        LengthOfCSV: Integer;
        NumberOfFilesErr: Label 'Unexpected number of files in zip archive';
        FileList: List of [Text];
        OutStream: OutStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataCompression.OpenZipArchive(InStream, false);
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
        EuroFXRefUrlTok: Label 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip';
    begin
        if not HttpClient.Get(EuroFXRefUrlTok, HttpResponseMessage) then
            exit(false);

        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit(false);

        HttpResponseMessage.Content.ReadAs(InStream);
        exit(true);
    end;

    local procedure ECBImport()
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CurrencyCode: Code[10];
        InStream: InStream;
        Column: Integer;
        DownloadErr: Label 'Failed to download ECB file. \%1', Comment = '%1 is the error message from the HTTP client';
    begin
        TempBlob.CreateInStream(InStream);
        if not DownloadFile(InStream) then
            Error(DownloadErr, GetLastErrorText());

        DecompressFile(TempBlob);
        FillCSVBuffer(TempCSVBuffer, TempBlob);
        for Column := 2 to TempCSVBuffer.GetNumberOfColumns() do begin
            TempCSVBuffer.Get(1, Column);
            CurrencyCode := CopyStr(TempCSVBuffer.Value, 1, MaxStrLen(CurrencyCode));
            CreateCurrencyAndExchagneRate(TempCSVBuffer, CurrencyCode, Column);
        end;
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
        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Description := CurrencyCode;
        Currency.Insert(true);
    end;

    local procedure InsertCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Init();
        CurrencyExchangeRate."Currency Code" := CurrencyCode;
        CurrencyExchangeRate."Starting Date" := StartingDate;
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Insert(true);
    end;
}