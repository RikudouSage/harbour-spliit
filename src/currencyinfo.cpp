#include "currencyinfo.h"

#include <QVariantMap>
#include <QVector>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QLibrary>

#include <unicode/ucurr.h>
#include <unicode/uenum.h>
#include <unicode/unum.h>
#include <unicode/ustring.h>

namespace {
constexpr const char *kIcuLibDir = "/usr/share/harbour-spliit/lib/";

template <typename T>
bool resolveSymbol(QLibrary &lib, const char *name, T &out, QStringList *missing = nullptr)
{
    out = reinterpret_cast<T>(lib.resolve(name));
    if (!out && missing) {
        missing->append(QString::fromLatin1(name));
    }
    return out != nullptr;
}

bool loadLibrary(QLibrary &lib, const QStringList &candidates, QLibrary::LoadHints hints, QString *errorOut = nullptr)
{
    QString lastError;
    for (const QString &candidate : candidates) {
        lib.setFileName(candidate);
        lib.setLoadHints(hints);
        if (lib.load()) {
            return true;
        }
        lastError = lib.errorString();
    }
    if (errorOut && !lastError.isEmpty()) {
        *errorOut = lastError;
    }
    return false;
}

QVector<int> parseVersion(const QString &name, const QString &prefix)
{
    if (!name.startsWith(prefix)) {
        return {};
    }
    const QString suffix = name.mid(prefix.size());
    if (suffix.isEmpty()) {
        return {};
    }
    const QStringList parts = suffix.split('.', QString::SkipEmptyParts);
    QVector<int> version;
    version.reserve(parts.size());
    for (const QString &part : parts) {
        bool ok = false;
        const int value = part.toInt(&ok);
        if (!ok) {
            return {};
        }
        version.append(value);
    }
    return version;
}

bool isVersionGreater(const QVector<int> &a, const QVector<int> &b)
{
    const int count = qMax(a.size(), b.size());
    for (int i = 0; i < count; ++i) {
        const int av = i < a.size() ? a.at(i) : 0;
        const int bv = i < b.size() ? b.at(i) : 0;
        if (av != bv) {
            return av > bv;
        }
    }
    return false;
}

QString bestVersionedLibraryInDir(const QString &dirPath, const QString &baseName)
{
    QDir dir(dirPath);
    if (!dir.exists()) {
        return QString();
    }
    const QString prefix = baseName + ".so.";
    const QStringList entries = dir.entryList(QStringList() << (baseName + ".so.*"), QDir::Files);
    QString bestName;
    QVector<int> bestVersion;
    for (const QString &entry : entries) {
        const QVector<int> version = parseVersion(entry, prefix);
        if (version.isEmpty()) {
            continue;
        }
        if (bestName.isEmpty() || isVersionGreater(version, bestVersion)) {
            bestName = entry;
            bestVersion = version;
        }
    }
    if (bestName.isEmpty()) {
        return QString();
    }
    return dir.absoluteFilePath(bestName);
}

QString &icuLastError()
{
    static QString error;
    return error;
}

struct IcuFunctions {
    bool ok = false;

    QLibrary dataLib;
    QLibrary ucLib;
    QLibrary i18nLib;

