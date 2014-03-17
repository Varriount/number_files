import nake, os

const
  exe_name = "number_files"

task "local_install", "Copies " & exe_name & " to your ~/bin directory":
  direshell("nimrod c -d:release", exe_name)
  let dest = getHomeDir() / "bin" / exe_name
  copyFile(exe_name, dest)
  dest.setFilePermissions(exe_name.getFilePermissions)
