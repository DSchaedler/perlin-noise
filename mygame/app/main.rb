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

require "app/noise.rb"

# Recommended to reduce the frequency if you increase this value.
PIXEL_SCALE = 1
OUTPUT_W = 1280
OUTPUT_H = 720

# number of octaves to use for the values
OCTAVES = 2
# multiplier for the frequency each octave; 2 is common in game dev
LACUNARITY = 2
# multiplier for the amplitude each octave; 0.5 is common in game dev
PERSISTENCE = 0.5

LOG = true

WIDTH = (OUTPUT_W / PIXEL_SCALE).to_i
HEIGHT = (OUTPUT_H / PIXEL_SCALE).to_i

def tick(args)
  $gtk.reset if args.inputs.keyboard.up

  # initialize the noise object. It doesn't actually perform anything yet,
  # just sets up its generation environment.
  args.state.perlin_noise ||= Noise::PerlinNoise.new(
    # required
    width: OUTPUT_W,
    # required
    height: OUTPUT_H,
    # optional
    octaves: OCTAVES,
    # optional
    persistence: PERSISTENCE,
    # optional
    lacunarity: LACUNARITY,
    # optional
    seed: 123
  )

  if args.tick_count == 0
    ts = Time.new
    # this will actually build the x,y noise array
    args.state.noise = build_noise_map(args.state.perlin_noise)
    te = Time.new
  end

  if args.tick_count.zero? && LOG
    puts(te - ts)
    p("noise") if LOG
  end

  ts = Time.new
  convert_pixels(args, args.state.noise) unless args.state.noise_pixels
  te = Time.new
  if args.tick_count.zero? && LOG
    puts(te - ts)
    p("convert_pixels")
  end

  args.state.output ||= false
  args.outputs.static_primitives.concat(args.state.noise_pixels) unless args.state.output
  args.state.output = true
end

def build_noise_map(noise)
  map = []
  width = WIDTH
  height = HEIGHT
  x = 0

  while x < width
    mx = (map[x] = [])
    y = 0
    while y < height
      # get the value at each x,y coordinate
      # based on the init params we specified earlier
      mx[y] = noise.noise2d_value(x, y)
      y += 1
    end

    x += 1
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

  px_scale = PIXEL_SCALE
  while x_iter < width
    y_iter = 0
    nx = noise[x_iter]
    while y_iter < height
      np[y_iter * width + x_iter] = {
        x: x_iter * px_scale,
        y: y_iter * px_scale,
        w: px_scale,
        h: px_scale,
        a: nx[y_iter] * 255,
        primitive_marker: :solid
      }
      y_iter += 1
    end

    x_iter += 1
  end
end
