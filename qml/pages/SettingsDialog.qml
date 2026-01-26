import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/arrays.js" as Arrays
import "../js/currencies.js" as Currencies
import "../js/objects.js" as Objects

DefaultDialog {
    property var group
    property var participants: ({})
    property var currencies: ({})
    property var updatedParticipants: ({});

    property bool groupChanged: false

    property string language: settings.rawLanguage
    property string participant: settings.currentParticipantId

    id: page
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

            content.sourceComponent: Column {
                spacing: Theme.paddingLarge
                TextField {
                    //% "Group name"
                    label: qsTrId("settings.group_name")
                    text: group.name

                    onTextChanged: {
                        group.name = text;
                        groupChanged = true;
                    }
                }

                ValueButton {
                    property string currency: group.currencyCode || group.currency;

                    //% "Main currency"
                    label: qsTrId("settings.currency")
                    value: typeof currencies[currency] !== 'undefined'
                        ? (currencies[currency].name + ' (' + currency + ')')
                        : currency;

                    onClicked: {
                        const dialog = pageStack.push("SelectCurrencyDialog.qml", {
                            currencies: Currencies.get(settings.language),
                        });
                        dialog.itemSelected.connect(function(code) {
                            currency = code;
                        });
                    }

                    onCurrencyChanged: {
                        group.currencyCode = currency;
                        groupChanged = true;
                    }
                }

                TextArea {
                    //% "Group information"
                    label: qsTrId("settings.group_information")
                    text: group.information || ""

                    onTextChanged: {
                        group.information = text || null;
                        groupChanged = true;
                    }
                }

                StandardLabel {
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    //% "Participants"
                    text: qsTrId("settings.participants")
                }

                Repeater {
                    model: updatedParticipants

                    delegate: Row {
                        width: parent.width - Theme.horizontalPageMargin
                        spacing: Theme.paddingSmall

                        TextField {
                            text: modelData.name
                            width: parent.width - parent.spacing - removeButton.width

                            onTextChanged: {
                                if (modelData.name === text) {
                                    return;
                                }
                                modelData.name = text;
                                updatedParticipants[index].name = text;
                                groupChanged = true;
                            }
                        }
                        IconButton {
                            id: removeButton
                            icon.source: "image://theme/icon-m-remove"
                            icon.color: Theme.errorColor

                            onClicked: {
                                var modelCopy = updatedParticipants;
                                modelCopy.splice(index, 1);
                                updatedParticipants = modelCopy;
                                groupChanged = true;
                            }
                        }
                    }
                }

                Button {
                    //% "Add participant"
                    text: qsTrId("settings.add_participant")
                    x: Theme.horizontalPageMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        var modelCopy = updatedParticipants;
                        modelCopy.push({id: null, name: ""});
                        updatedParticipants = modelCopy;
                        groupChanged = true;
                    }
                }
            }
        }
    }

    onGroupChanged: {
        if (!group) {
            return;
        }

        participants = Arrays.objectify(group.participants, "id");
    }

    Component.onCompleted: {
        currencies = Currencies.getAsMap(settings.language);
        updatedParticipants = group.participants.map(function(item) {
            return {
                id: item.id,
                name: item.name,
            }
        });
    }
}
