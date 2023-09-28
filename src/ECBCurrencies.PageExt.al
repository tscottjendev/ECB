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
                var
                    ECBImport: Report "ECB Import";
                begin
                    ECBImport.Run();
                end;
            }
        }
    }

}