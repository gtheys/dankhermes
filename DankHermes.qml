import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool slideoutVisible: false
    property var chatMessages: hermesService.messages
    property bool chatLoading: hermesService.loading
    property string chatError: hermesService.error

    HermesService {
        id: hermesService
    }

    Component.onCompleted: {
        if (pluginService) {
            hermesService.apiUrl = pluginService.loadPluginData("dankHermes", "apiUrl", "http://127.0.0.1:8642");
            hermesService.apiKey = pluginService.loadPluginData("dankHermes", "apiKey", "dms-hermes-plugin-key");
            hermesService.model = pluginService.loadPluginData("dankHermes", "model", "hermes-agent");
        }
        hermesService.testConnection();
    }

    function sendMessage(text) {
        if (!text || text.trim() === "")
            return;
        hermesService.sendMessage(text.trim());
    }

    // AIDEV-NOTE: slideOffset is bound to slideoutVisible (see PanelWindow) — the
    // slide animation runs on its own; IPC handlers must NOT touch slideContainer
    // (its id is not visible outside PanelWindow, that was the old crash).
    onSlideoutVisibleChanged: {
        if (slideoutVisible) {
            // Open on the focused monitor, not screens[0] (which may be a
            // lid-closed, inactive laptop panel). Not a binding: the focused
            // screen is resolved at open time.
            slideout.screen = parentScreen || CompositorService.getFocusedScreen();
            slideout.visible = true;
            hermesService.testConnection();
        }
    }

    // --- Slideout (always right side) ---
    PanelWindow {
        id: slideout
        visible: root.slideoutVisible
        screen: parentScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

        WlrLayershell.namespace: "dms:hermes-slideout"
        WlrLayershell.layer: WlrLayershell.Top
        WlrLayershell.exclusiveZone: 0
        WlrLayershell.keyboardFocus: root.slideoutVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors.top: true
        anchors.bottom: true
        anchors.right: true

        implicitWidth: 500
        implicitHeight: screen ? screen.height : 800

        color: "transparent"

        Item {
            id: slideContainer
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 500

            property real slideOffset: root.slideoutVisible ? 0 : width

            Behavior on slideOffset {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                    onRunningChanged: {
                        if (!running && !root.slideoutVisible) {
                            slideout.visible = false;
                        }
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                x: slideContainer.slideOffset

                color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, SettingsData.popupTransparency)
                radius: Theme.cornerRadius
                border.color: Theme.outlineMedium
                border.width: 1

                Rectangle {
                    id: header
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    color: "transparent"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingL
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DankIcon {
                            name: "smart_toy"
                            size: Theme.iconSize
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "Hermes AI"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Connection status dot: green=connected, red=unreachable, grey=checking/unknown
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: hermesService.connectionStatus === "connected" ? Theme.primary
                                 : hermesService.connectionStatus === "unreachable" ? Theme.error
                                 : Theme.surfaceVariantText
                        }

                        // Remote gateway runtime (from /v1/capabilities), e.g. "server · gpt-5"
                        StyledText {
                            visible: hermesService.runtimeMode !== "" || hermesService.runtimeModel !== ""
                            text: hermesService.runtimeMode !== "" && hermesService.runtimeModel !== ""
                                ? hermesService.runtimeMode + " · " + hermesService.runtimeModel
                                : hermesService.runtimeMode + hermesService.runtimeModel
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DankActionButton {
                            iconName: "delete_sweep"
                            iconSize: Theme.iconSize - 4
                            iconColor: Theme.surfaceText
                            onClicked: hermesService.clearHistory()
                        }

                        DankActionButton {
                            iconName: "close"
                            iconSize: Theme.iconSize - 4
                            iconColor: Theme.surfaceText
                            onClicked: root.slideoutVisible = false
                        }
                    }
                }

                Rectangle {
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.outlineMedium
                }

                ChatView {
                    anchors.top: header.bottom
                    anchors.topMargin: 1
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: inputArea.top
                    anchors.bottomMargin: Theme.spacingS
                    anchors.leftMargin: Theme.spacingS
                    anchors.rightMargin: Theme.spacingS

                    messages: root.chatMessages
                    loading: root.chatLoading
                    error: root.chatError
                }

                ChatInput {
                    id: inputArea
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Theme.spacingS

                    loading: root.chatLoading
                    onSendMessage: function(text) { root.sendMessage(text); }
                }
            }
        }
    }

    // --- IPC ---
    IpcHandler {
        function open(): string {
            root.slideoutVisible = true;
            return "HERMES_OPEN_SUCCESS";
        }

        function close(): string {
            root.slideoutVisible = false;
            return "HERMES_CLOSE_SUCCESS";
        }

        function toggle(): string {
            if (root.slideoutVisible) { close(); return "HERMES_TOGGLE_CLOSED"; }
            open(); return "HERMES_TOGGLE_OPENED";
        }

        function newChat(): string {
            hermesService.clearHistory();
            return "HERMES_NEW_CHAT_SUCCESS";
        }

        function sendMessage(message: string): string {
            if (!message || message.trim() === "") return "HERMES_ERROR_EMPTY_MESSAGE";
            root.slideoutVisible = true;
            root.sendMessage(message);
            return "HERMES_MESSAGE_SENT";
        }

        function status(): string {
            return JSON.stringify({
                visible: root.slideoutVisible,
                loading: hermesService.loading,
                messageCount: hermesService.messages.length,
                error: hermesService.error,
                apiUrl: hermesService.apiUrl,
                connectionStatus: hermesService.connectionStatus
            });
        }

        target: "hermes"
    }

    Item { width: 0; height: 0; visible: false }
}
