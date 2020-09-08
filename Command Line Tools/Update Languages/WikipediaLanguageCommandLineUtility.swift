import Foundation
import Combine

/// Command line tool for updating prebuilt language lists and lookup tables used in the app
class WikipediaLanguageCommandLineUtility {
    let pathComponents: [String]
    let api = WikipediaLanguageCommandLineUtilityAPI()

    /// - Parameter path: the path to the wikipedia-ios project folder
    init(path: String) {
        pathComponents = path.components(separatedBy: "/")
    }
    
    var cancellable: AnyCancellable?
    
    /// Generates all the necessary files
    func run(_ completion: @escaping () -> Void) {
        cancellable = api.getSites().sink(receiveCompletion: { (result) in
            switch result {
            case .failure(let error):
                print("Error fetching sites: \(error)")
                abort()
            default:
                break
            }
        }) { (sites) in
            let sortedSites = sites.sorted { (a, b) -> Bool in
                return a.languageCode < b.languageCode
            }
            self.writeCodable(sortedSites, to: ["Wikipedia", "Code", "wikipedia-languages.json"])
            self.cancellable = self.writeNamespaceFiles(with: sites) {
                self.cancellable = self.writeCodemirrorConfig(with: sites, completion: {
                    completion()
                })
            }
        }
    
    }
    
    private func getOutputFileURL(with components: [String]) -> URL {
        let outputComponents = pathComponents + components
        let outputPath = outputComponents.joined(separator: "/")
        return URL(fileURLWithPath: outputPath)
    }

    private func writeCodable<T: Codable>(_ codable: T, to pathComponents: [String]) {
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

    private func writeCodemirrorConfig(with sites: [Wikipedia], completion: @escaping () -> Void) -> AnyCancellable {
        Publishers.MergeMany(sites.map { site in
                api.getCodeMirrorConfigJSON(for: site.languageCode)
                    .map { ($0, site) }
            })
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print("Error writing codemirror config: \(error)")
                }
                completion()
            }) { (value) in
                let outputURL = self.getOutputFileURL(with: ["Wikipedia", "assets", "codemirror", "config", "codemirror-config-\(value.1.languageCode).json"])
                try! value.0.write(to: outputURL, atomically: true, encoding: .utf8)
            }
    }

    private func writeNamespaceFiles(with sites: [Wikipedia], completion: @escaping () -> Void) -> AnyCancellable? {
        return Publishers.MergeMany(sites.map { site in
                api.getSiteInfo(with: site.languageCode)
                    .map { ($0, site) }
            })
            .map {
                (self.getSiteInfoLookup(with: $0.0), $0.1)
            }
            .sink(receiveCompletion: { (result) in
                completion()
            }) { (siteInfoTuple) in
                self.writeCodable(siteInfoTuple.0, to: ["Wikipedia", "Code", "wikipedia-namespaces", "\(siteInfoTuple.1.languageCode).json"])
            }
    }
    
    private func getSiteInfoLookup(with siteInfo: SiteInfo) -> WikipediaSiteInfoLookup {
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
        return WikipediaSiteInfoLookup(namespace: namespaces, mainpage: siteInfo.query.general.mainpage.uppercased())
    }
}
