import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

DefaultPage {
    property alias errorText: errorLabel.text
    id: page

    StandardLabel {
        id: errorLabel
        //% "There was an error, please try again later or contact the developer with details about what you were doing."
        text: qsTrId("page.error.default_text")
        color: Theme.errorColor
    }
}
