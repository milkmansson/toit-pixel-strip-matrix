// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.   This also file includes derivative 
// work from other authors and sources.  See accompanying documentation.

import io
import gpio
import binary
import font show *
import bitmap show *
// import bitmap show bytemap_zap

import pixel-display show *
//import pixel-display.two-color show *                // color helper
import pixel-display.true-color show *               // color helper 
import pixel-strip show *                            // WS2812B driver (package)

import font-x11-adobe.sans-10
import font-x11-adobe.sans-08
import font-x11-adobe.sans-06
import font-x11-adobe.typewriter-08

import font-tiny.tiny 
import font-tiny.tiny-bigger-digits

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
  xy-to-strip-map_/Map := {:}

  /** Constructor pseudocode:
  1. Establish connection to strip
  2. Build map of xy coords to 1D strip sequence number (to accelerate writes)

  */

  constructor --pin/int --width/int --height/int --serpentine/bool=true:
    width_        = width
    height_       = height
    serpentine_   = serpentine
    total-length_ = height_ * width_
    strip_ = PixelStrip.uart (width * height) --pin=(gpio.Pin pin) --bytes-per-pixel=3
    build-xy-map_
    build-buffer_

  height -> int:       return height_
  width -> int:        return width_
  serpentine -> bool:  return serpentine_

  height value/int -> none:
    height_ = value
    total-length_ = height_ * width_
    build-xy-map_
    build-buffer_

  width value/int -> none:
    width_ = value
    total-length_ = height_ * width_
    build-xy-map_
    build-buffer_

  serpentine value/bool -> none:
    serpentine_ = value
    build-xy-map_

  build-buffer_ -> none:
    red-array   = ByteArray total-length_
    green-array = ByteArray total-length_
    blue-array  = ByteArray total-length_

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

main:
  strip-pin := 17
  gpio-pin  := gpio.Pin 17

  PIXELS    := 8 * 32
  strip  := PixelStrip.uart (8 * 32) --pin=gpio-pin

  r := ByteArray PIXELS
  g := ByteArray PIXELS
  b := ByteArray PIXELS

  // Paint all pixels with #4480ff.
  for i := 0; i <= 10; i += 1:
    r[i] = 0x44
    g[i] = 0x80
    b[i] = 0xff
  
  strip.output r g b
  sleep --ms=500

  r.fill 0x00
  g.fill 0x00
  b.fill 0x00

  strip.output r g b
  gpio-pin.close

  // Here we don't really need it, but in tight animation loops you must
  // occasionally sleep, to avoid triggering the watchdog.
  //sleep --ms=1


  // --pin=17  // Output pin - this is the normal pin for UART 2.

  pixel-matrix   := Pixel-Strip-Matrix --pin=17 --height=8 --width=64
  pixel-display  := PixelDisplay.true-color pixel-matrix
  pixel-display.background = BLACK
  pixel-display.draw

  //SANS-10 ::= Font [sans-10.ASCII, sans-10.LATIN-1-SUPPLEMENT]
  //SANS-08 ::= Font [sans-08.ASCII, sans-08.LATIN-1-SUPPLEMENT]
  //SANS-06 ::= Font [sans-06.ASCII, sans-06.LATIN-1-SUPPLEMENT]

  TYPEWRITER-08 ::= Font [typewriter-08.ASCII, typewriter-08.LATIN-1-SUPPLEMENT]
  //TINY-08 ::= Font [font-tiny.ASCII, font-tiny.LATIN-1-SUPPLEMENT]


  sans := TYPEWRITER-08
  [
    Label --x=0 --y=08 --id="time",
    //Label --x=0 --y=8 --id="date"
  ].do: pixel-display.add it

  STYLE ::= Style
      --type-map={
          "label": Style --font=sans --color=WHITE,
      }
  pixel-display.set-styles [STYLE]

  //date/Label := pixel-display.get-element-by-id "date"
  time/Label := pixel-display.get-element-by-id "time"
  
  while true:
    time.text     = "$(%02d Time.now.local.h):$(%02d Time.now.local.m):$(%02d Time.now.local.s)"
    //date.text     = "$(Time.now.local.year)-$(%02d Time.now.local.month)-$(%02d Time.now.local.day)  -" 

    pixel-display.draw
    sleep --ms=30000
