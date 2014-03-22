import nake, os, rester, strtabs, sequtils, htmlparser, xmltree, osproc

type
  In_out = tuple[src, dest, options: string]
    ## The tuple only contains file paths.

const
  exe_name = "number_files"
  workflow_dest = "number_files.workflow"
  workflow_src = "workflow_template_dir"
  workflow_bin = workflow_dest/"Contents"/exe_name

when defined(macosx):
  const
    local_install = "Copies " & exe_name & " to your ~/bin directory " &
      "and installs a workflow into ~/Library/Services/ for Finder"
else:
  const
    local_install = "Copies " & exe_name & " to your ~/bin directory"


template glob_rst(basedir: string): expr =
  ## Shortcut to simplify getting lists of files.
  to_seq(walk_files(basedir/"*.rst"))

let
  normal_rst_files = glob_rst(".")
var
  CONFIGS = newStringTable(modeCaseInsensitive)
    ## Stores previously read configuration files.


proc build_and_install_workflow() =
  ## Generates a temporary workflow directory and calls open on it.
  workflow_dest.remove_dir
  workflow_src.copy_dir(workflow_dest)
  exe_name.copy_file_with_permissions(workflow_bin)
  shell("open", workflow_dest)


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
  direshell("nimrod c -d:release", exe_name)
  when defined(macosx):
    build_and_install_workflow()

  let dest = getHomeDir() / "bin" / exe_name
  copyFile(exe_name, dest)
  dest.setFilePermissions(exe_name.getFilePermissions)


task "doc", "Generates HTML from the rst files.":
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


task "check_doc", "Validates rst format for a subset of documentation":
  for f in build_all_rst_files():
    let (rst_file, html_file, options) = f
    echo "Testing ", rst_file
    let (output, exit) = execCmdEx("rst2html.py " & rst_file & " /dev/null")
    if output.len > 0 or exit != 0:
      echo "Failed python processing of " & rst_file
      echo output


task "clean", "Removes temporal files, mainly":
  for path in walkDirRec("."):
    let (dir, name, ext) = splitFile(path)
    if ext == ".html":
      echo "Removing ", path
      path.removeFile()
