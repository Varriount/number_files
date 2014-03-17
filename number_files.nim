import argument_parser, os, strutils, tables, sequtils

type
  Tglobal = object ## \
    ## Holds all the global variables of the process.
    params: Tcommandline_results
    postfix: bool ## True if the numbers are to be added postfix.
    separator: string ## String used to join the number to the filename.
    padding: int ## Number of minimum number padding.
    start: int ## Value to start counting at.


var G: Tglobal

G.separator = " "
G.padding = 2

const
  version_str* = "0.1.1" ## Program version as a string.
  version_int* = (major: 0, minor: 1, maintenance: 1) ## \
  ## Program version as an integer tuple.
  ##
  ## Major version changes mean significant new features or a break in
  ## commandline backwards compatibility, either through removal of switches or
  ## modification of their purpose.
  ##
  ## Minor version changes can add switches. Minor
  ## odd versions are development/git/unstable versions. Minor even versions
  ## are public stable releases.
  ##
  ## Maintenance version changes mean bugfixes or non commandline changes.

  param_help = @["-h", "--help"]
  help_help = "Displays commandline help and exits."

  param_version = @["-v", "--version"]
  help_version = "Displays the current version and exists."

  param_postfix = @["-p", "--postfix"]
  help_postfix = "Add number before extension instead of prefixing name."

  param_separator = @["-s", "--separator"]
  help_separator = "Separator string between filename and number."

  param_length = @["-l", "--length"]
  help_length = "Minimum length of the number mask, padded to zeros."

  param_start = @["-start", "--start"]
  help_start = "Value of the first number assigned, by default zero."


proc process_commandline() =
  ## Parses the commandline, modifying the global structure.
  var PARAMS: seq[Tparameter_specification] = @[]
  PARAMS.add(new_parameter_specification(PK_HELP,
    names = param_help, help_text = help_help))
  PARAMS.add(new_parameter_specification(names = param_version,
    help_text = help_version))
  PARAMS.add(new_parameter_specification(PK_STRING, names = param_postfix,
    help_text = help_postfix))
  PARAMS.add(new_parameter_specification(PK_STRING, names = param_separator,
    help_text = help_separator))
  PARAMS.add(new_parameter_specification(PK_INT, names = param_length,
    help_text = help_length))
  PARAMS.add(new_parameter_specification(PK_INT, names = param_start,
    help_text = help_start))

  G.params = parse(PARAMS)

  if G.params.options.has_key(param_version[0]):
    echo "Version ", version_str
    quit()

  if G.params.options.has_key(param_postfix[0]):
    G.postfix = true

  if G.params.options.has_key(param_separator[0]):
    G.separator = G.params.options[param_separator[0]].str_val

  if G.params.options.has_key(param_length[0]):
    G.padding = G.params.options[param_length[0]].int_val
    if G.padding < 1:
      echo "The length value has to be a positive number."
      echo_help(params)
      quit()

  if G.params.options.has_key(param_start[0]):
    G.start = G.params.options[param_start[0]].int_val
    if G.start < 1:
      echo "The start value has to be a positive number."
      echo_help(params)
      quit()

  if G.params.positional_parameters.len < 1:
    echo "You need to specify files/directories to number."
    echo_help(params)
    quit()

  assert G.padding > 0


proc number_files(input_files: seq[string], postfix: bool,
    separator: string, padding, start: int) =
  ## Numbers input_files from start to infinite.
  if input_files.len < 1: return
  # Calculates the ending number of the sequence to figure out string padding.
  let
    last_value = start + len(input_files) - 1
    padding = min(padding, len($last_value))
  
  echo "Hey!"



when isMainModule:
  # Gets parameters and extracts them for easy access.
  process_commandline()

  number_files(mapIt(G.params.positional_parameters, string, it.str_val),
    G.postfix, G.separator, G.padding, G.start)
