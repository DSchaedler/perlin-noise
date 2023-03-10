module Noise
  class PerlinNoise
    def initialize(width:, height:, octaves: 1, persistence: 0.5, lacunarity: 2, seed: 123)
      @width = width
      @height = height
      @octaves = octaves
      @persistence = persistence
      @lacunarity = lacunarity
      @p = (0...([@width, @height].max)).to_a.shuffle(Random.new(seed)) * 2
      @grad_ary = [
        -> (x, y) { y },
        -> (x, y) { x + y },
        -> (x, y) { x },
        -> (x, y) { x - y },
        -> (x, y) { -y },
        -> (x, y) { -x - y },
        -> (x, y) { -x },
        -> (x, y) { -x + y }
      ]
      @cache = []
    end

    def noise2d_value(x, y)
      if !@cache[x]&.[](y)
        cx = (@cache[x] ||= [])
        total = 0.0
        amplitude = 1

        @frequency = 0.1
        octave = 0
        while octave < @octaves
          total += noise2d(x, y, octave) * amplitude
          amplitude *= @persistence
          @frequency *= @lacunarity
          octave += 1
        end

        cx[y] = total.clamp(0, 1)
      else
        @cache[x][y]
      end
    end

    def noise2d(x, y, octave)
      period = 1 << octave
      frequency = @frequency / period
      w_frequency = @width * frequency
      h_frequency = @height * frequency

      xa = (x * frequency) % w_frequency
      x1 = xa.to_i
      x2 = (x1 + 1) % w_frequency

      xf = xa - x1
      xb = xf * xf * xf * ((xf * ((xf * 6) - 15)) + 10)

      px1 = @p[x1]
      px2 = @p[x2]

      ya = (y * frequency) % h_frequency
      y1 = ya.to_i
      y2 = (y1 + 1) % h_frequency

      yf = ya - y1
      yb = yf * yf * yf * ((yf * ((yf * 6) - 15)) + 10)

      tl1 = @grad_ary[@p[px1 + y1] & 0x7][xf, yf]
      tl2 = @grad_ary[@p[px2 + y1] & 0x7][xf - 1, yf]
      top = (tl2 * xb) + (tl1 * (1.0 - xb))

      bl1 = @grad_ary[@p[px1 + y2] & 0x7][xf, yf - 1]
      bl2 = @grad_ary[@p[px2 + y2] & 0x7][xf - 1, yf - 1]
      bottom = (bl2 * xb) + (bl1 * (1.0 - xb))

      ((bottom * yb) + (top * (1.0 - yb)) + 1) / 2
    end

    def lerp(start, stop, step)
      (stop * step) + (start * (1.0 - step))
    end

    def fade(t)
      t * t * t * ((t * ((t * 6) - 15)) + 10)
    end
  end

end
