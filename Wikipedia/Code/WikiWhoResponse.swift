
import Foundation
import CocoaLumberjackSwift

struct WikiWhoResponse: Decodable {
    let extendedHtml: String
    let revisions: [String: Revision]
    let editors: [Editor]
    let tokens: [Token]
    
    enum CodingKeys: String, CodingKey {
        case extendedHtml = "extended_html"
        case wikiWhoData = "wikiwho_data"
        case revisions
        case editors = "present_editors"
        case tokens
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        extendedHtml = try container.decode(String.self, forKey: .extendedHtml)
        
        let wikiWhoData = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .wikiWhoData)
        let revisionsDict = try wikiWhoData.decode([String: [DataItem]].self, forKey: .revisions)
        let editorsArray = try container.decode([[DataItem]].self, forKey: .editors)
        let tokensArray = try wikiWhoData.decode([[DataItem]].self, forKey: .tokens)
        self.revisions = revisionsDict.transformedForRevisions()
        self.editors = editorsArray.transformedForEditors()
        self.tokens = tokensArray.transformedForTokens()
    }
    
    struct Revision {
        let revisionID: String
        let revisionDateString: String
        let editorID: String
        let editorName: String
    }
    
    struct Editor {
        let editorID: String
        let editorName: String
        let editorPercentage: Float
    }
    
    struct Token {
        let text: String
        let revisionID: String
        let editorID: String
    }
    
    struct DataItem: Decodable {
        
        enum DataType {
            case string(String)
            case float(Float)
            case unrecognized
        }
        
        let type: DataType
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            let floatData = try? container.decode(Float.self)
            let stringData = try? container.decode(String.self)
            
            if let floatData = floatData {
                self.type = .float(floatData)
            } else if let stringData = stringData {
                self.type = .string(stringData)
            } else {
                self.type = .unrecognized
            }
        }
    }

}

fileprivate extension Array where Element == [WikiWhoResponse.DataItem] {
    
    func transformedForTokens() -> [WikiWhoResponse.Token] {
        var transformedArray: [WikiWhoResponse.Token] = []
        for data in self {
            guard data.count == 7 else {
                DDLogDebug("Unexpected tokens data count, skipping item.")
                continue
            }
            
            switch (data[1].type, data[2].type, data[5].type) {
            case (.string(let text), .float(let revisionID), .string(let editorID)):
                let transformedToken = WikiWhoResponse.Token(text: text, revisionID: String(Int(revisionID)), editorID: editorID)
                transformedArray.append(transformedToken)
            default:
                DDLogDebug("Unexpected token types, skipping item.")
                continue
            }
        }
        return transformedArray
    }
    
    func transformedForEditors() -> [WikiWhoResponse.Editor] {
        
        var transformedArray: [WikiWhoResponse.Editor] = []
        for data in self {
            guard data.count == 3 else {
                DDLogDebug("Unexpected revisions data count, skipping item.")
                continue
            }
            
            switch (data[0].type, data[1].type, data[2].type) {
            case (.string(let editorName), .string(let editorID), .float(let percentage)):
                let transformedEditor = WikiWhoResponse.Editor(editorID: editorID, editorName: editorName, editorPercentage: percentage)
                transformedArray.append(transformedEditor)
            default:
                DDLogDebug("Unexpected editor types, skipping item.")
                continue
            }
        }
        return transformedArray
    }
}

fileprivate extension Dictionary where Key == String, Value == [WikiWhoResponse.DataItem] {
    
    func transformedForRevisions() -> [String: WikiWhoResponse.Revision] {
        
        var transformedDict: [String: WikiWhoResponse.Revision] = [:]
        for (key, data) in self {
            guard data.count == 4 else {
                DDLogDebug("Unexpected revisions data count, skipping item.")
                continue
            }
            
            switch (data[0].type, data[1].type, data[2].type, data[3].type) {
            case (.string(let datestamp), .float(let revisionID), .string(let editorID), .string(let editorName)):
                let transformedRevision = WikiWhoResponse.Revision(revisionID: String(Int(revisionID)), revisionDateString: datestamp, editorID: editorID, editorName: editorName)
                transformedDict[key] = transformedRevision
            default:
                DDLogDebug("Unexpected revision types, skipping item.")
                continue
            }
        }
        
        return transformedDict
    }
}
