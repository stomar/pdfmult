require './lib/pdfmult'

version  = Pdfmult::VERSION
date     = Pdfmult::DATE
homepage = Pdfmult::HOMEPAGE
tagline  = Pdfmult::TAGLINE

Gem::Specification.new do |s|
  s.name              = 'pdfmult'
  s.version           = version
  s.date              = date

  s.description = 'pdfmult is a command line tool that rearranges ' +
                  'multiple copies of a PDF page (shrunken) on one page. ' +
                  'It is a wrapper for pdflatex with the pdfpages package.'
  s.summary = "pdfmult - #{tagline}"

  s.authors = ['Marcus Stollsteimer']
  s.email = 'sto.mar@web.de'
  s.homepage = homepage

  s.license = 'GPL-3'

  s.requirements << 'pdflatex and the pdfpages package'

  s.add_development_dependency('rake')
  s.add_development_dependency('minitest')

  s.executables = ['pdfmult']
  s.bindir = 'bin'

  s.require_paths = ['lib']

  s.test_files = Dir.glob('test/**/test_*.rb')

  s.files = %w{
      README.md
      Rakefile
      pdfmult.gemspec
      pdfmult.h2m
    } +
    Dir.glob('example*.*') +
    Dir.glob('{bin,lib,man,test}/**/*')

  s.rdoc_options = ['--charset=UTF-8']
end
