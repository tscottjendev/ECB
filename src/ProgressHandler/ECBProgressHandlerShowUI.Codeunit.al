namespace Jendev.Finance.Currency;

codeunit 50103 "ECB Progress Handler Show UI" implements "ECB Progress Handler"
{
    var
        IsOpen: Boolean;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing...#1########', Comment = '#1 is the Currency Code';

    procedure CloseProgress()
    begin
        if IsOpen then
            ProgressDialog.Close();
    end;

    procedure OpenProgress()
    begin
        ProgressDialog.Open(ProgressMsg);
        IsOpen := true;
    end;

    procedure UpdateProgress(CurrencyCode: Code[10])
    begin
        if not IsOpen then
            exit;

        ProgressDialog.Update(1, CurrencyCode);
    end;
}