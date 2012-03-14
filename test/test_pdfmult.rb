#!/usr/bin/ruby -w
# test_pdfmult: Unit tests for the pdfmult script.
#
# Copyright (C) 2011-2012 Marcus Stollsteimer

require 'rubygems'
require 'minitest/spec'
require 'minitest/autorun'
load 'pdfmult'

PROGNAME    = 'test_pdfmult.rb'
PROGVERSION = '0.0.1'

SRCPATH = File.dirname(__FILE__)


describe Pdfmult::Optionparser do

  it 'should return the correct default values' do
    options = Pdfmult::Optionparser.parse!(['sample.pdf'])
    expected = {
      :infile => 'sample.pdf',
      :outfile => 'sample_2.pdf',
      :number => 2,
      :pages => nil
    }
    options.must_equal expected
  end

  it 'should recognize the -n option and set the corresponding output filename' do
    options = Pdfmult::Optionparser.parse!(['sample.pdf', '-n', '4'])
    options[:outfile].must_equal 'sample_4.pdf'
    options[:number].must_equal 4
  end

  it 'should not accept invalid -n option values' do
    lambda { Pdfmult::Optionparser.parse!(['sample.pdf', '-n', '3']) }.must_raise OptionParser::InvalidArgument
  end

  it 'should recognize the -o option' do
    options = Pdfmult::Optionparser.parse!(['sample.pdf', '-o', 'outfile.pdf'])
    options[:outfile].must_equal 'outfile.pdf'
  end

  it 'should recognize the -p option' do
    options = Pdfmult::Optionparser.parse!(['sample.pdf', '-p', '4'])
    options[:pages].must_equal 4
  end

  it 'should only accept positive -p option values' do
    lambda { Pdfmult::Optionparser.parse!(['sample.pdf', '-p', '0.5']) }.must_raise OptionParser::InvalidArgument
    lambda { Pdfmult::Optionparser.parse!(['sample.pdf', '-p', '0']) }.must_raise OptionParser::InvalidArgument
    lambda { Pdfmult::Optionparser.parse!(['sample.pdf', '-p', '-1']) }.must_raise OptionParser::InvalidArgument
  end

  it 'should not accept wrong number of arguments' do
    lambda { Pdfmult::Optionparser.parse!(['sample.pdf', 'sample2.pdf']) }.must_raise ArgumentError
    lambda { Pdfmult::Optionparser.parse!(['']) }.must_raise ArgumentError
    lambda { Pdfmult::Optionparser.parse!([]) }.must_raise ArgumentError
  end

  it 'should not accept invalid options' do
    lambda { Pdfmult::Optionparser.parse!(['-x']) }.must_raise OptionParser::InvalidOption
  end
end


describe Pdfmult::LaTeXDocument do

  it 'should return the expected LaTeX code' do
    document = Pdfmult::LaTeXDocument.new('sample.pdf', 8, 3)
    document.to_s.split(/\n/)[0].must_equal "\\documentclass[a4paper,landscape]{article}"
    document.to_s.split(/\n/)[-2].must_equal "\\includepdf[pages={3,3,3,3,3,3,3,3},nup=4x2]{sample.pdf}%"
  end
end


describe Pdfmult::PDFInfo do

  before do
    @sample_pdf = File.expand_path("#{SRCPATH}/sample.pdf")
  end

  describe 'when asked about the page count' do
    it 'should return the page count for existing file and system tool' do
      infocmd = Pdfmult::PDFInfo::PDFINFOCMD
      skip("Skipped: `#{infocmd}' not available on the system")  unless Pdfmult::PDFInfo.infocmd_available?
      Pdfmult::PDFInfo.new(@sample_pdf).page_count.must_equal 3
      Pdfmult::PDFInfo.new(@sample_pdf, :pdfinfocmd => infocmd).page_count.must_equal 3
    end

    it 'should return nil for non-existent files' do
      Pdfmult::PDFInfo.new('not_a_file.pdf').page_count.must_be_nil
    end

    it "should return nil for non-existent `pdfinfo' system tool" do
      Pdfmult::PDFInfo.new(@sample_pdf, :pdfinfocmd => 'not_a_command').page_count.must_be_nil
    end
  end
end
