import QtQuick 2.0
import Sailfish.Silica 1.0

import "../components"

DefaultPage {
    property var participants: ({})

    readonly property int limit: 40
    property int cursor: 0
    property bool hasMore: true
    property bool fetchingMore: false
    property var activities: []

    function fetchMore() {
        if (fetchingMore || !hasMore) {
            return;
        }

        fetchingMore = true;
        spliit.listActivities(settings.currentGroupId, cursor, limit);
    }

    id: page
    //% "Activities"
    title: qsTrId("activities.title")
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
        target: spliit

        onActivityListFailed: {
            //% "There was an error while fetching activities: %1"
            notificationStack.push(qsTrId("activities.error.fetching").arg(error));
            fetchingMore = false;
            loading = false;
        }

        onActivityListResult: {
            if (response.activities === null) {
                //% "Failed fetching more expenses from the api"
                errorLabel.text = qsTrId("add_group.error.fetch_more");
                return;
            }

            if (!response.hasMore) {
                hasMore = false;
            }

            const activities = page.activities;
            for (var i in response.activities) {
                if (!response.activities.hasOwnProperty(i)) {
                    continue;
                }

                const activity = response.activities[i];
                activities.push(activity);
            }
            page.activities = activities;
            cursor += limit
            fetchingMore = false;
            loading = false;
        }
    }

    Repeater {
        model: activities

        Row {
            // todo add click handling for expenses if modelData.expense exists
            //% "Unknown activity type"
            property string itemText: qsTrId("activity.unknown")

            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingMedium

            Label {
                id: date
                text: new Date(modelData.time).toLocaleString(settings.language)
                wrapMode: Text.Wrap
                width: parent.width / 4
                color: Theme.secondaryHighlightColor
            }

            Label {
                text: parent.itemText
                width: parent.width - date.width - parent.spacing
                wrapMode: Text.Wrap
            }

            Component.onCompleted: {
                const whodunit = modelData.participantId
                    ? typeof page.participants[modelData.participantId] !== 'undefined'
                      ? page.participants[modelData.participantId].name
                      //% "Unknown"
                      : qsTrId("participant.unknown")
                    //% "Unknown"
                    : qsTrId("participant.unknown")

                switch (modelData.activityType) {
                case 'UPDATE_GROUP':
                    //% "Group was updated by <strong>%1</strong>.
                    itemText = qsTrId("activity.update_group").arg(whodunit);
                    break;
                case 'CREATE_EXPENSE':
                    if (modelData.data) {
                        //% "Expense <i>%1</i> was created by <strong>%2</strong>."
                        itemText = qsTrId("activity.create_expense.with_name").arg(modelData.data).arg(whodunit);
                    } else {
                        //% "Expense was created by <strong>%1</strong>."
                        itemText = qsTrId("activity.create_expense.no_name").arg(whodunit);
                    }
                    break;
                case 'UPDATE_EXPENSE':
                    if (modelData.data) {
                        //% "Expense <i>%1</i> was updated by <strong>%2</strong>."
                        itemText = qsTrId("activity.update_expense.with_name").arg(modelData.data).arg(whodunit);
                    } else {
                        //% "Expense was updated by <strong>%1</strong>."
                        itemText = qsTrId("activity.update_expense.no_name").arg(whodunit);
                    }
                    break;
                case 'DELETE_EXPENSE':
                    if (modelData.data) {
                        //% "Expense <i>%1</i> was deleted by <strong>%2</strong>."
                        itemText = qsTrId("activity.delete_expense.with_name").arg(modelData.data).arg(whodunit);
                    } else {
                        //% "Expense was deleted by <strong>%1</strong>."
                        itemText = qsTrId("activity.delete_expense.no_name").arg(whodunit);
                    }
                    break;
                }
            }
        }
    }

    Component.onCompleted: {
        fetchMore();
    }
}
