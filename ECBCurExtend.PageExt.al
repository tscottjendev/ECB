pageextension 50100 "ECB CurExtend" extends Currencies
{
    actions
    {
        addfirst(processing)
        {
            action("ECB Import")
            {
                ApplicationArea = all;
                Caption = 'Import from ECB';
                Image = Import;
                ToolTip = 'Import from ECB';

                trigger OnAction()
                var
                    TempCSV: Record "CSV Buffer" temporary;
                    CurRec: Record Currency;
                    ExtRec: Record "Currency Exchange Rate";
                    Zip: Codeunit "Data Compression";
                    TmpBlob: Codeunit "Temp Blob";
                    CurCode: Code[10];
                    HttpClient: HttpClient;
                    Response: HttpResponseMessage;
                    CSVStream: InStream;
                    InS: InStream;
                    Col: Integer;
                    LengthOfCsv: Integer;
                    Line: Integer;
                    FileList: List of [Text];
                    OutS: OutStream;
                begin
                    // https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip
                    HttpClient.Get('https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip', Response);
                    if Response.IsSuccessStatusCode() then begin
                        Response.Content.ReadAs(InS);
                        Zip.OpenZipArchive(InS, false);
                        Zip.GetEntryList(FileList);
                        //Message('Found %1', FileList.Get(1));
                        TmpBlob.CreateOutStream(OutS);
                        Zip.ExtractEntry(FileList.Get(1), OutS, LengthOfCsv);
                        TmpBlob.CreateInStream(CSVStream);
                        TempCSV.LoadDataFromStream(CSVStream, ',');
                        for Col := 2 to TempCSV.GetNumberOfColumns() do begin
                            TempCSV.Get(1, Col);
                            CurCode := CopyStr(TempCSV.Value, 1, MaxStrLen(CurCode));
                            if CurCode <> '' then begin
                                if not CurRec.Get(CurCode) then begin
                                    CurRec.Init();
                                    CurRec.Code := CurCode;
                                    CurRec.Description := CurCode;
                                    CurRec.Insert(true);
                                end;
                                for Line := 2 to TempCSV.GetNumberOfLines() do begin
                                    ExtRec.Init();
                                    ExtRec."Currency Code" := CurRec.Code;
                                    TempCSV.Get(Line, 1);
                                    evaluate(ExtRec."Starting Date", TempCSV.Value, 9);
                                    ExtRec.Validate("Exchange Rate Amount", 1);
                                    TempCSV.Get(Line, Col);
                                    if evaluate(ExtRec."Relational Exch. Rate Amount", TempCSV.Value, 9) then begin
                                        ExtRec.Validate("Relational Exch. Rate Amount");
                                        ExtRec.Insert(true);
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
            }
        }
    }
}