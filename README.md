# Memory

An Omarchy shell plugin that puts RAM and swap use in the bar, measured the
way `systemd-oomd` measures them, so you can see an out-of-memory kill coming.

![The widget in the bar, left of the battery](preview.png)

On Omarchy, `systemd-oomd` watches your apps. Once RAM in use and swap in use
both pass 90%, it kills the app holding the most swap, and all the tabs of a
terminal window count as one app. A single kill takes the terminal and
everything running in it.

The widget shows two numbers:

- `󰍛` RAM in use: `MemTotal − MemAvailable` from `/proc/meminfo`, the figure
  oomd compares against its limit.
- `󰓡` swap in use: `SwapTotal − SwapFree`.

Each number turns orange once it reaches 85% and red at 90%, where oomd
starts killing; a soft outline groups the two, in bold title-size numbers.
The colours (`Attention.qml`, `Attention.js`): the theme's own orange when it
has a real one (some themes give the name to green, grey or blue), a standard
orange otherwise, and always a standard red; either one darkened or lightened
just enough to read at 3:1 against the bar. Hover for the amounts in GB;
click to open btop.
The numbers update every 3 seconds.

Right-click to see the GB in use instead of the percentages
(`󰍛 12.6G  󰓡 9.4G`), and right-click again to go back. The colours still
follow the percentages, and the choice is kept across restarts (the `units`
setting).

![The widget showing the GB in use](docs/img/2026-10-22-gb-1.png)

New on 22 Oct 2026 ([patch notes](docs/patch-notes.md#2026-10-22-right-click-for-the-gb-in-use)).

## Install

```bash
omarchy plugin add https://github.com/stefanoconiglio/omarchy-memory.git --enable
```

The widget lands in the right section. To put it just before the battery:

```bash
omarchy bar move io.github.stefanoconiglio.memory --section right --before omarchy.power
```

Requires Omarchy Quattro (the Quickshell-based `omarchy-shell`).

## Settings

| Setting       | Default   | Meaning                                                    |
|---------------|-----------|------------------------------------------------------------|
| `warnPercent` | `85`      | RAM or swap share at which its number turns orange         |
| `showSwap`    | `On`      | `Off` shows RAM only; swap still counts toward its colour  |
| `units`       | `Percent` | `GB` shows the GB in use; a right click switches it        |

```bash
omarchy bar set io.github.stefanoconiglio.memory warnPercent 80 --json
omarchy bar set io.github.stefanoconiglio.memory showSwap Off
omarchy bar set io.github.stefanoconiglio.memory units GB
```

On a vertical bar the widget shows only the icon; the colour and tooltip still
work.

## License

MIT
