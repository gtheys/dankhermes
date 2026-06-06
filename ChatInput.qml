import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
    id: root

    property bool loading: false
    signal sendMessage(string text)

    height: 48

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerHigh
        radius: Theme.cornerRadius

        Row {
            anchors.fill: parent
            anchors.leftMargin: Theme.spacingS
            anchors.rightMargin: Theme.spacingS
            spacing: Theme.spacingS

            DankTextField {
                id: inputField
                width: parent.width - sendBtn.width - Theme.spacingS
                height: parent.height
                placeholderText: root.loading ? "等待回复中..." : "输入消息..."
                enabled: !root.loading

                onAccepted: {
                    if (text.trim() !== "" && !root.loading) {
                        root.sendMessage(text.trim());
                        text = "";
                    }
                }
            }

            Rectangle {
                id: sendBtn
                width: 36
                height: 36
                radius: 18
                anchors.verticalCenter: parent.verticalCenter
                color: root.loading ? Theme.error : (inputField.text.trim() !== "" ? Theme.primary : Theme.surfaceContainerHighest)

                DankIcon {
                    anchors.centerIn: parent
                    name: root.loading ? "stop" : "send"
                    size: 18
                    color: root.loading ? Theme.errorText : (inputField.text.trim() !== "" ? Theme.primaryText : Theme.surfaceVariantText)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.loading) {
                            hermesService.stopRequest();
                        } else if (inputField.text.trim() !== "") {
                            root.sendMessage(inputField.text.trim());
                            inputField.text = "";
                        }
                    }
                }
            }
        }
    }

    function focusInput() {
        inputField.forceActiveFocus();
    }
}
