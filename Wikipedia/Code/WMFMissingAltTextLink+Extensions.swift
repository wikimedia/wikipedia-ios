import WMFData

public enum WMFMissingAltTextLinkExtractCaptionError: Error {
    case failureSettingUpRegex
    case errorStrippingTemplates
    case emptyContent
}

// Note: Ideally this would live in WMFData, but we can't move it there until we get magic words logic bundled there as well.
extension WMFMissingAltTextLink {
    @available(iOS 16.0, *)
    
    // Extracts a caption for display only. Note this strips out embedded links, templates, and html tags from caption, so it may not exactly match the original caption.
    func extractCaptionForDisplay(languageCode: String) throws -> String? {
        
        do {
            let onlyFilenameContentRegex = try Regex("^\\[\\[\\s*([^|]+\\s*)]]$")
            let ranges = file.ranges(of: onlyFilenameContentRegex)
            if ranges.count == 2 {
                return nil
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        
        // strip filename from text
        var finalText = text.replacingOccurrences(of: file, with: "")
        
        // strip any templates
        do {
            try stripTemplateRecursive(text: &finalText)
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.errorStrippingTemplates
        }
        
        // strip html
        finalText = finalText.removingHTML
        
        // strip params equal signs
        do {
            let paramsWithEqualSignsRegex = try Regex("\\|\\s*[^\\|\\=\\]]+=[^\\|\\=\\]]+\\s*")
            let ranges = finalText.ranges(of: paramsWithEqualSignsRegex)
            for range in ranges.reversed() {
                finalText.replaceSubrange(range, with: "")
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        // strip params with px
        do {
            let paramsWithSizeRegex = try Regex("\\|\\s*(?:\\d+)?x?\\d+px\\s*")
            let ranges = finalText.ranges(of: paramsWithSizeRegex)
            for range in ranges.reversed() {
                finalText.replaceSubrange(range, with: "")
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        // gather up all magic words
        var magicWords: [String] = []
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageThumbnail, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageRight, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageNone, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageLeft, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageFrameless, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageFramed, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageCenter, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageBaseline, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageBorder, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageMiddle, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageSub, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageSuper, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageTextBottom, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageTextTop, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageTop, languageCode: languageCode))
        magicWords.append(contentsOf: MagicWordUtils.getMagicWordsForKey(.imageUpright, languageCode: languageCode))
        
        let allMagicWords = magicWords.joined(separator: "|")
        
        // strip magic words
        do {
            let paramsWithMagicWordsRegex = try Regex("\\|\\s*(\(allMagicWords))\\s*")
            let ranges = finalText.ranges(of: paramsWithMagicWordsRegex)
            for range in ranges.reversed() {
                finalText.replaceSubrange(range, with: "")
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        // strip embedded links
        do {
            let paramsWithMagicWordsRegex = try Regex("\\|\\s*(\(allMagicWords))\\s*")
            let ranges = finalText.ranges(of: paramsWithMagicWordsRegex)
            for range in ranges.reversed() {
                finalText.replaceSubrange(range, with: "")
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        // strip the beginning and trailing links
        if finalText.prefix(2) == "[[" {
            finalText = String(finalText.dropFirst(2))
        }
        
        if finalText.suffix(2) == "]]" {
            finalText = String(finalText.dropLast(2))
        }
        
        // if there are any final links, clean up
        do {
            let linksRegex = try Regex("\\[\\[([^|\\[\\]]+\\|)[^|\\[\\]]+\\]\\]")
            let matches = finalText.matches(of: linksRegex)
            for match in matches.reversed() {
                guard match.count == 2,
                      let range = match[1].range else {
                    continue
                }
                
                finalText.replaceSubrange(range, with: "")
            }
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
        
        // strip remaining |, ], [ and spaces
        finalText = finalText.replacingOccurrences(of: "|", with: "")
        finalText = finalText.replacingOccurrences(of: "[", with: "")
        finalText = finalText.replacingOccurrences(of: "]", with: "")
        finalText = finalText.trimmingCharacters(in: .whitespaces)
        
        return finalText
    }
    
    @available(iOS 16.0, *)
    private func stripTemplateRecursive(text: inout String) throws {
        do {
            let templateContentRegex = try Regex("\\{\\{\\s*[^\\{\\}]+\\s*\\}\\}")
            let ranges = text.ranges(of: templateContentRegex)
            
            guard ranges.count > 0 else {
                return
            }
            
            for range in ranges.reversed() {
                text.replaceSubrange(range, with: "")
            }
            
            // try again
            do {
                try stripTemplateRecursive(text: &text)
            } catch {
                
            }
            
        } catch {
            throw WMFMissingAltTextLinkExtractCaptionError.failureSettingUpRegex
        }
    }
}
