
@objc extension NSString {
    func wmf_isPrimarilyRTL() -> Bool {
        return String(self).wmf_isPrimarilyRTL()
    }
}

extension String {
    private static let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
    
    func wmf_isPrimarilyRTL() -> Bool {
        String.tagger.string = self
        
        var dominantLang: String?
        if #available(iOS 11.0, *) {
            dominantLang = String.tagger.dominantLanguage
        } else {
            dominantLang = String.tagger.tag(at: 0, scheme: .language, tokenRange: nil, sentenceRange: nil)?.rawValue
        }
        
        guard let lang = dominantLang else {
            return false
        }
        
        let isRTL = lang == "he" || lang.hasPrefix("he-") || lang == "ar" || lang.hasPrefix("ar-") || lang == "fa" || lang.hasPrefix("fa-")
        return isRTL
    }
}
