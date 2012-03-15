#!/usr/bin/ruby -w
# == Name
#
# pdfmult - put multiple copies of a PDF page on one page
#
# == Synopsis
#
#    pdfmult [options] file
#
# == Description
#
# +pdfmult+ rearranges multiple copies of a PDF page (shrunken) on one page.
#
# The paper size of the produced PDF file is A4,
# the input file is also assumed to be in A4 format.
# The input PDF file may consist of several pages.
# If +pdfmult+ succeeds in obtaining the page count it will rearrange all pages,
# if not, only the first page is processed
# (unless the page count was specified via command line option).
#
# +pdfmult+ uses +pdflatex+ with the +pdfpages+ package,
# so both have to be installed on the system.
#
# == Options
#
# -n, --number:: Number of copies to put on one page: 2 (default), 4, 8, 9, 16.
#
# -o, --output:: Output file (default: infile_NUMBER.pdf).
#
# -p, --pages:: Number of pages to convert.
#               If given, +pdfmult+ does not try to obtain the page count from the source PDF.
#
# -h, --help:: Prints a brief help message and exits.
#
# -v, --version:: Prints a brief version information and exits.
#
# == Examples
#
#   pdfmult sample.pdf                 # =>  sample_2.pdf (2 copies)
#   pdfmult -n 4 sample.pdf            # =>  sample_4.pdf (4 copies)
#   pdfmult sample.pdf -o outfile.pdf  # =>  outfile.pdf  (2 copies)
#   pdfmult sample.pdf -p 3            # =>  processes 3 pages
#
# == Author
#
# Copyright (C) 2011-2012 Marcus Stollsteimer
#
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
#


require 'optparse'
require 'tempfile'
require 'fileutils'

