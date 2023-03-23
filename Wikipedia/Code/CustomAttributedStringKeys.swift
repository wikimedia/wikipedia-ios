import Foundation

extension NSAttributedString.Key {
    public static var wikitextBold: NSAttributedString.Key {
        return NSAttributedString.Key("WikitextBold")
    }
    
    public static var wikitextItalic: NSAttributedString.Key {
        return NSAttributedString.Key("WikitextItalic")
    }
    
    public static var wikitextBoldAndItalic: NSAttributedString.Key {
        return NSAttributedString.Key("WikitextBoldAndItalic")
    }
    
    public static var wikitextLink: NSAttributedString.Key {
        return NSAttributedString.Key("WikitextLink")
    }
    
    public static var wikitextImage: NSAttributedString.Key {
        return NSAttributedString.Key("WikitextImage")
    }
    
    public static var wikitextTemplate: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextTemplate")
    }
    
    public static var wikitextRef: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextRef")
    }
    
    public static var wikitextRefWithAttributes: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextRefWithAttributes")
    }
    
    public static var wikitextRefSelfClosing: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextRefSelfClosing")
    }
    
    public static var wikitextSuperscript: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextSuperscript")
    }
    
    public static var wikitextSubscript: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextSubscript")
    }
    
    public static var wikitextUnderline: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextUnderline")
    }
    
    public static var wikitextStrikethrough: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextStrikethrough")
    }
    
    public static var wikitextListBullet: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextListBullet")
    }
    
    public static var wikitextListNumber: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextListNumber")
    }
    
    public static var wikitextH2: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextH2")
    }
    
    public static var wikitextH3: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextH3")
    }
    
    public static var wikitextH4: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextH4")
    }
    
    public static var wikitextH5: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextH5")
    }
    
    public static var wikitextH6: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextH6")
    }
    
    public static var wikitextComment: NSAttributedString.Key {
        return NSAttributedString.Key("wikitextComment")
    }
}

@objc class WMFWikitextAttributedStringKeyWrapper: NSObject {
    @objc static func boldKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextBold
    }
    
    @objc static func italicKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextItalic
    }
    
    @objc static func boldAndItalicKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextBoldAndItalic
    }
    
    @objc static func linkKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextLink
    }
    
    @objc static func imageKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextImage
    }
    
    @objc static func templateKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextTemplate
    }
    
    @objc static func refKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextRef
    }
    
    @objc static func refWithAttributesKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextRefWithAttributes
    }
    
    @objc static func refSelfClosingKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextRefSelfClosing
    }
    
    @objc static func superscriptKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextSuperscript
    }
    
    @objc static func subscriptKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextSubscript
    }
    
    @objc static func underlineKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextUnderline
    }
    
    @objc static func strikethroughKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextStrikethrough
    }
    
    @objc static func listBulletKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextListBullet
    }
    
    @objc static func listNumberKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextListNumber
    }
    
    @objc static func h2Key() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextH2
    }
    
    @objc static func h3Key() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextH3
    }
    
    @objc static func h4Key() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextH4
    }
    
    @objc static func h5Key() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextH5
    }
    
    @objc static func h6Key() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextH6
    }
    
    @objc static func commentKey() -> NSAttributedString.Key {
        return NSAttributedString.Key.wikitextComment
    }
}
