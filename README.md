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

Both turn the theme's urgent colour once either one reaches 85%. Hover for the
amounts in GB; click to open btop. The numbers update every 3 seconds.

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

| Setting       | Default | Meaning                                                    |
|---------------|---------|------------------------------------------------------------|
| `warnPercent` | `85`    | RAM or swap share at which the widget turns urgent         |
| `showSwap`    | `On`    | `Off` shows RAM only; swap still counts toward the warning |

```bash
omarchy bar set io.github.stefanoconiglio.memory warnPercent 80 --json
omarchy bar set io.github.stefanoconiglio.memory showSwap Off
```

On a vertical bar the widget shows only the icon; the colour and tooltip still
work.

## License

MIT
