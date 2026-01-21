import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/arrays.js" as Arrays

DefaultDialog {
    property var group
    property var participants: ({})

    property string language: settings.rawLanguage
    property string participant: settings.currentParticipantId

    //% "Save"
    acceptText: qsTrId("global.save")
    //% "Cancel"
    cancelText: qsTrId("global.cancel")

    ExpandingSectionGroup {
        currentIndex: 0

        ExpandingSection {
            //% "App Settings"
            title: qsTrId("settings.section.app")

            content.sourceComponent: Column {
                width: parent.width - Theme.paddingLarge * 2
                x: Theme.paddingLarge

                ComboBox {
                    property var itemData: [
                        //: As in automatic language selection
                        //% "Automatic"
                        {text: qsTrId("settings.language.auto"), value: ""},
                        {text: "English", value: "en"},
                        {text: "Čeština", value: "cs"},
                    ]

                    id: langSelect
                    width: parent.width
                    //% "Language"
                    label: qsTrId("settings.language.label")

                    menu: ContextMenu {
                        Repeater {
                            model: langSelect.itemData
                            MenuItem {
                                property string value: modelData.value
                                text: modelData.text
                            }
                        }
                    }

                    onCurrentItemChanged: {
                        language = currentItem.value;
                    }

                    Component.onCompleted: {
                        const index = itemData.map(function(item) {
                            return item.value;
                        }).indexOf(language);
                        currentIndex = index;
                    }
                }

                ValueButton {
                    //% "Active user"
                    label: qsTrId("settings.current_participant")
                    value: typeof participants[participant] !== 'undefined'
                            ? participants[participant].name
                            : ''

                    onClicked: {
                        const dialog = pageStack.push("SelectParticipantDialog.qml", {
                            participants: group.participants,
                        });
                        dialog.itemSelected.connect(function(id) {
                            participant = id;
                        });
                    }
                }
            }
        }

        ExpandingSection {
            //% "Group Settings"
            title: qsTrId("settings.section.group")
        }
    }

    onGroupChanged: {
        if (!group) {
            return;
        }

        participants = Arrays.objectify(group.participants, "id");
    }
}
