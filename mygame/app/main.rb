# Dragonruby Implementation of this: https://github.com/mjwhitt/fractal_noise

# frozen_string_literal: true

WIDTH   = 1280 # 0 - 1280
HEIGHT  = 720 # 0 - 720

# Controls the scale of the noise
# Values over 10 break, so I'm assuming it's a percentage represented between 0-10
OCTAVE  = 5 

def tick(args)
  $perlin_noise ||= PerlinNoise.new(WIDTH, HEIGHT)
  $noise ||= $perlin_noise.noise(OCTAVE)

  convert_pixels($noise) unless $noise_pixels

  args.outputs.primitives << $noise_pixels
end

def convert_pixels(noise)
  noise.length.times_with_index do |x|
    noise[x].length.times_with_index do |y|
      $noise_pixels ||= []
      $noise_pixels << { x: x, y: y, w: 1, h: 1, a: noise[x][y] * 255, primitive_marker: :solid }
    end
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

    @width.times do |x|
      noise[x] ||= []
      xa = (x * frequency) % (@width * frequency)
      x1 = xa.to_i
      x2 = (x1 + 1) % (@width * frequency)

      xf = xa - xa.to_i
      xb = fade(xf)

      @height.times do |y|
        ya = (y * frequency) % (@height * frequency)
        y1 = ya.to_i
        y2 = (y1 + 1) % (@height * frequency)

        yf = ya - ya.to_i
        yb = fade(yf)

        top    = interpolate(gradient(@p[@p[x1] + y1], xf, yf), gradient(@p[@p[x2] + y1], xf - 1, yf), xb)
        bottom = interpolate(gradient(@p[@p[x1] + y2], xf, yf - 1), gradient(@p[@p[x2] + y2], xf - 1, yf - 1), xb)

        noise[x][y] = (interpolate(top, bottom, yb) + 1) / 2
      end
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
