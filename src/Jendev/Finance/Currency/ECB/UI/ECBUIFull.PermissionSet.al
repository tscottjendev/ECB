namespace Jendev.Finance.Currency.ECB.UI;

permissionset 50101 "ECB UIFull"
{
    Assignable = true;
    Caption = 'ECB Full', MaxLength = 30;
    Permissions =
        codeunit "ECB Progress Handler Default" = X,
        codeunit "ECB Progress Handler Hide UI" = X,
        codeunit "ECB Progress Handler Show UI" = X,
        codeunit "ECB Progress Handler Unknown" = X,
        codeunit "ECB Summary Handler Default" = X,
        codeunit "ECB Summary Handler Hide UI" = X,
        codeunit "ECB Summary Handler Show UI" = X,
        codeunit "ECB Summary Handler Unknown" = X;
}