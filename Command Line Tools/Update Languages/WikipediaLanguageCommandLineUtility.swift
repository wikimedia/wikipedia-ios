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
                completion()
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
                self.writeCodable(siteInfoTuple.0.namespaceInfo, to: ["Wikipedia", "Code", "wikipedia-namespaces", "\(siteInfoTuple.1.languageCode).json"])
                self.writeCodable(siteInfoTuple.0.magicWordInfo, to: ["Wikipedia", "Code", "wikipedia-magicwords", "\(siteInfoTuple.1.languageCode).json"])
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
        var recognizedMagicWords = siteInfo.query.magicwords.filter {
            return $0.name == "img_thumbnail" ||
            $0.name == "img_framed" ||
            $0.name == "img_frameless" ||
            $0.name == "img_right" ||
            $0.name == "img_left" ||
            $0.name == "img_center" ||
            $0.name == "img_none" ||
            $0.name == "img_alt" ||
            $0.name == "img_baseline" ||
            $0.name == "img_border" ||
            $0.name == "img_bottom" ||
            $0.name == "img_middle" ||
            $0.name == "img_sub" ||
            $0.name == "img_super" ||
            $0.name == "img_text_bottom" ||
            $0.name == "img_text_top" ||
            $0.name == "img_top" ||
            $0.name == "img_upright"
        }

        let namespaceAliases = siteInfo.query.namespacealiases
        var fileNamespaceMagicWords = namespaceAliases.filter { $0.id == 6 }.map { $0.alias }
        if let fileNamespaceMagicWord = siteInfo.query.namespaces["6"]?.name {
            fileNamespaceMagicWords.insert(fileNamespaceMagicWord, at: 0)
        }
        recognizedMagicWords.append(MagicWord(name: "file_namespace", aliases: fileNamespaceMagicWords))
        
        let namespaceInfo = WikipediaSiteInfoLookup.NamespaceInfo(namespace: namespaces, mainpage: siteInfo.query.general.mainpage.uppercased())
        return WikipediaSiteInfoLookup(namespaceInfo: namespaceInfo, magicWordInfo: recognizedMagicWords)
    }
}
