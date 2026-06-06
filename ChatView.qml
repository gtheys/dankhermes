import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
    id: root

    property var messages: []
    property bool loading: false
    property string error: ""

    onMessagesChanged: {
        Qt.callLater(scrollToBottom);
    }

    function scrollToBottom() {
        Qt.callLater(function() {
            flickable.contentY = flickable.contentHeight - flickable.height;
        });
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Flickable {
            id: flickable
            contentWidth: width
            contentHeight: chatColumn.height

            Column {
                id: chatColumn
                width: parent.width
                spacing: Theme.spacingM

                // Empty state — centered logo
                Item {
                    width: parent.width
                    height: 200
                    visible: root.messages.length === 0 && !root.loading

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        DankIcon {
                            name: "smart_toy"
                            size: 48
                            color: Theme.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        StyledText {
                            text: "Hermes AI"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                Repeater {
                    model: root.messages

                    ChatBubble {
                        role: modelData.role
                        content: modelData.content
                        timestamp: modelData.timestamp || ""
                    }
                }

                Item {
                    width: parent.width
                    height: loadingRow.height + Theme.spacingS * 2
                    visible: root.loading

                    Row {
                        id: loadingRow
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "smart_toy"
                            size: 14
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "思考中..."
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: 3

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Theme.primary

                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        running: root.loading

                                        NumberAnimation {
                                            from: 0.3
                                            to: 1.0
                                            duration: 600
                                        }
                                        NumberAnimation {
                                            from: 1.0
                                            to: 0.3
                                            duration: 600
                                        }

                                        PauseAnimation {
                                            duration: index * 200
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: errorColumn.height + Theme.spacingM * 2
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.1)
                    visible: root.error !== ""

                    Column {
                        id: errorColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Theme.spacingM
                        anchors.rightMargin: Theme.spacingM
                        spacing: Theme.spacingXS

                        Row {
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: "error"
                                size: Theme.iconSize - 4
                                color: Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "出错了"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            width: parent.width
                            text: root.error
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.spacingM
                }
            }
        }
    }
}
