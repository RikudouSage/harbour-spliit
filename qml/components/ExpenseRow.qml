import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    property var expense
    readonly property bool reimbursement: expense && expense.isReimbursement
    function formatAmount(amount) {
        return currencyInfo.formatCurrency(amount, currencyCode, settings.language)
            || (currencyInfo.formatNumber(amount, settings.language) + " " + currencyCode);
    }
    function participantIdForPaidForItem(item) {
        if (!item) {
            return "";
        }
        if (item.participant && item.participant.id) {
            return item.participant.id;
        }
        if (item.participantId) {
            return item.participantId;
        }
        if (typeof item.participant === "string") {
            return item.participant;
        }
        return "";
    }
    readonly property string paidByName: !expense || !expense.paidBy
        //: Paid by unknown participant
        //% "Unknown"
        ? qsTrId("participant.unknown")
        : expense.paidBy.name
    readonly property string paidForNames: !expense || !expense.paidFor
        //: Paid for unknown participant
        //% "Unknown"
        ? qsTrId("participant.unknown")
        : expense.paidFor.map(function(item) {
            return item && item.participant
                    ? item.participant.name
                    : (participants[participantIdForPaidForItem(item)]
                       ? participants[participantIdForPaidForItem(item)].name
                       : qsTrId("participant.unknown"));
        }).join(', ')

    property var participants: ({})
    property string currentParticipantId: ""
    property string currencyCode: ""
    readonly property string paidByParticipantId: expense && (
        (expense.paidBy && expense.paidBy.id)
        ? expense.paidBy.id
        : expense.paidById
    )
    readonly property bool paidByMe: !!currentParticipantId && !!paidByParticipantId && paidByParticipantId === currentParticipantId
    readonly property bool paidForMe: !!currentParticipantId && !!expense && !!expense.paidFor && expense.paidFor.some(function(item) {
        return participantIdForPaidForItem(item) === currentParticipantId;
    })
    readonly property bool participantInExpense: paidByMe || paidForMe
    readonly property int paidForCount: expense && expense.paidFor ? expense.paidFor.length : 0
    // TODO: implement correct balance math for non-even split modes and uneven shares.
    readonly property bool hideBalanceCalculation: !!expense && (
        (!!expense.splitMode && expense.splitMode !== "EVENLY")
        || (!!expense.paidFor && expense.paidFor.length > 0 && expense.paidFor.some(function(item) {
            return item && item.shares !== undefined && item.shares !== expense.paidFor[0].shares;
        }))
    )
    readonly property double totalAmount: expense ? expense.amount / 100 : 0
    readonly property double shareAmount: paidForCount > 0 ? totalAmount / paidForCount : 0
    readonly property double balanceRaw: participantInExpense
        ? ((paidByMe ? totalAmount : 0) - (paidForMe ? shareAmount : 0))
        : 0
    readonly property double balanceLeftAmount: participantInExpense
        ? (paidByMe ? totalAmount : totalAmount)
        : 0
    readonly property double balanceRightAmount: participantInExpense
        ? (paidByMe ? (paidForMe ? shareAmount : 0) : (paidForMe ? (totalAmount - shareAmount) : totalAmount))
        : 0
    readonly property string balance: participantInExpense ? formatAmount(balanceRaw) : ""
    readonly property string balanceCalcLeft: participantInExpense ? formatAmount(balanceLeftAmount) : ""
    readonly property string balanceCalcRight: participantInExpense ? formatAmount(balanceRightAmount) : ""
    property string groupId
    signal itemDeleted();

    id: root
    width: parent ? parent.width : implicitWidth
    contentHeight: content.implicitHeight + Theme.paddingMedium

    menu: ContextMenu {
        IconMenuItem {
            //% "Remove"
            text: qsTrId("global.remove")
            icon.source: "image://theme/icon-m-remove"

            onClicked: {
                remorseDelete(function() {
                    spliit.deleteExpense(groupId, expense.id, currentParticipantId);
                });
            }
        }
    }

    Connections {
        target: spliit

        onExpenseDeleted: {
            if (id !== expense.id) {
                return;
            }
            itemDeleted();
        }

        onExpenseDeleteFailed: {
            if (id !== expense.id) {
                return;
            }
            //% "Failed deleting the item: %1"
            notificationStack.push(qsTrId("expense_row.error.delete").arg(error), true);
        }
    }

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
                visible: participantInExpense && balance !== "" && !hideBalanceCalculation
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

}
