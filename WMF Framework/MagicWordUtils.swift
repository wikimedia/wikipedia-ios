import Foundation

public enum MagicWordKey: String {
    case fileNamespace = "file_namespace"
    case imageThumbnail = "img_thumbnail"
    case imageRight = "img_right"
    case imageNone = "img_none"
    case imageLeft = "img_left"
    case imageFrameless = "img_frameless"
    case imageFramed = "img_framed"
    case imageCenter = "img_center"
    case imageAlt = "img_alt"
    case imageBaseline = "img_baseline"
    case imageBorder = "img_border"
    case imageBottom = "img_bottom"
    case imageMiddle = "img_middle"
    case imageSub = "img_sub"
    case imageSuper = "img_super"
    case imageTextBottom = "img_text_bottom"
    case imageTextTop = "img_text_top"
    case imageTop = "img_top"
    case imageUpright = "img_upright"
}
public struct MagicWordUtils {
    
    public static func getMagicWordsForKey(_ key: MagicWordKey, languageCode: String) -> [String] {
        let magicWords = fromFile(with: languageCode)
        
        guard let magicWord = magicWords?.first(where: { $0.name == key.rawValue }) else {
            return []
        }
        
        return magicWord.aliases
    }
    
    public static func getMagicWordForKey(_ key: MagicWordKey, languageCode: String) -> String? {
        let magicWords = fromFile(with: languageCode)
        
        guard let magicWord = magicWords?.first(where: { $0.name == key.rawValue }) else {
            return nil
        }
        
        return magicWord.aliases.first
    }
    
    static func fromFile(with languageCode: String) -> [MagicWord]? {
        guard
            let url = Bundle.wmf.url(forResource: "wikipedia-magicwords/\(languageCode)", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            return nil
        }
        return try? JSONDecoder().decode([MagicWord].self, from: data)
    }
}
