import Foundation

// Emum for namespaces common amongst most Wikipedia languages.
@objc public enum PageNamespace: Int, Codable {
    case media = -2
    case special = -1
    case main = 0
    case talk = 1
    case user = 2
    case userTalk = 3
    case wikipedia = 4
    case wikipediaTalk = 5
    case file = 6
    case fileTalk = 7
    case mediawiki = 8
    case mediawikiTalk = 9
    case template = 10
    case templateTalk = 11
    case help = 12
    case helpTalk = 13
    case category = 14
    case cateogryTalk = 15
    case thread = 90
    case threadTalk =  91
    case summary = 92
    case summaryTalk = 93
    case portal = 100
    case portalTalk = 101
    case project = 102
    case projectTalk = 103
    // case ambiguous1 = 104
    // case ambiguous2 = 105
    // case ambiguous3 = 106
    // case ambiguous4 = 107
    case book = 108
    case bookTalk = 109
    // case ambiguous5 = 110
    // case ambiguous6 = 111
    case draft = 118
    case draftTalk = 119
    case educationProgram = 446
    case educationProgramTalk = 447
    case campaign = 460
    case campaignTalk = 461
    case timedText = 710
    case timedTextTalk = 711
    case module = 828
    case moduleTalk = 829
    case gadget = 2300
    case gadgetTalk = 2301
    case gadgetDefinition = 2302
    case gadgetDefinitionTalk = 2303
    case topic = 2600
    
    public var canonicalName: String {
        switch self {
        case .media: return "Media"
        case .special: return "Special"
        case .talk: return "Talk"
        case .user: return "User"
        case .userTalk: return "User talk"
        case .wikipedia: return "Wikipedia"
        case .wikipediaTalk: return "Wikipedia talk"
        case .file: return "File"
        case .fileTalk: return "File talk"
        case .mediawiki: return "MediaWiki"
        case .mediawikiTalk: return "MediaWiki talk"
        case .template: return "Template"
        case .templateTalk: return "Template talk"
        case .help: return "Help"
        case .helpTalk: return "Help talk"
        case .category: return "Category"
        case .cateogryTalk: return "Category talk"
        case .portal: return "Portal"
        case .portalTalk: return "Portal talk"
        case .draft: return "Draft"
        case .draftTalk: return "Draft talk"
        case .timedText: return "TimedText"
        case .timedTextTalk: return "TimedText talk"
        case .module: return "Module"
        case .moduleTalk: return "Module talk"
        case .gadget: return "Gadget"
        case .gadgetTalk: return "Gadget talk"
        case .gadgetDefinition: return "Gadget definition"
        case .gadgetDefinitionTalk: return "Gadget definition talk"
        default:
            return ""
        }
    }

    public var isTalkBased: Bool {
        return 
            self == .talk ||
            self == .userTalk ||
            self == .wikipediaTalk ||
            self == .fileTalk ||
            self == .mediawikiTalk ||
            self == .templateTalk ||
            self == .helpTalk ||
            self == .cateogryTalk ||
            self == .threadTalk ||
            self == .summaryTalk ||
            self == .portalTalk ||
            self == .projectTalk ||
            self == .bookTalk ||
            self == .draftTalk ||
            self == .educationProgramTalk ||
            self == .campaignTalk ||
            self == .timedTextTalk ||
            self == .moduleTalk ||
            self == .gadgetTalk ||
            self == .gadgetDefinitionTalk
    }

    public var convertedPrimaryTalkPageNamespace: PageNamespace {
        switch self {
        case .talk:
            return .main
        case .userTalk:
            return .user
        case .wikipediaTalk:
            return .wikipedia
        case .fileTalk:
            return .file
        case .mediawikiTalk:
            return .mediawiki
        case .templateTalk:
            return .template
        case .helpTalk:
            return .help
        case .cateogryTalk:
            return .category
        case .threadTalk:
            return .thread
        case .summaryTalk:
            return .summary
        case .portalTalk:
            return .portal
        case .projectTalk:
            return .project
        case .bookTalk:
            return .book
        case .draftTalk:
            return .draft
        case .educationProgramTalk:
            return .educationProgram
        case .campaignTalk:
            return .campaign
        case .timedTextTalk:
            return .timedText
        case .moduleTalk:
            return .module
        case .gadgetTalk:
            return .gadget
        case .gadgetDefinitionTalk:
            return .gadgetDefinition
        default:
            return .main
        }
    }

    public var convertedToOrFromTalk: PageNamespace? {
        switch self {
        case .main:
            return .talk
        case .talk:
            return .main
        default:
            return nil
        }
    }
}

extension PageNamespace {
    public init?(namespaceValue: Int?) {
        guard let rawValue = namespaceValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
