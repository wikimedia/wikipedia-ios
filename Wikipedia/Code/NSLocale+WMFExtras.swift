//  Created by Monte Hurd on 10/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

import Foundation

extension NSLocale {
    class func wmf_isCurrentLocaleEnglish() -> Bool {
        guard let langCode = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String else {
            return false
        }
        return (langCode == "en" || langCode.hasPrefix("en-")) ? true : false;
    }
    func wmf_localizedLanguageNameForCode(code: String) -> String? {
        return self.displayNameForKey(NSLocaleLanguageCode, value: code)
    }
}
