// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.   This also file includes derivative 
// work from other authors and sources.  See accompanying documentation.

import io
import gpio
import binary
import bitmap show *

import pixel-display show *
import pixel-display.true-color show *               // color helper 
import pixel-strip show *                            // WS2812B driver (package)

/**
Started with the idea of using a lookup table - but it doesn't seem to be proving too efficient.

Running a new function now that calculates the pixel strip position, given an x/y from the
driver drawing functions.

Reading the WS2812 driver, it doesn't support getting a partial update - eg, just a small set of
pixels being updated.

Constructor pseudocode:
  1. Establish connection to strip
  2. Build an R, G and B buffer
  3. Copy in updates
  4. Push out buffer whenever 'draw' called 

State:
  1. xy-to-strip-map_ being commented out - seems to cause a heap crash on second or third test
     without rebooting the ESP32.

*/


class Pixel-Strip-Matrix extends AbstractDriver:     // “TrueColor” compatible
  width_/int             := ? 
  height_/int            := ?
  serpentine_/bool       := ?
  total-length_/int      := ?
  strip_/PixelStrip      := ?
  flags/int              := 0
  red-array/ByteArray    := #[]
  green-array/ByteArray  := #[]
  blue-array/ByteArray   := #[]


  // A map where map[x,y] holds the *strip index* for position (x,y):
  //xy-to-strip-map_/Map := {:}

  constructor --pin/gpio.Pin --width/int --height/int --serpentine/bool=true:
    width_        = width
    height_       = height
    serpentine_   = serpentine
    total-length_ = height_ * width_
    strip_ = PixelStrip.uart (width * height) --pin=pin --bytes-per-pixel=3
    build-buffer_
    //build-xy-map_

  height -> int:       return height_
  width -> int:        return width_
  serpentine -> bool:  return serpentine_

  height value/int -> none:
    height_ = value
    total-length_ = height_ * width_
    build-buffer_
    //build-xy-map_

  width value/int -> none:
    width_ = value
    total-length_ = height_ * width_
    build-buffer_
    //build-xy-map_

  serpentine value/bool -> none:
    serpentine_ = value
    //build-xy-map_

  build-buffer_ -> none:
    red-array   = ByteArray total-length_
    green-array = ByteArray total-length_
    blue-array  = ByteArray total-length_

  /*
  // Map keyed with x & y packed into 64 bit key
  pack x y -> int:
    return ((x & 0xFFFFFFFF) << 32) | (y & 0xFFFFFFFF)

  // led index for (x,y) in a lookup map with x&y packed as a key
  build-xy-map_ -> none:
    xy-to-strip-map_ = {:}
    counter/int     := 0
    for x := 0; x <= width_ - 1; x += 1:
      if serpentine_ and (x % 2 == 1):
        for y := height_ - 1; y >= 0; y -= 1:
          xy-to-strip-map_[pack x y] = counter
          counter += 1
      else:
        for y := 0; y <= height_ - 1; y += 1:
          xy-to-strip-map_[pack x y] = counter
          counter += 1
  */

  // led index for (x,y)
  compute-index x y -> int:
    base := x * height_
    if serpentine_ and (x % 2 == 1):
      return base + (height_ - 1 - y)
    else:
      return base + y

  draw-true-color left/int top/int right/int bottom/int red/ByteArray green/ByteArray blue/ByteArray -> none:
    if left < 0 or top < 0 or right > width_ or bottom > height_:
      return

    // Fast linear walk over the patch.
    // 'k' is the linear index into red/green/blue for (x,y) within the patch.
    k := 0

    for y := top; y <= (bottom - 1); y += 1:
      for x := left; x <= (right - 1); x += 1:
        // Map absolute (x,y) to LED index in panel/strip.
        //led-seq-number := xy-to-strip-map_[pack x y]
        led-seq-number := compute-index x y

        //print "$(x) $(y) = $(led-seq-number)"
        //red-array[led-seq-number]   = red[k] / 2
        blit red[k..] red-array[led-seq-number..] 1
        green-array[led-seq-number] = green[k] / 2
        blue-array[led-seq-number]  = blue[k] / 2

        // Next pixel in the patch row.
        k = k + 1

    strip_.output red-array green-array blue-array
    sleep --ms=2
