import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "dankHermes"

    StyledText {
        width: parent.width
        text: "Hermes API 配置"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Connect to a local or remote Hermes agent. For a remote server, set the API URL to its address (HTTPS supported) and use that server's API key."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "apiUrl"
        label: "API 地址"
        description: "Hermes API server address — local (http://127.0.0.1:8642) or remote (https://hermes.example.com)"
        placeholder: "http://127.0.0.1:8642"
        defaultValue: "http://127.0.0.1:8642"
    }

    StringSetting {
        settingKey: "apiKey"
        label: "API 密钥"
        description: "Hermes API 服务器的认证密钥"
        placeholder: "dms-hermes-plugin-key"
        defaultValue: "dms-hermes-plugin-key"
    }

    StringSetting {
        settingKey: "model"
        label: "模型"
        description: "聊天补全使用的模型名称"
        placeholder: "hermes-agent"
        defaultValue: "hermes-agent"
    }

    StyledText {
        width: parent.width
        text: "For a local Hermes gateway, enable its API server in ~/.hermes/.env and restart it with 'hermes gateway restart':"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Rectangle {
        width: parent.width
        height: envExample.implicitHeight + Theme.spacingM * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        StyledText {
            id: envExample
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            text: "API_SERVER_ENABLED=true\nAPI_SERVER_KEY=dms-hermes-plugin-key\nAPI_SERVER_PORT=8642\nAPI_SERVER_HOST=127.0.0.1"
            font.pixelSize: Theme.fontSizeSmall
            font.family: "monospace"
            color: Theme.surfaceText
            wrapMode: Text.WordWrap
        }
    }
}
