source("renv/activate.R")

## This makes sure that R loads the workflowr package
## automatically, everytime the project is loaded
if (requireNamespace("workflowr", quietly = TRUE)) {
  message("Loading .Rprofile for the current workflowr project")
  library("workflowr")
} else {
  message("workflowr package not installed, please run install.packages(\"workflowr\") to use the workflowr functions")
}

Sys.setenv(TERM_PROGRAM="vscode")
if (interactive() && Sys.getenv("RSTUDIO") == "") {
  source(file.path(Sys.getenv(if (.Platform$OS.type == "windows") "USERPROFILE" else "HOME"), ".vscode-R", "init.R"))
}

options(vsc.viewer = "Beside")
