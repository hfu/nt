# frozen_string_literal: true

# Parser for Jordan transformation parameters
# Jordan transformation is a 2D conformal coordinate transformation
# commonly used for converting between local and standard coordinate systems
class JordanParser
  attr_reader :grid_points

  def initialize
    @grid_points = []
  end

  # Parse a Jordan transformation parameter file
  # Expected format:
  # X Y dX dY (space or comma separated)
  # or
  # ID X Y dX dY dZ (for 3D transformations)
  def parse_file(filename)
    @grid_points = []
    
    File.foreach(filename) do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      # Try comma-separated first, then space-separated
      parts = if line.include?(',')
                line.split(',').map(&:strip)
              else
                line.split(/\s+/)
              end
      
      next if parts.length < 4
      
      grid_point = parse_line(parts)
      @grid_points << grid_point if grid_point
    end
    
    @grid_points
  end

  # Parse a single line
  def parse_line(parts)
    if parts.length >= 6
      # Format: ID X Y dX dY dZ
      point_id = parts[0]
      x = parts[1].to_f
      y = parts[2].to_f
      dx = parts[3].to_f
      dy = parts[4].to_f
      dz = parts[5].to_f
    elsif parts.length >= 5
      # Format: ID X Y dX dY
      point_id = parts[0]
      x = parts[1].to_f
      y = parts[2].to_f
      dx = parts[3].to_f
      dy = parts[4].to_f
      dz = 0.0
    else
      # Format: X Y dX dY
      point_id = "PT#{@grid_points.length + 1}"
      x = parts[0].to_f
      y = parts[1].to_f
      dx = parts[2].to_f
      dy = parts[3].to_f
      dz = 0.0
    end
    
    # Validate
    return nil if x == 0.0 && y == 0.0 && parts[0] != '0' && parts[0] != '0.0'
    
    {
      point_id: point_id,
      x: x,
      y: y,
      latitude: y,      # Assume Y is latitude for NTv2 conversion
      longitude: x,     # Assume X is longitude for NTv2 conversion
      lat_shift: dy,    # dY becomes latitude shift
      lon_shift: dx,    # dX becomes longitude shift
      height_shift: dz
    }
  rescue StandardError => e
    warn "Warning: Failed to parse line: #{parts.join(' ')} - #{e.message}"
    nil
  end

  # Get grid bounds
  def bounds
    return nil if @grid_points.empty?
    
    lats = @grid_points.map { |p| p[:latitude] }
    lons = @grid_points.map { |p| p[:longitude] }
    
    {
      min_lat: lats.min,
      max_lat: lats.max,
      min_lon: lons.min,
      max_lon: lons.max
    }
  end

  # Get grid statistics
  def statistics
    return nil if @grid_points.empty?
    
    lat_shifts = @grid_points.map { |p| p[:lat_shift] }
    lon_shifts = @grid_points.map { |p| p[:lon_shift] }
    
    {
      total_points: @grid_points.length,
      lat_shift_range: [lat_shifts.min, lat_shifts.max],
      lon_shift_range: [lon_shifts.min, lon_shifts.max],
      bounds: bounds
    }
  end
end
