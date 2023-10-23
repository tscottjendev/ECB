namespace Jendev.Finance.Currency.ECB;

tableextension 50100 "ECB CSV Buffer" extends System.IO."CSV Buffer"
{
    /// <summary>
    /// This function converts the current record's value to a date.
    /// </summary>
    /// <param name="DateVar">The date variable to store the converted value.</param>
    /// <returns>True if the conversion is successful, otherwise false.</returns>
    procedure Convert(var DateVar: Date): Boolean
    begin
        exit(Evaluate(DateVar, Value, 9));
    end;

    /// <summary>
    /// This function converts the current record's value to a decimal.
    /// </summary>
    /// <param name="DecimalVar">The decimal variable to store the converted value.</param>
    /// <returns>True if the conversion is successful, otherwise false.</returns>
    procedure Convert(var DecimalVar: Decimal): Boolean
    begin
        exit(Evaluate(DecimalVar, Value, 9));
    end;

    /// <summary>
    /// This function gets the record of the for the latest exchange rate date and returns the data.
    /// </summary>
    /// <returns>The most recent exchange rate date.</returns>
    procedure GetLatestExchangeRateDate() ExchangeRateDate: Date
    begin
        Get(2, 1);
        if Convert(ExchangeRateDate) then
            exit(ExchangeRateDate);

        exit(0D);
    end;

}