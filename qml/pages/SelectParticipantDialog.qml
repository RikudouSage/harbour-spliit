import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

Page {
    property alias participants: listView.model
    signal itemSelected(string id)

    SilicaListView {
        id: listView
        anchors.fill: parent
        header: PageHeader {
            //% "Choose a participant"
            title: qsTrId("participant_select.title")
        }

        VerticalScrollDecorator {}

        delegate: ListItem {
            StandardLabel { text: modelData.name }

            onClicked: {
                itemSelected(modelData.id)
                pageStack.pop()
            }
        }
    }
}
