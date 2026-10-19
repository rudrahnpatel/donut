import QtQuick 6.11
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

// Today's work: the total with personal time beside it, what is counting
// right now (with a compact manual Start / Stop), projects in Work and
// Personal groups (click one to move it; the day recounts), and the work
// sessions, each dropable if it wasn't work at all.
Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: 560 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  readonly property var main: pluginApi?.mainInstance
  readonly property var projectNames: main ? names(main.projectSeconds) : []
  readonly property var workNames: projectNames.filter(n => !main.isPersonal(n))
  readonly property var personalNames: projectNames.filter(n => main.isPersonal(n))

  function clock(ms) {
    return new Date(ms).toLocaleTimeString(Qt.locale(), "h:mm ap");
  }

  function names(bucket) {
    return Object.keys(bucket || {}).sort((a, b) => bucket[b] - bucket[a]);
  }

  function duration(seconds) {
    return main ? main.formatDuration(seconds) : "";
  }

  // A project and its time today; click to move it to the other group.
  // (Inline components can't see this file's ids: the tracker is passed in.)
  component ProjectChip: Rectangle {
    id: chip
    required property string modelData
    required property var tracker
    readonly property bool personal: tracker.isPersonal(modelData)
    radius: Style.radiusM
    color: mouse.containsMouse ? Color.mHover : personal ? "transparent" : Qt.alpha(Color.mPrimary, 0.18)
    border.width: personal ? 1 : 0
    border.color: Color.mOutline
    implicitWidth: label.implicitWidth + Style.marginM * 2
    implicitHeight: label.implicitHeight + Style.marginS * 2

    NText {
      id: label
      anchors.centerIn: parent
      pointSize: Style.fontSizeS
      color: mouse.containsMouse ? Color.mOnHover : chip.personal ? Color.mOnSurfaceVariant : Color.mOnSurface
      text: chip.modelData + " · " + chip.tracker.formatDuration(chip.tracker.projectSeconds[chip.modelData] || 0)
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: chip.tracker.setPersonal(chip.modelData, !chip.personal)
    }
  }

  component SectionLabel: NText {
    pointSize: Style.fontSizeS
    font.weight: Style.fontWeightBold
    color: Color.mOnSurfaceVariant
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Total, and personal time beside it.
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        ColumnLayout {
          spacing: 0

          NText {
            text: "Worked today"
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
          }

          NText {
            text: root.duration(root.main ? root.main.todaySeconds : 0)
            pointSize: Style.fontSizeXXL * 1.4
            font.weight: Style.fontWeightBold
          }
        }

        Item {
          Layout.fillWidth: true
        }

        Rectangle {
          visible: root.main && root.main.personalSeconds > 0
          Layout.alignment: Qt.AlignBottom
          Layout.bottomMargin: Style.marginXS
          radius: Style.radiusM
          color: "transparent"
          border.width: 1
          border.color: Color.mOutline
          implicitWidth: personalText.implicitWidth + Style.marginM * 2
          implicitHeight: personalText.implicitHeight + Style.marginS * 2

          NText {
            id: personalText
            anchors.centerIn: parent
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            text: root.duration(root.main ? root.main.personalSeconds : 0) + " personal"
          }
        }
      }

      // What is counting now, and the manual switch.
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        Rectangle {
          implicitWidth: 8
          implicitHeight: 8
          radius: 4
          color: root.main && root.main.working ? Color.mPrimary : Color.mOutline
        }

        NText {
          Layout.fillWidth: true
          elide: Text.ElideRight
          pointSize: Style.fontSizeS
          color: root.main && root.main.working ? Color.mOnSurface : Color.mOnSurfaceVariant
          text: !root.main ? "" : (root.main.working ? "Counting · " : "Not counting · ") + root.main.reason
        }

        NButton {
          text: root.main && root.main.manual ? "Stop" : "Start"
          icon: root.main && root.main.manual ? "player-stop" : "player-play"
          outlined: !(root.main && root.main.manual)
          fontSize: Style.fontSizeS
          tooltipText: "Count a session by hand"
          onClicked: root.main?.toggleManual()
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      RowLayout {
        Layout.fillWidth: true

        SectionLabel {
          text: "Work"
        }

        Item {
          Layout.fillWidth: true
        }

        NText {
          text: "click a project to move it"
          pointSize: Style.fontSizeXS
          color: Color.mOnSurfaceVariant
        }
      }

      Flow {
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: root.workNames
          delegate: ProjectChip {
            tracker: root.main
          }
        }
      }

      SectionLabel {
        visible: root.personalNames.length > 0
        text: "Personal"
      }

      Flow {
        visible: root.personalNames.length > 0
        Layout.fillWidth: true
        spacing: Style.marginS

        Repeater {
          model: root.personalNames
          delegate: ProjectChip {
            tracker: root.main
          }
        }
      }

      NDivider {
        Layout.fillWidth: true
      }

      SectionLabel {
        text: "Sessions"
      }

      NScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          width: scroll.availableWidth
          spacing: Style.marginS

          Repeater {
            model: root.main ? root.main.sessions.slice().reverse() : []

            delegate: Rectangle {
              id: row
              required property var modelData
              Layout.fillWidth: true
              radius: Style.radiusM
              color: Qt.alpha(Color.mSurfaceVariant, 0.6)
              implicitHeight: rowContent.implicitHeight + Style.marginS * 2

              RowLayout {
                id: rowContent
                anchors.fill: parent
                anchors.leftMargin: Style.marginM
                anchors.rightMargin: Style.marginXS
                anchors.topMargin: Style.marginS
                anchors.bottomMargin: Style.marginS
                spacing: Style.marginS

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  RowLayout {
                    Layout.fillWidth: true

                    NText {
                      text: root.clock(row.modelData.start) + " – " + root.clock(row.modelData.end)
                      font.weight: Style.fontWeightBold
                    }

                    Item {
                      Layout.fillWidth: true
                    }

                    NText {
                      text: root.duration((row.modelData.end - row.modelData.start) / 1000)
                      font.weight: Style.fontWeightBold
                      color: Color.mPrimary
                    }
                  }

                  NText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    pointSize: Style.fontSizeS
                    text: root.names(row.modelData.projects).join(", ")
                  }

                  NText {
                    visible: Object.keys(row.modelData.personal || {}).length > 0
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    text: "with personal: " + root.names(row.modelData.personal).join(", ")
                  }
                }

                NIconButton {
                  icon: "trash"
                  baseSize: Style.baseWidgetSize * 0.8
                  tooltipText: "Not work at all: drop this span"
                  onClicked: root.main.discard(row.modelData)
                }
              }
            }
          }
        }
      }
    }
  }
}
