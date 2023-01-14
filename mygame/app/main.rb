# Dragonruby Implementation of this: https://github.com/mjwhitt/fractal_noise

# frozen_string_literal: true

WIDTH   = 400 # 0 - 1280
HEIGHT  = 400 # 0 - 720

# Controls the scale of the noise
# Values 10 or over break, so I'm assuming it's a percentage represented between 0-9
OCTAVE  = 5

def tick(args)
  $perlin_noise ||= PerlinNoise.new(WIDTH, HEIGHT)
  $noise ||= $perlin_noise.noise(OCTAVE)

  convert_pixels($noise) unless $noise_pixels

  $output ||= false
  args.outputs.static_primitives.concat($noise_pixels) unless $output
  $output = true
end

def convert_pixels(noise)
  $noise_pixels ||= []
  x_iter = 0

  while x_iter < WIDTH
    y_iter = 0
    while y_iter < HEIGHT
      $noise_pixels.unshift({ x: x_iter, y: y_iter, w: 1, h: 1, a: noise[x_iter][y_iter] * 255, primitive_marker: :solid })
      y_iter += 1
    end
    x_iter += 1
  end
end

class PerlinNoise
  def initialize(width, height, random = rand())
    super
    @width = width
    @height = height

    @p = (0...([@width, @height].max)).to_a.shuffle * 2
  end

  def noise(octave)
    noise     = []
    period    = 1 << octave
    frequency = 1.0 / period

    w_frequency = @width * frequency
    h_frequency = @height * frequency

    x_iter = 0

    while x_iter < @width
      noise[x_iter] ||= []
      xa = (x_iter * frequency) % w_frequency
      x1 = xa.to_i
      x2 = (x1 + 1) % w_frequency

      xf = xa - xa.to_i
      xb = fade(xf)

      px1 = @p[x1]
      px2 = @p[x2]

      y_iter = 0

      while y_iter < @height
        ya = (y_iter * frequency) % h_frequency
        y1 = ya.to_i
        y2 = (y1 + 1) % h_frequency

        yf = ya - ya.to_i
        yb = fade(yf)

        top    = interpolate(gradient(@p[px1 + y1], xf, yf), gradient(@p[px2 + y1], xf - 1, yf), xb)
        bottom = interpolate(gradient(@p[px1 + y2], xf, yf - 1), gradient(@p[px2 + y2], xf - 1, yf - 1), xb)

        noise[x_iter][y_iter] = (interpolate(top, bottom, yb) + 1) / 2
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
    when 0 then y
    when 1 then x + y
    when 2 then x
    when 3 then x - y
    when 4 then - y
    when 5 then -x - y
    when 6 then -x
    when 7 then -x + y
    end
  end
end
