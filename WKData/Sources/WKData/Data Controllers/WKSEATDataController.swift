import Foundation

public final class WKSEATDataController {
    
    public static let shared = WKSEATDataController()
    
    var mediaWikiService: WKService?
    var basicService: WKService?
    
    let enProject = WKProject.wikipedia(WKLanguage(languageCode: "en", languageVariantCode: nil))
    let esProject = WKProject.wikipedia(WKLanguage(languageCode: "es", languageVariantCode: nil))
    let ptProject = WKProject.wikipedia(WKLanguage(languageCode: "pt", languageVariantCode: nil))
    
    public private(set) var sampleData: [WKProject: [WKSEATItem]] = [:]
    public private(set) var isLoading: Bool = false
    
    private var completionHandlers: [() -> Void] = []
    
    public init() {
        self.mediaWikiService = WKDataEnvironment.current.mediaWikiService
        self.basicService = WKDataEnvironment.current.basicService
    }
    
    lazy var projectArticleTitles: [WKProject: [String]] = {
        return [
            enProject: ["Infection","The_Structure_of_Scientific_Revolutions","Law_of_superposition","Metropolitan_Borough_of_Greenwich","City_of_London","Esperanza_Spalding ","Carolingian_Empire","Butter","Facies","Surface_water","Habitat_fragmentation","Predation","Autoimmune_disease","Illustration","Headphones","Electric_generator","Fuel_cell","Drizzle","Ship_canal","Solid_geometry","Soap_bubble","Foam","Polytope","Gaels","Folklore_studies","Culture","Bitburg","Metonymy","Retail","Trolleybus","Domesday_Book","Human_history","Nomad","Pleistocene","International_Council_for_Science","Validity_(logic)","Shekhawati_painting","Maithili_Sharan_Gupt","Nationalities_and_regions_of_Spain","Pyrenees","Economy","Commodity","Glutamic_acid","Acid","Lord_Kelvin","Venus_of_Hohle_Fels","Alpine_ibex","Lightning ","Lake_Erie","Wheat"],
            esProject: ["Globalización ","Consumer_Electronics_Show ","Bioquímica","Genealogía ","Familia","Investigación ","Mate_(infusión)","Teatro_Solís","Tango","Bote","Ursus_maritimus","Playa","Fútbol","Otariinae","Carnaval","Auricular","IPhone","Espuma","Frida_Kahlo","Joaquín_Torres_García","Canal_de_navegación","Cuadrado ","Té_matcha","Salar ","Triticum ","Trolebús ","Río_Amazonas ","Phoenicopterus","Computadora","32X","Valhalla","Mitología_nórdica","Keagan_Dolly ","Villa_Pilar ","Zoe_Saldaña","Star_Wars","Nazca","Terremotos_de_Herat_de_2023","Pac-Man","Panthera_leo","Vultur_gryphus","Médico","Wikipedia ","Transporte_público","Conferencia","Lionel_Messi","FIFA","Biblioteca_del_Poder_Legislativo_de_Uruguay","Peach_&_Convention","Liceo_Héctor_Miranda"],
            ptProject: ["Infecção","Recurso_natural","Penicilina","Biologia","Organismo","Ronaldo_Nazário","Solanaceae","Kamini_Roy","Maciço","Magia","Cultura","História","Sociedade","Madeira","Ciclone_tropical","Propagação_térmica","Condução_térmica","Topologia_(matemática)","Fenomenologia","Filosofia","Banana","Enzima","Artista","Gênio_(pessoa)","Informática","Arado","Gás_natural","Carvão_mineral","Música","Scheila_Carvalho","Colônia_do_Sacramento","Carnaval_de_Florianópolis","Economia","Theatro_Municipal_do_Rio_de_Janeiro","Argila","Mecânica_dos_solos","TV_Fama","Laika","Foguete_espacial","Combustível","Pântano","Rio_Paraíba_do_Sul","Casa_Batlló","Galinha_caipira","Avião_a_jato","Velociraptor","Raio_(meteorologia)","Cerrado","Castelinho_do_Flamengo","Architectonica_maxima"]
        ]
    }()
    
