import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"
import "../js/objects.js" as Objects
import "../js/currencies.js" as Currencies

DefaultDialog {
    property var currencies: ({})
    property var categories: ({})
    property var participants: ({})
    property var currencyDetail

    property alias name: nameField.text
    property alias amount: amountField.text
    property var date
    property int categoryId: 0
    property string currency
    property string paidBy
    property alias isReimbursement: isReimbursementSwitch.checked
    property alias notes: notesField.text
    property var paidFor: []
    property var paidForIds: paidFor.map(function(item) {return item.id});

    id: page
    loading: true
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
            loading = false;
            fetchingFailedhandler();
            console.error(error);
        }

        onCategoriesFetched: {
            loading = false;
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
        value: date.toLocaleDateString(Qt.locale(settings.language), Locale.ShortFormat)

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
                return paidForIds.length === 0 || paidForIds.indexOf(modelData.id) > -1
            }

            onCheckedChanged: {
                if (checked) {
                    paidFor.push(modelData.id);
                } else {
                    paidFor = paidFor.filter(function(id) {
                        return id !== modelData.id;
                    });
                }
            }
        }
    }

    Component.onCompleted: {
        if (!date) {
            date = new Date();
        }
        spliit.getCategories();

        currencies = Currencies.getAsMap(settings.language);
        if (!currency) {
            currency = "EUR";
        }

        if (!paidFor.length) {
            paidFor = Objects.values(participants).map(function(participant) {
                return participant.id;
            });
        }
    }
}
