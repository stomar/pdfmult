require 'lib/pdfmult'

version = Pdfmult::VERSION
date    = Pdfmult::DATE

Gem::Specification.new do |s|
  s.name              = 'pdfmult'
  s.version           = version
  s.date              = date
  s.rubyforge_project = 'pdfmult'

  s.description = 'pdfmult is a command line tool that rearranges ' +
                  'multiple copies of a PDF page (shrunken) on one page. ' +
                  'It is a wrapper for pdflatex with the pdfpages package.'
  s.summary = 'pdfmult - puts multiple copies of a PDF page on one page'

  s.authors = ['Marcus Stollsteimer']
  s.email = 'sto.mar@web.de'
  s.homepage = 'https://github.com/stomar/pdfmult/'

  s.license = 'GPL-3'

  s.requirements << 'pdflatex and the pdfpages package'

  s.executables = ['pdfmult']
  s.bindir = 'bin'
  s.require_path = 'lib'
  s.test_files = Dir.glob('test/**/test_*.rb')

  s.rdoc_options = ['--charset=UTF-8']

  s.files = %w[
      README.md
      Rakefile
      pdfmult.gemspec
      pdfmult.h2m
    ] +
    Dir.glob('example*.*') +
    Dir.glob('{bin,lib,man,test}/**/*')

  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')
end