# This module contains the classes for the +pdfmult+ tool
module Pdfmult

  PROGNAME  = 'pdfmult'
  VERSION   = '1.0.0'
  COPYRIGHT = "Copyright (C) 2011-2012 Marcus Stollsteimer.\n" +
              "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n" +
              "This is free software: you are free to change and redistribute it.\n" +
              "There is NO WARRANTY, to the extent permitted by law."

  PDFLATEX  = '/usr/bin/pdflatex'
  KPSEWHICH = '/usr/bin/kpsewhich'

  # Parser for the command line options.
  # The class method parse! does the job.
  class Optionparser

    # Parses the command line options from +argv+.
    # (+argv+ is cleared).
    # Might print out help or version information.
    #
    # +argv+ - array with the command line options
    #
    # Returns a hash containing the option parameters.
    def self.parse!(argv)

      options = {
        :number  => 2,
        :infile  => nil,
        :outfile => nil,
        :pages => nil
      }

      opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: #{PROGNAME} [options] file"
        opt.separator ''
        opt.separator 'pdfmult is a command line tool that'
        opt.separator 'rearranges multiple copies of a PDF page (shrunken) on one page.'
        opt.separator ''
        opt.separator 'The paper size of the produced PDF file is A4,'
        opt.separator 'the input file is also assumed to be in A4 format.'
        opt.separator 'The input PDF file may consist of several pages.'
        opt.separator 'If pdfmult succeeds in obtaining the page count it will rearrange all pages,'
        opt.separator 'if not, only the first page is processed'
        opt.separator '(unless the page count was specified via command line option).'
        opt.separator ''
        opt.separator 'Options'
        opt.separator ''

        # process --version and --help first,
        # exit successfully (GNU Coding Standards)
        opt.on_tail('-h', '--help', 'Prints a brief help message and exits.') do
          puts opt_parser
          puts "\nReport bugs on the pdfmult home page: <https://github.com/stomar/pdfmult/>"
          exit
        end

        opt.on_tail('-v', '--version',
                    'Prints a brief version information and exits.') do
          puts "#{PROGNAME} #{VERSION}"
          puts COPYRIGHT
          exit
        end

        opt.on('-n', '--number NUMBER', ['2', '4', '8', '9', '16'], Integer,
               'Number of copies to put on one page: 2 (default), 4, 8, 9, 16.') do |n|
          options[:number] = n
        end

        opt.on('-o', '--output FILE', String,
               'Output file (default: file_2.pdf).') do |f|
          options[:outfile] = f
        end

        opt.on('-p', '--pages NUMBER', Integer,
               'Number of pages to convert.',
               "If given, #{PROGNAME} does not try to obtain the page count from the source PDF.") do |p|
          raise(OptionParser::InvalidArgument, p)  unless p > 0
          options[:pages] = p
        end

        opt.separator ''
      end
      opt_parser.parse!(argv)

      # only input file should be left in argv
      raise(ArgumentError, 'wrong number of arguments')  if (argv.size != 1 || argv[0] == '')

      options[:infile] = argv.pop

      # set output file unless set by option
      options[:outfile] ||= options[:infile].gsub(/(.pdf)$/, '') + "_#{options[:number].to_s}.pdf"

      options
    end
  end

  # Class for the LaTeX document.
  #
  # Create an instance with LaTeXDocument.new, specifying
  # the input file, the number of pages to put on one page,
  # and the page count of the input file.
  #
  # The method +to_s+ returns the document as multiline string.
  class LaTeXDocument

    attr_accessor :infile, :number, :page_count

    HEADER =
      "\\documentclass[CLASSOPTIONS]{article}\n" +
      "\\usepackage{pdfpages}\n" +
      "\\pagestyle{empty}\n" +
      "\\setlength{\\parindent}{0pt}\n" +
      "\\begin{document}%\n"

    CONTENT =
      "\\includepdf[pages={PAGES},nup=GEOMETRY]{FILENAME}%\n"

    FOOTER =
      '\end{document}'

    # Initializes a LaTeXDocument instance.
    #
    # +infile+     - input file name
    # +number+     - number of pages to put on one page
    # +page_count+ - page count of the input file
    def initialize(infile, number, page_count)
      @infile = infile
      @number = number
      @page_count = page_count
    end

    def to_s
      class_options = 'a4paper'
      page_string = 'PAGE,' * (@number - 1) + 'PAGE'  # 4 copies: e.g. 1,1,1,1

      case @number
      when 2
        class_options += ',landscape'
        geometry = '2x1'
      when 4
        geometry = '2x2'
      when 8
        class_options += ',landscape'
        geometry = '4x2'
      when 9
        geometry = '3x3'
      when 16
        geometry = '4x4'
      end

      content_template = CONTENT.gsub(/PAGES/, page_string).gsub(/GEOMETRY/, geometry).gsub(/FILENAME/, @infile)

      content = HEADER.gsub(/CLASSOPTIONS/, class_options)
      @page_count.times do |i|
        content << content_template.gsub(/PAGE/,"#{i+1}")
      end

      content << FOOTER
    end
  end

  # A class for PDF meta data (up to now only used for the page count).
  #
  # Create an instance with PDFInfo.new, specifying the file name.
  # +PDFInfo+ tries to use the +pdfinfo+ system tool to obtain meta data.
  # If successful, the attribute +page_count+ contains the page count,
  # else the attribute is set to +nil+.
  class PDFInfo

    PDFINFOCMD = '/usr/bin/pdfinfo'

    # Contains the page count of the input file, or nil.
    attr_reader :page_count

    # This is the initialization method for the class.
    #
    # +file+ - file name of the PDF file
    def initialize(file, options={})
      @page_count = nil
      infos = Hash.new

      binary = options[:pdfinfocmd] || PDFINFOCMD  # only for unit tests
      command = "#{binary} #{file}"
      if Application.command_available?(command)
        infostring = `#{command}`
        infostring.each_line do |line|
          key, val = line.chomp.split(/\s*:\s*/, 2)
          infos[key] = val
        end
        value = infos['Pages']
        @page_count = value.to_i  unless value.nil?
      end
    end

    # Returns true if default +pdfinfo+ system tool is available (for unit tests).
    def self.infocmd_available? # :nodoc:
      Application.command_available?(PDFINFOCMD + ' -v')
    end
  end

  # The main program. It's run! method is called
  # if the script is run from the command line.
  # It parses the command line arguments and does the job.
  class Application

    ERRORCODE = {:general => 1, :usage => 2}

    # The main program.
    def self.run!

      # parse options
      begin
        options = Optionparser.parse!(ARGV)
      rescue => e
        usage_fail(e.message)
      end

      # tests
      general_fail("`#{PDFLATEX}' seems not to be installed")  unless command_available?("#{PDFLATEX} --version")
      general_fail("`pdfpages.sty' seems not to be installed")  unless command_available?("#{KPSEWHICH} pdfpages.sty")

      # main body #

      infile = options[:infile]
      outfile = options[:outfile]

      # test input file
      usage_fail("no such file: `#{infile}'")  unless File.exist?(infile)
      usage_fail("specified input not of the type `file'")  unless File.ftype(infile) == 'file'

      # set page number (get PDF info if necessary)
      pages = options[:pages]
      pages ||= PDFInfo.new(infile).page_count
      pages ||= 1

      # create LaTeX document
      document = LaTeXDocument.new(infile, options[:number], pages)

      Dir.mktmpdir('pdfmult') do |dir|
        open("#{dir}/pdfmult.tex", 'w') do |f|
          pdfpath = "#{dir}/pdfmult.pdf"
          f.write(document.to_s)
          f.flush
          system("/usr/bin/pdflatex -output-directory #{dir} pdfmult.tex")
          puts "Writing on #{outfile}."
          FileUtils::mv(pdfpath, outfile)
        end
      end
    end

    # Prints an error message and exits.
    def self.general_fail(message) # :nodoc:
      warn "#{PROGNAME}: #{message}"
      exit ERRORCODE[:general]
    end

    # Prints an error message and a short help information, then exits.
    def self.usage_fail(message) # :nodoc:
      warn "#{PROGNAME}: #{message}"
      warn "Use `#{PROGNAME} --help' for valid options."
      exit ERRORCODE[:usage]
    end

    # Tests silently whether the given system command is available.
    #
    # +command+ - command to test
    def self.command_available?(command) # :nodoc:
      !!system(command + ' >/dev/null 2>&1')
    end
  end

### call main method only if called on command line

if __FILE__ == $0
  Application.run!
end

end  # module
