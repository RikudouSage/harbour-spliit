#ifndef APPSETTINGS_H
#define APPSETTINGS_H

#include <QObject>
#include <QSettings>
#include <QStandardPaths>
#include <QStringList>

class AppSettings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(QString rawLanguage READ rawLanguage WRITE setRawLanguage NOTIFY rawLanguageChanged)
    Q_PROPERTY(QString currentGroupId READ currentGroupId WRITE setCurrentGroupId NOTIFY currentGroupIdChanged)
    Q_PROPERTY(QStringList storedGroups READ storedGroups WRITE setStoredGroups NOTIFY storedGroupsChanged)
public:
    explicit AppSettings(QObject *parent = nullptr);
    ~AppSettings();

    const QString language() const;
    void setLanguage(const QString &value);
    const QString rawLanguage() const;
    void setRawLanguage(const QString &value);
    const QString currentGroupId() const;
    void setCurrentGroupId(const QString &value);
    const QStringList storedGroups();
    void setStoredGroups(const QStringList &value);

signals:
    void languageChanged();
    void rawLanguageChanged();
    void currentGroupIdChanged();
    void storedGroupsChanged();

private:
    void saveConfig(const QString &name, const QVariant &value);

    QSettings* settings = new QSettings(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/settings.ini",
        QSettings::IniFormat,
        this
    );

    QString prop_language;
    QString prop_currentGroupId;
    QStringList prop_storedGroups;
};

#endif // APPSETTINGS_H
