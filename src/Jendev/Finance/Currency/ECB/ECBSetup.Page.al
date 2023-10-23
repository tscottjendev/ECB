namespace Jendev.Finance.Currency.ECB;

page 50100 "ECB Setup"
{
    ApplicationArea = All;
    Caption = 'ECB Setup';
    PageType = Card;
    SourceTable = "ECB Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("Download URL"; Rec."Download URL")
                {
                    ToolTip = 'Specifies the download URL to the ECB historical rates file.';
                }
                field("Last Exchange Date Imported"; Rec."Last Exchange Date Imported")
                {
                    ToolTip = 'Specifies the last exchange date for which the ECB historical rates file was imported.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetDefaultDataAction)
            {
                Caption = 'Set Default Data';
                Image = CreateForm;
                ToolTip = 'Sets the default data for the ECB Import';
                Visible = IsSetDefaultDataActionVisible;

                trigger OnAction()
                begin
                    Rec.SetupDefaultData();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        IsSetDefaultDataActionVisible: Boolean;

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
        SetDefaultDataActionVisible();
    end;

    local procedure SetDefaultDataActionVisible()
    begin
        IsSetDefaultDataActionVisible := not Rec.IsConfigured();
    end;
}
