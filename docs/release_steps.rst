====================================
What to do for a new public release?
====================================

* Create new milestone with version number.
* Create new dummy issue `Release versionname` and assign to that milestone.
* Annotate the release issue with the Nimrod commit used to compile sources.
* ``git flow release start versionname`` (versionname without v).
* Update version numbers:

  * Modify `readme.rst <../readme.rst>`_ (s/development/stable/).
  * Modify `number_files.nim <../number_files.nim>`_.
  * Modify `number_files.babel <../number_files.babel>`_.
  * Update `docs/changes.rst <changes.rst>`_ with list of changes and
    version/number.

* ``git commit -av`` into the release branch the version number changes.
* ``git flow release finish versionname`` (the tagname is versionname without
  ``v``).  When specifying the tag message, copy and paste a text version of
  the changes log into the message. Add rst item markers.
* Move closed issues to the release milestone.
* ``git push origin master stable --tags``.
* Build binaries for macosx/linux with nake ``dist`` command.
* Attach the binaries to the appropriate release at
  `https://github.com/gradha/number_files/releases
  <https://github.com/gradha/number_files/releases>`_.
* Use nake ``md5`` task to generate md5 values, add them to the release.
* Increase version numbers, ``master`` branch gets +0.0.1.

  * Modify `readme.rst <../readme.rst>`_ (s/development/stable/).
  * Modify `number_files.nim <../number_files.nim>`_.
  * Modify `number_files.babel <../number_files.babel>`_.
  * Add to `docs/changes.rst <changes.rst>`_ development version with unknown
    date.

* ``git commit -av`` into ``master`` with *Bumps version numbers for
  development version. Refs #release issue*.
* ``git push origin master stable --tags``.
* Close the dummy release issue.
* Announce at http://forum.nimrod-lang.org/.
* Close the milestone on github.
