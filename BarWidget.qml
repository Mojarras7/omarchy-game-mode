import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.mojarras7.game-mode"

  property bool active: false
  property string profile: "performance"

  readonly property string statePath: {
    var xdg = Quickshell.env("XDG_STATE_HOME")
    var base = xdg && xdg !== "" ? xdg : (Quickshell.env("HOME") + "/.local/state")
    return base + "/omarchy/game-mode/active"
  }

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  function refreshState() {
    stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var content = String(text() || "").trim()
      root.active = content !== ""
      root.profile = content === "silent" ? "silent" : "performance"
    }
    onLoadFailed: {
      root.active = false
      root.profile = "performance"
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    onTriggered: root.refreshState()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    icon: root.active && root.profile === "silent" ? "󰌪" : "󰊗"
    iconColor: root.active ? Commons.Color.accent : (root.bar ? root.bar.foreground : Commons.Color.foreground)
    tooltipText: root.active
      ? (root.profile === "silent" ? strings.t("tooltip.activeSilent") : strings.t("tooltip.active"))
      : strings.t("tooltip.inactive")

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) {
        root.bar.run("omarchy-game-mode --menu")
      } else if (b === Qt.LeftButton) {
        root.bar.run("omarchy-game-mode")
      }
      Qt.callLater(root.refreshState)
    }
  }
}
