import nake, os, rester, strtabs, sequtils, htmlparser, xmltree, osproc,
  zipfiles, number_files

type
  In_out = tuple[src, dest, options: string]
    ## The tuple only contains file paths.

const
  name = "number_files"
  workflow_dest = "number_files.workflow"
  workflow_src = "workflow_template_dir"
  workflow_bin = workflow_dest/"Contents"/name
  automator_prefix = "automator_"
  dist_dir = "dist"
let
  exe_name = name.change_file_ext(exe_ext)

when defined(macosx):
  const
    local_install = "Copies " & name & " to your ~/bin directory " &
      "and installs a workflow into ~/Library/Services/ for Finder"
else:
  const
    local_install = "Copies " & name & " to your ~/bin directory"


template glob_rst(basedir: string = nil): expr =
  ## Shortcut to simplify getting lists of files.
  ##
  ## Pass nil to iterate over rst files in the current directory. This avoids
  ## prefixing the paths with "./" unnecessarily.
  if baseDir.isNil:
    to_seq(walk_files("*.rst"))
  else:
    to_seq(walk_files(basedir/"*.rst"))

let
  normal_rst_files = concat(glob_rst(), glob_rst("docs"))
var
  CONFIGS = newStringTable(modeCaseInsensitive)
    ## Stores previously read configuration files.


proc build_workflow(do_install: bool = false) =
  ## Generates a temporary workflow directory.
  ##
  ## If you pass true, calls open on the generated directory, which by default
  ## tends to install the service in your user account after a GUI confirmation
  ## dialog.
  workflow_dest.remove_dir
  workflow_src.copy_dir(workflow_dest)
  name.copy_file_with_permissions(workflow_bin)
  if do_install: shell("open", workflow_dest)


proc needs_refresh(target: In_out): bool =
  ## Wrapper around the normal needs_refresh for In_out types.
  if target.options.isNil:
    result = target.dest.needs_refresh(target.src)
  else:
    result = target.dest.needs_refresh(target.src, target.options)


proc load_config(path: string): string =
  ## Loads the config at path and returns it.
  ##
  ## Uses the CONFIGS variable to cache contents. Returns nil if path is nil.
  if path.isNil: return
  if CONFIGS.hasKey(path): return CONFIGS[path]
  CONFIGS[path] = path.readFile
  result = CONFIGS[path]


proc rst2html(src: string, out_path = ""): bool =
  ## Converts the filename `src` into `out_path` or src with extension changed.
  let output = safe_rst_file_to_html(src)
  if output.len > 0:
    let dest = if out_path.len > 0: out_path else: src.changeFileExt("html")
    dest.writeFile(output)
    result = true


proc change_rst_links_to_html(html_file: string) =
  ## Opens the file, iterates hrefs and changes them to .html if they are .rst.
  let html = loadHTML(html_file)
  var DID_CHANGE: bool

  for a in html.findAll("a"):
    let href = a.attrs["href"]
    if not href.isNil:
      let (dir, filename, ext) = splitFile(href)
      if cmpIgnoreCase(ext, ".rst") == 0:
        a.attrs["href"] = dir / filename & ".html"
        DID_CHANGE = true

  if DID_CHANGE:
    writeFile(html_file, $html)


iterator all_rst_files(): In_out =
  ## Iterates over all the rst files.
  var x: In_out
  for plain_rst in normal_rst_files:
    x.src = plain_rst
    x.dest = plain_rst.changeFileExt("html")
    x.options = nil
    yield x


proc build_all_rst_files(): seq[In_out] =
  ## Wraps iterator to avoid https://github.com/Araq/Nimrod/issues/866.
  ##
  ## The wrapping forces `for` loops to use a single variable and an extra
  ## `let` line to unpack the tuple.
  result = to_seq(all_rst_files())


task "local_install", local_install:
  direshell("nimrod c --verbosity:0 -d:release", name)
  when defined(macosx):
    build_workflow(true)

  let dest = getHomeDir() / "bin" / exe_name
  exe_name.copy_file_with_permissions(dest)


proc doc() =
  # Generate html files from the rst docs.
  for f in build_all_rst_files():
    let (rst_file, html_file, options) = f
    if not f.needs_refresh: continue
    discard change_rst_options(options.load_config)
    if not rst2html(rst_file, html_file):
      quit("Could not generate html doc for " & rst_file)
    else:
      if options.isNil:
        change_rst_links_to_html(html_file)
      echo rst_file & " -> " & html_file

  echo "All docs generated"

task "doc", "Generates HTML from the rst files.": doc()


task "check_doc", "Validates rst format for a subset of documentation":
  for f in build_all_rst_files():
    let rst_file = f.src
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output


proc clean() =
  dist_dir.remove_dir
  dist_dir.create_dir
  for path in walkDirRec("."):
    let ext = splitFile(path).ext
    if ext == ".html":
      echo "Removing ", path
      path.removeFile()

task "clean", "Removes temporal files, mostly.": clean()


proc make_zip(dir_name, zip_name: string, files: seq[string]) =
  zip_name.remove_file
  var Z: TZipArchive
  if not Z.open(zip_name, fmWrite):
    quit("Couldn't open zip " & zip_name)
  try:
    echo "Adding files to ", zip_name
    for filename in files:
      let target = dir_name/filename
      echo target
      assert filename.exists_file
      Z.addFile(target, filename)
  finally:
    Z.close
  echo "Built ", zip_name, " sized ", zip_name.getFileSize, " bytes."


template os_task(define_name): stmt {.immediate.} =
  task "dist", "Generate distribution binary for " & define_name:
    clean()
    doc()

    direShell("nimrod c --verbosity:0 -d:release --out:" & name, name & ".nim")
    var
      dname = name & "-" & number_files.version_str & "-" & define_name
      zname = dname & ".zip"
      html_files = mapIt(build_all_rst_files(), string, it.dest)
    make_zip(dname, zname, concat(@[name], html_files))
    zname.move_file(dist_dir/zname)

    when defined(macosx):
      # Additional workflow building for macosx.
      build_workflow()
      dname.insert(automator_prefix)
      zname.insert(automator_prefix)
      make_zip(dname, zname,
        concat(to_seq(walk_dir_rec(workflow_dest)), html_files))
      zname.move_file(dist_dir/zname)


when defined(macosx): os_task("macosx")
when defined(linux): os_task("linux")
