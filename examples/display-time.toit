// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import io
import gpio
import binary
import font show *
import bitmap show *

import pixel-display show *
import pixel-display.true-color show *               // color helper 
import pixel-strip show *                            // WS2812B driver (package)

import font-x11-adobe.sans-10
import font-x11-adobe.sans-08
import font-x11-adobe.sans-06
import font-x11-adobe.typewriter-08

import font-tiny.tiny 
import font-tiny.tiny-bigger-digits

import ..src.pixel-strip-matrix as pixel-strip-matrix


PIXELS-HEIGHT  ::= 8
PIXELS-WIDTH   ::= 32


main:
  strip-pin    := 17
  gpio-pin     := gpio.Pin 17
  total-pixels := (PIXELS-HEIGHT * PIXELS-WIDTH)
  strip        := PixelStrip.uart total-pixels --pin=gpio-pin

  r := ByteArray total-pixels
  g := ByteArray total-pixels
  b := ByteArray total-pixels

  // TEST: Paint some pixels with #4480ff, To verify correctly operating

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


  // STRIP now verified, start with the display driver

  pixel-matrix   := pixel-strip-matrix.Pixel-Strip-Matrix --pin=gpio-pin --height=PIXELS-HEIGHT --width=PIXELS-WIDTH
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
