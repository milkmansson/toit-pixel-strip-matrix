// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.   This also file includes derivative
// work from other authors and sources.  See accompanying documentation.

import pixel-display show AbstractDriver FLAG-TRUE-COLOR
import pixel-strip show PixelStrip

/**
A pixel-display driver for a WS2812 (Neopixel) strip laid out as a
  two-dimensional panel.

LED 0 is always at (x=0, y=0).  With $PixelStripMatrix.column-major the strip
  runs down the first column (LED 1 is at x=0, y=1); otherwise it runs along
  the first row (LED 1 is at x=1, y=0).  With $PixelStripMatrix.serpentine,
  every odd column (or row) runs in the opposite direction.

# Implementation notes
The display library (pixel-display) calls $draw-true-color with a rectangle
  given as left/top/right/bottom (right and bottom exclusive), even though the
  upstream abstract signature names the parameters x/y/w/h.  This was verified
  by reading pixel-display-impl_.toit: `draw_ left top right bottom canvas`.
Because this driver does not set FLAG-PARTIAL-UPDATES, the display always
  redraws the whole screen in horizontal bands whose height is rounded up to
  $y-rounding (8), so `bottom` may exceed $height.  The driver clips.
WS2812 strips must always be refreshed in full, so the frame is only sent to
  the strip in $commit, which the display calls exactly once per draw.
*/
class PixelStripMatrix extends AbstractDriver:
  // Brightness is reduced by this many bits (1 = half brightness) so a
  // full-white frame does not overload a typical 5V supply.
  static DIM-SHIFT_ ::= 1

  width_/int
  height_/int
  serpentine_/bool
  column-major_/bool
  strip_/PixelStrip
  red_/ByteArray
  green_/ByteArray
  blue_/ByteArray

  /**
  Constructs a driver for a $width x $height panel built from a single strip
    on GPIO number $pin.

  With $column-major the strip runs down the first column before moving to
    the next; otherwise it runs along the first row.  With $serpentine, every
    odd column (or row) is wired in the opposite direction (zig-zag).
  */
  constructor --pin/int --width/int --height/int --serpentine/bool=true --column-major/bool=true:
    width_ = width
    height_ = height
    serpentine_ = serpentine
    column-major_ = column-major
    total := width * height
    red_ = ByteArray total
    green_ = ByteArray total
    blue_ = ByteArray total
    strip_ = PixelStrip.uart total --pin=pin --bytes-per-pixel=3

  width -> int: return width_
  height -> int: return height_
  serpentine -> bool: return serpentine_
  column-major -> bool: return column-major_
  flags -> int: return FLAG-TRUE-COLOR

  /** Returns the strip index of the LED at ($x, $y). */
  strip-index_ x/int y/int -> int:
    if column-major_:
      base := x * height_
      if serpentine_ and (x & 1) == 1:
        return base + (height_ - 1 - y)
      return base + y
    base := y * width_
    if serpentine_ and (y & 1) == 1:
      return base + (width_ - 1 - x)
    return base + x

  /**
  Copies a patch of the canvas into the frame buffers.

  The patch covers $left..$right and $top..$bottom (exclusive) and may extend
    past the panel edges; pixels outside the panel are ignored.  Each of $red,
    $green and $blue is row-major with a stride of `right - left`.
  */
  draw-true-color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    stride := right - left
    x-end := min right width_
    y-end := min bottom height_
    for y := max top 0; y < y-end; y++:
      row := (y - top) * stride
      for x := max left 0; x < x-end; x++:
        k := row + (x - left)
        i := strip-index_ x y
        red_[i] = red[k] >> DIM-SHIFT_
        green_[i] = green[k] >> DIM-SHIFT_
        blue_[i] = blue[k] >> DIM-SHIFT_

  /** Sends the complete frame to the strip. */
  commit left/int top/int right/int bottom/int -> none:
    strip_.output red_ green_ blue_
    // The strip detects a new frame by a pause in transmission.
    sleep --ms=2

  close -> none:
    strip_.close
