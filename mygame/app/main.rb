# Dragonruby Implementation of this: https://github.com/mjwhitt/fractal_noise

# ===ORIGINAL LICENSE===

# The MIT License (MIT)
#
# Copyright (c) 2014 Melissa Whittington
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ===BEGIN CODE===

# frozen_string_literal: true

PIXEL_SCALE = 4 # Recommended to reduce the octave if you increase this value.
OUTPUT_W = 1280
OUTPUT_H = 720

OCTAVE = 4 # 0 - 9
FREQUENCY_NUMERATOR = 1.0

Log = false

WIDTH = OUTPUT_W / PIXEL_SCALE
HEIGHT = OUTPUT_H / PIXEL_SCALE

def tick(args)
  $perlin_noise ||= PerlinNoise.new(WIDTH, HEIGHT)
  ts = Time.new
  $noise ||= $perlin_noise.noise(OCTAVE)
  te = Time.new

  if args.tick_count == 0 && Log
    puts(te - ts)
    p("noise") if Log
  end

  ts = Time.new
  convert_pixels($noise) unless $noise_pixels
  te = Time.new
  if args.tick_count == 0 && Log
    puts(te - ts)
    p("convert_pixels")
  end

  $output ||= false
  args.outputs.static_primitives.concat($noise_pixels) unless $output
  $output = true
end

def convert_pixels(noise)
  np = $noise_pixels ||= []
  width = WIDTH
  height = HEIGHT
  x_iter = 0

  while x_iter < width
    y_iter = 0
    while y_iter < height
      np[y_iter * width + x_iter] = {x: x_iter * PIXEL_SCALE, y: y_iter * PIXEL_SCALE, w: 1 * PIXEL_SCALE, h: 1 * PIXEL_SCALE, a: noise[x_iter][y_iter] * 255, primitive_marker: :solid}
      y_iter += 1
    end

    x_iter += 1
  end
end

class PerlinNoise
  def initialize(width, height, random = rand)
    super
    @width = width
    @height = height

    @p = (0...([@width, @height].max)).to_a.shuffle * 2
  end

  def noise(octave)
    noise = []
    period = 1 << octave
    frequency = FREQUENCY_NUMERATOR / period

    w_frequency = @width * frequency
    h_frequency = @height * frequency

    grad_ary = [
      -> (x, y) { y },
      -> (x, y) { x + y },
      -> (x, y) { x },
      -> (x, y) { x - y },
      -> (x, y) { -y },
      -> (x, y) { -x - y },
      -> (x, y) { -x },
      -> (x, y) { -x + y }
    ]

    x_iter = 0
    while x_iter < @width
      nx = noise[x_iter] ||= []
      xa = (x_iter * frequency) % w_frequency
      x1 = xa.to_i
      x2 = (x1 + 1) % w_frequency

      xf = xa - x1
      xb = fade(xf)

      px1 = @p[x1]
      px2 = @p[x2]

      y_iter = 0

      while y_iter < @height
        ya = (y_iter * frequency) % h_frequency
        y1 = ya.to_i
        y2 = (y1 + 1) % h_frequency

        yf = ya - y1
        yb = fade(yf)
        top = linear_interpolation(grad_ary[@p[px1 + y1] & 0x7][xf, yf], grad_ary[@p[px2 + y1] & 0x7][xf - 1, yf], xb)
        bottom = linear_interpolation(grad_ary[@p[px1 + y2] & 0x7][xf, yf - 1], grad_ary[@p[px2 + y2] & 0x7][xf - 1, yf - 1], xb)
        #leaving the old version to check whether my results weren't wrong
        # top = linear_interpolation(gradient(@p[px1 + y1], xf, yf), gradient(@p[px2 + y1], xf - 1, yf), xb)
        # bottom = linear_interpolation(gradient(@p[px1 + y2], xf, yf - 1), gradient(@p[px2 + y2], xf - 1, yf - 1), xb)

        nx[y_iter] = (linear_interpolation(top, bottom, yb) + 1) / 2
        y_iter += 1
      end

      x_iter += 1
    end

    noise
  end

  def interpolate(a, b, alpha)
    linear_interpolation(a, b, alpha)
  end

  def linear_interpolation(a, b, alpha)
    a * (1 - alpha) + b * alpha
  end

  def fade(t)
    t * t * t * (t * (t * 6 - 15) + 10)
  end

  def gradient(h, x, y)
    case h & 7
    when 0
      y
    when 1
      x + y
    when 2
      x
    when 3
      x - y
    when 4
      -y
    when 5
      -x - y
    when 6
      -x
    when 7
      -x + y
    end
  end
end
