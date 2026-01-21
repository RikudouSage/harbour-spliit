#ifndef CURRENCYINFO_H
#define CURRENCYINFO_H

#include <QObject>
#include <QStringList>
#include <QVariant>

class CurrencyInfo : public QObject
{
    Q_OBJECT

public:
    explicit CurrencyInfo(QObject *parent = nullptr);

    Q_INVOKABLE QStringList allCurrencyCodes() const;
    Q_INVOKABLE QVariantList infoForCodes(const QStringList &codes, const QString &languageTag) const;
    Q_INVOKABLE QString formatCurrency(double amount, const QString &currencyCode, const QString &languageTag) const;
};

#endif // CURRENCYINFO_H
