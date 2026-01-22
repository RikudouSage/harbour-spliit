# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-spliit

QT += concurrent

harbour_store {
    DEFINES += ICU_DYNAMIC
} else {
    PKGCONFIG += icu-uc icu-i18n
}
#PKGCONFIG += icu-uc icu-i18n
GO_LIB_BUILD_DIR = $$PWD/lib
GO_LIB_INSTALL_DIR = /usr/share/$$TARGET/lib

INCLUDEPATH += $$GO_LIB_BUILD_DIR
LIBS += -L$$GO_LIB_BUILD_DIR -lspliit
QMAKE_RPATHDIR += $$GO_LIB_INSTALL_DIR

GO_LIBDIR = /usr/share/$$TARGET/lib
INCLUDEPATH += $$PWD/lib
LIBS += -L$$GO_LIBDIR -lspliit

QMAKE_RPATHDIR += $$GO_LIBDIR

CONFIG += sailfishapp

SOURCES += src/harbour-spliit.cpp \
    src/appsettings.cpp \
    src/currencyinfo.cpp \
    src/spliitapi.cpp

libspliit.path = /usr/share/harbour-spliit/lib
libspliit.files = lib/*.so

INSTALLS += libspliit

DISTFILES += qml/harbour-spliit.qml \
    qml/components/DefaultDialog.qml \
    qml/components/DefaultPage.qml \
    qml/components/ExpenseRow.qml \
    qml/components/NotificationBanner.qml \
    qml/components/NotificationStack.qml \
    qml/components/StandardLabel.qml \
    qml/cover/CoverPage.qml \
    qml/js/arrays.js \
    qml/js/currencies.js \
    qml/js/objects.js \
    qml/js/strings.js \
    qml/pages/AddExpenseDialog.qml \
    qml/pages/AddGroupDialog.qml \
    qml/pages/GroupDetailPage.qml \
    qml/pages/GroupSelectorPage.qml \
    qml/pages/InitialPage.qml \
    qml/pages/ErrorPage.qml \
    qml/components/SafePage.qml \
    qml/pages/SelectCategoryDialog.qml \
    qml/pages/SelectCurrencyDialog.qml \
    qml/pages/SelectParticipantDialog.qml \
    qml/pages/SettingsDialog.qml \
    rpm/harbour-spliit.changes.in \
    rpm/harbour-spliit.changes.run.in \
    rpm/harbour-spliit.spec \
    translations/*.ts \
    harbour-spliit.desktop\
    lib/libspliit.so

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n sailfishapp_i18n_idbased

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-spliit-en.ts \
                translations/harbour-spliit-cs.ts

HEADERS += \
    src/appsettings.h \
    src/currencyinfo.h \
    lib/libspliit.h \
    src/spliitapi.h
