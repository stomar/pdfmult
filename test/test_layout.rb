# test_layout.rb: Unit tests for the pdfmult script.
#
# Copyright (C) 2011-2017 Marcus Stollsteimer

require 'minitest/autorun'
require 'pdfmult'


describe Pdfmult::Layout do

  before do
    @layout = Pdfmult::Layout.new(2)
  end

  it 'can return the number of pages' do
    @layout.pages.must_equal 2
  end

  it 'can return the geometry' do
    @layout.geometry.must_equal '2x1'
  end

  it 'knows whether it is landscape' do
    @layout.landscape?.must_equal true
  end

  it 'returns the correct layout for 2 pages' do
    layout = Pdfmult::Layout.new(2)
    layout.geometry.must_equal '2x1'
    layout.landscape?.must_equal true
  end

  it 'returns the correct layout for 4 pages' do
    layout = Pdfmult::Layout.new(4)
    layout.geometry.must_equal '2x2'
    layout.landscape?.must_equal false
  end

  it 'returns the correct layout for 8 pages' do
    layout = Pdfmult::Layout.new(8)
    layout.geometry.must_equal '4x2'
    layout.landscape?.must_equal true
  end

  it 'returns the correct layout for 9 pages' do
    layout = Pdfmult::Layout.new(9)
    layout.geometry.must_equal '3x3'
    layout.landscape?.must_equal false
  end

  it 'returns the correct layout for 16 pages' do
    layout = Pdfmult::Layout.new(16)
    layout.geometry.must_equal '4x4'
    layout.landscape?.must_equal false
  end
end
