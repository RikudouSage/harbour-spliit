import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property alias categories: listView.model
    signal itemSelected(int id)

    SilicaListView {
        id: listView

        delegate: ListItem {
            Label { text: modelData.name }

            onClicked: {
                itemSelected(modelData.id)
                pageStack.pop()
            }
        }
    }
}
