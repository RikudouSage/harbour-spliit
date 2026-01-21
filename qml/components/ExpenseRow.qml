import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property var expense
    readonly property bool reimbursement: expense.isReimbursement
    readonly property string paidByName: expense.paidBy === null
        //% "Unknown"
        ? qsTrId("participant.unknown")
        : expense.paidBy.name
    readonly property string paidForNames: expense.paidFor === null
        //% "Unknown"
        ? qsTrId("participant.unknown")
        : expense.paidFor.map(function(item) {
            return item.participant.name;
        }).join(', ')

    property var participants: ({})
    property double balanceRaw: 0
    property string currentParticipantId: ""
    property string currencyCode: ""
    property string balance: currencyInfo.formatCurrency(balanceRaw, currencyCode, settings.language)

    id: root
    width: parent ? parent.width : implicitWidth
    implicitHeight: content.implicitHeight + Theme.paddingMedium

    Column {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
        }
        spacing: Theme.paddingSmall

        Item {
            id: titleRow
            height: titleLabel.implicitHeight
            width: parent.width

            Label {
                id: titleLabel
                anchors {
                    left: parent.left
                    right: parent.right
                }
                text: expense.title
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeMedium
                font.italic: reimbursement
            }
        }

        Item {
            id: detailsRow
            width: parent.width
            height: Math.max(detailsLabel.implicitHeight, amountLabel.implicitHeight)

            Label {
                id: detailsLabel
                anchors {
                    left: parent.left
                    right: amountLabel.left
                    rightMargin: Theme.paddingLarge
                }
                //% "Paid by <strong>%1</strong> for <strong>%2</strong>"
                text: qsTrId("expense_row.paid_by_for_label").arg(paidByName).arg(paidForNames)
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                font.italic: reimbursement
                color: Theme.secondaryColor
            }

            Label {
                id: amountLabel
                anchors {
                    right: parent.right
                    top: parent.top
                }
                // todo format using intl
                text: currencyInfo.formatCurrency(expense.amount / 100, currencyCode, settings.language)
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                font.italic: reimbursement
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            id: metaRow
            width: parent.width
            height: Math.max(balanceLabel.implicitHeight, dateLabel.implicitHeight)

            Label {
                id: balanceLabel
                anchors {
                    left: parent.left
                    right: dateLabel.left
                    rightMargin: Theme.paddingLarge
                }
                //% "Your balance: <strong>%1</strong>"
                text: qsTrId("expense_row.balance").arg(balance)
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                font.italic: reimbursement
                color: balanceRaw >= 0 ? Theme.highlightColor : Theme.errorColor
                visible: settings.currentParticipantId !== ""
            }

            Label {
                id: dateLabel
                anchors {
                    right: parent.right
                    top: parent.top
                }
                text: new Date(expense.expenseDate).toLocaleDateString(settings.language)
                font.pixelSize: Theme.fontSizeSmall
                font.italic: reimbursement
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Component.onCompleted: {
        if (expense.paidBy.id === settings.currentParticipantId) {
            balanceRaw = (expense.amount / 100) - (expense.amount / 100 / expense.paidFor.length);
        } else {
            balanceRaw = -(expense.amount / 100 / expense.paidFor.length);
        }
    }
}
