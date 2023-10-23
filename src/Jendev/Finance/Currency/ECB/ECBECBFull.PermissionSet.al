namespace Jendev.Finance.Currency.ECB;

permissionset 50100 "ECB ECBFull"
{
    Assignable = true;
    Caption = 'ECB Full', MaxLength = 30;
    IncludedPermissionSets = Jendev.Finance.Currency.ECB.UI."ECB UIFull";
    Permissions =
        table "ECB Setup" = X,
        tabledata "ECB Setup" = RIMD,
        codeunit "ECB Import" = X,
        codeunit "ECB Import Impl." = X,
        codeunit "ECB Published Events" = X,
        page "ECB Setup" = X,
        report "ECB Import" = X;
}