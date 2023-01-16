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

PIXEL_SCALE = 4 # Recommended to reduce the frequency if you increase this value.
OUTPUT_W = 1280
OUTPUT_H = 720

# FREQUENCY = 3 # 0 - 9. How gritty or smooth the noise is
BRIGHTNESS = 2 #

OCTAVES = 2 # number of octaves to use for the values
LACUNARITY = 2 # multiplier for the frequency each octave; 2 is common in game dev
PERSISTENCE = 0.5 # multiplier for the amplitude each octave; 0.5 is common in game dev

Log = false

# WIDTH = OUTPUT_W / PIXEL_SCALE
# HEIGHT = OUTPUT_H / PIXEL_SCALE
WIDTH = (OUTPUT_W / PIXEL_SCALE).to_i
HEIGHT = (OUTPUT_H / PIXEL_SCALE).to_i

def tick(args)
  $gtk.reset if args.inputs.keyboard.up

  # args.state.perlin_noise ||= PerlinNoise.new(WIDTH, HEIGHT)

  # initialize the noise object. It doesn't actually perform anything yet,
  # just sets up its generation environment.
  args.state.perlin_noise ||= PerlinNoise.new(
    width: OUTPUT_W, # required
    height: OUTPUT_H, # required
    octaves: OCTAVES, # optional
    persistence: PERSISTENCE, # optional
    lacunarity: LACUNARITY, # optional
    seed: 123 # optional
  )

  # ts = Time.new
  # args.state.noise ||= args.state.perlin_noise.noise(FREQUENCY)
  # te = Time.new

  if args.tick_count.zero?
    ts = Time.new
    # this will actually build the x,y noise array
    args.state.noise ||= build_noise_map(args)
    te = Time.new
  end

  if args.tick_count == 0 && Log
  puts(te - ts)
    p("noise") if Log
  end

  ts = Time.new
  convert_pixels(args, args.state.noise) unless args.state.noise_pixels
  te = Time.new
  if args.tick_count == 0 && Log
    puts(te - ts)
    p("convert_pixels")
  end

  args.state.output ||= false
  args.outputs.static_primitives.concat(args.state.noise_pixels) unless args.state.output
  args.state.output = true
end

def build_noise_map(args)
  map = Array.new(WIDTH) { Array.new(HEIGHT) }
  WIDTH.times do |x|
    HEIGHT.times do |y|
      # get the value at each x,y coordinate
      # based on the init params we specified earlier
      map[x][y] = args.state.perlin_noise.noise2d_value(x, y)
    end
  end
  # This is our completed perlin noise map.
  # Each x,y coordinate will have a float between 0 and 1 (inclusive)
  map
end

def convert_pixels(args, noise)
  np = args.state.noise_pixels ||= []
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
  def initialize(width:, height:, octaves: 1, persistence: 0.5, lacunarity: 2, seed: 123)
    @width = width
    @height = height
    @octaves = octaves
    @persistence = persistence
    @lacunarity = lacunarity
    @p = (0...([@width, @height].max)).to_a.shuffle(Random.new(seed)) * 2
  end

  def noise2d_value(x, y)
    total = 0.0
    amplitude = 1

    @frequency = 0.1
    @octaves.times do |octave|
      total += noise2d(x, y, octave) * amplitude
      amplitude *= @persistence
      @frequency *= @lacunarity
    end
    return total.clamp(0, 1)
  end

  private

  def noise2d(x, y, octave)
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

    period = 1 << octave
    frequency = @frequency / period
    w_frequency = @width * frequency
    h_frequency = @height * frequency

    xa = (x * frequency) % w_frequency
    x1 = xa.to_i
    x2 = (x1 + 1) % w_frequency

    xf = xa - x1
    xb = fade(xf)

    px1 = @p[x1]
    px2 = @p[x2]

    ya = (y * frequency) % h_frequency
    y1 = ya.to_i
    y2 = (y1 + 1) % h_frequency

    yf = ya - y1
    yb = fade(yf)
    top = lerp(grad_ary[@p[px1 + y1] & 0x7][xf, yf], grad_ary[@p[px2 + y1] & 0x7][xf - 1, yf], xb)
    bottom = lerp(grad_ary[@p[px1 + y2] & 0x7][xf, yf - 1], grad_ary[@p[px2 + y2] & 0x7][xf - 1, yf - 1], xb)
    (lerp(top, bottom, yb) + 1) / 2
  end

  def lerp(start, stop, step)
    (stop * step) + (start * (1.0 - step))
  end

  def fade(t)
    t * t * t * ((t * ((t * 6) - 15)) + 10)
  end
end
