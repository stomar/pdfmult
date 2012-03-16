#!/usr/bin/ruby -w
# test_latex_document.rb: Unit tests for the pdfmult script.
#
# Copyright (C) 2011-2012 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pdfmult'


describe Pdfmult::LaTeXDocument do

  it 'should return the expected LaTeX code' do
    document = Pdfmult::LaTeXDocument.new('sample.pdf', 8, 3)
    document.to_s.split(/\n/)[0].must_equal "\\documentclass[a4paper,landscape]{article}"
    document.to_s.split(/\n/)[-2].must_equal "\\includepdf[pages={3,3,3,3,3,3,3,3},nup=4x2]{sample.pdf}%"
  end
end
