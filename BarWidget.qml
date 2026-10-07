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

  implicitWidth: vertical ? iconButton.implicitWidth : outlineBox.width + Style.space(10)
  implicitHeight: vertical ? iconButton.implicitHeight : barSize


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
      var w = Math.ceil(numbers.width) + Style.space(8)
      return w % 2 === 0 ? w : w + 1
    }
    height: {
      var h = root.barSize - Style.space(6)
      return (root.barSize - h) % 2 === 0 ? h : h - 1
    }
    radius: height / 2
    color: "transparent"
    border.width: Math.max(1, Math.round(Style.space(1.5)))
    border.color: attention.outline
  }

  // On a vertical bar, the icon alone.
  WidgetButton {
    id: iconButton
    anchors.fill: parent
    bar: root.bar
    text: root.vertical && root.memTotal > 0 ? "󰍛" : ""
    foreground: root.levelColor(root.worstPercent)
    tooltipText: root.tooltip
    horizontalMargin: 8.75
    verticalPadding: 8.75
    onPressed: function(b) { root.openBtop(b) }
  }

  // The numbers in the outlined widgets' type (bold, title size), drawn by
  // hand since WidgetButton has no bold: so the item registers as a click
  // target and reports tooltipHovered itself, as WidgetButton would.
  Item {
    id: numbers
    visible: !root.vertical && root.memTotal > 0
    anchors.centerIn: parent
    width: numbersRow.width + Style.space(8)
    height: root.barSize
    readonly property bool tooltipHovered: numbersMouse.containsMouse

    Component.onCompleted: if (root.bar && root.bar.registerClickTarget) root.bar.registerClickTarget(numbers)
    Component.onDestruction: if (root.bar && root.bar.unregisterClickTarget) root.bar.unregisterClickTarget(numbers)

    FontMetrics { id: numberMetrics; font: ramText.font }
    // Digits set the baseline, so the numbers sit centred in the bar.
    TextMetrics { id: digitInk; font: ramText.font; text: "88" }
    // Room for two digits, so 9% turning into 10% doesn't move the bar.
    TextMetrics { id: slotInk; font: ramText.font; text: "󰍛 88%" }

    Row {
      id: numbersRow
      x: Style.space(4)
      y: Math.round((numbers.height - digitInk.tightBoundingRect.height) / 2
                    - digitInk.tightBoundingRect.y - numberMetrics.ascent)
      spacing: Style.space(10)

      BarNumber {
        id: ramText
        text: "󰍛 " + root.memPercent + "%"
        color: root.levelColor(root.showSwap ? root.memPercent : root.worstPercent)
      }
      BarNumber {
        visible: root.showSwap
        text: "󰓡 " + root.swapPercent + "%"
        color: root.levelColor(root.swapPercent)
      }
    }

    MouseArea {
      id: numbersMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: if (root.bar) root.bar.showTooltip(numbers, root.tooltip)
      onExited: if (root.bar) root.bar.hideTooltip(numbers)
      onClicked: function(mouse) {
        if (root.bar) root.bar.hideTooltip(numbers)
        root.openBtop(mouse.button)
      }
    }
  }

  component BarNumber: Text {
    width: Math.max(implicitWidth, slotInk.width)
    textFormat: Text.PlainText
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.title
    font.bold: true
  }
}
