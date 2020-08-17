import Foundation
import Combine

/// **THIS IS NOT PART OF THE MAIN APP - IT'S A COMMAND LINE UTILITY**

let count = CommandLine.arguments.count
guard count > 1 else {
    abort()
}

let path = CommandLine.arguments[1]
let utility = WikipediaLanguageCommandLineUtility(path: path)
utility.run {
    exit(0)
}

dispatchMain()
