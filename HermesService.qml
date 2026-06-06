import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root

    // API configuration — overridable by main component from plugin settings
    property string apiUrl: "http://127.0.0.1:8642"
    property string apiKey: "dms-hermes-plugin-key"
    property string model: "hermes-agent"
    property string sessionId: ""

    // Conversation state
    property var messages: []
    property bool loading: false
    property string error: ""

    signal responseReceived(string content)
    signal requestFailed(string errorMsg)

    function getTimestamp() {
        var now = new Date();
        var h = now.getHours().toString().padStart(2, '0');
        var m = now.getMinutes().toString().padStart(2, '0');
        return h + ":" + m;
    }

    function sendMessage(userMessage) {
        if (loading)
            return;

        loading = true;
        error = "";

        // Append user message to history
        var newMessages = messages.slice();
        newMessages.push({
            role: "user",
            content: userMessage,
            timestamp: getTimestamp()
        });
        messages = newMessages;

        // Build the messages JSON array
        var messagesJson = "[";
        for (var i = 0; i < messages.length; i++) {
            if (i > 0)
                messagesJson += ",";
            messagesJson += "{\"role\":\"" + escapeJson(messages[i].role) + "\",\"content\":\"" + escapeJson(messages[i].content) + "\"}";
        }
        messagesJson += "]";

        // Build full request body
        var body = "{\"model\":\"" + escapeJson(root.model) + "\",\"messages\":" + messagesJson + ",\"stream\":false}";

        // Build curl command — $REQUEST_BODY comes from environment (double quotes for expansion)
        var sessionHeader = root.sessionId !== "" ? " -H 'X-Hermes-Session-Id: " + root.sessionId + "'" : "";
        var curlCmd = "curl -sS --connect-timeout 10 --max-time 120" +
            " -X POST '" + root.apiUrl + "/v1/chat/completions'" +
            " -H 'Content-Type: application/json'" +
            " -H 'Authorization: Bearer " + root.apiKey + "'" +
            sessionHeader +
            " -d \"$REQUEST_BODY\"";

        var process = processComponent.createObject(root, {
            command: ["sh", "-c", curlCmd],
            requestBody: body
        });

        if (process) {
            process.running = true;
        } else {
            loading = false;
            error = "创建请求进程失败";
            requestFailed(error);
        }
    }

    function escapeJson(str) {
        if (!str)
            return "";
        var result = str;
        result = result.replace(/\\/g, "\\\\");
        result = result.replace(/"/g, "\\\"");
        result = result.replace(/\n/g, "\\n");
        result = result.replace(/\r/g, "\\r");
        result = result.replace(/\t/g, "\\t");
        return result;
    }

    function handleResponse(output, exitCode) {
        loading = false;

        if (exitCode !== 0) {
            if (exitCode === 7) {
                error = "无法连接 Hermes API。请在 ~/.hermes/.env 中启用 API_SERVER_ENABLED";
            } else if (exitCode === 28) {
                error = "请求超时，Hermes 可能正在处理复杂任务";
            } else {
                error = "请求失败（curl 退出码: " + exitCode + "）";
            }
            // Remove the failed user message
            var newMessages = messages.slice();
            if (newMessages.length > 0 && newMessages[newMessages.length - 1].role === "user") {
                newMessages.pop();
                messages = newMessages;
            }
            requestFailed(error);
            return;
        }

        var raw = output.trim();
        if (!raw) {
            error = "服务器返回空响应";
            requestFailed(error);
            return;
        }

        try {
            var response = JSON.parse(raw);

            if (response.error) {
                error = response.error.message || "API error";
                // Remove the failed user message
                var newMessages = messages.slice();
                if (newMessages.length > 0 && newMessages[newMessages.length - 1].role === "user") {
                    newMessages.pop();
                    messages = newMessages;
                }
                requestFailed(error);
                return;
            }

            var assistantMessage = response.choices?.[0]?.message?.content || "";
            if (!assistantMessage) {
                error = "响应中没有内容";
                requestFailed(error);
                return;
            }

            // Append assistant message to history
            var updatedMessages = messages.slice();
            updatedMessages.push({
                role: "assistant",
                content: assistantMessage,
                timestamp: getTimestamp()
            });
            messages = updatedMessages;

            error = "";
            responseReceived(assistantMessage);
        } catch (e) {
            error = "解析响应失败: " + e.toString();
            requestFailed(error);
        }
    }

    function clearHistory() {
        messages = [];
        sessionId = "";
        error = "";
    }

    function clearError() {
        error = "";
    }

    function stopRequest() {
        for (var i = children.length - 1; i >= 0; i--) {
            var child = children[i];
            if (child && child.command && child.running) {
                child.signal(2);  // SIGINT
                child.signal(15); // SIGTERM
            }
        }
        loading = false;
    }

    Component {
        id: processComponent

        Process {
            id: proc
            property string requestBody: ""

            environment: ({
                "REQUEST_BODY": requestBody
            })

            stdout: StdioCollector {
                onStreamFinished: {
                    proc.outputText = text;
                }
            }

            stderr: StdioCollector {
                onStreamFinished: {
                    if (text.trim()) {
                        console.warn("HermesService: curl stderr:", text.trim());
                    }
                }
            }

            property string outputText: ""

            onExited: (exitCode) => {
                root.handleResponse(outputText, exitCode);
                destroy();
            }
        }
    }
}
