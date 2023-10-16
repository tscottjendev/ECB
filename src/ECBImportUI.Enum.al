enum 50100 "ECB Import UI" implements "ECB Progress Handler"
    , "ECB Summary Handler"
{
    DefaultImplementation = "ECB Progress Handler" = "ECB Progress Handler Default"
        , "ECB Summary Handler" = "ECB Summary Handler Default";
    Extensible = true;
    UnknownValueImplementation = "ECB Progress Handler" = "ECB Progress Handler Unknown"
        , "ECB Summary Handler" = "ECB Summary Handler Unknown";

    value(0; ShowUI)
    {
        Caption = 'Show UI';
        Implementation = "ECB Progress Handler" = "ECB Progress Handler Show UI"
            , "ECB Summary Handler" = "ECB Summary Handler Show UI";
    }
    value(1; HideUI)
    {
        Caption = 'Hide UI';
        Implementation = "ECB Progress Handler" = "ECB Progress Handler Hide UI"
            , "ECB Summary Handler" = "ECB Summary Handler Hide UI";
    }
}