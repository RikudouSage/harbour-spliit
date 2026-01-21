#include "currencyinfo.h"

#include <QVariantMap>
#include <QVector>

#include <unicode/ucurr.h>
#include <unicode/uenum.h>
#include <unicode/unum.h>
#include <unicode/ustring.h>

namespace {
QString toIcuLocale(const QString &languageTag)
{
    if (languageTag.isEmpty()) {
        return QStringLiteral("en");
    }
    QString locale = languageTag;
    locale.replace('-', '_');
    return locale;
}

QString uCharToQString(const UChar *data, int32_t length)
{
    if (!data || length <= 0) {
        return QString();
    }
    return QString::fromUtf16(reinterpret_cast<const char16_t *>(data), length);
}
}

CurrencyInfo::CurrencyInfo(QObject *parent)
    : QObject(parent)
{
}

QStringList CurrencyInfo::allCurrencyCodes() const
{
    QStringList codes;
    UErrorCode status = U_ZERO_ERROR;
    UEnumeration *en = ucurr_openISOCurrencies(UCURR_COMMON | UCURR_NON_DEPRECATED, &status);
    if (U_FAILURE(status) || !en) {
        return codes;
    }

    int32_t length = 0;
    const char *code = nullptr;
    while ((code = uenum_next(en, &length, &status)) != nullptr && U_SUCCESS(status)) {
        codes.append(QString::fromUtf8(code, length));
    }

    uenum_close(en);
    return codes;
}

QVariantList CurrencyInfo::infoForCodes(const QStringList &codes, const QString &languageTag) const
{
    const QString locale = toIcuLocale(languageTag);
    QVariantList result;
    result.reserve(codes.size());

    for (const QString &code : codes) {
        QVariantMap entry;
        entry.insert(QStringLiteral("code"), code);

        UErrorCode status = U_ZERO_ERROR;
        UChar ucode[4] = {0};
        int32_t ucodeLen = 0;
        u_strFromUTF8(ucode, 4, &ucodeLen, code.toUtf8().constData(), -1, &status);

        QString symbol = code;
        QString name = code;
        if (U_SUCCESS(status)) {
            UBool isChoiceFormat = false;

            status = U_ZERO_ERROR;
            int32_t symbolLen = 0;
            const UChar *symbolPtr = ucurr_getName(ucode, locale.toUtf8().constData(),
                                                   UCURR_SYMBOL_NAME, &isChoiceFormat,
                                                   &symbolLen, &status);
            if (U_SUCCESS(status) && symbolPtr) {
                symbol = uCharToQString(symbolPtr, symbolLen);
            }

            status = U_ZERO_ERROR;
            int32_t nameLen = 0;
            const UChar *namePtr = ucurr_getName(ucode, locale.toUtf8().constData(),
                                                 UCURR_LONG_NAME, &isChoiceFormat,
                                                 &nameLen, &status);
            if (U_SUCCESS(status) && namePtr) {
                name = uCharToQString(namePtr, nameLen);
            }
        }

        entry.insert(QStringLiteral("code"), code);
        entry.insert(QStringLiteral("symbol"), symbol);
        entry.insert(QStringLiteral("name"), name);
        result.append(entry);
    }

    return result;
}

QString CurrencyInfo::formatCurrency(double amount, const QString &currencyCode,
                                      const QString &languageTag) const
{
    const QString locale = toIcuLocale(languageTag);

    UErrorCode status = U_ZERO_ERROR;
    UChar ucode[4] = {0};
    int32_t ucodeLen = 0;
    u_strFromUTF8(ucode, 4, &ucodeLen, currencyCode.toUtf8().constData(), -1, &status);
    if (U_FAILURE(status) || ucodeLen <= 0) {
        return QString();
    }

    status = U_ZERO_ERROR;
    UNumberFormat *format = unum_open(UNUM_CURRENCY, nullptr, 0,
                                      locale.toUtf8().constData(), nullptr, &status);
    if (U_FAILURE(status) || !format) {
        return QString();
    }

    status = U_ZERO_ERROR;
    unum_setTextAttribute(format, UNUM_CURRENCY_CODE, ucode, ucodeLen, &status);
    if (U_FAILURE(status)) {
        unum_close(format);
        return QString();
    }

    UChar stackBuffer[64] = {0};
    status = U_ZERO_ERROR;
    int32_t length = unum_formatDouble(format, amount, stackBuffer,
                                       sizeof(stackBuffer) / sizeof(UChar), nullptr, &status);
    QString result;
    if (status == U_BUFFER_OVERFLOW_ERROR) {
        status = U_ZERO_ERROR;
        QVector<UChar> heapBuffer(length + 1);
        length = unum_formatDouble(format, amount, heapBuffer.data(),
                                   heapBuffer.size(), nullptr, &status);
        if (U_SUCCESS(status)) {
            result = uCharToQString(heapBuffer.data(), length);
        }
    } else if (U_SUCCESS(status)) {
        result = uCharToQString(stackBuffer, length);
    }

    unum_close(format);
    return result;
}
