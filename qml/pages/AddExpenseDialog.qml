import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/objects.js" as Objects
import "../js/strings.js" as Strings
import "../js/currencies.js" as Currencies

DefaultDialog {
    property bool categoriesLoading: true
    property bool expenseLoading: true

    property var currencies: ({})
    property var categories: ({})
    property var participants: ({})
    property var currencyDetail

    property string groupId: ''
    property string expenseId: ''

    property alias name: nameField.text
    property alias amount: amountField.text
    property var date
    property int categoryId: 0
    property string currency
    property string paidBy
    property alias isReimbursement: isReimbursementSwitch.checked
    property alias notes: notesField.text
    property var paidFor: []

    id: page
    loading: categoriesLoading || expenseLoading
    //% "Cancel"
    cancelText: qsTrId("global.cancel")
    //% "Add"
    acceptText: qsTrId("global.add")

    canAccept: nameField.isValid && amountField.isValid && paidBy && paidFor.length > 0

    onCurrencyChanged: {
        currencyDetail = currencyInfo.infoForCodes([currency], settings.language)[0];
    }

    Component {
        id: datePickerComponent
        DatePickerDialog {}
    }

    Connections {
        target: spliit

        function fetchingFailedHandler() {
            //% "Fetching categories failed, only the default category will be available."
            errorText.text = qsTrId("add_expense.error.category_fetching_failed");
            // todo find out about localizations
            categories[0] = {"id": 0, "grouping": "Uncategorized", "name": "General"};
        }

        onCategoryFetchingFailed: {
            categories = false;
            fetchingFailedhandler();
            console.error(error);
        }

        onCategoriesFetched: {
            categoriesLoading = false;
            if (response.categories === null) {
                fetchingFailedHandler();
                return;
            }

            const categories = {};
            for (var i in response.categories) {
                if (!response.categories.hasOwnProperty(i)) {
                    continue;
                }
                const category = response.categories[i];
                categories[category.id] = category;
            }
            page.categories = categories;
        }

        onExpenseFetchFailed: {
            if (id !== expenseId) {
                return;
            }
            // intentionally don't clear loading, staying in forever loading is better
            //% "Fetching the expense failed: %1"
            notificationStack.push(qsTrId("add_expense.error.fetching_failed").arg(error), true);
        }

        onExpenseFetched: {
            if (response.expense.id !== expenseId) {
                return;
            }

            const expense = response.expense;

            if (expense.originalAmount) {
                //% "Warning: This expense is in a non-default currency, this app does not support it yet. Please don't save anything."
                notificationStack.push(qsTrId("add_expense.error.unsupported_multi_currency"), true);
            }

            var amount = Strings.leftPad(String(expense.amount), 3, '0');
            amount = Strings.insertAt(amount, ".", -2);

            name = expense.title;
            page.amount = amount;
            date = new Date(expense.expenseDate);
            categoryId = expense.category.id;
            paidBy = expense.paidBy.id;
            isReimbursement = expense.isReimbursement;
            notes = expense.notes || '';
            paidFor = expense.paidFor.map(function(item) {
                return item.participantId;
            });

            expenseLoading = false;
        }
    }

    StandardLabel {
        id: errorText
        visible: text != ""
    }

    TextField {
        readonly property bool isValid: text != ""

        id: nameField
        //: Title of the expense
        //% "Title"
        label: qsTrId("add_expense.field.name")
    }

    ValueButton {
        //% "Expense date"
        label: qsTrId("add_expense.field.date")
        value: date ? date.toLocaleDateString(Qt.locale(settings.language), Locale.ShortFormat) : ''

        onClicked: {
            const dialog = pageStack.push(datePickerComponent, {
                date: date,
            });
            dialog.accepted.connect(function() {
                date = dialog.date;
            });
        }
    }

    ValueButton {
        //% "Category"
        label: qsTrId("add_expense.field.category")
        value: typeof categories[categoryId] !== 'undefined' ? categories[categoryId].name : ''

        onClicked: {
            const dialog = pageStack.push("SelectCategoryDialog.qml", {
                categories: Objects.values(categories),
            });
            dialog.itemSelected.connect(function(id) {
                categoryId = id;
            });
        }
    }

    ValueButton {
        //% "Currency"
        label: qsTrId("add_expense.field.currency")
        value: typeof currencies[currency] !== 'undefined'
                    ? (currencies[currency].name + ' (' + currency + ')')
                    : currency;
        visible: false

        onClicked: {
            const dialog = pageStack.push("SelectCurrencyDialog.qml", {
                currencies: Currencies.get(settings.language),
            });
            dialog.itemSelected.connect(function(code) {
                currency = code;
            });
        }
    }

    TextField {
        readonly property bool isValid: text != "" && (Number(text) > 0 || Number(text) < 0)

        id: amountField
        label: currencyDetail
               //% "Amount (%1)"
               ? qsTrId("add_expense.field.amount").arg(currencyDetail.symbol)
               //% "Amount"
               : qsTrId("add_expense.field.amount_no_currency")
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    TextSwitch {
        id: isReimbursementSwitch
        //% "This is a reimbursement"
        text: qsTrId("add_expense.field.is_reimbursement")
    }

    ValueButton {
        //% "Paid by"
        label: qsTrId("add_expense.field.paid_by")
        value: paidBy && typeof participants[paidBy] !== 'undefined'
               ? participants[paidBy].name
               : ''

        onClicked: {
            const dialog = pageStack.push("SelectParticipantDialog.qml", {
                participants: Objects.values(participants),
            });
            dialog.itemSelected.connect(function(id) {
                paidBy = id;
            });
        }
    }

    TextArea {
        id: notesField
        //% "Notes"
        label: qsTrId("add_expense.field.notes")
    }

    StandardLabel {
        font.pixelSize: Theme.fontSizeLarge
        //% "Paid for"
        text: qsTrId("add_expense.label.paid_for")
    }

    Repeater {
        model: Objects.values(participants)

        TextSwitch {
            text: modelData.name
            checked: {
                return paidFor.length === 0 || paidFor.indexOf(modelData.id) > -1
            }

            onCheckedChanged: {
                if (checked) {
                    if (paidFor.indexOf(modelData.id) === -1) {
                        paidFor.push(modelData.id);
                    }
                } else {
                    paidFor = paidFor.filter(function(id) {
                        return id !== modelData.id;
                    });
                }

            }
        }
    }

    Component.onCompleted: {
        spliit.getCategories();
        currencies = Currencies.getAsMap(settings.language);

        if (expenseId) {
            spliit.getExpense(groupId, expenseId);
        } else {
            expenseLoading = false;
            date = new Date();

            if (!currency) {
                currency = "EUR";
            }

            paidFor = Objects.values(participants).map(function(participant) {
                return participant.id;
            });
        }
    }
}
