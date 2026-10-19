import QtQuick 6.11
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null

  readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int editIdleMinutes: pluginApi?.pluginSettings?.idleMinutes ?? defaults.idleMinutes ?? 5
  property bool editCountClaude: pluginApi?.pluginSettings?.countClaudeCode ?? defaults.countClaudeCode ?? true
  property string editWorkApps: pluginApi?.pluginSettings?.workApps ?? defaults.workApps ?? ""
  property string editBrowserKeywords: pluginApi?.pluginSettings?.browserKeywords ?? defaults.browserKeywords ?? ""
  property string editPersonalProjects: pluginApi?.pluginSettings?.personalProjects ?? defaults.personalProjects ?? ""

  function saveSettings() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.idleMinutes = root.editIdleMinutes;
    pluginApi.pluginSettings.countClaudeCode = root.editCountClaude;
    pluginApi.pluginSettings.workApps = root.editWorkApps;
    pluginApi.pluginSettings.browserKeywords = root.editBrowserKeywords;
    pluginApi.pluginSettings.personalProjects = root.editPersonalProjects;
    pluginApi.saveSettings();
  }

  NSpinBox {
    label: "Idle after"
    description: "No keyboard or mouse for this long ends a session."
    from: 1
    to: 30
    suffix: " min"
    value: root.editIdleMinutes
    defaultValue: root.defaults.idleMinutes
    onValueChanged: root.editIdleMinutes = value
  }

  NToggle {
    label: "Count Claude Code"
    description: "Time Claude Code is busy in a project counts, even while you're away from the keyboard."
    checked: root.editCountClaude
    defaultValue: root.defaults.countClaudeCode
    onToggled: checked => root.editCountClaude = checked
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Work apps"
    description: "App ids (comma-separated) where your active time counts."
    text: root.editWorkApps
    onTextChanged: root.editWorkApps = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Personal projects"
    description: "Project folder names (comma-separated) that never count, even with Claude Code busy in them."
    text: root.editPersonalProjects
    onTextChanged: root.editPersonalProjects = text
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Work sites"
    description: "Words in a browser tab's title that make it work (comma-separated)."
    text: root.editBrowserKeywords
    onTextChanged: root.editBrowserKeywords = text
  }
}
