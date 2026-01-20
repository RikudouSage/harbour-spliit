import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

Page {
    property alias currencies: listView.model
    signal itemSelected(string code)

    SilicaListView {
        id: listView
        anchors.fill: parent
        header: PageHeader {
            //% "Choose currency"
            title: qsTrId("currency_select.title")
        }

        VerticalScrollDecorator {}

        delegate: ListItem {
            StandardLabel {
                text: modelData.name + " (" + modelData.code + ")"
            }

            onClicked: {
                itemSelected(modelData.code)
                pageStack.pop()
            }
        }
    }
}