    public func generateSampleData(project: WKProject, completion: @escaping () -> Void) {
        
        if let existingData = sampleData[project],
           !existingData.isEmpty {
            completion()
            return
        }
        
        self.completionHandlers.append(completion)
        
        guard !isLoading else {
            return
        }
        
        let executeAllCompletionHandlers = { [weak self] in
            
            guard let self else {
                return
            }
            
            for completionHandler in completionHandlers {
                completionHandler()
            }
            
            self.completionHandlers.removeAll()
        }
        
        guard let mediaWikiService else {
            executeAllCompletionHandlers()
            return
        }
        
        guard let articleTitles = projectArticleTitles[project] else {
            executeAllCompletionHandlers()
            return
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            executeAllCompletionHandlers()
            return
        }
        
        let concatTitles: String = articleTitles.joined(separator: "|")
        
        let parameters = [
            "action": "query",
            "prop": "revisions",
            "titles": concatTitles,
            "rvprop": "content",
            "format": "json",
            "formatversion": "2"
        ]
        
        var finalItems: [WKSEATItem] = []
        
        isLoading = true
        
        let group = DispatchGroup()
        group.enter()
        let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)
        mediaWikiService.perform(request: request) { [weak self] result in
            
            guard let self else {
                return
            }
            
            switch result {
            case .success(let dict):
                
                guard let query = dict?["query"] as? [String: AnyObject],
                    let pages = query["pages"] as? [[String: AnyObject]] else {
                    group.leave()
                    return
                }

                for page in pages {
                    guard let title = page["title"] as? String,
                          let firstRevision = (page["revisions"] as? [[String: AnyObject]])?.first,
                          let wikitext = firstRevision["content"] as? String else {
                        continue
                    }
                    
                    
                    let items = self.items(from: project, namespace: "File:", articleTitle: title, articleWikitext: wikitext, group: group)
                    finalItems.append(contentsOf: items)
                    let items2 = self.items(from: project, namespace: "Image:", articleTitle: title, articleWikitext: wikitext, group: group)
                    finalItems.append(contentsOf: items2)
                    
                    if project == esProject {
                        let moreItems1 = self.items(from: project, namespace: "Archivo:", articleTitle: title, articleWikitext: wikitext, group: group)
                        finalItems.append(contentsOf: moreItems1)
                        let moreItems2 = self.items(from: project, namespace: "Imagen:", articleTitle: title, articleWikitext: wikitext, group: group)
                        finalItems.append(contentsOf: moreItems2)
                    } else if project == ptProject {
                        let moreItems1 = self.items(from: project, namespace: "Ficheiro:", articleTitle: title, articleWikitext: wikitext, group: group)
                        finalItems.append(contentsOf: moreItems1)
                        let moreItems2 = self.items(from: project, namespace: "Arquivo:", articleTitle: title, articleWikitext: wikitext, group: group)
                        finalItems.append(contentsOf: moreItems2)
                        let moreItems3 = self.items(from: project, namespace: "Imagem:", articleTitle: title, articleWikitext: wikitext, group: group)
                        finalItems.append(contentsOf: moreItems3)
                    }
                }
                
                group.leave()
            case .failure:
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            self?.sampleData = [project: finalItems]
            executeAllCompletionHandlers()
        }
    }
    
    private func items(from project: WKProject, namespace: String, articleTitle: String, articleWikitext: String, group: DispatchGroup) -> [WKSEATItem] {
        
        let fileLinksWithoutAlt = try? NSRegularExpression(pattern: "\\[\\[\(namespace)(?![^]]*\\|\\s*alt\\s*=)[^]]*\\]\\]", options: [])
        
        var itemsToReturn: [WKSEATItem] = []
        fileLinksWithoutAlt?.enumerateMatches(in: articleWikitext, options: [], range: NSRange(location: 0, length: articleWikitext.count), using: { match, _, stop in
            guard let matchRange = match?.range(at: 0),
                  matchRange.location != NSNotFound else {
                return
            }
            
            let fileLinkWikitext = (articleWikitext as NSString).substring(with: matchRange)
            let fileNameRegex = try? NSRegularExpression(pattern: "\\[\\[(\(namespace).*?)\\|", options: [])
            
            guard let fileNameMatch = fileNameRegex?.firstMatch(in: fileLinkWikitext, range: NSRange(location: 0, length: fileLinkWikitext.count)) else {
                return
            }
            
            let fileNameRange = fileNameMatch.range(at: 1)
            
            guard fileNameRange.location != NSNotFound else {
                return
            }
            
            let wikitextFileName = (fileLinkWikitext as NSString).substring(with: fileNameRange)
            var commonsFileName: String = wikitextFileName
            commonsFileName = wikitextFileName.replacingOccurrences(of: "Image:", with: "File:")
            if project == esProject {
                commonsFileName = wikitextFileName.replacingOccurrences(of: "Archivo:", with: "File:")
                commonsFileName = commonsFileName.replacingOccurrences(of: "Imagen:", with: "File:")
            } else if project == ptProject {
                commonsFileName = wikitextFileName.replacingOccurrences(of: "Arquivo:", with: "File:")
                commonsFileName = commonsFileName.replacingOccurrences(of: "Ficheiro:", with: "File:")
                commonsFileName = commonsFileName.replacingOccurrences(of: "Imagem:", with: "File:")
            }
            
            let item = WKSEATItem(project: project, articleTitle: articleTitle, articleWikitext: articleWikitext, imageWikitext: fileLinkWikitext, imageWikitextFileName: wikitextFileName, imageCommonsFileName: commonsFileName, imageWikitextLocation: matchRange.location)

            populateThumbnailURLs(item: item, group: group)
            
            itemsToReturn.append(item)
        })
        
        populateArticleDetails(project: project, articleTitle: articleTitle, items: itemsToReturn, group: group)
        
        return itemsToReturn
    }
    
