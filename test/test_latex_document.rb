# test_latex_document.rb: Unit tests for the pdfmult script.
#
# Copyright (C) 2011-2012 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pdfmult'


describe Pdfmult::LaTeXDocument do

  before do
    @layout_class = Pdfmult::Layout
  end

  it 'should return the expected LaTeX code for 4 pages' do
    layout = @layout_class.new(4)
    document_lines = Pdfmult::LaTeXDocument.new('sample.pdf', layout, 3).to_s.split(/\n/)
    document_lines[0].must_equal  '\documentclass[a4paper]{article}'
    document_lines[-2].must_equal '\includepdf[pages={3,3,3,3},nup=2x2]{sample.pdf}%'
  end

  it 'should return the expected LaTeX code for 8 pages' do
    layout = @layout_class.new(8)
    document_lines = Pdfmult::LaTeXDocument.new('sample.pdf', layout, 3).to_s.split(/\n/)
    document_lines[0].must_equal  '\documentclass[a4paper,landscape]{article}'
    document_lines[-2].must_equal '\includepdf[pages={3,3,3,3,3,3,3,3},nup=4x2]{sample.pdf}%'
  end
end
