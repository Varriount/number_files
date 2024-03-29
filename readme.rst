============
Number files
============

**Number files** is a small program to rename a list of specified files with a
prefix or suffix and a counter value. It is a command line program but it comes
with an `Automator <http://automator.us>`_ workflow to be invoked from MacOSX
Finder contextual menu.  Hypothetical command line usage::

    $ number_files  --separator .-. --length 4 \
        --from 42 secret_folder/*jpg
    'kpop_porn.jpg' -> '0042.-.kpop_porn.jpg'
    'midgets_porn.jpg' -> '0043.-.midgets_porn.jpg'
    'nimrod_porn.jpg' -> '0044.-.nimrod_porn.jpg'

While this kind of file renaming is easy if you have a working shell, the
arcane syntax of shells requires much escaping for files with spaces or special
characters and is prone to error. It is also a pain to switch between GUI and
command line or share a shell script with non command line users.


License
=======

`MIT license <license.rst>`_.


Command line switches
=====================

-h, --help               Displays commandline help and exits.
-v, --version            Displays the current version and exists.
-p, --postfix            Add number before extension instead of prefixing name.
-s, --separator STRING   Separator string between filename and number.
-l, --length INT         Minimum length of the number mask, padded to zeros.
-f, --from INT           Value of the first number assigned, by default zero.

There is not much more than that, but if you are curious you can also check the
`docindex file <docindex.rst>`_ for internal documentation.


Installing from source code
===========================

Stable version
--------------

Install the `Nimrod compiler <http://nimrod-lang.org>`_. Then use `Nimrod's
babel package manager <https://github.com/nimrod-code/babel>`_ to install the
binary::

    $ babel update
    $ babel install number_files

This will install the ``number_files`` command into Babel's binary directory.
If you are running MacOSX and you want to install the Automator workflow, type
the following commands::

    $ cd `babel path number_files`
    $ nake install_workflow


Development version
-------------------

Install the `Nimrod compiler <http://nimrod-lang.org>`_. Then use `Nimrod's
babel package manager <https://github.com/nimrod-code/babel>`_ to install
locally the github checkout::

    $ babel install nake argument_parser
    $ git clone --recursive https://github.com/gradha/number_files/
    $ cd number_files
    $ babel install

The ``install`` task will use Babel's mechanism to install the binary. On
MacOSX this will also trigger installation of the Finder workflow.  Later, if
you want to update you need to make sure git submodules get updated too::

    $ cd number_files
    $ git pull
    $ git submodule update


Installing prebuilt binaries
----------------------------

If you trust binaries and random strangers on the internet, you can go to
`https://github.com/gradha/number_files/releases
<https://github.com/gradha/number_files/releases>`_ and download any of the
``.zip`` files attached to a specific release.

The binary has been only tested on MacOSX 10.8 and 10.9, but should work on
pretty much every Intel machine out there. Tell me if it doesn't. Put the
binary file somewhere in your ``$PATH`` and invoke at will.

To `install the Automator workflow
<http://macosxautomation.com/automator/serviceinstall/index.html>`_ you only
need to double click on the file and Automator will ask you first if you trust
the unsigned software (see `instructions on how to avoid this
<http://macosxautomation.com/automator/serviceinstall/index.html>`_) and then
if you want to install the service.

Once the service has been installed, select a few files with Finder, ctrl+click
on them and you should see somewhere a **Number files** service menu option.
The Automator workflow doesn't use any fancy command line switches by default,
but you can open the installed workflow at ``~/Library/Services`` and change
the invocation parameters to what you like (e.g. add ``--length 6`` to force
the numbers to be padded to six digits or change ``--from 1`` because you are a
programmer and prefer to count from zero).


Changes
=======

This is development version 0.2.3. For a list of changes see the
`docs/changes.rst file <docs/changes.rst>`_.


Git branches
============

This project uses the `git-flow branching model
<https://github.com/nvie/gitflow>`_ with reversed defaults. Stable releases are
tracked in the ``stable`` branch. Development happens in the default ``master``
branch.


Feedback
========

You can send me feedback through `github's issue tracker
<https://github.com/gradha/number_files/issues>`_. I also take a look from time
to time to `Nimrod's forums <http://forum.nimrod-code.org>`_ where you can talk
to other nimrod programmers.
