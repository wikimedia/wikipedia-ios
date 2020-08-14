import Foundation
import Combine

/// **THIS IS NOT PART OF THE MAIN APP - IT'S A COMMAND LINE UTILITY**

let count = CommandLine.arguments.count
guard count > 1 else {
    abort()
}

let actionAPI = WikipediaLanguageUtilityAPI()


let path = CommandLine.arguments[1]
let pathComponents = path.components(separatedBy: "/")
let jsonExtractionRegex = try! NSRegularExpression(pattern: #"(?:mw\.config\.set\()(.*?)(?:\);\n*\}\);)"#, options: [.dotMatchesLineSeparators])

func extractJSONString(from responseString: String) -> String? {
    let results = jsonExtractionRegex.matches(in: responseString, range: NSRange(responseString.startIndex..., in: responseString))
    guard
        results.count == 1,
        let firstResult = results.first,
        firstResult.numberOfRanges == 2,
        let soughtCaptureGroupRange = Range(firstResult.range(at: 1), in: responseString)
    else {
        return nil
    }
    return String(responseString[soughtCaptureGroupRange])
}


func getCodeMirrorConfigJSON(for wikiLanguage: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "http://\(wikiLanguage).wikipedia.org/w/load.php?debug=false&lang=en&modules=ext.CodeMirror.data") else {
        completion(nil)
        return
    }
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else {
            completion(nil)
            return
        }
        guard let responseString = String(data: data, encoding: .utf8) else {
            completion(nil)
            return
        }
        guard let soughtSubstring = extractJSONString(from: responseString) else {
            completion(nil)
            return
        }
        completion(soughtSubstring.replacingOccurrences(of: "!0", with: "true"))
        }.resume()
}

func getOutputFileURL(with components: [String]) -> URL {
    let outputComponents = pathComponents + components
    let outputPath = outputComponents.joined(separator: "/")
    return URL(fileURLWithPath: outputPath)
}

func writeCodable<T: Codable>(_ codable: T, to pathComponents: [String]) {
    do {
        let data = try JSONEncoder().encode(codable)
        let outputFileURL = getOutputFileURL(with:  pathComponents)
        try data.write(to: outputFileURL)
    } catch let error {
        print("Error writing to file: \(error)")
    }
}

func writeCodemirrorConfig(with sites: [Wikipedia], completion: @escaping () -> Void) {
    sites.asyncForEach({ (site, siteCompletion) in
         getCodeMirrorConfigJSON(for: site.languageCode) { (response) in
           defer {
              siteCompletion()
           }
           guard let response = response else {
               return
           }
           let outputURL = getOutputFileURL(with: ["Wikipedia", "assets", "codemirror", "config", "codemirror-config-\(site.languageCode).json"])
           try! response.write(to: outputURL, atomically: true, encoding: .utf8)
        }
    }, completion: completion)

}

func writeNamespaceFiles(with sites: [Wikipedia], completion: @escaping () -> Void) {
    sites.asyncForEach({ (site, siteCompletion) in
        actionAPI.getSiteInfo(with: site.languageCode) { (result) in
            switch result {
            case .success(let siteInfo):
                var namespaces = [String: PageNamespace].init(minimumCapacity: siteInfo.query.namespaces.count)
                for namespace in siteInfo.query.namespaces {
                    namespaces[namespace.value.name.uppercased()] = PageNamespace(rawValue: Int(namespace.key)!)
                    guard let canonical = namespace.value.canonical else {
                        continue
                    }
                    namespaces[canonical.uppercased()] = PageNamespace(rawValue: Int(namespace.key)!)
                }
                let siteInfoLookup = WikipediaSiteInfoLookup(namespace: namespaces, mainpage: siteInfo.query.general.mainpage.uppercased())
                writeCodable(siteInfoLookup, to: ["Wikipedia", "Code", "wikipedia-namespaces", "\(site.languageCode).json"])
            case .failure(let error):
                print("error fetching site info: \(error)")
            }
            siteCompletion()
        }
    }, completion: completion)
}

let group = DispatchGroup()

group.enter()
let result = actionAPI.getSites().sink(receiveCompletion: { (done) in
}) { (sites) in
    /// Add testwiki
    let allSites = sites + [Wikipedia(languageCode: "test", languageName: "Test", localName: "Test", siteName: "Test Wikipedia", dbName: "testwiki")]
    let sitesByCode = allSites.reduce(into: [String: Wikipedia]()) { (result, wikipedia) in
        result[wikipedia.languageCode] = wikipedia
    }
    writeCodable(sitesByCode, to: ["Wikipedia", "Code", "wikipedia-languages.json"])
    group.enter()
    writeNamespaceFiles(with: sites) {
        writeCodemirrorConfig(with: sites) {
            group.leave()
        }
    }
    group.leave()
}

group.notify(queue: DispatchQueue.main) {
    exit(0)
}

dispatchMain()
