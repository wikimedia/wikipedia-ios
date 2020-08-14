import Foundation

class WikipediaLanguageUtility {
    let pathComponents: [String]
    let api = WikipediaLanguageUtilityAPI()
    let jsonExtractionRegex = try! NSRegularExpression(pattern: #"(?:mw\.config\.set\()(.*?)(?:\);\n*\}\);)"#, options: [.dotMatchesLineSeparators])
    
    init(path: String) {
        pathComponents = path.components(separatedBy: "/")
    }
    
    func run(_ completion: @escaping () -> Void) {
        let group = DispatchGroup()
        group.enter()
        api.getSites { result in
            switch result {
            case .failure(let error):
                print("Error fetching sites: \(error)")
                abort()
            case .success(let sites):
                let sortedSites = sites.sorted { (a, b) -> Bool in
                    return a.languageCode < b.languageCode
                }
                self.writeCodable(sortedSites, to: ["Wikipedia", "Code", "wikipedia-languages.json"])
                group.enter()
                self.writeNamespaceFiles(with: sites) {
                    self.writeCodemirrorConfig(with: sites) {
                        group.leave()
                    }
                }
            }
            group.leave()
        }

        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
    
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
            guard let soughtSubstring = self.extractJSONString(from: responseString) else {
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
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(codable)
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
                let outputURL = self.getOutputFileURL(with: ["Wikipedia", "assets", "codemirror", "config", "codemirror-config-\(site.languageCode).json"])
               try! response.write(to: outputURL, atomically: true, encoding: .utf8)
            }
        }, completion: completion)

    }

    func writeNamespaceFiles(with sites: [Wikipedia], completion: @escaping () -> Void) {
        sites.asyncForEach({ (site, siteCompletion) in
            api.getSiteInfo(with: site.languageCode) { (result) in
                switch result {
                case .success(let siteInfo):
                    var namespaces = [String: PageNamespace].init(minimumCapacity: siteInfo.query.namespaces.count + siteInfo.query.namespacealiases.count)
                    for (_, namespace) in siteInfo.query.namespaces {
                        namespaces[namespace.name.uppercased()] = PageNamespace(rawValue: namespace.id)
                        guard let canonical = namespace.canonical else {
                            continue
                        }
                        namespaces[canonical.uppercased()] = PageNamespace(rawValue: namespace.id)
                    }
                    for namespaceAlias in siteInfo.query.namespacealiases {
                        namespaces[namespaceAlias.alias.uppercased()] = PageNamespace(rawValue: namespaceAlias.id)
                    }
                    let siteInfoLookup = WikipediaSiteInfoLookup(namespace: namespaces, mainpage: siteInfo.query.general.mainpage.uppercased())
                    self.writeCodable(siteInfoLookup, to: ["Wikipedia", "Code", "wikipedia-namespaces", "\(site.languageCode).json"])
                case .failure(let error):
                    print("error fetching site info: \(error)")
                }
                siteCompletion()
            }
        }, completion: completion)
    }
}
