// Colours for a bar face drawn as an outline on the theme's own bar.
//
// Normal values use the bar's text colour. Values that need attention use
// orange or red: the theme's own (colors.toml) when it really is orange or red,
// a standard one otherwise. Several themes name other colours so: green on
// Hackerman, greys on Vantablack and White, blue and magenta on Lupine, a red
// for orange on Matte Black. Either is then darkened (light bar) or lightened
// (dark bar) as little as needed to reach minContrast on the bar's background.
//
// Colours here are [r, g, b] arrays in 0..1, so the file runs under node too.

var minContrast = 3.0

function parseHex(hex) {
  var m = /^#?([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$/.exec(String(hex || "").trim())
  return m ? [parseInt(m[1], 16) / 255, parseInt(m[2], 16) / 255, parseInt(m[3], 16) / 255] : null
}

// The keys of colors.toml that matter here: red and orange, as [r, g, b].
function parsePalette(text) {
  var palette = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var m = /^\s*(red|orange)\s*=\s*["']?(#[0-9A-Fa-f]{6})/.exec(lines[i])
    if (m) palette[m[1]] = parseHex(m[2])
  }
  return palette
}

// Hue in degrees and HSV saturation.
function hueSat(rgb) {
  var max = Math.max(rgb[0], rgb[1], rgb[2]), min = Math.min(rgb[0], rgb[1], rgb[2])
  var d = max - min
  var h = 0
  if (d > 0) {
    if (max === rgb[0]) h = ((rgb[1] - rgb[2]) / d) % 6
    else if (max === rgb[1]) h = (rgb[2] - rgb[0]) / d + 2
    else h = (rgb[0] - rgb[1]) / d + 4
    h = (h * 60 + 360) % 360
  }
  return { hue: h, sat: max > 0 ? d / max : 0 }
}

var standard = { orange: parseHex("#f97316"), red: parseHex("#ef4444") }

function looksLike(kind, rgb) {
  if (!rgb) return false
  var hs = hueSat(rgb)
  if (hs.sat < 0.35) return false
  if (kind === "red") return hs.hue >= 340 || hs.hue <= 12
  return hs.hue > 12 && hs.hue <= 45
}

// "orange" or "red" for this theme on this background.
function attention(kind, palette, background) {
  var own = palette ? palette[kind] : null
  return readable(looksLike(kind, own) ? own : standard[kind], background)
}

function channel(c) {
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
}

// WCAG relative luminance and contrast ratio.
function luminance(rgb) {
  return 0.2126 * channel(rgb[0]) + 0.7152 * channel(rgb[1]) + 0.0722 * channel(rgb[2])
}

function contrast(a, b) {
  var la = luminance(a), lb = luminance(b)
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
}

function mix(a, b, t) {
  return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t]
}

// The colour itself when it reads well enough on the background; otherwise
// the least shift toward black (light background) or white (dark one) that
// does, keeping the hue.
function readable(rgb, background, ratio) {
  var target = ratio || minContrast
  if (!rgb || !background || contrast(rgb, background) >= target) return rgb
  var toward = luminance(background) > 0.18 ? [0, 0, 0] : [1, 1, 1]
  for (var step = 1; step <= 20; step++) {
    var next = mix(rgb, toward, step / 20)
    if (contrast(next, background) >= target) return next
  }
  return toward
}

// The background the face is drawn on. A transparent bar sits on the
// wallpaper, which the shell answers by choosing a light or dark text colour;
// assume the opposite extreme behind it.
function effectiveBackground(background, foreground, transparent) {
  if (!transparent && background) return background
  return luminance(foreground) > 0.4 ? [0, 0, 0] : [1, 1, 1]
}

if (typeof module !== "undefined") {
  module.exports = {
    minContrast: minContrast,
    parseHex: parseHex,
    parsePalette: parsePalette,
    hueSat: hueSat,
    looksLike: looksLike,
    attention: attention,
    luminance: luminance,
    contrast: contrast,
    readable: readable,
    effectiveBackground: effectiveBackground
  }
}
