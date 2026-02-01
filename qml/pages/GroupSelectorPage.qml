import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Share 1.0

import "../components"

DefaultPage {
    property var groupNames: ({})
    id: page
    //% "Select a Group"
    title: qsTrId("group_selector.title")

    function fetchGroups() {
        if (settings.storedGroups.length === 0) {
            return;
        }
        loading = true;
        groupNames = {};
        spliit.getGroups(settings.storedGroups);
    }

    Connections {
        target: settings
        onStoredGroupsChanged: fetchGroups()
    }

    Connections {
        target: spliit

        onGroupFetchFailed: {
            //% "Failed fetching list of groups, please  try again later."
            errorText.text = qsTrId("group_selector.failed_fetching");
        }

        onGroupsFetched: {
            if (response.groups === null || !response.groups.length) {
                errorText.text = qsTrId("group_selector.failed_fetching");
                return;
            }

            const groupNames = {};
            for (var i in response.groups) {
                if (!response.groups.hasOwnProperty(i)) {
                    continue;
                }
                const group = response.groups[i];
                groupNames[group.id] = group.name;
            }
            page.groupNames = groupNames;

            loading = false;
        }
    }

    PullDownMenu {
        MenuItem {
            //% "Create group"
            text: qsTrId("group_selector.create_group")
            onClicked: {
                Qt.openUrlExternally("https://spliit.app/groups/create")
            }
        }

        MenuItem {
            //% "Select existing group"
            text: qsTrId("group_selector.add_group")
            onClicked: {
                const dialog = pageStack.push("AddGroupDialog.qml");
                dialog.accepted.connect(function() {
                    if (!dialog.groupId || !dialog.groupName) {
                        //% "Invalid group provided."
                        errorText.text = qsTrId("group_selector.invalid_group_provided");
                        return;
                    }

                    settings.storedGroups.push(dialog.groupId);
                });
            }
        }
    }

    StandardLabel {
        id: errorText
        color: Theme.errorColor
    }

    StandardLabel {
        visible: settings.storedGroups.length === 0
        //% "There are no groups saved. You can use the pull-down menu to add a new one."
        text: qsTrId("group_selector.no_groups")
    }

    StandardLabel {
        visible: settings.storedGroups.length > 0
        //% "Saved Groups"
        text: qsTrId("group_selector.stored_groups")
    }

    Repeater {
        id: groupsRepeater
        model: settings.storedGroups

        delegate: ListItem {
            property var item: groupsRepeater.model[index]

            function remove() {
                remorseDelete(function() {
                    settings.storedGroups = settings.storedGroups.filter(function(testedItem) {
                        return testedItem !== item;
                    });
                    if (settings.currentGroupId === item) {
                        settings.currentGroupId = "";
                        pageStack.replace("InitialPage.qml");
                    }
                });
            }

            id: listItem
            width: parent.width - Theme.horizontalPageMargin * 2
            x: Theme.horizontalPageMargin
            contentHeight: Theme.itemSizeMedium
            visible: typeof groupNames[item] !== 'undefined'
            anchors.horizontalCenter: parent.horizontalCenter
            menu: contextMenu

            onClicked: {
                settings.currentGroupId = item;
                settings.currentParticipantId = "";
                if (pageStack.depth === 1) {
                    pageStack.replace("GroupDetailPage.qml")
                } else {
                    pageStack.pop();
                }
            }

            Component {
                 id: contextMenu
                 ContextMenu {
                     IconMenuItem {
                         //% "Remove"
                         text: qsTrId("global.remove")
                         icon.source: "image://theme/icon-m-remove"

                         onClicked: {
                             remove();
                         }
                     }

                     IconMenuItem {
                         //% "Share URL"
                         text: qsTrId("group_selector.share_group_url")
                         icon.source: "image://theme/icon-m-share"

                         onClicked: {
                             sharer.trigger();
                         }

                         ShareAction {
                            readonly property string url: "https://spliit.app/groups/" + item + "/expenses?ref=share"

                            id: sharer
                            mimeType: "text/x-url"
                            resources: [{
                                "data": url,
                                "type": sharer.mimeType,
                                //% "Spliit group %1"
                                "linkTitle": qsTrId("group_selector.share_group.title").arg(visible ? groupNames[item] : ''),
                                "name": qsTrId("group_selector.share_group.title").arg(visible ? groupNames[item] : '') + ".url",
                                "status": url, // whisperfish expects it in this field because... reasons
                            }]
                            //% "Share group %1 link"
                            title: qsTrId("group_selector.share_group.sharer_title").arg(visible ? groupNames[item] : '')
                         }
                     }
                 }
             }

            Label {
                text: visible ? groupNames[item] : ''
                visible: parent.visible
                anchors.centerIn: parent
            }
        }
    }

    Component.onCompleted: {
        fetchGroups();
    }
}
