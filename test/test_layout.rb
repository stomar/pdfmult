require "minitest/autorun"
require "pdfmult"


describe Pdfmult::Layout do

  before do
    @layout = Pdfmult::Layout.new(2)
  end

  it "can return the number of pages" do
    _(@layout.pages).must_equal 2
  end

  it "can return the geometry" do
    _(@layout.geometry).must_equal "2x1"
  end

  it "knows whether it is landscape" do
    _(@layout.landscape?).must_equal true
  end

  it "returns the correct layout for 2 pages" do
    layout = Pdfmult::Layout.new(2)
    _(layout.geometry).must_equal "2x1"
    _(layout.landscape?).must_equal true
  end

  it "returns the correct layout for 4 pages" do
    layout = Pdfmult::Layout.new(4)
    _(layout.geometry).must_equal "2x2"
    _(layout.landscape?).must_equal false
  end

  it "returns the correct layout for 8 pages" do
    layout = Pdfmult::Layout.new(8)
    _(layout.geometry).must_equal "4x2"
    _(layout.landscape?).must_equal true
  end

  it "returns the correct layout for 9 pages" do
    layout = Pdfmult::Layout.new(9)
    _(layout.geometry).must_equal "3x3"
    _(layout.landscape?).must_equal false
  end

  it "returns the correct layout for 16 pages" do
    layout = Pdfmult::Layout.new(16)
    _(layout.geometry).must_equal "4x4"
    _(layout.landscape?).must_equal false
  end
end
