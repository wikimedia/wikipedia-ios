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
    //case ambiguous1 = 104
    //case ambiguous2 = 105
    //case ambiguous3 = 106
    //case ambiguous4 = 107
    case book = 108
    case bookTalk = 109
    //case ambiguous5 = 110
    //case ambiguous6 = 111
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
        case .talk:
            return "Talk"
        case .userTalk:
            return "User talk"
        default: // add these as needed
            return ""
        }
    }
}

extension PageNamespace {
    init?(namespaceValue: Int?) {
        guard let rawValue = namespaceValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
