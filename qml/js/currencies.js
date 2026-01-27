.import "strings.js" as Strings

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

function parseCentsToAmount(input) {
    var amount = Strings.leftPad(String(input), 3, '0');
    amount = Strings.insertAt(amount, ".", -2);

    return amount;
}

function parseAmountToCents(input) {
    if (input === undefined || input === null) {
        return NaN;
    }

    var text = String(input).trim();
    if (text === '') {
        return NaN;
    }

    var negative = text[0] === '-';
    if (negative) {
        text = text.slice(1);
    }

    text = text.replace(/\s+/g, '');

    var lastDot = text.lastIndexOf('.');
    var lastComma = text.lastIndexOf(',');
    var decimalSep = '';

    if (lastDot !== -1 && lastComma !== -1) {
        decimalSep = lastDot > lastComma ? '.' : ',';
    } else if (lastDot !== -1) {
        decimalSep = '.';
    } else if (lastComma !== -1) {
        decimalSep = ',';
    }

    var integerPart = '';
    var fractionPart = '';

    if (decimalSep) {
        var splitIndex = text.lastIndexOf(decimalSep);
        integerPart = text.slice(0, splitIndex).replace(/[^0-9]/g, '');
        fractionPart = text.slice(splitIndex + 1).replace(/[^0-9]/g, '');
    } else {
        integerPart = text.replace(/[^0-9]/g, '');
    }

    if (integerPart === '' && fractionPart === '') {
        return NaN;
    }

    if (fractionPart.length > 2) {
        fractionPart = fractionPart.slice(0, 2);
    } else if (fractionPart.length === 1) {
        fractionPart = fractionPart + '0';
    } else if (fractionPart.length === 0) {
        fractionPart = '00';
    }

    var cents = (Number(integerPart || '0') * 100) + Number(fractionPart || '0');
    return negative ? -cents : cents;
}
