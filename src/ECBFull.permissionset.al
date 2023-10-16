namespace Jendev.Finance.Currency;

permissionset 50100 ECBFull
{
    Assignable = true;
    Caption = 'ECB Full', MaxLength = 30;
    Permissions =
        table "ECB Setup" = X,
        tabledata "ECB Setup" = RIMD,
        codeunit "ECB Import" = X,
        codeunit "ECB Import Impl." = X,
        codeunit "ECB Progress Handler Default" = X,
        codeunit "ECB Progress Handler Hide UI" = X,
        codeunit "ECB Progress Handler Show UI" = X,
        codeunit "ECB Progress Handler Unknown" = X,
        codeunit "ECB Published Events" = X,
        codeunit "ECB Summary Handler Default" = X,
        codeunit "ECB Summary Handler Hide UI" = X,
        codeunit "ECB Summary Handler Show UI" = X,
        codeunit "ECB Summary Handler Unknown" = X,
        page "ECB Setup" = X,
        report "ECB Import" = X;
}