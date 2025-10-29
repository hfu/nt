# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/jordan_parser'

class TestJordanParser < Minitest::Test
  def setup
    @parser = JordanParser.new
  end

  def test_parse_line_4_parts
    parts = ['139.0', '35.0', '0.001', '0.002']
    result = @parser.parse_line(parts)
    
    assert_equal 'PT1', result[:point_id]
    assert_in_delta 35.0, result[:latitude], 0.0001
    assert_in_delta 139.0, result[:longitude], 0.0001
    assert_in_delta 0.001, result[:lon_shift], 0.000001
    assert_in_delta 0.002, result[:lat_shift], 0.000001
    assert_in_delta 0.0, result[:height_shift], 0.01
  end

  def test_parse_line_5_parts
    parts = ['P1', '139.0', '35.0', '0.001', '0.002']
    result = @parser.parse_line(parts)
    
    assert_equal 'P1', result[:point_id]
    assert_in_delta 35.0, result[:latitude], 0.0001
    assert_in_delta 139.0, result[:longitude], 0.0001
    assert_in_delta 0.001, result[:lon_shift], 0.000001
    assert_in_delta 0.002, result[:lat_shift], 0.000001
  end

  def test_parse_line_6_parts
    parts = ['P1', '139.0', '35.0', '0.001', '0.002', '5.5']
    result = @parser.parse_line(parts)
    
    assert_equal 'P1', result[:point_id]
    assert_in_delta 35.0, result[:latitude], 0.0001
    assert_in_delta 139.0, result[:longitude], 0.0001
    assert_in_delta 0.001, result[:lon_shift], 0.000001
    assert_in_delta 0.002, result[:lat_shift], 0.000001
    assert_in_delta 5.5, result[:height_shift], 0.01
  end

  def test_parse_file
    # Create a temporary test file
    test_file = File.join(Dir.tmpdir, 'test_jordan.txt')
    File.open(test_file, 'w') do |f|
      f.puts "# Comment line"
      f.puts "139.0 35.0 0.001 0.002"
      f.puts "P1 139.1 35.1 0.003 0.004"
      f.puts ""  # Empty line
      f.puts "P2 139.2 35.2 0.005 0.006 10.0"
    end
    
    grid_points = @parser.parse_file(test_file)
    
    assert_equal 3, grid_points.length
    assert_equal 'PT1', grid_points[0][:point_id]
    assert_equal 'P1', grid_points[1][:point_id]
    assert_equal 'P2', grid_points[2][:point_id]
    assert_in_delta 10.0, grid_points[2][:height_shift], 0.01
    
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
end
