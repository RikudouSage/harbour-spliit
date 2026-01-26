import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

CoverBackground {
    property string currentGroupName: ''

    Row {
        id: branding
        anchors.top: parent.top
        anchors.topMargin: Theme.paddingLarge * 3
        anchors.horizontalCenter: parent.horizontalCenter

        HighlightImage {
            id: icon
            source: "file:///usr/share/harbour-spliit/icons/bare.png"
            sourceSize.width: Theme.iconSizeMedium
            sourceSize.height: sourceSize.width
        }

        Label {
            text: "Spliit"
            anchors.verticalCenter: icon.verticalCenter
            font.pixelSize: Theme.fontSizeLarge
        }
    }

    StandardLabel {
        text: currentGroupName
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge * 3
        horizontalAlignment: Text.AlignHCenter
    }

    /*CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }
    }*/
}
