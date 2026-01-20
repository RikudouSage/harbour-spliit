function get(locale) {
    return currencyInfo.infoForCodes(currencyInfo.allCurrencyCodes(), locale);
}

function getAsMap(locale) {
    var currencies = currencyInfo.infoForCodes(currencyInfo.allCurrencyCodes(), locale);
    var result = {};

    for (var i in currencies) {
        if (!currencies.hasOwnProperty(i)) {
            continue;
        }

        var currency = currencies[i];
        result[currency.code] = currency;
    }

    return result;
}
