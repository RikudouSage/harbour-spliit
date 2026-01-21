import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/arrays.js" as Arrays

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
    loading: true

    VerticalScrollDecorator {}

    Connections {
        target: settings

        onCurrentGroupIdChanged: {
            fetchGroup();
        }
    }

    Connections {
        target: spliit

        onExpenseCreated: {
            expenses = [];
            fetchMore();
        }

        onExpenseCreationFailed: {
            loading = false;
            //% "Creating the expense failed: %1"
            errorLabel.text = qsTrId("group_detail.create_failed").arg(error);
        }

        onGroupFetchFailed: {
            //% "There was an error: %1"
            errorLabel.text = qsTrId("add_group.error.generic").arg(error);
            loading = false;
        }

        onGroupFetched: {
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
            loading = false;
        }

        onExpenseListResult: {
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
            loading = false;
        }
    }

    PullDownMenu {
        visible: !loading
        MenuItem {
            //% "Change group"
            text: qsTrId("group_detail.change_group")
            onClicked: {
                errorLabel.text = "";
                pageStack.push("GroupSelectorPage.qml");
            }
        }

        MenuItem {
            //% "Settings"
            text: qsTrId("global.settings")
            onClicked: {
                errorLabel.text = "";
                const dialog = pageStack.push("SettingsDialog.qml", {
                    group: group,
                });
                dialog.accepted.connect(function() {
                    settings.rawLanguage = dialog.language;
                    settings.currentParticipantId = dialog.participant;
                });
            }
        }

        MenuItem {
            //% "Add expense"
            text: qsTrId("group_detail.add_expense")
            onClicked: {
                errorLabel.text = "";
                const dialog = pageStack.push("AddExpenseDialog.qml", {
                    currency: group.currencyCode || group.currency,
                    participants: Arrays.objectify(group.participants, "id"),
                    paidBy: settings.currentParticipantId,
                });
                dialog.accepted.connect(function() {
                    loading = true;
                    const form = {
                        expenseDate: dialog.date.toISOString(),
                        title: dialog.name,
                        category: dialog.categoryId,
                        amount: Number(String(dialog.amount) + "00"),
                        paidBy: dialog.paidBy,
                        paidFor: dialog.paidFor.map(function(id) {
                            return {
                                participant: id,
                                shares: 100,
                            };
                        }),
                        splitMode: "EVENLY",
                        isReimbursement: dialog.isReimbursement,
                        notes: dialog.notes,
                        recurrenceRule: "NONE",
                    };

                    spliit.createExpense(group.id, form, settings.currentParticipantId);
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

    Repeater {
        model: expenses

        ExpenseRow {
            expense: modelData
            participants: Arrays.objectify(group.participants, "id")
            currentParticipantId: settings.currentParticipantId
            currencyCode: group ? (group.currencyCode || group.currency) : ""
        }
    }

    Component.onCompleted: {
        fetchGroup();
    }
}
