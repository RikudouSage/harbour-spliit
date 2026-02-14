import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    property alias label: textLabel.text
    property alias value: valueLabel.text

    x: Theme.horizontalPageMargin
    spacing: Theme.paddingSmall
    width: page.width - Theme.horizontalPageMargin * 2

    Label {
        id: textLabel
    }

    Label {
        id: valueLabel
        width: parent.width - textLabel.width - parent.spacing * 2
        horizontalAlignment: Text.AlignRight
    }
}
