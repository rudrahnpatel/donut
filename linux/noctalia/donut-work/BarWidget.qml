import QtQuick 6.11
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

// Today's working time in the bar, bright while it is counting. Left click
// opens the day's sessions; right click starts or stops a manual session.
Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property var main: pluginApi?.mainInstance
  readonly property bool working: main ? main.working : false

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property bool pillDirection: BarService.getPillDirection(root)

  implicitWidth: isVertical ? capsuleHeight : row.implicitWidth + Style.marginM * 2
  implicitHeight: capsuleHeight

  Rectangle {
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.implicitWidth
    height: root.implicitHeight
    color: mouse.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS
      layoutDirection: root.pillDirection ? Qt.LeftToRight : Qt.RightToLeft

      NIcon {
        icon: root.main && root.main.manual ? "player-record" : "code"
        applyUiScale: false
        color: mouse.containsMouse ? Color.mOnHover : root.working ? Color.mPrimary : Color.mOnSurfaceVariant
      }

      NText {
        visible: !root.isVertical
        family: Settings.data.ui.fontFixed
        pointSize: root.barFontSize
        font.weight: Style.fontWeightBold
        color: mouse.containsMouse ? Color.mOnHover : root.working ? Color.mOnSurface : Color.mOnSurfaceVariant
        text: root.main ? root.main.formatDuration(root.main.todaySeconds) : "–"
      }
    }
  }

  NPopupContextMenu {
    id: menu

    model: [
      {
        "label": root.main && root.main.manual ? "Stop session" : "Start a session",
        "action": "toggle",
        "icon": root.main && root.main.manual ? "player-stop" : "player-play"
      },
      {
        "label": "Open Donut",
        "action": "donut",
        "icon": "clock"
      },
      {
        "label": "Widget settings",
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      menu.close();
      PanelService.closeContextMenu(root.screen);
      if (action === "toggle" && root.main)
        root.main.toggleManual();
      else if (action === "donut")
        Quickshell.execDetached(["gtk-launch", "dev.rudra.donut"]);
      else if (action === "settings")
        BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: event => {
      if (event.button === Qt.LeftButton)
        root.pluginApi?.openPanel(root.screen, root);
      else
        PanelService.showContextMenu(menu, root, root.screen);
    }
  }
}
