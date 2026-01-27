import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property var series: [] // [ { name: "John", value: 133 }, ... ]
    property real maxAbsValue: 1

    function recomputeMaxAbs() {
        var max = 0;
        for (var i = 0; i < series.length; ++i) {
            var v = Math.abs(series[i].value);
            if (v > max) {
                max = v;
            }
        }
        maxAbsValue = (max === 0) ? 1 : max;
    }

    id: chart
    width: parent ? parent.width : Screen.width

    onSeriesChanged: recomputeMaxAbs()

    Repeater {
        model: chart.series

        delegate: Item {
            readonly property real value: modelData.value
            readonly property bool positive: value > 0
            readonly property bool negative: value < 0

            width: chart.width - 2 * Theme.horizontalPageMargin
            height: Theme.itemSizeMedium
            anchors.horizontalCenter: chart.horizontalCenter

            Rectangle {
                id: zeroLine
                x: parent.width / 2 - 1
                width: 2
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Theme.secondaryColor
            }

            Rectangle {
                id: negBar
                visible: negative
                height: parent.height * 0.6
                anchors.verticalCenter: parent.verticalCenter
                width: (parent.width / 2) * (-value / chart.maxAbsValue)
                x: parent.width / 2 - width
                radius: 2
                color: Theme.errorColor

                Label {
                    text: modelData.valueLabel
                    color: Theme.primaryColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingSmall
                    horizontalAlignment: Text.AlignRight
                    font.bold: true
                }
            }

            Rectangle {
                id: posBar
                visible: positive
                height: parent.height * 0.6
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width / 2
                width: (parent.width / 2) * (value / chart.maxAbsValue)
                radius: 2
                color: Theme.secondaryColor

                Label {
                    text: modelData.valueLabel
                    color: Theme.primaryColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingSmall
                    horizontalAlignment: Text.AlignLeft
                    font.bold: true
                }
            }

            Label {
                visible: positive
                text: modelData.name
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: zeroLine.left
                anchors.rightMargin: Theme.paddingSmall
                horizontalAlignment: Text.AlignRight
                truncationMode: TruncationMode.Fade
            }

            Label {
                visible: negative || !positive
                text: modelData.name
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: zeroLine.right
                anchors.leftMargin: Theme.paddingSmall
                horizontalAlignment: Text.AlignLeft
                truncationMode: TruncationMode.Fade
            }
        }
    }

    Component.onCompleted: recomputeMaxAbs()
}
