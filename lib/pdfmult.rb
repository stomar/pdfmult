#!/usr/bin/env ruby
# frozen_string_literal: true

# == Name
#
# pdfmult - put multiple copies of a PDF page on one page
#
# == Description
#
# +pdfmult+ rearranges multiple copies of a PDF page (shrunken) on one page.
#
# == See also
#
# Use <tt>pdfmult --help</tt> to display a brief help message.
#
# The full documentation for +pdfmult+ is available on the
# project home page.
#
# == Author
#
# Copyright (C) 2011-2024 Marcus Stollsteimer
#
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>

require "optparse"
require "tempfile"
require "open3"
require "erb"

# This module contains the classes for the +pdfmult+ tool.
module Pdfmult

  PROGNAME  = "pdfmult"
  VERSION   = "1.4.0"
  DATE      = "2024-01-05"
  HOMEPAGE  = "https://github.com/stomar/pdfmult/"
  TAGLINE   = "puts multiple copies of a PDF page on one page"

  COPYRIGHT = <<~TEXT
    Copyright (C) 2011-2024 Marcus Stollsteimer.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
  TEXT

  PDFLATEX  = "/usr/bin/pdflatex"
  KPSEWHICH = "/usr/bin/kpsewhich"

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
        force: false,
        infile: nil,
        latex: false,
        number: 2,
        outfile: nil,
        silent: false,
        pages: nil
      }

      opt_parser = OptionParser.new do |opt|
        opt.banner = "Usage: #{PROGNAME} [options] file"
        opt.separator ""
        opt.separator <<~DESCRIPTION
          pdfmult is a command line tool that
          rearranges multiple copies of a PDF page (shrunken) on one page.

          The paper size of the produced PDF file is A4,
          the input file is also assumed to be in A4 format.
          The input PDF file may consist of several pages.
          If pdfmult succeeds in obtaining the page count it will rearrange all pages,
          if not, only the first page is processed
          (unless the page count was specified via command line option).

          pdfmult uses pdflatex with the pdfpages package,
          so both have to be installed on the system.
          If the --latex option is used, though, pdflatex is not run
          and a LaTeX file is created instead of a PDF.

          Options:
        DESCRIPTION

        # process --version and --help first,
        # exit successfully (GNU Coding Standards)
        opt.on_tail("-h", "--help", "Print a brief help message and exit.") do
          puts opt_parser
          puts "\nReport bugs on the #{PROGNAME} home page: <#{HOMEPAGE}>"
          exit
        end

        opt.on_tail("-v", "--version",
                    "Print a brief version information and exit.") do
          puts "#{PROGNAME} #{VERSION}"
          puts COPYRIGHT
          exit
        end

        opt.on("-n", "--number NUMBER", %w[2 4 8 9 16], Integer,
               "Number of copies to put on one page: 2 (default), 4, 8, 9, 16.") do |n|
          options[:number] = n
        end

        opt.on("-f", "--[no-]force", "Do not prompt before overwriting.") do |f|
          options[:force] = f
        end

        opt.on("-l", "--latex", "Create a LaTeX file instead of a PDF file (default: file_2.tex).") do
          options[:latex] = true
        end

        opt.on("-o", "--output FILE", String,
               "Output file (default: file_2.pdf). Use - to output to stdout.") do |f|
          options[:outfile] = f
        end

        opt.on("-p", "--pages NUMBER", Integer,
               "Number of pages to convert.",
               "If given, #{PROGNAME} does not try to obtain the page count from the source PDF.") do |p|
          raise(OptionParser::InvalidArgument, p)  unless p.positive?

          options[:pages] = p
        end

        opt.on("-s", "--[no-]silent", "Do not output progress information.") do |s|
          options[:silent] = s
        end

        opt.separator ""
      end
      opt_parser.parse!(argv)

      # only input file should be left in argv
      raise(ArgumentError, "wrong number of arguments")  if argv.size != 1 || argv[0].empty?

      options[:infile] = argv.pop

      # set output file unless set by option
      ext = options[:latex] ? "tex" : "pdf"
      infile_without_ext = options[:infile].delete_suffix(".pdf")
      options[:outfile] ||= "#{infile_without_ext}_#{options[:number]}.#{ext}"

      options
    end
  end

  # Class for the page layout.
  #
  # Create an instance with Layout.new, specifying
  # the number of pages to put on one page.
  # Layout#geometry returns the geometry string.
  class Layout

    attr_reader :pages, :geometry

    GEOMETRY = {
      2 => "2x1",
      4 => "2x2",
      8 => "4x2",
      9 => "3x3",
      16 => "4x4"
    }.freeze

    def initialize(pages)
      @pages = pages
      @geometry = GEOMETRY[pages]
    end

    def landscape?
      %w[2x1 4x2].include?(geometry)
    end
  end

  # Class for the LaTeX document.
  #
  # Create an instance with LaTeXDocument.new, specifying the
  # input file, the layout, and the page count of the input file.
  #
  # The method +to_s+ returns the document as multiline string.
  class LaTeXDocument

    attr_reader :pdffile, :layout, :page_count

    TEMPLATE = <<~'LATEX'
      \documentclass[<%= class_options %>]{article}
      \usepackage{pdfpages}
      \pagestyle{empty}
      \setlength{\parindent}{0pt}
      \begin{document}
      % pages_strings.each do |pages|
      \includepdf[pages={<%= pages %>},nup=<%= geometry %>]{<%= pdffile %>}%
      % end
      \end{document}
    LATEX

    # Initializes a LaTeXDocument instance.
    # Expects an argument hash with:
    #
    # +:pdffile+    - filename of input pdf file
    # +:layout+     - page layout
    # +:page_count+ - page count of the input file
    def initialize(args)
      @pdffile    = args[:pdffile]
      @layout     = args[:layout]
      @page_count = args[:page_count]
    end

    def to_s
      latex = ERB.new(TEMPLATE, trim_mode: "%<>")

      latex.result(binding)
    end

    private

    def geometry
      layout.geometry
    end

    def class_options
      layout.landscape? ? "a4paper,landscape" : "a4paper"
    end

    def pages_per_sheet
      layout.pages
    end

    # Returns an array of pages strings.
    # For 4 copies and 2 pages: ["1,1,1,1", "2,2,2,2"].
    def pages_strings
      pages = (1..page_count).to_a

      pages.map {|page| ([page] * pages_per_sheet).join(",") }
    end
  end

  # A class for PDF meta data (up to now only used for the page count).
  #
  # Create an instance with PDFInfo.new, specifying the file name.
  # +PDFInfo+ tries to use the +pdfinfo+ system tool to obtain meta data.
  # If successful, the attribute +page_count+ contains the page count,
  # else the attribute is set to +nil+.
  class PDFInfo

    PDFINFOCMD = "/usr/bin/pdfinfo"

    # Returns the page count of the input file, or nil.
    attr_reader :page_count

    # This is the initialization method for the class.
    #
    # +file+ - file name of the PDF file
    def initialize(file, options = {})
      @file = file
      @binary = options[:pdfinfocmd] || PDFINFOCMD  # for unit tests
      infos = retrieve_infos
      @page_count = infos["Pages"]&.to_i
    end

    # Returns true if default +pdfinfo+ system tool is available (for unit tests).
    def self.infocmd_available?
      Application.command_available?("#{PDFINFOCMD} -v")
    end

    private

    # Tries to retrieve the PDF infos for the file; returns an info hash.
    def retrieve_infos
      command = "#{@binary} #{@file}"
      return {}  unless Application.command_available?(command)

      info_array = `#{command}`.split("\n")

      info_array.to_h {|line| line.split(/\s*:\s*/, 2) }
    end
  end

  # The main program. It's run! method is called
  # if the script is run from the command line.
  # It parses the command line arguments and does the job.
  class Application

    ERRORCODE = { general: 1, usage: 2 }.freeze

    def initialize
      begin
        options = Optionparser.parse!(ARGV)
      rescue StandardError => e
        usage_fail(e.message)
      end
      @infile = options[:infile]
      @outfile = options[:outfile]
      @use_stdout = (@outfile == "-")
      @silent = options[:silent]
      @force = options[:force]
      @latex = options[:latex]
      @number = options[:number]
      @pages = options[:pages] || PDFInfo.new(@infile).page_count || 1
    end

    # The main program.
    def run!
      # test for pdflatex installation
      unless @latex
        message = "seems not to be installed (you might try using the -l option)"
        general_fail("`#{PDFLATEX}' #{message}")  unless self.class.command_available?("#{PDFLATEX} --version")
        general_fail("`pdfpages.sty' #{message}")  unless self.class.command_available?("#{KPSEWHICH} pdfpages.sty")
      end

      # test input file
      usage_fail("no such file: `#{@infile}'")  unless File.exist?(@infile)
      usage_fail("specified input not of the type `file'")  unless File.ftype(@infile) == "file"

      # test for existing output file
      if !@use_stdout && !@force && File.exist?(@outfile)
        overwrite_ok = confirm("File `#{@outfile}' already exists. Overwrite?")
        exit  unless overwrite_ok
      end

      # create LaTeX document
      args = {
        pdffile: @infile,
        layout: Layout.new(@number),
        page_count: @pages
      }
      document = LaTeXDocument.new(args)

      output = nil
      if @latex
        output = document.to_s
      else
        Dir.mktmpdir("pdfmult") do |dir|
          texfile = "pdfmult.tex"
          pdffile = "pdfmult.pdf"
          File.write("#{dir}/#{texfile}", document.to_s)
          command = "#{PDFLATEX} -output-directory #{dir} #{texfile}"
          Open3.popen3(command) do |_stdin, stdout, stderr|
            stdout.each_line {|line| warn line.chomp }  unless @silent # redirect progress messages to stderr
            stderr.read  # make sure all streams are read (and command has finished)
          end
          output = File.read("#{dir}/#{pdffile}")
        end
      end

      # redirect stdout to output file
      $stdout.reopen(@outfile, "w")  unless @use_stdout

      warn "Writing on #{@outfile}."  unless @use_stdout || @silent
      puts output
    end

    # Tests silently whether the given system command is available.
    #
    # +command+ - command to test
    def self.command_available?(command) # :nodoc:
      !!system("#{command} >/dev/null 2>&1")
    end

    private

    # Asks for yes or no (y/n).
    #
    # +question+ - string to be printed
    #
    # Returns +true+ if the answer is yes.
    def confirm(question)
      loop do
        $stderr.print "#{question} [y/n] "
        reply = $stdin.gets.chomp.downcase  # $stdin avoids gets/ARGV problem
        return reply == "y"  if reply.match?(/\A[yn]\z/)

        warn "Please answer `y' or `n'."
      end
    end

    # Prints an error message and exits.
    def general_fail(message)
      warn "#{PROGNAME}: #{message}"
      exit ERRORCODE[:general]
    end

    # Prints an error message and a short help information, then exits.
    def usage_fail(message)
      warn "#{PROGNAME}: #{message}"
      warn "Use `#{PROGNAME} --help' for valid options."
      exit ERRORCODE[:usage]
    end
  end
end

### call main method only if called on command line

Pdfmult::Application.new.run!  if __FILE__ == $PROGRAM_NAME
