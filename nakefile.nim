import nake, os

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


proc build_and_install_workflow() =
  ## Generates a temporary workflow directory and calls open on it.
  workflow_dest.remove_dir
  workflow_src.copy_dir(workflow_dest)
  exe_name.copy_file_with_permissions(workflow_bin)
  shell("open", workflow_dest)


task "local_install", local_install:
  direshell("nimrod c -d:release", exe_name)
  when defined(macosx):
    build_and_install_workflow()

  let dest = getHomeDir() / "bin" / exe_name
  copyFile(exe_name, dest)
  dest.setFilePermissions(exe_name.getFilePermissions)

