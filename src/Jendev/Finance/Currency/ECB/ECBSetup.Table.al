namespace Jendev.Finance.Currency.ECB;

table 50100 "ECB Setup"
{
    Access = Internal;
    Caption = 'ECB Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            NotBlank = false;
        }
        field(10; "Download URL"; Text[250])
        {
            Caption = 'Download URL';
        }
        field(11; "Last Exchange Date Imported"; Date)
        {
            Caption = 'Last Exchange Date Imported';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        RecordHasBeenRead: Boolean;

    protected var
        FieldNotDefinedMsg: Label '%1 is not defined.', Comment = '%1=Field caption';
        OpenSetupPageLbl: Label 'Open Setup Page';

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure GetRecordOnceAgain()
    begin
        RecordHasBeenRead := false;
        GetRecordOnce();
    end;

    procedure InsertIfNotExists()
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;

    procedure SetupDefaultData()
    var
        EuroFXRefUrlTok: Label 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.zip', Locked = true;
    begin
        InsertIfNotExists();
        "Download URL" := EuroFXRefUrlTok;
        Modify(true);
    end;

    internal procedure GetDownloadURL(): Text
    var
        ECBSetup: Record "ECB Setup";
    begin
        ECBSetup.GetRecordOnce();
        exit(ECBSetup."Download URL");
    end;

    internal procedure IsConfigured(): Boolean
    var
        Configured: Boolean;
        Ishandled: Boolean;
    begin
        Configured := false;

        OnBeforeIsConfigured(Configured, Ishandled);
        if Ishandled then
            exit;

        Configured := Configured or ("Download URL" <> '');

        OnAfterIsConfigured(Configured);

        exit(Configured);
    end;

    internal procedure TestSetupForImport()
    begin
        TestDownloadURL();

        OnTestSetupForImport();
    end;

    local procedure TestDownloadURL()
    var
        CollectibleError: ErrorInfo;
        DetailInfoMsg: Label 'The %1 is required to allow the import of exchange rates from the European Central Bank.', Comment = '%1= is field caption';
    begin
        CollectibleError := ErrorInfo.Create();
        CollectibleError.Message := StrSubstNo(FieldNotDefinedMsg, FieldCaption("Download URL"));
        CollectibleError.DetailedMessage := StrSubstNo(DetailInfoMsg, FieldCaption("Download URL"));
        CollectibleError.Collectible := true;
        CollectibleError.RecordId := Rec.RecordId();
        CollectibleError.FieldNo := FieldNo("Download URL");
        CollectibleError.Verbosity := Verbosity::Critical;
        CollectibleError.PageNo := Page::"ECB Setup";
        CollectibleError.AddNavigationAction(OpenSetupPageLbl);
        if ("Download URL" = '') then
            Error(CollectibleError);

    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsConfigured(var Configured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsConfigured(var Configured: Boolean; var Ishandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnTestSetupForImport()
    begin
    end;
}