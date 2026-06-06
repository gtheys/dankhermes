import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property string role: "user"
    property string content: ""
    property string timestamp: ""

    width: parent ? parent.width : 400
    height: bubbleBg.height + Theme.spacingS

    Rectangle {
        id: bubbleBg
        anchors.left: role === "assistant" ? parent.left : undefined
        anchors.right: role === "user" ? parent.right : undefined
        anchors.top: parent.top
        width: parent.width * 0.85
        height: bubbleContent.height + Theme.spacingM * 2
        radius: 8
        color: role === "user" ? Theme.primary : Theme.surfaceContainerHigh
        opacity: role === "user" ? 0.9 : 1.0

        Column {
            id: bubbleContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Theme.spacingM
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            spacing: Theme.spacingXS

            Row {
                spacing: Theme.spacingXS
                visible: role === "assistant"

                DankIcon {
                    name: "smart_toy"
                    size: 14
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "助手"
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                width: parent.width
                text: root.content
                font.pixelSize: Theme.fontSizeMedium
                color: role === "user" ? Theme.primaryText : Theme.surfaceText
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: Theme.spacingXS
                layoutDirection: role === "user" ? Qt.RightToLeft : Qt.LeftToRight

                StyledText {
                    text: root.timestamp
                    font.pixelSize: Theme.fontSizeSmall
                    color: role === "user" ? Qt.rgba(Theme.primaryText.r, Theme.primaryText.g, Theme.primaryText.b, 0.7) : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                DankActionButton {
                    iconName: "content_copy"
                    iconSize: 14
                    iconColor: role === "user" ? Qt.rgba(Theme.primaryText.r, Theme.primaryText.g, Theme.primaryText.b, 0.7) : Theme.surfaceVariantText
                    onClicked: {
                        Quickshell.execDetached(["dms", "cl", "copy", root.content]);
                        ToastService.showInfo("已复制到剪贴板");
                    }
                }
            }
        }
    }
}
