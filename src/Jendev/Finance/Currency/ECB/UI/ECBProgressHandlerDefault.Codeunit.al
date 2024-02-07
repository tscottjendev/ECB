namespace Jendev.Finance.Currency.ECB.UI;

codeunit 50101 "ECB Progress Handler Default" implements "ECB Progress Handler"
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
        IsOpen := false;
        if not GuiAllowed() then
            exit;

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