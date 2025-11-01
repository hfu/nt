# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/tky2jgd_parser'

class TestTky2jgdParser < Minitest::Test
  def setup
    @parser = Tky2jgdParser.new
  end

  def test_parse_line
    parts = ['5339357700', '35.6583333', '139.7000000', '-11.5325', '4.2451', '-36.12']
    result = @parser.parse_line(parts)
    
    assert_equal '5339357700', result[:mesh_code]
    assert_in_delta 35.6583333, result[:latitude], 0.0001
    assert_in_delta 139.7000000, result[:longitude], 0.0001
    assert_in_delta -11.5325 / 3600.0, result[:lat_shift], 0.000001
    assert_in_delta 4.2451 / 3600.0, result[:lon_shift], 0.000001
    assert_in_delta -36.12, result[:height_shift], 0.01
  end

  def test_parse_line_invalid
    parts = ['invalid', 'data']
    result = @parser.parse_line(parts)
    
    assert_nil result
  end

  def test_parse_file
    # Create a temporary test file
    test_file = File.join(Dir.tmpdir, 'test_tky2jgd.par')
    File.open(test_file, 'w') do |f|
      f.puts "# Comment line"
      f.puts "5339357700 35.6583333 139.7000000 -11.5325 4.2451 -36.12"
      f.puts "5339357701 35.6583333 139.7083333 -11.5318 4.2447 -36.11"
      f.puts ""  # Empty line
      f.puts "5339357702 35.6583333 139.7166667 -11.5311 4.2443 -36.10"
    end
    
    grid_points = @parser.parse_file(test_file)
    
    assert_equal 3, grid_points.length
    assert_equal '5339357700', grid_points[0][:mesh_code]
    assert_equal '5339357701', grid_points[1][:mesh_code]
    assert_equal '5339357702', grid_points[2][:mesh_code]
    
    File.delete(test_file) if File.exist?(test_file)
  end

  def test_bounds
    @parser.instance_variable_set(:@grid_points, [
      { latitude: 35.0, longitude: 139.0 },
      { latitude: 36.0, longitude: 140.0 },
      { latitude: 35.5, longitude: 139.5 }
    ])
    
    bounds = @parser.bounds
    
    assert_equal 35.0, bounds[:min_lat]
    assert_equal 36.0, bounds[:max_lat]
    assert_equal 139.0, bounds[:min_lon]
    assert_equal 140.0, bounds[:max_lon]
  end

  def test_bounds_empty
    bounds = @parser.bounds
    assert_nil bounds
  end

  def test_statistics
    @parser.instance_variable_set(:@grid_points, [
      { latitude: 35.0, longitude: 139.0, lat_shift: 0.001, lon_shift: 0.002 },
      { latitude: 36.0, longitude: 140.0, lat_shift: 0.003, lon_shift: 0.004 }
    ])
    
    stats = @parser.statistics
    
    assert_equal 2, stats[:total_points]
    assert_equal [0.001, 0.003], stats[:lat_shift_range]
    assert_equal [0.002, 0.004], stats[:lon_shift_range]
  end

  def test_statistics_empty
    stats = @parser.statistics
    assert_nil stats
  end
end
