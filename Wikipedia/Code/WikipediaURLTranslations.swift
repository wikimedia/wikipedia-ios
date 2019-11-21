
struct WikipediaURLTranslations {
    private static var sharedLookupTable = WikipediaURLTranslation(languageCode: "en").languagecode

    private static func updateLookupTableIfNecessary(for languageCode: String) {
        guard sharedLookupTable[languageCode] == nil else {
            return
        }
        let translationsForLanguageCode = WikipediaURLTranslation(languageCode: languageCode).languagecode
        sharedLookupTable.merge(translationsForLanguageCode) {(current, _) in current}
    }
    
    static func commonNamespace(for namespaceString: String, in languageCode: String) -> WikipediaURLCommonNamespace? {
        updateLookupTableIfNecessary(for: languageCode)
        return WikipediaURLTranslations.sharedLookupTable[languageCode]?.namespace[namespaceString.uppercased().replacingOccurrences(of: "_", with: " ")]
    }

    static func mainpage(in languageCode: String) -> String? {
        updateLookupTableIfNecessary(for: languageCode)
        return WikipediaURLTranslations.sharedLookupTable[languageCode]?.mainpage
    }
}

struct WikipediaURLTranslation: Codable {
    var languagecode: Dictionary<String, WikipediaURLLanguageCodeTranslations> = Dictionary()
    init(languageCode: String) {
        guard
            let url = Bundle.main.url(forResource: "wikipedia-namespaces/\(languageCode)", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            assertionFailure("Unable to open JSON")
            return
        }
        do {
            languagecode = (try JSONDecoder().decode(WikipediaURLTranslation.self, from: data)).languagecode
        } catch {
            assertionFailure("Unable to decode WikipediaURLTranslation from JSON data")
        }
    }
}

struct WikipediaURLLanguageCodeTranslations: Codable {
    let namespace: Dictionary<String, WikipediaURLCommonNamespace>
    let mainpage: String
}

// Emum for namespaces common amongst most Wikipedia languages.
enum WikipediaURLCommonNamespace: Int, Codable {
    case Media = -2
    case Special = -1
    case Article = 0
    case Talk = 1
    case User = 2
    case User_talk = 3
    case Wikipedia = 4
    case Wikipedia_talk = 5
    case File = 6
    case File_talk = 7
    case MediaWiki = 8
    case MediaWiki_talk = 9
    case Template = 10
    case Template_talk = 11
    case Help = 12
    case Help_talk = 13
    case Category = 14
    case Category_talk = 15
    case Thread = 90
    case Thread_talk =  91
    case Summary = 92
    case Summary_talk = 93
    case Portal = 100
    case Portal_talk = 101
    case Project = 102
    case Project_talk = 103
    //case Ambiguous_1 = 104
    //case Ambiguous_2 = 105
    //case Ambiguous_3 = 106
    //case Ambiguous_4 = 107
    case Book = 108
    case Book_talk = 109
    //case Ambiguous_5 = 110
    //case Ambiguous_6 = 111
    case Draft = 118
    case Draft_talk = 119
    case Education_Program = 446
    case Education_Program_talk = 447
    case Campaign = 460
    case Campaign_talk = 461
    case TimedText = 710
    case TimedText_talk = 711
    case Module = 828
    case Module_talk = 829
    case Gadget = 2300
    case Gadget_talk = 2301
    case Gadget_definition = 2302
    case Gadget_definition_talk = 2303
    case Topic = 2600
}