    UEnumeration *(*ucurr_openISOCurrencies)(uint32_t, UErrorCode *) = nullptr;
    const char *(*uenum_next)(UEnumeration *, int32_t *, UErrorCode *) = nullptr;
    void (*uenum_close)(UEnumeration *) = nullptr;
    const UChar *(*ucurr_getName)(const UChar *, const char *, UCurrNameStyle, UBool *, int32_t *, UErrorCode *) = nullptr;
    void (*u_strFromUTF8)(UChar *, int32_t, int32_t *, const char *, int32_t, UErrorCode *) = nullptr;
    UNumberFormat *(*unum_open)(UNumberFormatStyle, const UChar *, int32_t, const char *, UParseError *, UErrorCode *) = nullptr;
    void (*unum_setTextAttribute)(UNumberFormat *, UNumberFormatTextAttribute, const UChar *, int32_t, UErrorCode *) = nullptr;
    int32_t (*unum_formatDouble)(const UNumberFormat *, double, UChar *, int32_t, UFieldPosition *, UErrorCode *) = nullptr;
    void (*unum_close)(UNumberFormat *) = nullptr;
    void (*unum_setSymbol)(UNumberFormat *, UNumberFormatSymbol, const UChar *, int32_t, UErrorCode *) = nullptr;
};

IcuFunctions &icuFunctions()
{
    static IcuFunctions fns;
    static bool initialized = false;
    if (initialized) {
        return fns;
    }
    initialized = true;

    const QString base = QString::fromUtf8(kIcuLibDir);
    const QStringList libDirs = {
        base,
        QStringLiteral("/usr/lib/"),
        QStringLiteral("/usr/lib64/"),
        QStringLiteral("/lib/"),
        QStringLiteral("/lib64/")
    };
    const QStringList dataNames = {
        QStringLiteral("libicudata.so")
    };
    const QStringList ucNames = {
        QStringLiteral("libicuuc.so")
    };
    const QStringList i18nNames = {
        QStringLiteral("libicui18n.so")
    };
    QStringList dataCandidates;
    QStringList ucCandidates;
    QStringList i18nCandidates;
    for (const QString &dir : libDirs) {
        const QString dataBest = bestVersionedLibraryInDir(dir, QStringLiteral("libicudata"));
        if (!dataBest.isEmpty()) {
            dataCandidates.append(dataBest);
        }
        const QString ucBest = bestVersionedLibraryInDir(dir, QStringLiteral("libicuuc"));
        if (!ucBest.isEmpty()) {
            ucCandidates.append(ucBest);
        }
        const QString i18nBest = bestVersionedLibraryInDir(dir, QStringLiteral("libicui18n"));
        if (!i18nBest.isEmpty()) {
            i18nCandidates.append(i18nBest);
        }
        for (const QString &name : dataNames) {
            dataCandidates.append(dir + name);
        }
        for (const QString &name : ucNames) {
            ucCandidates.append(dir + name);
        }
        for (const QString &name : i18nNames) {
            i18nCandidates.append(dir + name);
        }
    }
    dataCandidates.append(QStringLiteral("icudata"));
    ucCandidates.append(QStringLiteral("icuuc"));
    i18nCandidates.append(QStringLiteral("icui18n"));

    QString dataError;
    QString ucError;
    QString i18nError;
    const bool dataLoaded = loadLibrary(fns.dataLib, dataCandidates, QLibrary::ExportExternalSymbolsHint, &dataError);
    const bool ucLoaded = loadLibrary(fns.ucLib, ucCandidates, QLibrary::ExportExternalSymbolsHint, &ucError);
    const bool i18nLoaded = loadLibrary(fns.i18nLib, i18nCandidates, QLibrary::ExportExternalSymbolsHint, &i18nError);

    if (!dataLoaded || !ucLoaded || !i18nLoaded) {
        QStringList details;
        if (!dataLoaded) {
            details.append(QStringLiteral("icudata: %1").arg(dataError.isEmpty() ? QStringLiteral("not found") : dataError));
        }
        if (!ucLoaded) {
            details.append(QStringLiteral("icuuc: %1").arg(ucError.isEmpty() ? QStringLiteral("not found") : ucError));
        }
        if (!i18nLoaded) {
            details.append(QStringLiteral("icui18n: %1").arg(i18nError.isEmpty() ? QStringLiteral("not found") : i18nError));
        }
        icuLastError() = QStringLiteral("Failed to load ICU libraries (%1)").arg(details.join(QStringLiteral("; ")));
        return fns;
    }

    bool ok = true;
    QStringList missing;
    ok &= resolveSymbol(fns.i18nLib, "ucurr_openISOCurrencies", fns.ucurr_openISOCurrencies, &missing);
    ok &= resolveSymbol(fns.i18nLib, "ucurr_getName", fns.ucurr_getName, &missing);
    ok &= resolveSymbol(fns.i18nLib, "unum_open", fns.unum_open, &missing);
    ok &= resolveSymbol(fns.i18nLib, "unum_setTextAttribute", fns.unum_setTextAttribute, &missing);
    ok &= resolveSymbol(fns.i18nLib, "unum_formatDouble", fns.unum_formatDouble, &missing);
    ok &= resolveSymbol(fns.i18nLib, "unum_close", fns.unum_close, &missing);
    ok &= resolveSymbol(fns.i18nLib, "unum_setSymbol", fns.unum_setSymbol, &missing);
    ok &= resolveSymbol(fns.ucLib, "uenum_next", fns.uenum_next, &missing);
    ok &= resolveSymbol(fns.ucLib, "uenum_close", fns.uenum_close, &missing);
    ok &= resolveSymbol(fns.ucLib, "u_strFromUTF8", fns.u_strFromUTF8, &missing);

    fns.ok = ok;
    if (!ok) {
        icuLastError() = QStringLiteral("Failed to resolve ICU symbols (%1)").arg(missing.join(QStringLiteral(", ")));
    }
    return fns;
}

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
    const auto &icuFns = icuFunctions();
    if (!icuFns.ok) {
        m_valid = false;
        m_error = icuLastError();
        emit icuLoadFailed(m_error);
    }
}

