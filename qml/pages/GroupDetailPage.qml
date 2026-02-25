import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/arrays.js" as Arrays
import "../js/strings.js" as Strings
import "../js/currencies.js" as Currencies
import "../js/forms.js" as Forms

DefaultPage {
    readonly property int limit: 40
    property int cursor: 0
    property bool hasMore: true
    property bool fetchingMore: false

    property var group
    property var expenses: []

    function fetchGroup() {
        loading = true;
        group = undefined;
        resetItems();
        errorLabel.text = "";

        spliit.getGroup(settings.currentGroupId);
    }

    function resetItems() {
        expenses = [];
        hasMore = true;
        cursor = 0;
        fetchingMore = false;
    }

    function fetchMore() {
        if (fetchingMore || !hasMore) {
            return;
        }
        fetchingMore = true;
        errorLabel.text = "";
        spliit.listExpenses(group.id, cursor, limit);
    }

    function createFormFromDialog(dialog) {
        return Forms.expenseFormFromDialog(dialog)
    }

    id: page
    title: typeof group === 'undefined' ? '' : group.name
    loading: true

    onContentYChanged: {
        if (loading) {
            return;
        }

        if (page.flickable.contentY + page.flickable.height >= page.flickable.contentHeight - Theme.itemSizeLarge * 4) {
            fetchMore()
        }
    }


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
            resetItems();
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
            app.cover.currentGroupName = group.name;
            fetchMore();

            safeCall(function() {
                pageStack.pushAttached("BalancesPage.qml", {
                    participants: Arrays.objectify(group.participants, "id"),
                    currencyCode: group.currencyCode || group.currency,
                });
            });
        }

        onExpenseListFailed: {
            //% "Failed fetching more expenses from the api"
            errorLabel.text = qsTrId("add_group.error.fetch_more");
            fetchingMore = false;
            loading = false;
        }

        onExpenseListResult: {
            if (response.expenses === null) {
                //% "Failed fetching more expenses from the api"
                errorLabel.text = qsTrId("add_group.error.fetch_more");
                return;
            }

            if (!response.hasMore) {
                hasMore = false;
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
            cursor += limit
            fetchingMore = false;
            loading = false;
        }

        onExpenseUpdateFailed: {
            loading = false;
            //% "Updating the item failed: %1"
            notificationStack.push(qsTrId("group_detail.error.updating_failed").arg(error), true);
        }

        onExpenseUpdated: {
            spliit.getExpense(group.id, id);
        }

        onExpenseFetched: {
            const expense = response.expense;
            const id = expense.id;

            const expenses = page.expenses;
            for (var i in expenses) {
                if (!expenses.hasOwnProperty(i)) {
                    continue;
                }

                const item = expenses[i];
                if (item.id !== id) {
                    continue;
                }
                expenses[i] = expense;
                break;
            }
            page.expenses = expenses;
            loading = false;
        }

        onGroupUpdated: {
            fetchGroup();
        }

        onGroupUpdateFailed: {
            //% "Failed updating group: %1"
            notificationStack.push(qsTrId("group_detail.error.group_update").arg(error), true);
            console.error(error);
        }
    }

    PullDownMenu {
        visible: !loading
        MenuItem {
            //% "Activities"
            text: qsTrId("group_detail.activities")
            onClicked: {
                errorLabel.text = "";
                pageStack.push("ActivitiesPage.qml", {
                    participants: Arrays.objectify(group.participants, "id"),
                });
            }
        }

        MenuItem {
            //% "Groups"
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

                    if (dialog.groupChanged) {
                        var form = {
                            name: dialog.group.name,
                            information: dialog.group.information || null,
                            currencyCode: dialog.group.currencyCode,
                            currency: currencyInfo.infoForCodes([dialog.group.currencyCode], settings.language)[0].symbol,
                            participants: dialog.updatedParticipants,
                        };

                        spliit.updateGroup(group.id, form, settings.currentParticipantId);
                    }
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
                    groupId: group.id,
                });
                dialog.accepted.connect(function() {
                    loading = true;
                    const form = createFormFromDialog(dialog);
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
            participants: group ? Arrays.objectify(group.participants, "id") : {}
            currentParticipantId: settings.currentParticipantId
            currencyCode: group ? (group.currencyCode || group.currency) : ""
            groupId: group ? group.id : ''
            onItemDeleted: {
                visible = false;
            }
            onClicked: {
                const dialog = pageStack.push("AddExpenseDialog.qml", {
                    participants: Arrays.objectify(group.participants, "id"),
                    //% "Update expense"
                    acceptText: qsTrId("add_expense.confirm_text"),
                    groupId: group.id,
                    expenseId: modelData.id,
                    currency: group.currencyCode || group.currency,
                });

                const pageCopy = page;
                const groupCopy = page.group;
                const modelDataCopy = modelData;
                const settingsCopy = settings;
                const spliitCopy = spliit;
                dialog.accepted.connect(function() {
                    loading = true;
                    const form = pageCopy.createFormFromDialog(dialog);
                    spliitCopy.updateExpense(groupCopy.id, modelDataCopy.id, form, settingsCopy.currentParticipantId);
                });
            }
        }
    }

    Component.onCompleted: {
        fetchGroup();
    }
}
