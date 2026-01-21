#include "appsettings.h"

#include <QLocale>

AppSettings::AppSettings(QObject *parent) : QObject(parent)
{
    prop_language = settings->value("language", "").toString();
    prop_currentGroupId = settings->value("currentGroupId", "").toString();
    prop_storedGroups = settings->value("storedGroups").toStringList();
    prop_currentParticipantId = settings->value("currentParticipantId", "").toString();
}

AppSettings::~AppSettings() {
    settings->sync();
}

const QString AppSettings::language() const
{
    if (prop_language != "") {
        return prop_language;
    }

    return QLocale::languageToString(QLocale::system().language()).toLower();
}

void AppSettings::setLanguage(const QString &value)
{
    setRawLanguage(value);
}

const QString AppSettings::rawLanguage() const
{
    return prop_language;
}

void AppSettings::setRawLanguage(const QString &value)
{
    if (value == prop_language) {
        return;
    }

    settings->setValue("language", value);
    prop_language = value;

    emit languageChanged();
    emit rawLanguageChanged();
}

const QString AppSettings::currentGroupId() const
{
    return prop_currentGroupId;
}

void AppSettings::setCurrentGroupId(const QString &value)
{
    if (value == prop_currentGroupId) {
        return;
    }

    settings->setValue("currentGroupId", value);
    prop_currentGroupId = value;

    emit currentGroupIdChanged();
}

const QStringList AppSettings::storedGroups()
{
    return prop_storedGroups;
}

void AppSettings::setStoredGroups(const QStringList &value)
{
    if (value == prop_storedGroups) {
        return;
    }

    settings->setValue("storedGroups", value);
    prop_storedGroups = value;

    emit storedGroupsChanged();
}

const QString AppSettings::currentParticipantId() const
{
    return prop_currentParticipantId;
}

void AppSettings::setCurrentParticipantId(const QString &value)
{
    if (value == prop_currentParticipantId) {
        return;
    }

    settings->setValue("currentParticipantId", value);
    prop_currentParticipantId = value;

    emit currentParticipantIdChanged();
}
