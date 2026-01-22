import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

SafePage {
    id: page

    allowedOrientations: Orientation.All

    BusyLabel {
        //% "Loading..."
        text: qsTrId("global.loading")
        running: true
    }

    Component.onCompleted: {
        if (!currencyInfo.isValid()) {
            safeCall(function() {
                pageStack.replace("ErrorPage.qml", {
                    //% "Currency Initialization Failed"
                    title: qsTrId("page.init.currency_initialization_failed"),
                    //% "Currency formatting libraries failed to load. Please reinstall the app or contact the developer."
                    errorText: qsTrId("page.init.currency_initialization_failed_description")
                });
            });
            return;
        }

        if (!spliit.isValid()) {
            safeCall(function() {
                pageStack.replace("ErrorPage.qml", {
                    //% "Initialization Failed"
                    title: qsTrId("page.init.initialization_failed"),
                    //% "The initialization of the app failed. There's not much you can do about it except contacting the developer."
                    errorText: qsTrId("page.init.initialization_failed_description")
                });
            });
            return;
        }

        if (!settings.currentGroupId) {
            safeCall(function() {
                pageStack.replace("GroupSelectorPage.qml");
            });
        } else {
            safeCall(function() {
                pageStack.replace("GroupDetailPage.qml");
            });
        }
    }
}
