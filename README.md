pdfmult
=======

`pdfmult` is a command line tool (written in [Ruby][Ruby]) that
rearranges multiple copies of a PDF page (shrunken) on one page.

The paper size of the produced PDF file is A4,
the input file is also assumed to be in A4 format.
The input PDF file may consist of several pages.
If `pdfmult` succeeds in obtaining the page count it will rearrange all pages,
if not, only the first page is processed
(unless the page count was specified via command line option).

If the `--latex` option is used, `pdflatex` is not run and
a LaTeX file is created instead of a PDF.

Examples
--------

Use the program as shown in the examples below.

* `pdfmult sample.pdf`

    writes 2 copies of `sample.pdf` to `sample_2.pdf`

    <img src="example1.png" alt="" width="152" height="59">

* `pdfmult -n 4 sample.pdf`

    writes 4 copies of `sample.pdf` to `sample_4.pdf`

    <img src="example2.png" alt="" width="234" height="59">

* `pdfmult sample.pdf -o outfile.pdf`

    writes 2 copies of `sample.pdf` to `outfile.pdf`

* `pdfmult sample.pdf -p 3`

    processes the first 3 pages of `sample.pdf`

* `pdfmult sample.pdf -o - | lpr`

    sends output via stdout to print command

Installation
------------

Use `gem install pdfmult` to install from RubyGems.org.

Or copy `lib/pdfmult.rb` under the name `pdfmult` into your search path.

On a Linux system you can use `[sudo] rake install`
to install `pdfmult` and its man page to `/usr/local`.

Requirements
------------

As of now, `pdfmult` has only been tested on a Linux system.

- `pdfmult` is written in [Ruby][Ruby], so Ruby must be installed on your system.
- `pdfmult` uses `pdflatex` with the `pdfpages` package, so both have to be installed on the system.
  (If `pdfmult` cannot find the `pdflatex` command on your system
  you might want to use the `--latex` option.)
- `pdfmult` tries to obtain the page count of PDF files with `pdfinfo`.
  If it fails, by default only the first page of a PDF file will be processed.

Documentation
-------------

Use `pdfmult --help` to display a brief help message.

If you installed `pdfmult` using `rake install` you can read
its man page with `man pdfmult`.

Reporting bugs
--------------

Report bugs on the `pdfmult` home page: <https://github.com/stomar/pdfmult/>

License
-------

Copyright &copy; 2011-2013 Marcus Stollsteimer

`pdfmult` is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3 or later (GPLv3+),
see [www.gnu.org/licenses/gpl.html](http://www.gnu.org/licenses/gpl.html).
There is NO WARRANTY, to the extent permitted by law.


[Ruby]: http://www.ruby-lang.org/