    private func populateThumbnailURLs(item: WKSEATItem, group: DispatchGroup) {
        
        guard let fileName = item.imageWikitextFileName?.replacingOccurrences(of: " ", with: "_") else {
            return
        }
        
        let parameters = [
            "action": "query",
            "prop": "imageinfo",
            "titles": fileName,
            "iilimit": "50",
            "iiprop": "url",
            "iiurlwidth": "300",
            "format": "json",
            "formatversion": "2"
        ]
        
        guard let url = URL.mediaWikiAPIURL(project: item.project) else {
            return
        }
        
        group.enter()
        let request = WKMediaWikiServiceRequest(url: url, method: .GET, parameters: parameters)
        mediaWikiService?.perform(request: request) { result in
            switch result {
            case .success(let dict):
                
                guard let query = dict?["query"] as? [String: AnyObject],
                      let pages = query["pages"] as? [[String: AnyObject]] else {
                    group.leave()
                    return
                }
                
                if let firstPage = pages.first {
                    
                    guard let imageInfo = (firstPage["imageinfo"] as? [[String: AnyObject]])?.first,
                    let thumbUrlString = imageInfo["thumburl"] as? String,
                          let thumbUrl = URL(string: thumbUrlString) else {
                        group.leave()
                        return
                    }
                    
                    let responsiveUrlStrings = imageInfo["responsiveUrls"] as? [String: String]
                    
                    item.imageThumbnailURLs["1"] = thumbUrl
                    
                    if let nextUrlString = responsiveUrlStrings?["1.5"] as? String,
                    let nextURL = URL(string: nextUrlString) {
                        item.imageThumbnailURLs["1.5"] = nextURL
                    }
                    
                    if let nextUrlString = responsiveUrlStrings?["2"] as? String,
                    let nextURL = URL(string: nextUrlString) {
                        item.imageThumbnailURLs["2"] = nextURL
                    }
                    
                    group.leave()
                }
            case .failure:
                group.leave()
            }
        }
    }
    
    private func populateArticleDetails(project: WKProject, articleTitle: String, items: [WKSEATItem], group: DispatchGroup) {

        guard let url = URL.summaryAPIURL(title: articleTitle, project: project) else {
            return
        }
        
        group.enter()
        let request = WKBasicServiceRequest(url: url, method: .GET)
        basicService?.perform(request: request) { result in
            switch result {
            case .success(let dict):
                let description = dict?["description"] as? String
                let summary = dict?["extract"] as? String
                for item in items {
                    item.articleDescription = description
                    item.articleSummary = summary
                }
                group.leave()
            case .failure:
                group.leave()
            }
        }
    }
}

public final class WKSEATItem: Equatable, Hashable {
    public static func == (lhs: WKSEATItem, rhs: WKSEATItem) -> Bool {
        return lhs.project == rhs.project &&
        lhs.articleTitle == rhs.articleTitle &&
        lhs.imageCommonsFileName == rhs.imageCommonsFileName
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(project)
        hasher.combine(articleTitle)
        hasher.combine(imageCommonsFileName)
    }
    
    public let project: WKProject
    public let articleTitle: String
    public fileprivate(set) var articleWikitext: String
    public fileprivate(set)var articleDescription: String?
    public fileprivate(set)var articleSummary: String?
    public fileprivate(set) var imageWikitext: String?
    public fileprivate(set) var imageWikitextFileName: String?
    public fileprivate(set) var imageCommonsFileName: String?
    public fileprivate(set) var imageThumbnailURLs: [String : URL]
    public fileprivate(set) var imageWikitextLocation: Int?
    
    public var imageDetailsURL: URL? {
        guard let imageWikitextFileName else {
            return nil
        }
        
        var languageCode = "en"
        switch project {
        case .wikipedia(let language):
            languageCode = language.languageCode
        default:
            break
        }
        
        let denormalizedFileName = imageWikitextFileName.replacingOccurrences(of: " ", with: "_")
        if let encodedFileName = denormalizedFileName.addingPercentEncoding(withAllowedCharacters: .urlQueryComponentAllowed) {
            return URL(string: "https://\(languageCode).wikipedia.org/wiki/\(encodedFileName)")
        }
        
        return nil
        
    }
    
    public var articleURL: URL? {
        switch project {
        case .wikipedia(let language):
            let denormalizedTitle = articleTitle.replacingOccurrences(of: " ", with: "_")
            if let encodedTitle = denormalizedTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryComponentAllowed) {
                return URL(string: "https://\(language.languageCode).wikipedia.org/wiki/\(encodedTitle)")
            }
            
            return nil
        default:
            return nil
        }
    }
    
    internal init(project: WKProject, articleTitle: String, articleWikitext: String, articleDescription: String? = nil, articleSummary: String? = nil, imageWikitext: String? = nil, imageWikitextFileName: String? = nil, imageCommonsFileName: String? = nil, imageThumbnailURLs: [String : URL] = [:], imageWikitextLocation: Int? = nil) {
        self.project = project
        self.articleTitle = articleTitle
        self.articleWikitext = articleWikitext
        self.articleDescription = articleDescription
        self.articleSummary = articleSummary
        self.imageWikitext = imageWikitext
        self.imageWikitextFileName = imageWikitextFileName
        self.imageCommonsFileName = imageCommonsFileName
        self.imageThumbnailURLs = imageThumbnailURLs
        self.imageWikitextLocation = imageWikitextLocation
    }
    
}
