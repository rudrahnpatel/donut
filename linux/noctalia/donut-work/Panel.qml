import QtQuick 6.11
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

// Today's work: the total, what is counting right now, a manual start /
// stop, time per project, and each session (drop ones that weren't work).
Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 380 * Style.uiScaleRatio
  property real contentPreferredHeight: 460 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  readonly property var main: pluginApi?.mainInstance

  function clock(ms) {
    const d = new Date(ms);
    return d.toLocaleTimeString(Qt.locale(), "h:mm ap");
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: "Worked today"
        pointSize: Style.fontSizeM
        color: Color.mOnSurfaceVariant
      }

      NText {
        text: root.main ? root.main.formatDuration(root.main.todaySeconds) : "–"
        pointSize: Style.fontSizeXXL * 1.4
        font.weight: Style.fontWeightBold
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: root.main && root.main.working ? Color.mPrimary : Color.mOnSurfaceVariant
        text: !root.main ? "" : root.main.working ? "● Counting · " + root.main.reason : "○ Not counting · " + root.main.reason
      }

      NButton {
        Layout.fillWidth: true
        text: root.main && root.main.manual ? "Stop session" : "Start a session"
        icon: root.main && root.main.manual ? "player-stop" : "player-play"
        onClicked: root.main?.toggleManual()
      }

      NDivider {
        Layout.fillWidth: true
      }

      // Time per project.
      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: {
            if (!root.main)
              return [];
            const p = root.main.projectSeconds;
            return Object.keys(p).sort((a, b) => p[b] - p[a]).map(k => ({
                  "name": k,
                  "seconds": p[k]
                }));
          }

          delegate: Rectangle {
            required property var modelData
            radius: Style.radiusM
            color: Color.mSurfaceVariant
            implicitWidth: chipRow.implicitWidth + Style.marginM * 2
            implicitHeight: chipRow.implicitHeight + Style.marginS * 2

            RowLayout {
              id: chipRow
              anchors.centerIn: parent
              spacing: Style.marginXS

              NText {
                text: modelData.name + " · " + root.main.formatDuration(modelData.seconds)
                pointSize: Style.fontSizeS
              }

              NIconButton {
                icon: "user-off"
                baseSize: Style.baseWidgetSize * 0.6
                tooltipText: "Personal project: stop counting it"
                onClicked: root.main.setPersonal(modelData.name, true)
              }
            }
          }
        }
      }

      // Personal projects, click one to count it again.
      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS
        visible: root.main && root.main.personalProjects.length > 0

        NText {
          text: "Personal:"
          pointSize: Style.fontSizeS
          color: Color.mOnSurfaceVariant
        }

        Repeater {
          model: root.main ? root.main.personalProjects : []

          delegate: NButton {
            required property string modelData
            text: modelData + "  ×"
            fontSize: Style.fontSizeS
            onClicked: root.main.setPersonal(modelData, false)
          }
        }
      }

      NText {
        text: "Sessions"
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }

      NScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          width: parent.width
          spacing: Style.marginS

          Repeater {
            model: root.main ? (root.main.revision, root.main.sessions.slice().reverse()) : []

            delegate: RowLayout {
              required property var modelData
              required property int index
              Layout.fillWidth: true

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                NText {
                  text: root.clock(modelData.start) + " – " + root.clock(modelData.end) + "   " + root.main.formatDuration((modelData.end - modelData.start) / 1000)
                  font.weight: Style.fontWeightBold
                }

                NText {
                  text: Object.keys(modelData.projects).join(", ") + (modelData.manual ? " · manual" : "")
                  color: Color.mOnSurfaceVariant
                  pointSize: Style.fontSizeS
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
              }

              NIconButton {
                icon: "trash"
                tooltipText: "Not work: drop this session"
                onClicked: root.main.discard(root.main.sessions.length - 1 - index)
              }
            }
          }
        }
      }
    }
  }
}
