namespace Jendev.Finance.Currency.ECB;

report 50100 "ECB Import"
{
    ApplicationArea = All;
    Caption = 'ECB Import';
    ProcessingOnly = true;
    UsageCategory = Administration;

    dataset { }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(General)
                {
                    Caption = 'General';

                    field(ShowProgressField; ShowProgress)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Progress Window';
                        ToolTip = 'Specifies if you want to see the progress of the import, set this option.  Do NOT set this option if you are scheduling the report or running the report through the job queue.';
                    }
                    field(ShowSummaryField; ShowSummary)
                    {
                        ApplicationArea = All;
                        Caption = 'Show Summary Window';
                        ToolTip = 'Specifies if you want to see the summary of the import after the report is complete, set this option.  Do NOT set this option if you are scheduling or using the job queue.';
                    }
                }
            }
        }
    }

    trigger OnPostReport()
    var
        ECBImport: Codeunit "ECB Import";
    begin
        ECBImport.ImportExchangeRates(ShowProgress, ShowSummary);
    end;

    var
        ShowProgress: Boolean;
        ShowSummary: Boolean;
}