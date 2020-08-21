### Updating languages

Inside the main project, there's a `languages` target that is a Mac command line tool. You can edit the swift files used by this target (inside `Command Line Tools/Update Languages/`) to update the languages script. Running the `Update Languages` scheme will create all of the needed config files for any new Wikipedia languages detected. You can then submit a PR with the changes generated. 
