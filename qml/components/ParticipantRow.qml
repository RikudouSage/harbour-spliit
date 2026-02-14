import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property alias name: nameField.text
    signal removeButtonClicked();

    width: parent.width - Theme.horizontalPageMargin
    spacing: Theme.paddingSmall

    TextField {
        id: nameField
        width: parent.width - parent.spacing - removeButton.width
    }
    IconButton {
        id: removeButton
        icon.source: "image://theme/icon-m-remove"
        icon.color: Theme.errorColor

        onClicked: {
            removeButtonClicked();
        }
    }
}
