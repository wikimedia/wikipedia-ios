import WMF
import SwiftUI

struct VanishAccountFooterView: View {
    
    enum LocalizedStrings {
        static let courtesyVanishingFooter = WMFLocalizedString("vanish-account-bottom-text", value: "Account deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. You may use the form below to request a courtesy vanishing. Vanishing does not guarantee complete anonymity or remove contributions to the projects.", comment: "Informative text on accounting deletion on Wikipedia")
        
        @available(iOS 15, *)
        static var courtesyVanishingFooteriOS15: AttributedString? = {
                
            let localizedString = WMFLocalizedString("vanish-account-bottom-text-with-link", value: "Account deletion on Wikipedia is done by changing your account name to make it so others cannot recognize your contributions in a process called account vanishing. You may use the form below to request a %1$@courtesy vanishing%2$@%3$@. Vanishing does not guarantee complete anonymity or remove contributions to the projects.", comment: "Informative text on accounting deletion on Wikipedia, contains link to more info on a web page. The parameters do not require translation, as they are used for markdown formatting. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting.")
        
            let substitutedString = String.localizedStringWithFormat(
                    localizedString,
                    "[",
                    "]",
                    "(https://meta.wikimedia.org/wiki/Right_to_vanish)"
            )

            return try? AttributedString(markdown: substitutedString)
        }()
    }
    
    var body: some View {
        if #available(iOS 15, *) {
            if let footer = LocalizedStrings.courtesyVanishingFooteriOS15 {
                Text(footer)
            } else {
                Text(LocalizedStrings.courtesyVanishingFooter)
            }
        } else {
            Text(LocalizedStrings.courtesyVanishingFooter)
        }
    }
}
