#!/usr/bin/swift

import Foundation

// print("\n\nfilepath given to script:\n\(CommandLine.arguments[0])")

extension FileManager {
    func listFiles(path: String) -> [URL] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls = [URL]()
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
            let url = relativeURL.absoluteURL
            urls.append(url)
        })
        return urls
    }

	func listFiles(path: String, withSuffix suffix: String) -> [URL] {
		return listFiles(path: currentDirectoryPath).filter({$0.absoluteString.hasSuffix(suffix)})
	}
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
    var alphanumeric: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_").lowercased()
    }
}

let snapshotsPathString = NSURL.fileURL(withPath: "\(FileManager.default.currentDirectoryPath)/Snapshots").absoluteString

// Move the file from its subdir to the "allImagesFlattened" dir in same dir as this script.
// Keeps subdir(s) as part of the file name - slashes and spaces are converted to underscores.
let renameAndMoveFileToDirOfThisScript = { (file: URL) in
	let filePathWithoutSnapshotsPathStringPrefix = file.absoluteString.deletingPrefix(snapshotsPathString)
	let newFileNameWithoutSpacesOrSlashes = filePathWithoutSnapshotsPathStringPrefix.replacingOccurrences(of: "(%20)|[\\s/]+", with: "_", options: [.regularExpression])
	do {
	    try FileManager.default.copyItem(at: file, to: NSURL.fileURL(withPath: "\(FileManager.default.currentDirectoryPath)/SnapshotsFlattened/\(newFileNameWithoutSpacesOrSlashes)"))
	}
	catch let error as NSError {
	    print("Something went wrong: \(error)")
	}
}

let filesToMove = FileManager.default.listFiles(path: FileManager.default.currentDirectoryPath, withSuffix: ".png")
filesToMove.forEach(renameAndMoveFileToDirOfThisScript)
