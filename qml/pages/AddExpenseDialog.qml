import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

DefaultDialog {
    property var categories: ({})

    property var date
    property int categoryId: 0

    id: page
    loading: true
    //% "Cancel"
    cancelText: qsTrId("global.cancel")
    //% "Add"
    acceptText: qsTrId("global.add")

    canAccept: name.text !== ""

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
        id: name
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
                categories: categories,
            });
            dialog.itemSelected.connect(function(id) {
                categoryId = id;
            });
        }
    }

    Component.onCompleted: {
        date = new Date();
        spliit.getCategories();
    }
}
