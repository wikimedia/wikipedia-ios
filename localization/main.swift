import Foundation

let count = CommandLine.arguments.count
guard count > 1 else {
    abort()
}

let path = CommandLine.arguments[1]

//Process.launchedProcess(launchPath: "\(path)/scripts/localization_extract", arguments: [path]).waitUntilExit()

if CommandLine.arguments.contains("export") {
    exportLocalizationsFromSourceCode(path)
}

if CommandLine.arguments.contains("import") {
    importLocalizationsFromTWN(path)
}
