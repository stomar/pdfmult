# frozen_string_literal: true

require "minitest/autorun"
require "pdfmult"

SRCPATH = File.dirname(__FILE__)


describe Pdfmult::PDFInfo do

  before do
    @sample_pdf = File.expand_path("#{SRCPATH}/sample.pdf")
  end

  describe "when asked about the page count" do
    it "should return the page count for existing file and system tool" do
      infocmd = Pdfmult::PDFInfo::PDFINFOCMD
      skip("Skipped: `#{infocmd}' not available on the system")  unless Pdfmult::PDFInfo.infocmd_available?
      _(Pdfmult::PDFInfo.new(@sample_pdf).page_count).must_equal 3
      _(Pdfmult::PDFInfo.new(@sample_pdf, pdfinfocmd: infocmd).page_count).must_equal 3
    end

    it "should return nil for non-existent files" do
      _(Pdfmult::PDFInfo.new("not_a_file.pdf").page_count).must_be_nil
    end

    it "should return nil for non-existent `pdfinfo' system tool" do
      _(Pdfmult::PDFInfo.new(@sample_pdf, pdfinfocmd: "not_a_command").page_count).must_be_nil
    end
  end
end
