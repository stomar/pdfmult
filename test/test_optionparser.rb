require "minitest/autorun"
require "pdfmult"


describe Pdfmult::Optionparser do

  it "should return the correct default values" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf"])
    expected = {
      force: false,
      infile: "sample.pdf",
      latex: false,
      number: 2,
      outfile: "sample_2.pdf",
      pages: nil,
      silent: false
    }
    _(options).must_equal expected
  end

  it "should recognize the -n option and set the corresponding output filename" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-n", "4"])
    _(options[:outfile]).must_equal "sample_4.pdf"
    _(options[:number]).must_equal 4
  end

  it "should not accept invalid -n option values" do
    _ { Pdfmult::Optionparser.parse!(["sample.pdf", "-n", "3"]) }.must_raise OptionParser::InvalidArgument
  end

  it "should recognize the -o option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-o", "outfile.pdf"])
    _(options[:outfile]).must_equal "outfile.pdf"
  end

  it "should recognize the -p option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-p", "4"])
    _(options[:pages]).must_equal 4
  end

  it "should recognize the -f option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-f"])
    _(options[:force]).must_equal true
  end

  it "should recognize the --no-force option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "--no-force"])
    _(options[:force]).must_equal false
  end

  it "should recognize the -l option and set the corresponding output filename" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-l"])
    _(options[:outfile]).must_equal "sample_2.tex"
    _(options[:latex]).must_equal true
  end

  it "should only accept positive -p option values" do
    _ { Pdfmult::Optionparser.parse!(["sample.pdf", "-p", "0.5"]) }.must_raise OptionParser::InvalidArgument
    _ { Pdfmult::Optionparser.parse!(["sample.pdf", "-p", "0"]) }.must_raise OptionParser::InvalidArgument
    _ { Pdfmult::Optionparser.parse!(["sample.pdf", "-p", "-1"]) }.must_raise OptionParser::InvalidArgument
  end

  it "should recognize the -s option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "-s"])
    _(options[:silent]).must_equal true
  end

  it "should recognize the --no-silent option" do
    options = Pdfmult::Optionparser.parse!(["sample.pdf", "--no-silent"])
    _(options[:silent]).must_equal false
  end

  it "should not accept wrong number of arguments" do
    _ { Pdfmult::Optionparser.parse!(["sample.pdf", "sample2.pdf"]) }.must_raise ArgumentError
    _ { Pdfmult::Optionparser.parse!([""]) }.must_raise ArgumentError
    _ { Pdfmult::Optionparser.parse!([]) }.must_raise ArgumentError
  end

  it "should not accept invalid options" do
    _ { Pdfmult::Optionparser.parse!(["-x"]) }.must_raise OptionParser::InvalidOption
  end
end
