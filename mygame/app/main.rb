# frozen_string_literal: true

GRID_SIZE = 80
ROWS = 720 / GRID_SIZE
COLUMNS = 1280 / GRID_SIZE
PIXEL_SCALE = 10

def tick(args)
  args.state.starup_done ||= false
  run_startup(args) unless args.state.startup_done

  args.state.grid_array ||= []
  define_grid(args) unless args.state.grid_array != []

  args.state.pixels ||= []
  find_pixel_alphas(args) unless args.state.pixels != []

  args.outputs.primitives << args.state.pixels
end

def define_grid(args)
  COLUMNS.times_with_index do |i|
    args.state.grid_array[i] ||= []
    ROWS.times_with_index do |j|
      args.state.grid_array[i][j] =
        point_at_distance_angle({ point: { x: 0, y: 0 }, distance: 1, angle: (rand * 360).round(0) })
    end
  end
end

def find_pixel_alphas(args)
  (1280 / PIXEL_SCALE).times_with_index do |i|
    args.state.pixels[i] ||= []
    (720 / PIXEL_SCALE).times_with_index do |j|
      # find which grid cell we're in
      ll_corner = { x: ((i * PIXEL_SCALE) - ((i * PIXEL_SCALE) % GRID_SIZE)) / GRID_SIZE,
                    y: ((j * PIXEL_SCALE) - ((j * PIXEL_SCALE) % GRID_SIZE)) / GRID_SIZE }
      ul_corner = { x: ll_corner[:x], y: ll_corner[:y] + 1 }
      lr_corner = { x: ll_corner[:x] + 1, y: ll_corner[:y] }
      ur_corner = { x: ll_corner[:x] + 1, y: ll_corner[:y] + 1 }

      ll_distance = point_difference(point2: { x: ll_corner[:x] * GRID_SIZE, y: ll_corner[:y] * GRID_SIZE },
                                     point1: { x: i * PIXEL_SCALE,
                                               y: j * PIXEL_SCALE })
      ll_distance = normalize_vector(ll_distance)
      ul_distance = point_difference(point2: { x: ul_corner[:x] * GRID_SIZE, y: ul_corner[:y] * GRID_SIZE },
                                     point1: { x: i * PIXEL_SCALE,
                                               y: j * PIXEL_SCALE })
      ul_distance = normalize_vector(ul_distance)
      lr_distance = point_difference(point2: { x: lr_corner[:x] * GRID_SIZE, y: lr_corner[:y] * GRID_SIZE },
                                     point1: { x: i * PIXEL_SCALE,
                                               y: j * PIXEL_SCALE })
      lr_distance = normalize_vector(lr_distance)
      ur_distance = point_difference(point2: { x: ur_corner[:x] * GRID_SIZE, y: ur_corner[:y] * GRID_SIZE },
                                     point1: { x: i * PIXEL_SCALE,
                                               y: j * PIXEL_SCALE })
      ur_distance = normalize_vector(ur_distance)

      dot_products = []

      args.state.grid_array[ll_corner[:x]] ||= []
      args.state.grid_array[ll_corner[:x]][ll_corner[:y]] ||= { x: 0, y: 0 }
      ll_product = vector_dot_product(vector1: args.state.grid_array[ll_corner[:x]][ll_corner[:y]],
                                      vector2: ll_distance)

      args.state.grid_array[ul_corner[:x]] ||= []
      args.state.grid_array[ul_corner[:x]][ul_corner[:y]] ||= { x: 0, y: 0 }
      ul_product = vector_dot_product(vector1: args.state.grid_array[ul_corner[:x]][ul_corner[:y]],
                                      vector2: ul_distance)

      args.state.grid_array[lr_corner[:x]] ||= []
      args.state.grid_array[lr_corner[:x]][lr_corner[:y]] ||= { x: 0, y: 0 }
      lr_product = vector_dot_product(vector1: args.state.grid_array[lr_corner[:x]][lr_corner[:y]],
                                      vector2: lr_distance)

      args.state.grid_array[ur_corner[:x]] ||= []
      args.state.grid_array[ur_corner[:x]][ur_corner[:y]] ||= { x: 0, y: 0 }
      ur_product = vector_dot_product(vector1: args.state.grid_array[ur_corner[:x]][ur_corner[:y]],
                                      vector2: ur_distance)

      left_average = (ll_product + ul_product) / 2
      right_average = (lr_product + ur_product) / 2
      interpolated_value = (left_average + right_average) / 2

      interpolated_value += 1
      interpolated_value *= 64

      args.state.pixels[i][j] =
        { x: i * PIXEL_SCALE, y: j * PIXEL_SCALE, w: 1 * PIXEL_SCALE, h: 1 * PIXEL_SCALE, r: 255, a: interpolated_value,
          primitive_marker: :solid }
    end
  end
end

def run_startup(args)
  args.state.startup_done = true
  putz "Rows: #{ROWS}, Columns: #{COLUMNS}"
end

def normalize_vector(vector)
  length = point_distance(point1: { x: 0, y: 0 }, point2: vector)
  { x: vector[:x] / length, y: vector[:y] / length }
end

def point_average(point1:, point2:)
  { x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2 }
end

def point_at_distance_angle(options = {})
  point = options[:point]
  distance = options[:distance]
  angle = options[:angle]

  new_point = {}

  new_point[:x] = (distance * Math.cos(angle * Math::PI / 180)) + point[:x]
  new_point[:y] = (distance * Math.sin(angle * Math::PI / 180)) + point[:y]
  new_point
end

def point_difference(point1:, point2:)
  { x: (point1.x - point2.x), y: (point1.y - point2.y) }
end

def vector_dot_product(vector1:, vector2:)
  (vector1[:x] * vector2[:x]) + (vector1[:y] * vector2[:y])
end

def point_distance(point1:, point2:)
  dx = (point2.x - point1.x)
  dy = (point2.y - point1.y)
  Math.sqrt((dx * dx) + (dy * dy))
end
