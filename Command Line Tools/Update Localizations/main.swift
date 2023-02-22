import Foundation

/// **THIS IS A COMMAND LINE UTILITY FOR LOCALIZATION**
let count = CommandLine.arguments.count
guard count > 1 else {
    print("Please provide a path argument.")
    exit(1)
}

let path = CommandLine.arguments[1]

print("Extracting localizations from source code...")
let extractProcess = Process.launchedProcess(launchPath: "\(path)/scripts/localization_extract", arguments: [path])
extractProcess.waitUntilExit()

if extractProcess.terminationStatus == 0 {
    print("Localizations extracted successfully.")
    print("Exporting localizations from source code...")
    exportLocalizationsFromSourceCode(path)
    print("Importing localizations from TWN...")
    importLocalizationsFromTWN(path)
    print("Localizations imported successfully.")
} else {
    print("Failed to extract localizations from source code.")
    exit(1)
}
