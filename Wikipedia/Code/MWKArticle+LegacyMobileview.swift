
fileprivate extension MWKSection {
    func mobileViewDict() -> [String: Any?] {
        var dict: [String: Any?] = [:]
        dict["toclevel"] = toclevel
        dict["level"] = level?.stringValue
        dict["line"] = line
        dict["number"] = number
        dict["index"] = index
        dict["anchor"] = anchor
        dict["id"] = sectionId
        dict["text"] = text // stringByReplacingImageURLsWithAppSchemeURLs(inHTMLString: text ?? "", withBaseURL: baseURL, targetImageWidth: imageWidth)
        dict["fromtitle"] = fromURL?.wmf_titleWithUnderscores
        return dict
    }
}

fileprivate extension MWKArticle {
    func mobileViewLastModified() -> String? {
        guard let lastModifiedDate = lastmodified else {
            return nil
        }
        return iso8601DateString(lastModifiedDate)
    }
    func mobileViewLastModifiedBy() -> [String: String]? {
        guard let lastmodifiedby = lastmodifiedby else {
            return nil
        }
        return [
            "name": lastmodifiedby.name ?? "",
            "gender": lastmodifiedby.gender ?? ""
        ]
    }
    func mobileViewPageProps() -> [String: String]? {
        guard let wikidataId = wikidataId else {
            return nil
        }
        return [
            "wikibase_item": wikidataId
        ]
    }
    func mobileViewDescriptionSource() -> String? {
        switch descriptionSource {
        case .local:
            return "local"
        case .central:
            return "central"
        default:
            // should default use "local" too?
            return nil
        }
    }
    func mobileViewImage(size: CGSize) -> [String: Any]? {
        guard let imgName = image?.canonicalFilename() else {
            return nil
        }
        return [
            "file": imgName,
            "width": size.width,
            "height": size.height
        ]
    }
    func mobileViewThumbnail() -> [String: Any]? {
        guard let thumbnailSourceURL = imageURL /*article.thumbnail?.sourceURL.absoluteString*/ else {
            return nil
        }
        return [
            "url": thumbnailSourceURL
            // Can't seem to find the original thumb "width" and "height" to match that seen in the orig mobileview - did we not save/model these?
        ]
    }
    func mobileViewProtection() -> [String: Any]? {
        guard let protection = protection else {
            return nil
        }
        var protectionDict:[String: Any] = [:]
        for protectedAction in protection.protectedActions() {
            guard let actionString = protectedAction as? String else {
                continue
            }
            protectionDict[actionString] = protection.allowedGroups(forAction: actionString)
        }
        return protectionDict
    }
}

extension MWKArticle {
    @objc public func reconstructMobileViewJSON(imageSize: CGSize) -> [String: Any]? {
        /*
        print("""
        
            MWK ARTICLE:
            \(self)
            
        """)
        */
        guard
            let sections = sections?.entries as? [MWKSection]
        else {
            assertionFailure("Couldn't get expected article sections")
            return nil
        }

        var mvDict: [String: Any] = [:]
        
        mvDict["ns"] = ns
        mvDict["lastmodified"] = mobileViewLastModified()
        mvDict["lastmodifiedby"] = mobileViewLastModifiedBy()
        mvDict["revision"] = revisionId
        mvDict["languagecount"] = languagecount
        mvDict["displaytitle"] = displaytitle
        mvDict["id"] = articleId
        mvDict["pageprops"] = mobileViewPageProps()
        mvDict["description"] = entityDescription
        mvDict["descriptionsource"] = mobileViewDescriptionSource()
        mvDict["sections"] = sections.map { $0.mobileViewDict() }
        mvDict["editable"] = editable
        mvDict["image"] = mobileViewImage(size: imageSize)
        mvDict["thumb"] = mobileViewThumbnail()
        mvDict["protection"] = mobileViewProtection()

        return ["mobileview": mvDict]
    }
}

/*
extension Dictionary {
    func printAsFormattedJSON() {
        guard
            let d = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]),
            let s = String(data: d, encoding: .utf8)
        else {
            print("Unable to convert dict to JSON string")
            return
        }
        print(s as NSString) // https://stackoverflow.com/a/46740338
    }
}
*/
