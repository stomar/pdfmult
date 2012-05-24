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
# If the --latex option is used, though, +pdflatex+ is not run
# and a LaTeX file is created instead of a PDF.
#
# == Options
#
# -n, --number:: Number of copies to put on one page: 2 (default), 4, 8, 9, 16.
#
# -f, --[no-]force:: Do not prompt before overwriting.
#
# -l, --latex:: Create a LaTeX file instead of a PDF file (default: infile_NUMBER.tex).
#
# -o, --output:: Output file (default: infile_NUMBER.pdf).
#                Use - to output to stdout.
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
#   pdfmult sample.pdf -o - | lpr      # =>  sends output via stdout to print command
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
require 'open3'

# This module contains the classes for the +pdfmult+ tool
module Pdfmult

  PROGNAME  = 'pdfmult'
  VERSION   = '1.2.0'
  DATE      = '2012-04-15'
  HOMEPAGE  = 'https://github.com/stomar/pdfmult/'

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
        :force   => false,
        :infile  => nil,
        :latex   => false,
        :number  => 2,
        :outfile => nil,
        :pages   => nil
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
        opt.separator 'pdfmult uses pdflatex with the pdfpages package,'
        opt.separator 'so both have to be installed on the system.'
        opt.separator 'If the --latex option is used, though, pdflatex is not run'
        opt.separator 'and a LaTeX file is created instead of a PDF.'
        opt.separator ''
        opt.separator 'Options'
        opt.separator ''

        # process --version and --help first,
        # exit successfully (GNU Coding Standards)
        opt.on_tail('-h', '--help', 'Prints a brief help message and exits.') do
          puts opt_parser
          puts "\nReport bugs on the #{PROGNAME} home page: <#{HOMEPAGE}>"
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

        opt.on('-f', '--[no-]force', 'Do not prompt before overwriting.') do |f|
          options[:force] = f
        end

        opt.on('-l', '--latex', 'Create a LaTeX file instead of a PDF file (default: file_2.tex).') do
          options[:latex] = true
        end

        opt.on('-o', '--output FILE', String,
               'Output file (default: file_2.pdf). Use - to output to stdout.') do |f|
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
      ext = options[:latex] ? 'tex' : 'pdf'
      infile_without_ext = options[:infile].gsub(/(.pdf)\Z/, '')
      options[:outfile] ||= "#{infile_without_ext}_#{options[:number].to_s}.#{ext}"

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
      "\\end{document}\n"

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
        class_options << ',landscape'
        geometry = '2x1'
      when 4
        geometry = '2x2'
      when 8
        class_options << ',landscape'
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
      Application.command_available?("#{PDFINFOCMD} -v")
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

      infile = options[:infile]
      outfile = options[:outfile]
      use_stdout = (outfile == '-')

      # test for pdflatex installation
      unless options[:latex]
        message = 'seems not to be installed (you might try using the -l option)'
        general_fail("`#{PDFLATEX}' #{message}")  unless command_available?("#{PDFLATEX} --version")
        general_fail("`pdfpages.sty' #{message}")  unless command_available?("#{KPSEWHICH} pdfpages.sty")
      end

      # test input file
      usage_fail("no such file: `#{infile}'")  unless File.exist?(infile)
      usage_fail("specified input not of the type `file'")  unless File.ftype(infile) == 'file'

      # test for existing output file
      if !use_stdout and !options[:force] and File.exist?(outfile)
        overwrite_ok = ask("File `#{outfile}' already exists. Overwrite?")
        exit  unless overwrite_ok
      end

      # set page number (get PDF info if necessary)
      pages = options[:pages]
      pages ||= PDFInfo.new(infile).page_count
      pages ||= 1

      # create LaTeX document
      document = LaTeXDocument.new(infile, options[:number], pages)

      if options[:latex]
        if use_stdout
          puts document.to_s
        else
          warn "Writing on #{outfile}."
          open(outfile, 'w') {|f| f.write(document.to_s) }
        end
      else
        Dir.mktmpdir('pdfmult') do |dir|
          texfile = 'pdfmult.tex'
          pdffile = 'pdfmult.pdf'
          open("#{dir}/#{texfile}", 'w') {|f| f.write(document.to_s) }
          command = "#{PDFLATEX} -output-directory #{dir} #{texfile}"
          Open3.popen3(command) do |stdin, stdout, stderr|
            stdout.each_line {|line| warn line.chomp }  # redirect progress messages to stderr
            stderr.read  # make sure all streams are read (and command has finished)
          end
          if use_stdout
            File.open("#{dir}/#{pdffile}") do |f|
              f.each_line {|line| puts line }
            end
          else
            warn "Writing on #{outfile}."
            FileUtils::mv("#{dir}/#{pdffile}", outfile)
          end
        end
      end
    end

    # Asks for yes or no (y/n).
    #
    # +question+ - string to be printed
    #
    # Returns +true+ if the answer is yes.
    def self.ask(question) # :nodoc:
      while true
        $stderr.print "#{question} [y/n] "
        reply = $stdin.gets.chomp.downcase  # $stdin: avoids gets / ARGV problem
        return true   if reply == 'y'
        return false  if reply == 'n'
        warn "Please answer `y' or `n'."
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
      !!system("#{command} >/dev/null 2>&1")
    end
  end

### call main method only if called on command line

if __FILE__ == $0
  Application.run!
end

end  # module
