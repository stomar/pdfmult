# frozen_string_literal: true

require "minitest/autorun"
require "pdfmult"


describe Pdfmult::LaTeXDocument do

  before do
    @layout_class = Pdfmult::Layout
  end

  it "should return the expected LaTeX code for 4 pages" do
    args = {
      pdffile: "sample.pdf",
      layout: @layout_class.new(4),
      page_count: 3
    }
    document_lines = Pdfmult::LaTeXDocument.new(args).to_s.split("\n")
    _(document_lines[0]).must_equal  '\documentclass[a4paper]{article}'
    _(document_lines[-2]).must_equal '\includepdf[pages={3,3,3,3},nup=2x2]{sample.pdf}%'
    _(document_lines.grep(/includepdf/).size).must_equal args[:page_count]
  end

  it "should return the expected LaTeX code for 8 pages" do
    args = {
      pdffile: "sample.pdf",
      layout: @layout_class.new(8),
      page_count: 5
    }
    document_lines = Pdfmult::LaTeXDocument.new(args).to_s.split("\n")
    _(document_lines[0]).must_equal  '\documentclass[a4paper,landscape]{article}'
    _(document_lines[-2]).must_equal '\includepdf[pages={5,5,5,5,5,5,5,5},nup=4x2]{sample.pdf}%'
    _(document_lines.grep(/includepdf/).size).must_equal args[:page_count]
  end
end
