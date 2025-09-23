// Copyright (C) 2025 Toit Contributors
// Use of this source code is governed by an MIT-style license that can be
// found in the package's LICENSE file.   This also file includes derivative 
// work from other authors and sources.  See accompanying documentation.

import gpio
import pixel-display show *
import pixel-display.true-color show *

import .toit-pixelstripmatrix.src.pixelstripmatrix as pixelstripmatrix

get-display -> PixelDisplay:
  driver := pixelstripmatrix.Driver --width=16 --height=16 --pin=(gpio.Pin 2) --serpentine=true
  return PixelDisplay.true-color driver


main: 
  
  Ssd1306device  := null
  Ssd1306driver  := null
  Ssd1306display := null
  
  
  Ssd1306display = PixelDisplay.true-color pixelstripmatrix.Driver
  Ssd1306display.background = BLACK
  Ssd1306display.draw












/*
import pixel
import display
import graphics


WIDTH:  int = 16
HEIGHT: int = 8
BRIGHTNESS: float = 0.4  // Scale between 0.0 and 1.0

pixel-strip := pixel.Pixel-out
  --pin=gpio.Pin.out 21
  --length=WIDTH * HEIGHT
  --order=pixel.ColorOrder.GRB


class LEDDisplay:
  - _disp: display.Display
  - _strip: pixel.Pixel
  - _width: int
  - _height: int
  - _zigzag: bool
  - _brightness: float

  constructor new disp:display.Display strip:pixel.Pixel width:int height:int zigzag:bool brightness:float:
    _disp = disp
    _strip = strip
    _width = width
    _height = height
    _zigzag = zigzag
    _brightness = brightness

    _disp.on-flush = -> flush

  flush:
    colors := List pixel.Color _width * _height

    for y := 0; y < _height; y += 1:
      for x := 0; x < _width; x += 1:
        color16 := _disp.get-pixel x y  // Returns 16-bit color (RGB565)
        rgb := _rgb565_to_color color16
        scaled := _scale_brightness rgb _brightness
        index := _map_xy x y
        colors[index] = scaled

    _strip.write colors

  _rgb565_to_color value:
    r := ((value >> 11) & 0x1F) * 255 // 5 bits
    g := ((value >> 5) & 0x3F) * 255 // 6 bits
    b := (value & 0x1F) * 255        // 5 bits

    // Normalize to 0–255
    r = (r + 15) / 31
    g = (g + 31) / 63
    b = (b + 15) / 31

    return pixel.Color.rgb r b g  // Note: GRB order is handled by Pixel driver config

  _scale_brightness color:pixel.Color factor:float -> pixel.Color:
    r := (color.r * factor).to-int
    g := (color.g * factor).to-int
    b := (color.b * factor).to-int
    return pixel.Color.rgb r g b

  _map_xy x y:
    if _zigzag and (y % 2 = 1):
      return y * _width + (_width - 1 - x)
    else:
      return y * _width + x


main:
  disp := display.Display WIDTH HEIGHT
  _ := LEDDisplay disp pixel-strip WIDTH HEIGHT true BRIGHTNESS

  g := graphics.Graphics disp

  hue := 0
  loop:
    g.clear
    g.draw-rect 0 0 WIDTH HEIGHT false

    // Animate RGB text
    color := graphics.Color.hsv hue 1.0 1.0
    g.set-color color
    g.draw-text "Hello!" 1 1

    disp.flush
    hue = (hue + 10) % 360
    sleep --ms=300
*/
