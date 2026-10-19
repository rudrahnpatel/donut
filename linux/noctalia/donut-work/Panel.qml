import QtQuick 6.11
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

// Today's work: the total (and personal time beside it), what is counting
// right now, a manual start / stop, every project as a chip you click to
// switch between work and personal (the day recounts), and the work
// sessions with their split (drop one that wasn't work at all).
Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: 520 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  readonly property var main: pluginApi?.mainInstance

  function clock(ms) {
    return new Date(ms).toLocaleTimeString(Qt.locale(), "h:mm ap");
  }

  function names(bucket) {
    return Object.keys(bucket || {}).sort((a, b) => bucket[b] - bucket[a]);
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

      RowLayout {
        spacing: Style.marginL

        NText {
          text: root.main ? root.main.formatDuration(root.main.todaySeconds) : "–"
          pointSize: Style.fontSizeXXL * 1.4
          font.weight: Style.fontWeightBold
        }

        NText {
          visible: root.main && root.main.personalSeconds > 0
          text: root.main ? "+ " + root.main.formatDuration(root.main.personalSeconds) + " personal" : ""
          color: Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: Style.marginXS
        }
      }

      NText {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: root.main && root.main.working ? Color.mPrimary : Color.mOnSurfaceVariant
        text: !root.main ? "" : (root.main.working ? "● Counting · " : "○ Not counting · ") + root.main.reason
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

      NText {
        text: "Projects · click to switch work / personal"
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
      }

      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: root.main ? root.names(root.main.projectSeconds) : []

          delegate: Rectangle {
            id: chip
            required property string modelData
            readonly property bool personal: root.main.isPersonal(modelData)
            radius: Style.radiusM
            color: chipMouse.containsMouse ? Color.mHover : personal ? "transparent" : Qt.alpha(Color.mPrimary, 0.18)
            border.width: personal ? 1 : 0
            border.color: Color.mOutline
            implicitWidth: chipText.implicitWidth + Style.marginM * 2
            implicitHeight: chipText.implicitHeight + Style.marginS * 2

            NText {
              id: chipText
              anchors.centerIn: parent
              pointSize: Style.fontSizeS
              font.strikeout: chip.personal
              color: chipMouse.containsMouse ? Color.mOnHover : chip.personal ? Color.mOnSurfaceVariant : Color.mOnSurface
              text: (chip.personal ? "personal · " : "") + chip.modelData + " · " + root.main.formatDuration(root.main.projectSeconds[chip.modelData] || 0)
            }

            MouseArea {
              id: chipMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.main.setPersonal(chip.modelData, !chip.personal)
            }
          }
        }
      }

      NText {
        text: "Work sessions"
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
            model: root.main ? root.main.sessions.slice().reverse() : []

            delegate: RowLayout {
              required property var modelData
              Layout.fillWidth: true

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                NText {
                  text: root.clock(modelData.start) + " – " + root.clock(modelData.end) + "   " + root.main.formatDuration((modelData.end - modelData.start) / 1000)
                  font.weight: Style.fontWeightBold
                }

                NText {
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                  pointSize: Style.fontSizeS
                  text: root.names(modelData.projects).join(", ")
                }

                NText {
                  visible: Object.keys(modelData.personal || {}).length > 0
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                  pointSize: Style.fontSizeS
                  color: Color.mOnSurfaceVariant
                  text: "alongside, personal: " + root.names(modelData.personal).join(", ")
                }
              }

              NIconButton {
                icon: "trash"
                tooltipText: "Not work at all: drop this span"
                onClicked: root.main.discard(modelData)
              }
            }
          }
        }
      }
    }
  }
}
