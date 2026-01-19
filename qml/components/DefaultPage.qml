import QtQuick 2.0
import Sailfish.Silica 1.0

SafePage {
    property alias title: pageHeader.title
    property alias loading: loader.running
    //% "Loading..."
    property string loadText: qsTrId("global.loading")
    default property alias main: column.data

    BusyLabel {
        id: loader
        text: loadText
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: page.width
            visible: !loading

            PageHeader {
                id: pageHeader
            }
        }
    }
}
