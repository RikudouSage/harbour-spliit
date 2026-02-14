import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/objects.js" as Objects
import "../js/currencies.js" as Currencies
import "../js/forms.js" as Forms
import "../js/strings.js" as Strings

DefaultPage {
    readonly property string requestId: String(Math.random())

    property var balances: ({})
    property var reimbursements: []
    property var participants: ({})
    property var stats: ({})
    property string currencyCode
    property string groupId: settings.currentGroupId

    property bool initialized: false

    id: page
    loading: !initialized

    function fetchData() {
        if (initialized) {
            return;
        }

        spliit.getBalances(groupId);
        spliit.getStats(groupId, settings.currentParticipantId);
    }

    //% "Balances"
    title: qsTrId("balances.title")

    Connections {
        target: spliit

        onBalanceFetchingFailed: {
            //% "Failed fetching list of balances: %1"
            notificationStack.push(qsTrId("balances.error.fetching").arg(error), true)
        }

        onStatsFetchingFailed: {
            //% "Failed fetching stats: %1"
            notificationStack.push(qsTrId("balances.error.stats_fetching").arg(error), true)
        }

        onStatsFetched: {
            stats = response;
        }

        onBalancesFetched: {
            balances = response.balances;
            reimbursements = response.reimbursements;
            initialized = true;
        }

        onExpenseCreated: {
            if (requestId === page.requestId) {
                //% "The reimbursement has been successfully created."
                notificationStack.push(qsTrId("balances.reimbursement_created"), false);
            }

            initialized = false;
            if (page.status === PageStatus.Active) {
                fetchData();
            }
        }

        onExpenseCreationFailed: {
            if (requestId !== page.requestId) {
                return;
            }

            //% "Creating the reimbursement failed: %1"
            notificationStack.push(qsTrId("balances.reimbursement_create_failed").arg(error), true);
            initialized = true;
        }

        onExpenseUpdated: {
            initialized = false;
            if (page.status === PageStatus.Active) {
                fetchData();
            }
        }

        onExpenseDeleted: {
            initialized = false;
            if (page.status === PageStatus.Active) {
                fetchData();
            }
        }
    }

    StandardLabel {
        //% "This is the amount that each participant paid or was paid for."
        text: qsTrId("balances.description");
        color: Theme.primaryColor
    }

    StandardLabel {
        //% "Nobody owes anyone anything—isn't that nice? But it also means there's nothing to display on this page."
        text: qsTrId("balances.no_balances");
        visible: Objects.values(balances).length === 0
        color: Theme.highlightColor
    }

    Chart {
        visible: initialized
        series: initialized
            ? Objects.entries(balances).map(function(item) {
                var key = item[0];
                var value = item[1];

                return {
                    name: participants[key].name,
                    value: value.total,
                    valueLabel: currencyInfo.formatCurrency(
                        Currencies.parseCentsToAmount(value.total),
                        currencyCode,
                        settings.language
                    ) || (currencyInfo.formatNumber(
                        Currencies.parseCentsToAmount(value.total),
                        settings.language
                    ) + ' ' + currencyCode),
                }
            })
            : []
    }

    Item {
        height: Theme.paddingLarge
        width: parent.width
    }

    SectionTitle {
        //% "Suggested reimbursements"
        text: qsTrId("balances.reimbursements")
        visible: reimbursements.length > 0
    }

    Repeater {
        model: reimbursements

        Row {
            property real amount: Number(Currencies.parseCentsToAmount(modelData.amount))

            x: Theme.horizontalPageMargin
            spacing: Theme.paddingSmall
            width: page.width - Theme.horizontalPageMargin * 2

            Label {
                id: textLabel
                property string owing: typeof participants[modelData.from] === 'undefined'
                    //: Unknown participant owes money
                    //% "Unknown"
                    ? qsTrId("participant.unknown")
                    : participants[modelData.from].name
                property string owingTo: typeof participants[modelData.to] === 'undefined'
                    //: Unknown participant is owed money
                    //% "Unknown"
                    ? qsTrId("participant.unknown")
                    : participants[modelData.to].name

                //% "<strong>%1</strong> owes <strong>%2</strong>"
                text: qsTrId("balances.reimbursements.owing_text").arg(owing).arg(owingTo)
                anchors.verticalCenter: markAsPaidButton.verticalCenter
            }

            IconButton {
                id: markAsPaidButton
                icon.source: "image://theme/icon-s-accept"
                icon.color: Theme.highlightColor
                icon.sourceSize: Qt.size(Theme.iconSizeMedium, Theme.iconSizeMedium)

                onClicked: {
                    const dialog = pageStack.push("AddExpenseDialog.qml", {
                        participants: participants,
                        isReimbursement: true,
                        paidBy: modelData.from,
                        currency: currencyCode,
                        groupId: groupId,
                        //: The name of a new expense when created from the "Mark as paid" button on the balances/reimbursements page
                        //% "Reimbursement"
                        name: qsTrId("balances.reimbursements.add_expense_name"),
                        amount: parent.amount,
                        initialPaidFor: [modelData.to],
                    });

                    dialog.accepted.connect(function() {
                        initialized = false;
                        const form = Forms.expenseFormFromDialog(dialog);
                        spliit.createExpense(groupId, form, settings.currentParticipantId, requestId);
                    });
                }
            }

            Label {
                width: parent.width - textLabel.width - markAsPaidButton.width - parent.spacing * 2
                horizontalAlignment: Text.AlignRight
                text: currencyInfo.formatCurrency(amount, currencyCode, settings.language)
                    || currencyInfo.formatNumber(amount, settings.language) + ' ' + currencyCode
                anchors.verticalCenter: markAsPaidButton.verticalCenter
            }
        }
    }

    Column {
        width: parent.width
        spacing: parent.spacing
        visible: typeof stats.totalGroupSpendings !== 'undefined'

        SectionTitle {
            //% "Stats"
            text: qsTrId("balances.stats")
        }

        Row {
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingSmall
            width: page.width - Theme.horizontalPageMargin * 2
        }

        TextValue {
            property var amount: typeof stats.totalGroupSpendings === 'undefined'
                                 ? 0
                                 : Currencies.parseCentsToAmount(stats.totalGroupSpendings)

            //% "Total group spendings"
            label: qsTrId("balances.stats.total_spendings")
            value: currencyInfo.formatCurrency(amount, currencyCode, settings.language)
                   || currencyInfo.formatNumber(amount, settings.language) + ' ' + currencyCode
        }

        TextValue {
            property var amount: typeof stats.totalGroupSpendings === 'undefined'
                                 ? 0
                                 : Currencies.parseCentsToAmount(stats.totalParticipantSpendings)
            //% "Your total spendings"
            label: qsTrId("balances.stats.total_spendings_participant")
            value: currencyInfo.formatCurrency(amount, currencyCode, settings.language)
                   || currencyInfo.formatNumber(amount, settings.language) + ' ' + currencyCode
            visible: typeof stats.totalGroupSpendings !== 'undefined'
        }

        TextValue {
            property var amount: typeof stats.totalParticipantShare === 'undefined'
                                 ? 0
                                 : Currencies.parseCentsToAmount(stats.totalParticipantShare)
            //% "Your total share"
            label: qsTrId("balances.stats.total_share_participant")
            value: currencyInfo.formatCurrency(amount, currencyCode, settings.language)
                   || currencyInfo.formatNumber(amount, settings.language) + ' ' + currencyCode
            visible: typeof stats.totalParticipantShare !== 'undefined'
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            fetchData();
        }
    }
}
