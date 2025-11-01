# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../lib/ntv2_writer'

class TestNTv2Writer < Minitest::Test
  def setup
    @sample_points = [
      { latitude: 35.0, longitude: 139.0, lat_shift: -0.003203, lon_shift: 0.001179, height_shift: -36.12, mesh_code: '5339357700' },
      { latitude: 35.0, longitude: 139.1, lat_shift: -0.003202, lon_shift: 0.001179, height_shift: -36.11, mesh_code: '5339357701' },
      { latitude: 35.1, longitude: 139.0, lat_shift: -0.003194, lon_shift: 0.001176, height_shift: -36.09, mesh_code: '5339357710' },
      { latitude: 35.1, longitude: 139.1, lat_shift: -0.003193, lon_shift: 0.001175, height_shift: -36.08, mesh_code: '5339357711' }
    ]
    @writer = NTv2Writer.new(@sample_points)
  end

  def test_initialize
    assert_instance_of NTv2Writer, @writer
  end

  def test_write_creates_file
    output_file = File.join(Dir.tmpdir, 'test_output.gsb')
    
    # Remove file if it exists
    File.delete(output_file) if File.exist?(output_file)
    
    @writer.write(output_file)
    
    assert File.exist?(output_file)
    assert File.size(output_file) > 0
    
    # Clean up
    File.delete(output_file) if File.exist?(output_file)
  end

  def test_write_binary_format
    output_file = File.join(Dir.tmpdir, 'test_output.gsb')
    
    @writer.write(output_file)
    
    # Read and verify it's binary
    content = File.binread(output_file, 100)
    
    # Check for NTv2 header markers
    assert content.include?('NUM_OREC'), 'Should contain NUM_OREC'
    
    # Clean up
    File.delete(output_file) if File.exist?(output_file)
  end

  def test_empty_grid_points
    empty_writer = NTv2Writer.new([])
    output_file = File.join(Dir.tmpdir, 'test_empty.gsb')
    
    # Should handle empty grid gracefully
    empty_writer.write(output_file)
    
    assert File.exist?(output_file)
    
    # Clean up
    File.delete(output_file) if File.exist?(output_file)
  end
end