bool CurrencyInfo::isValid() const
{
    return m_valid;
}

QString CurrencyInfo::error() const
{
    return m_error;
}

QStringList CurrencyInfo::allCurrencyCodes() const
{
    QStringList codes;
    const auto &icuFns = icuFunctions();
    if (!icuFns.ok) {
        return codes;
    }
    UErrorCode status = U_ZERO_ERROR;
    UEnumeration *en = icuFns.ucurr_openISOCurrencies(UCURR_COMMON | UCURR_NON_DEPRECATED, &status);
    if (U_FAILURE(status) || !en) {
        return codes;
    }

    int32_t length = 0;
    const char *code = nullptr;
    while ((code = icuFns.uenum_next(en, &length, &status)) != nullptr && U_SUCCESS(status)) {
        codes.append(QString::fromUtf8(code, length));
    }

    icuFns.uenum_close(en);
    return codes;
}

QVariantList CurrencyInfo::infoForCodes(const QStringList &codes, const QString &languageTag) const
{
    const QString locale = toIcuLocale(languageTag);
    QVariantList result;
    result.reserve(codes.size());
    const auto &icuFns = icuFunctions();
    if (!icuFns.ok) {
        return result;
    }

    for (const QString &code : codes) {
        QVariantMap entry;
        entry.insert(QStringLiteral("code"), code);

        UErrorCode status = U_ZERO_ERROR;
        UChar ucode[4] = {0};
        int32_t ucodeLen = 0;
        icuFns.u_strFromUTF8(ucode, 4, &ucodeLen, code.toUtf8().constData(), -1, &status);

        QString symbol = code;
        QString name = code;
        if (U_SUCCESS(status)) {
            UBool isChoiceFormat = false;

            status = U_ZERO_ERROR;
            int32_t symbolLen = 0;
            const UChar *symbolPtr = icuFns.ucurr_getName(ucode, locale.toUtf8().constData(),
                                                   UCURR_SYMBOL_NAME, &isChoiceFormat,
                                                   &symbolLen, &status);
            if (U_SUCCESS(status) && symbolPtr) {
                symbol = uCharToQString(symbolPtr, symbolLen);
            }

            status = U_ZERO_ERROR;
            int32_t nameLen = 0;
            const UChar *namePtr = icuFns.ucurr_getName(ucode, locale.toUtf8().constData(),
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
    const auto &icuFns = icuFunctions();
    if (!icuFns.ok) {
        return QString();
    }

    UErrorCode status = U_ZERO_ERROR;
    UChar ucode[4] = {0};
    int32_t ucodeLen = 0;
    icuFns.u_strFromUTF8(ucode, 4, &ucodeLen, currencyCode.toUtf8().constData(), -1, &status);
    if (U_FAILURE(status) || ucodeLen <= 0) {
        return QString();
    }

    status = U_ZERO_ERROR;
    UNumberFormat *format = icuFns.unum_open(UNUM_CURRENCY, nullptr, 0,
                                      locale.toUtf8().constData(), nullptr, &status);
    if (U_FAILURE(status) || !format) {
        return QString();
    }

    status = U_ZERO_ERROR;
    icuFns.unum_setTextAttribute(format, UNUM_CURRENCY_CODE, ucode, ucodeLen, &status);
    if (U_FAILURE(status)) {
        icuFns.unum_close(format);
        return QString();
    }

    UChar stackBuffer[64] = {0};
    status = U_ZERO_ERROR;
    int32_t length = icuFns.unum_formatDouble(format, amount, stackBuffer,
                                       sizeof(stackBuffer) / sizeof(UChar), nullptr, &status);
    QString result;
    if (status == U_BUFFER_OVERFLOW_ERROR) {
        status = U_ZERO_ERROR;
        QVector<UChar> heapBuffer(length + 1);
        length = icuFns.unum_formatDouble(format, amount, heapBuffer.data(),
                                   heapBuffer.size(), nullptr, &status);
        if (U_SUCCESS(status)) {
            result = uCharToQString(heapBuffer.data(), length);
        }
    } else if (U_SUCCESS(status)) {
        result = uCharToQString(stackBuffer, length);
    }

    icuFns.unum_close(format);
    return result;
}

QString CurrencyInfo::formatNumber(double amount, const QString &languageTag) const
{
    const QString locale = toIcuLocale(languageTag);
    const auto &icuFns = icuFunctions();
    if (!icuFns.ok) {
        return QString();
    }

    UErrorCode status = U_ZERO_ERROR;
    UNumberFormat *format = icuFns.unum_open(UNUM_CURRENCY, nullptr, 0,
                                      locale.toUtf8().constData(), nullptr, &status);
    if (U_FAILURE(status) || !format) {
        return QString();
    }

    const UChar empty[1] = {0};
    status = U_ZERO_ERROR;
    icuFns.unum_setSymbol(format, UNUM_CURRENCY_SYMBOL, empty, 0, &status);
    if (U_FAILURE(status)) {
        icuFns.unum_close(format);
        return QString();
    }

    status = U_ZERO_ERROR;
    icuFns.unum_setSymbol(format, UNUM_INTL_CURRENCY_SYMBOL, empty, 0, &status);
    if (U_FAILURE(status)) {
        icuFns.unum_close(format);
        return QString();
    }

    UChar stackBuffer[64] = {0};
    status = U_ZERO_ERROR;
    int32_t length = icuFns.unum_formatDouble(format, amount, stackBuffer,
                                       sizeof(stackBuffer) / sizeof(UChar), nullptr, &status);
    QString result;
    if (status == U_BUFFER_OVERFLOW_ERROR) {
        status = U_ZERO_ERROR;
        QVector<UChar> heapBuffer(length + 1);
        length = icuFns.unum_formatDouble(format, amount, heapBuffer.data(),
                                   heapBuffer.size(), nullptr, &status);
        if (U_SUCCESS(status)) {
            result = uCharToQString(heapBuffer.data(), length);
        }
    } else if (U_SUCCESS(status)) {
        result = uCharToQString(stackBuffer, length);
    }

    icuFns.unum_close(format);
    return result.trimmed();
}
