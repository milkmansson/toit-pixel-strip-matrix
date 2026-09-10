# pixel-strip-matrix

A [pixel-display](https://github.com/toitware/toit-pixel-display) driver that
turns a WS2812 / Neopixel strip, wired as a two-dimensional panel, into a
true-colour display. Anything the display library can draw (labels, fonts,
shapes, PNGs) can then be rendered on the panel.

The strip itself is driven by the
[pixel-strip](https://github.com/toitware/toit-pixel-strip) package over the
UART peripheral.

## Requirements

- An ESP32-family board running Toit, with a free UART.
- A WS2812/WS2812B strip. The UART backend inverts the TX pin by default; see
  the pixel-strip docs if your level shifter also inverts.
- Packages: `pixel-display`, `pixel-strip`, and a font package if you want text.

```sh
toit pkg install github.com/toitware/toit-pixel-display
toit pkg install github.com/toitware/toit-pixel-strip
toit pkg install github.com/toitware/toit-font-x11-adobe   # Optional, for text.
```

## Wiring layout

Physically the LEDs are one long chain. The driver needs to know how that
chain snakes across the panel. LED 0 is always the top-left pixel `(0, 0)`.

| Option                      | Meaning                                                              |
|-----------------------------|----------------------------------------------------------------------|
| `--column-major` (default)  | The chain runs *down* the first column, then the second, and so on. |
| `--no-column-major`         | The chain runs *along* the first row, then the second, and so on.   |
| `--serpentine` (default)    | Every odd column (or row) runs in the opposite direction (zig-zag).  |
| `--no-serpentine`           | Every column (or row) runs in the same direction.                    |

Example, a 4×3 panel with `--column-major --serpentine`:

```
x:   0   1   2   3
y=0  0   5   6  11
y=1  1   4   7  10
y=2  2   3   8   9
```

The same panel with `--no-column-major --serpentine`:

```
x:   0   1   2   3
y=0  0   1   2   3
y=1  7   6   5   4
y=2  8   9  10  11
```

If your panel's data-in is at a different corner, mirror your drawing with the
display library's `--inverted` / `--portrait` options or a custom `Transform`.

## Usage

```toit
import pixel-display show *
import pixel-display.true-color show *
import font show *
import font-x11-adobe.typewriter-08

import .pixel-strip-matrix

main:
  driver := PixelStripMatrix
      --pin=7            // GPIO number, not a gpio.Pin object.
      --width=38
      --height=8
      --serpentine       // Default; --no-serpentine for straight wiring.
      --column-major     // Default; --no-column-major for row-wise wiring.

  display := PixelDisplay.true-color driver
  display.background = BLACK

  font := Font [typewriter-08.ASCII]
  clock := Label --x=0 --y=8 --id="clock"
  display.add clock
  display.set-styles [
    Style --type-map={"label": Style --font=font --color=WHITE},
  ]

  while true:
    now := Time.now.local
    clock.text = "$(%02d now.h):$(%02d now.m):$(%02d now.s)"
    display.draw
    sleep --ms=1000
```

Call `driver.close` (or `display.close`) when you are done to release the
UART and GPIO. Only one `PixelStrip` may be opened on a given pin — do not
create your own `PixelStrip.uart` on the same pin alongside the driver.

## Behaviour and limitations

- **Whole-frame refresh.** WS2812 strips cannot be partially updated, so the
  driver keeps a full frame buffer and sends the entire strip once per
  `display.draw`, regardless of how little changed.
- **Any size works.** Width and height need not be multiples of 8; the driver
  clips the 8-pixel-aligned bands the display library produces.
- **Brightness.** All channels are halved (`DIM-SHIFT_ = 1`) so a full-white
  frame doesn't overload a typical 5 V supply. Change the constant if your
  supply can take it, or if you want full range.
- **Colour order.** RGB strips only (`bytes-per-pixel=3`). RGBW is not
  supported.
- **Frame pacing.** The driver sleeps 2 ms after each frame so the strip sees
  the reset gap it needs. Keep your own draw loop slower than that.
- **Runtime resizing** is not supported; create a new driver instead.

## How it fits together

```
Label / Element  ──►  PixelDisplay (dirty tracking, 8-px bands)
                              │  draw-true-color left top right bottom r g b
                              ▼
                      PixelStripMatrix (clip, map (x,y) → strip index, buffer)
                              │  commit → strip.output
                              ▼
                      PixelStrip.uart  ──►  WS2812 chain
```
