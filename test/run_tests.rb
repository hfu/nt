#!/usr/bin/env ruby
# frozen_string_literal: true

# Test runner for all tests
require 'minitest/autorun'

# Require all test files
Dir[File.join(__dir__, 'test_*.rb')].each { |file| require file }
