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
    property string balanceCalcLeft: '0'
    property string balanceCalcRight: '0'

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
                text: currencyInfo.formatCurrency(expense.amount / 100, currencyCode, settings.language)
                    || (currencyInfo.formatNumber(expense.amount / 100, settings.language) + ' ' + currencyCode)
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
                //: Your balance: <strong>€ 2.00</strong> (€3.00 - €1.00)
                //% "Your balance: <strong>%1</strong> (%2 - %3)"
                text: qsTrId("expense_row.balance")
                        .arg(balance)
                        .arg(balanceCalcLeft)
                        .arg(balanceCalcRight)
                textFormat: Text.RichText
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                font.italic: reimbursement
                color: balanceRaw >= 0 ? Theme.highlightColor : Theme.errorColor
                visible: currentParticipantId !== "" && balance !== ""
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

    onCurrentParticipantIdChanged: {
        if (currentParticipantId) {
            const paidByMe = expense.paidBy.id === currentParticipantId;

            const paidByMeLeft = expense.amount / 100;
            const paidByMeRight = expense.amount / 100 / expense.paidFor.length;
            const notPaidByMeleft = expense.amount / 100;
            const notPaidByMeRight = (expense.amount / 100 / expense.paidFor.length) * (expense.paidFor.length - 1);

            if (paidByMe) {
                balanceRaw = (expense.amount / 100) - (expense.amount / 100 / expense.paidFor.length);
                balanceCalcLeft = currencyInfo.formatCurrency(paidByMeLeft, currencyCode, settings.language);
                balanceCalcRight = currencyInfo.formatCurrency(paidByMeRight, currencyCode, settings.language);
            } else {
                balanceRaw = -(expense.amount / 100 / expense.paidFor.length);
                balanceCalcLeft = currencyInfo.formatCurrency(notPaidByMeleft, currencyCode, settings.language);
                balanceCalcRight = currencyInfo.formatCurrency(notPaidByMeRight, currencyCode, settings.language);
            }

            // custom currencies
            if (balance === "") {
                balance = currencyInfo.formatNumber(balanceRaw, settings.language) + " " + currencyCode;
                if (paidByMe) {
                    balanceCalcLeft = currencyInfo.formatNumber(paidByMeLeft, settings.language) + " " + currencyCode;
                    balanceCalcRight = currencyInfo.formatNumber(paidByMeRight, settings.language) + " " + currencyCode;
                } else {
                    balanceCalcLeft = currencyInfo.formatNumber(notPaidByMeleft, settings.language) + " " + currencyCode;
                    balanceCalcRight = currencyInfo.formatNumber(notPaidByMeRight, settings.language) + " " + currencyCode;
                }
            }
        }
    }
}
