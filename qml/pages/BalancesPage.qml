import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/objects.js" as Objects
import "../js/currencies.js" as Currencies

DefaultPage {
    property var balances: ({})
    property var reimbursements: []
    property var participants: ({})
    property string currencyCode

    property bool initialized: false
    loading: !initialized

    function fetchData() {
        if (initialized) {
            return;
        }

        spliit.getBalances(settings.currentGroupId);
    }

    //% "Balances"
    title: qsTrId("balances.title")

    Connections {
        target: spliit

        onBalanceFetchingFailed: {
            //% "Failed fetching list of balances: %1"
            notificationStack.push(qsTrId("balances.error.fetching").arg(error), true)
        }

        onBalancesFetched: {
            balances = response.balances;
            reimbursements = response.reimbursements;
            initialized = true;
        }
    }

    StandardLabel {
        //% "This is the amount that each participant paid or was paid for."
        text: qsTrId("balances.description");
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

    onStatusChanged: {
        if (status === PageStatus.Active) {
            fetchData();
        }
    }
}
