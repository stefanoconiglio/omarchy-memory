import QtQuick
import Quickshell.Io
import qs.Commons
import "Attention.js" as A

// The colours of a bar face drawn as an outline (Attention.js): the outline,
// the normal text, and orange and red for values that need attention, all
// following the current theme. Shared by the outlined widgets; each plugin
// carries its own copy.
QtObject {
  id: root

  property var bar: null

  readonly property color normal: bar ? bar.barForeground : Color.foreground
  // The outline groups a tool's items without competing with the numbers.
  readonly property color outline: Qt.rgba(normal.r, normal.g, normal.b, 0.45)
  readonly property color dim: Qt.rgba(normal.r, normal.g, normal.b, 0.6)

  readonly property var background: A.effectiveBackground(
    bar ? [bar.background.r, bar.background.g, bar.background.b] : [Color.background.r, Color.background.g, Color.background.b],
    [normal.r, normal.g, normal.b],
    bar ? bar.transparent === true : false)

  property string paletteText: ""
  readonly property var palette: A.parsePalette(paletteText)
  readonly property color orange: toColor(A.attention("orange", palette, background))
  readonly property color red: toColor(A.attention("red", palette, background))

  function toColor(rgb) {
    return Qt.rgba(rgb[0], rgb[1], rgb[2], 1)
  }

  // The shell takes a new theme's colours over IPC (omarchy-theme-set), after
  // the theme's files are in place; reading the file again when its colours
  // change keeps orange and red with the theme.
  property FileView file: FileView {
    path: Color.currentThemePath + "/colors.toml"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.paletteText = text()
  }

  property Connections themeWatch: Connections {
    target: Color
    function onBackgroundChanged() { root.file.reload() }
    function onUrgentChanged() { root.file.reload() }
  }
}
