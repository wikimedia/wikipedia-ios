@objc extension HTTPCookieStorage {
    public func cookiesWithNamePrefix(_ prefix: String, for domain: String) -> [HTTPCookie] {
        guard let cookies = cookies, !cookies.isEmpty else {
            return []
        }
        let standardizedPrefix = prefix.lowercased().precomposedStringWithCanonicalMapping
        let standardizedDomain = domain.lowercased().precomposedStringWithCanonicalMapping
        return cookies.filter({ (cookie) -> Bool in
            return cookie.domain.lowercased().precomposedStringWithCanonicalMapping == standardizedDomain && cookie.name.lowercased().precomposedStringWithCanonicalMapping.hasPrefix(standardizedPrefix)
        })
    }
    
    public func copyCookiesWithNamePrefix(_ prefix: String, for domain: String, to toDomains: [String]) {
        let cookies = cookiesWithNamePrefix(prefix, for: domain)
        for toDomain in toDomains {
            for cookie in cookies {
                var properties = cookie.properties ?? [:]
                properties[.domain] = toDomain
                guard let copiedCookie = HTTPCookie(properties: properties) else {
                    continue
                }
                setCookie(copiedCookie)
            }
        }
    }
    
    @objc public static func migrateCookiesToSharedStorage() {
        let legacyStorage = HTTPCookieStorage.shared
        let sharedStorage = Session.sharedCookieStorage
        guard let legacyCookies = legacyStorage.cookies else {
            return
        }
        
        for legacyCookie in legacyCookies {
            sharedStorage.setCookie(legacyCookie)
            legacyStorage.deleteCookie(legacyCookie)
        }
    }
}
