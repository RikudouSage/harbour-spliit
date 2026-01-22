import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

DefaultDialog {
    property bool loading: false
    property string groupId
    property string groupName

    //% "Add"
    acceptText: qsTrId("global.add")
    //% "Cancel"
    cancelText: qsTrId("global.cancel")
    canAccept: groupId !== '' && groupName !== ''

    Connections {
        target: spliit

        onGroupFetchFailed: {
            //% "There was an error: %1"
            errorLabel.text = qsTrId("add_group.error.generic").arg(error);
            loading = false;
        }

        onGroupFetched:     {
            loading = false;
            if (response.group === null) {
                //% "The group does not exist."
                errorLabel.text = qsTrId("add_group.error.not_found");
                return;
            }
            groupName = response.group.name;
        }
    }

    Timer {
        id: debounceFetchTimer
        interval: 250
        repeat: false
        running: false

        onTriggered: {
            spliit.getGroup(groupId);
        }
    }

    StandardLabel {
        //% "Please provide the group ID below."
        text: qsTrId("add_group.help_text")
    }

    TextField {
        id: groupIdField
        //% "Group ID"
        label: qsTrId("add_group.group_id_field.label")
        placeholderText: "vxPfqptGutSUr8LcY7iiJ"

        onTextChanged: {
            groupId = text;
            groupName = "";
            debounceFetchTimer.stop();
            errorLabel.text = "";

            if (text) {
                loading = true;
                debounceFetchTimer.start();
            }
        }

        Component.onCompleted: {
            if (isDebug) {
                text = placeholderText;
            }
        }
    }

    StandardLabel {
        id: groupNameLabel
        //% "Group name: %1"
        text: qsTrId("add_group.group_name_label").arg(groupName)
        visible: groupName !== ""
    }

    StandardLabel {
        id: errorLabel
        color: Theme.errorColor
    }

    BusyLabel {
        //% "Loading..."
        text: qsTrId("global.loading")
        visible: loading
    }
}
