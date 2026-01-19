import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

Page {
    property alias categories: listView.model
    signal itemSelected(int id)

    SilicaListView {
        id: listView
        anchors.fill: parent
        header: PageHeader {
            //% "Choose a category"
            title: qsTrId("category_select.title")
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

    Component.onCompleted: {
        console.log(JSON.stringify(categories))
    }
}
