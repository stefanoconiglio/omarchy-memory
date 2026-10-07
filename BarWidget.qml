import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// RAM and swap in use, read from /proc/meminfo the way systemd-oomd reads it:
// used memory is MemTotal - MemAvailable, used swap is SwapTotal - SwapFree.
// oomd kills the unit holding the most swap once both pass 90%, so each
// number turns orange at warnPercent and red at 90%, inside a soft outline
// that groups the two (Attention.qml: the theme's own orange and red when it
// has them, always readable on its bar).
//
// Left click opens btop.
BarWidget {
  id: root
  moduleName: "io.github.stefanoconiglio.memory"

  // All in kB, as /proc/meminfo reports them.
  property real memTotal: 0
  property real memUsed: 0
  property real swapTotal: 0
  property real swapUsed: 0

  readonly property int warnPercent: Number(setting("warnPercent", 85))
  readonly property bool showSwap: String(setting("showSwap", "On")) !== "Off" && swapTotal > 0
  readonly property int memPercent: memTotal > 0 ? Math.round(100 * memUsed / memTotal) : 0
  readonly property int swapPercent: swapTotal > 0 ? Math.round(100 * swapUsed / swapTotal) : 0
  readonly property int redPercent: 90

  Attention { id: attention; bar: root.bar }

  function levelColor(percent) {
    if (percent >= redPercent) return attention.red
    if (percent >= warnPercent) return attention.orange
    return attention.normal
  }

  // On a vertical bar the icon alone, and with swap hidden the RAM number, in
  // the colour of the fuller of the two: swap still counts.
  readonly property int worstPercent: Math.max(memPercent, swapTotal > 0 ? swapPercent : 0)

  readonly property string tooltip: memTotal <= 0 ? ""
    : "RAM " + gb(memUsed) + " of " + gb(memTotal) + " GB (" + memPercent + "%)\n"
      + (swapTotal > 0
        ? "Swap " + gb(swapUsed) + " of " + gb(swapTotal) + " GB (" + swapPercent + "%)\n"
        : "No swap\n")
      + "systemd-oomd kills once both pass 90%\n"
      + "Click to open btop"

  function gb(kb) {
    return (kb / 1048576).toFixed(1)
  }

  function update(text) {
    var kb = {}
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^(\w+):\s+(\d+)/)
      if (m) kb[m[1]] = Number(m[2])
    }
    if (!kb.MemTotal) return
    memTotal = kb.MemTotal
    memUsed = kb.MemTotal - (kb.MemAvailable || 0)
    swapTotal = kb.SwapTotal || 0
    swapUsed = swapTotal - (kb.SwapFree || 0)
  }

  function refresh() {
    if (!memProc.running) memProc.running = true
  }

  implicitWidth: vertical ? ramButton.implicitWidth : outlineBox.width + Style.space(10)
  implicitHeight: vertical ? ramButton.implicitHeight : faceRow.implicitHeight

  // procfs files report a size of zero and never fire inotify, so poll with
  // cat rather than a FileView.
  Process {
    id: memProc
    command: ["cat", "/proc/meminfo"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.update(text) }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  function openBtop(b) {
    if (root.bar && b === Qt.LeftButton) root.bar.run("omarchy-launch-or-focus-tui btop")
  }

  // Even width and a height of the bar's parity, so centring leaves no half pixel.
  Rectangle {
    id: outlineBox
    visible: !root.vertical && root.memTotal > 0
    anchors.centerIn: parent
    width: {
      var w = Math.ceil(faceRow.implicitWidth) + Style.space(10)
      return w % 2 === 0 ? w : w + 1
    }
    height: {
      var size = root.bar ? root.bar.barSize : Style.bar.sizeHorizontal
      var h = size - Style.space(6)
      return (size - h) % 2 === 0 ? h : h - 1
    }
    radius: height / 2
    color: "transparent"
    border.width: Math.max(1, Math.round(Style.space(1.5)))
    border.color: attention.outline
  }

  Row {
    id: faceRow
    anchors.centerIn: parent

    WidgetButton {
      id: ramButton
      bar: root.bar
      text: root.memTotal <= 0 ? "" : root.vertical ? "󰍛" : "󰍛 " + root.memPercent + "%"
      foreground: root.levelColor(root.vertical || !root.showSwap ? root.worstPercent : root.memPercent)
      tooltipText: root.tooltip
      horizontalMargin: root.vertical ? 8.75 : 4
      verticalPadding: 8.75
      onPressed: function(b) { root.openBtop(b) }
    }

    WidgetButton {
      id: swapButton
      bar: root.bar
      text: root.memTotal <= 0 || root.vertical || !root.showSwap ? "" : "󰓡 " + root.swapPercent + "%"
      foreground: root.levelColor(root.swapPercent)
      tooltipText: root.tooltip
      horizontalMargin: 4
      verticalPadding: 8.75
      onPressed: function(b) { root.openBtop(b) }
    }
  }
}
