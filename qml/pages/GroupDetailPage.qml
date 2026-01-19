import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

DefaultPage {
    readonly property int limit: 40
    property int cursor: 0

    property var group
    property var expenses: []

    function fetchGroup() {
        loading = true;
        group = undefined;
        expenses = [];
        cursor = 0;
        errorLabel.text = "";

        spliit.getGroup(settings.currentGroupId);
    }

    function fetchMore() {
        errorLabel.text = "";
        spliit.listExpenses(group.id, cursor, limit);
    }

    id: page
    title: typeof group === 'undefined' ? '' : group.name

    VerticalScrollDecorator {}

    Connections {
        target: settings

        onCurrentGroupIdChanged: {
            fetchGroup();
        }
    }

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

            group = response.group;
            fetchMore();
        }

        onExpenseListFailed: {
            //% "Failed fetching more expenses from the api"
            errorLabel.text = qsTrId("add_group.error.fetch_more");
        }

        onExpenseListResult: {
            loading = false;
            if (response.expenses === null) {
                //% "Failed fetching more expenses from the api"
                errorLabel.text = qsTrId("add_group.error.fetch_more");
                return;
            }

            const expenses = page.expenses;
            for (var i in response.expenses) {
                if (!response.expenses.hasOwnProperty(i)) {
                    continue;
                }

                const expense = response.expenses[i];
                expenses.push(expense);
            }
            page.expenses = expenses;
            console.log(JSON.stringify(expenses));
        }
    }

    PullDownMenu {
        visible: !loading
        MenuItem {
            //% "Change group"
            text: qsTrId("group_detail.change_group")
            onClicked: {
                pageStack.push("GroupSelectorPage.qml");
            }
        }

        MenuItem {
            //% "Add expense"
            text: qsTrId("group_detail.add_expense")
            onClicked: {
                const dialog = pageStack.push("AddExpenseDialog.qml");
                dialog.accepted.connect(function() {
                });
            }
        }
    }

    StandardLabel {
        id: errorLabel
        color: Theme.errorColor
        visible: text != "" && !loading
    }

    StandardLabel {
        visible: !loading && expenses.length === 0
        //% "Wouldn't you look at that, no expenses yet! Why don't you create your first?"
        text: qsTrId("group_detail.no_expenses")
    }

    Component.onCompleted: {
        fetchGroup();
    }
}
