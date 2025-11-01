# frozen_string_literal: true

# Writer for NTv2 grid format
# NTv2 is a binary format for storing datum transformation grids
class NTv2Writer
  SECONDS_PER_DEGREE = 3600.0
  
  def initialize(grid_points)
    @grid_points = grid_points
    @overview_record = {}
    @sub_grid_records = []
  end

  # Write NTv2 format file
  def write(filename)
    organize_grid
    
    File.open(filename, 'wb') do |f|
      write_overview_record(f)
      @sub_grid_records.each do |sub_grid|
        write_sub_grid(f, sub_grid)
      end
    end
  end

  private

  # Organize grid points into sub-grids
  def organize_grid
    if @grid_points.empty?
      # Handle empty grid with default values
      @min_lat = 0.0
      @max_lat = 0.0
      @min_lon = 0.0
      @max_lon = 0.0
      @lat_spacing = 0.0125
      @lon_spacing = 0.0125
      @gs_count = 0
      return
    end
    
    # Calculate grid boundaries
    lats = @grid_points.map { |p| p[:latitude] }
    lons = @grid_points.map { |p| p[:longitude] }
    
    @min_lat = lats.min
    @max_lat = lats.max
    @min_lon = lons.min
    @max_lon = lons.max
    
    # Determine grid spacing
    unique_lats = lats.uniq.sort
    unique_lons = lons.uniq.sort
    
    @lat_spacing = if unique_lats.length > 1
                      (unique_lats[1] - unique_lats[0]).round(6)
                    else
                      0.0125  # Default 45 arcseconds
                    end
    
    @lon_spacing = if unique_lons.length > 1
                      (unique_lons[1] - unique_lons[0]).round(6)
                    else
                      0.0125  # Default 45 arcseconds
                    end
    
    @gs_count = 1  # Number of sub-grids
    
    # Create single sub-grid (can be extended for multiple sub-grids)
    @sub_grid_records << {
      name: 'TOKYO-JGD',
      parent: 'NONE',
      created: Time.now.strftime('%Y%m%d'),
      updated: Time.now.strftime('%Y%m%d'),
      min_lat: @min_lat,
      max_lat: @max_lat,
      min_lon: @min_lon,
      max_lon: @max_lon,
      lat_spacing: @lat_spacing,
      lon_spacing: @lon_spacing,
      points: @grid_points
    }
  end

  # Write overview record
  def write_overview_record(file)
    # NUM_OREC: Number of header records (11)
    write_record(file, 'NUM_OREC', 'I', 11)
    
    # NUM_SREC: Number of sub-header records (11)
    write_record(file, 'NUM_SREC', 'I', 11)
    
    # NUM_FILE: Number of sub-grids
    write_record(file, 'NUM_FILE', 'I', @gs_count)
    
    # GS_TYPE: Grid shift type (SECONDS)
    write_record(file, 'GS_TYPE ', 'A', 'SECONDS ')
    
    # VERSION: Version number
    write_record(file, 'VERSION ', 'A', 'NTv2.0  ')
    
    # SYSTEM_F: From system (Tokyo)
    write_record(file, 'SYSTEM_F', 'A', 'TOKYO   ')
    
    # SYSTEM_T: To system (JGD2000)
    write_record(file, 'SYSTEM_T', 'A', 'JGD2000 ')
    
    # MAJOR_F: Semi-major axis of from ellipsoid (Bessel 1841)
    write_record(file, 'MAJOR_F ', 'D', 6377397.155)
    
    # MINOR_F: Semi-minor axis of from ellipsoid (Bessel 1841)
    write_record(file, 'MINOR_F ', 'D', 6356078.963)
    
    # MAJOR_T: Semi-major axis of to ellipsoid (GRS80)
    write_record(file, 'MAJOR_T ', 'D', 6378137.0)
    
    # MINOR_T: Semi-minor axis of to ellipsoid (GRS80)
    write_record(file, 'MINOR_T ', 'D', 6356752.314)
  end

  # Write sub-grid header and data
  def write_sub_grid(file, sub_grid)
    lat_count = ((sub_grid[:max_lat] - sub_grid[:min_lat]) / sub_grid[:lat_spacing]).round + 1
    lon_count = ((sub_grid[:max_lon] - sub_grid[:min_lon]) / sub_grid[:lon_spacing]).round + 1
    
    # SUB_NAME: Sub-grid name
    write_record(file, 'SUB_NAME', 'A', sub_grid[:name].ljust(8))
    
    # PARENT: Parent sub-grid name
    write_record(file, 'PARENT  ', 'A', sub_grid[:parent].ljust(8))
    
    # CREATED: Creation date
    write_record(file, 'CREATED ', 'A', sub_grid[:created].ljust(8))
    
    # UPDATED: Update date
    write_record(file, 'UPDATED ', 'A', sub_grid[:updated].ljust(8))
    
    # S_LAT: South latitude
    write_record(file, 'S_LAT   ', 'D', sub_grid[:min_lat])
    
    # N_LAT: North latitude
    write_record(file, 'N_LAT   ', 'D', sub_grid[:max_lat])
    
    # E_LONG: East longitude (positive east)
    write_record(file, 'E_LONG  ', 'D', sub_grid[:max_lon])
    
    # W_LONG: West longitude (positive east)
    write_record(file, 'W_LONG  ', 'D', sub_grid[:min_lon])
    
    # LAT_INC: Latitude increment
    write_record(file, 'LAT_INC ', 'D', sub_grid[:lat_spacing])
    
    # LONG_INC: Longitude increment
    write_record(file, 'LONG_INC', 'D', sub_grid[:lon_spacing])
    
    # GS_COUNT: Number of grid points
    write_record(file, 'GS_COUNT', 'I', lat_count * lon_count)
    
    # Write grid shift data
    write_grid_data(file, sub_grid)
  end

  # Write grid shift data
  def write_grid_data(file, sub_grid)
    lat_count = ((sub_grid[:max_lat] - sub_grid[:min_lat]) / sub_grid[:lat_spacing]).round + 1
    lon_count = ((sub_grid[:max_lon] - sub_grid[:min_lon]) / sub_grid[:lon_spacing]).round + 1
    
    # Create lookup hash for faster access
    point_hash = {}
    sub_grid[:points].each do |point|
      key = [point[:latitude].round(6), point[:longitude].round(6)]
      point_hash[key] = point
    end
    
    # Write in row-major order (west to east, south to north)
    (0...lat_count).each do |i|
      (0...lon_count).each do |j|
        lat = sub_grid[:min_lat] + i * sub_grid[:lat_spacing]
        lon = sub_grid[:min_lon] + j * sub_grid[:lon_spacing]
        
        key = [lat.round(6), lon.round(6)]
        point = point_hash[key]
        
        if point
          # Convert degrees to arcseconds
          lat_shift = point[:lat_shift] * SECONDS_PER_DEGREE
          lon_shift = point[:lon_shift] * SECONDS_PER_DEGREE
          lat_accuracy = 0.0001  # Default accuracy in arcseconds
          lon_accuracy = 0.0001
        else
          # No data at this point
          lat_shift = 0.0
          lon_shift = 0.0
          lat_accuracy = 0.0
          lon_accuracy = 0.0
        end
        
        # Write shift values (4 floats: lat_shift, lon_shift, lat_accuracy, lon_accuracy)
        file.write([lat_shift].pack('f'))
        file.write([lon_shift].pack('f'))
        file.write([lat_accuracy].pack('f'))
        file.write([lon_accuracy].pack('f'))
      end
    end
  end

  # Write a single NTv2 record
  def write_record(file, key, type, value)
    # Key: 8 bytes
    file.write(key.ljust(8)[0, 8])
    
    # Type: 8 bytes
    file.write(type.ljust(8)[0, 8])
    
    # Value: 8 bytes
    case type
    when 'I'
      # Integer
      file.write([value].pack('i'))
      file.write("\x00" * 4)
    when 'D'
      # Double
      file.write([value].pack('d'))
    when 'A'
      # ASCII string
      file.write(value.ljust(8)[0, 8])
    end
  end
end
