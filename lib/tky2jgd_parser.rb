# frozen_string_literal: true

# Parser for tky2jgd.par format
# tky2jgd.par contains transformation parameters from Tokyo Datum to JGD2000/JGD2011
# Format: mesh code, latitude shift, longitude shift, altitude shift
class Tky2jgdParser
  SECONDS_PER_DEGREE = 3600.0
  
  attr_reader :grid_points

  def initialize
    @grid_points = []
  end

  # Parse a tky2jgd.par file
  # Expected format:
  # MeshCode Lat Lon dB(sec) dL(sec) dH(m)
  def parse_file(filename)
    @grid_points = []
    
    File.foreach(filename) do |line|
      line = line.strip
      next if line.empty? || line.start_with?('#')
      
      parts = line.split(/\s+/)
      next if parts.length < 6
      
      grid_point = parse_line(parts)
      @grid_points << grid_point if grid_point
    end
    
    @grid_points
  end

  # Parse a single line
  def parse_line(parts)
    return nil if parts.length < 6
    
    mesh_code = parts[0]
    lat = parts[1].to_f
    lon = parts[2].to_f
    d_lat = parts[3].to_f / SECONDS_PER_DEGREE  # Convert arcseconds to degrees
    d_lon = parts[4].to_f / SECONDS_PER_DEGREE  # Convert arcseconds to degrees
    d_h = parts[5].to_f
    
    # Validate that we have reasonable values
    return nil if lat == 0.0 && lon == 0.0 && parts[1] != '0.0' && parts[2] != '0.0'
    
    {
      mesh_code: mesh_code,
      latitude: lat,
      longitude: lon,
      lat_shift: d_lat,
      lon_shift: d_lon,
      height_shift: d_h
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
