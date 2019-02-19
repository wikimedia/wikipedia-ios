import Foundation

@objc(WMFLicenses)
@objcMembers public class Licenses: NSObject {
    public static let localizedCCZEROTitle = WMFLocalizedString("cc-zero", value: "Creative Commons CC0", comment: "Name of the CC Zero license - https://creativecommons.org/publicdomain/zero/1.0/")
    public static let localizedSaveTermsTitle = WMFLocalizedString("wikitext-upload-save-terms-name", value: "Terms of Use", comment: "This message is used in the message [[Wikimedia:Wikipedia-ios-wikitext-upload-save-terms-and-license]].")

   
    public static let CCBYSA3URL = URL(string: "https://creativecommons.org/licenses/by-sa/3.0/")
    public static let CCZEROURL = URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")
    public static let GFDLURL = URL(string: "https://www.gnu.org/licenses/fdl.html")
    public static let saveTermsURL = URL(string:"https://foundation.wikimedia.org/wiki/Terms_of_Use")
}

