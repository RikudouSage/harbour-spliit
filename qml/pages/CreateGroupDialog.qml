import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/currencies.js" as Currencies
import "../js/objects.js" as Objects
import "../js/arrays.js" as Arrays

DefaultDialog {
    property var currencies: ({})
    property var group: ({
        name: '',
        information: null,
        currency: 'EUR',
        participants: [],
    })
    property var participants: []

    canAccept: group && group.name && group.currency && group.participants.length

    //% "Create"
    acceptText: qsTrId("global.create")
    //% "Cancel"
    cancelText: qsTrId("global.cancel")

    function refreshGroup() {
        var copy = group;
        group = copy;
    }

    TextField {
        //% "Group name"
        label: qsTrId("settings.group_name")

        onTextChanged: {
            group.name = text;
            refreshGroup();
        }
    }

    ValueButton {
        property string currency: 'EUR';

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
            refreshGroup();
        }
    }

    TextArea {
        //% "Group information"
        label: qsTrId("settings.group_information")

        onTextChanged: {
            group.information = text || null;
            refreshGroup();
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
        model: participants

        delegate: ParticipantRow {
            name: modelData.name

            onNameChanged: {
                if (modelData.name === name) {
                    return;
                }
                modelData.name = name;
                participants[index].name = name;
            }

            onRemoveButtonClicked: {
                var modelCopy = participants;
                modelCopy.splice(index, 1);
                participants = modelCopy;
            }
        }
    }

    Button {
        //% "Add participant"
        text: qsTrId("settings.add_participant")
        x: Theme.horizontalPageMargin
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: {
            var modelCopy = participants;
            modelCopy.push({id: null, name: ""});
            participants = modelCopy;
        }
    }

    onParticipantsChanged: {
        group.participants = participants;
        refreshGroup();
    }

    Component.onCompleted: {
        currencies = Currencies.getAsMap(settings.language);
    }
}
