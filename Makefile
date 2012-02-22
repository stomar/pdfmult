# Makefile for pdfmult
#
# targets: man, install, uninstall
#
# M. Stollsteimer, Dec 2012

#### Start of system configuration section. ####

srcdir = .

bindir = /usr/local/bin
mandir = /usr/local/man/man1

INSTALL = install
INSTALL_DIR = $(srcdir)/mkinstalldirs
INSTALL_DATA = $(INSTALL) -m 644

HELP2MAN = help2man
SED = sed

#### End of system configuration section. ####

# files to install in bindir/mandir

binfiles = pdfmult
manfiles = pdfmult.1

### Targets. ####

.PHONY : usage
usage :
	@echo "usage: make <target>"
	@echo "targets are \`install', \`uninstall', and \`man'"


.PHONY : man
man: pdfmult.1


pdfmult.1: pdfmult pdfmult.h2m
	@$(HELP2MAN) --no-info --name='puts multiple copies of a PDF page on one page' \
	          --include=pdfmult.h2m -o pdfmult.1 ./pdfmult
	@$(SED) -i '/\.PP/{N;s/\.PP\nOptions/.SH OPTIONS/}' pdfmult.1
	@$(SED) -i 's/^License GPL/.br\nLicense GPL/;s/There is NO WARRANTY/.br\nThere is NO WARRANTY/' pdfmult.1


.PHONY : installdirs
installdirs: mkinstalldirs
	$(INSTALL_DIR) $(DESTDIR)$(bindir)
	$(INSTALL_DIR) $(DESTDIR)$(mandir)


.PHONY : install
install: $(INSTFILES) installdirs
	$(INSTALL) $(binfiles) $(bindir)
	$(INSTALL_DATA) $(manfiles) $(mandir)


.PHONY : uninstall
uninstall:
	cd $(bindir) && rm -f $(binfiles) && \
	cd $(mandir) && rm -f $(manfiles)
