# rakefile for the pdfmult script.
#
# Copyright (C) 2012 Marcus Stollsteimer

require 'rake/testtask'

BINDIR = '/usr/local/bin'
MANDIR = '/usr/local/man/man1'

HELP2MAN = 'help2man'
SED = 'sed'

BINARY = 'pdfmult'
MANPAGE = 'pdfmult.1'
H2MFILE = 'pdfmult.h2m'


task :default => [:test]

Rake::TestTask.new do |t|
  t.pattern = 'test_*.rb'
  t.verbose = true
  t.warning = true
end


desc 'Install binary and man page'
task :install => [BINARY, MANPAGE] do
  mkdir_p BINDIR
  install(BINARY, BINDIR)
  mkdir_p MANDIR
  install(MANPAGE, MANDIR, :mode => 0644)
end


desc 'Uninstall binary and man page'
task :uninstall do
  rm "#{BINDIR}/#{BINARY}"
  rm "#{MANDIR}/#{MANPAGE}"
end


desc 'Create man page'
task :man => [MANPAGE]

file MANPAGE => [BINARY, H2MFILE] do
  sh "#{HELP2MAN} --no-info --include=#{H2MFILE} -o #{MANPAGE} ./#{BINARY}"
  sh "#{SED} -i '/\.PP/{N;s/\.PP\\nOptions/.SH OPTIONS/}' #{MANPAGE}"
  sh "#{SED} -i 's/^License GPL/.br\\nLicense GPL/;s/There is NO WARRANTY/.br\\nThere is NO WARRANTY/' #{MANPAGE}"
end
