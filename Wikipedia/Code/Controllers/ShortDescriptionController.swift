import Foundation
import WMF
import WMFData

enum ShortDescriptionControllerError: Error {
    case failureConstructingRegexExpression
    case missingSelf
}

protocol ShortDescriptionControllerDelegate: AnyObject {
    func currentDescription(completion: @escaping (String?) -> Void)
}

class ShortDescriptionController: ArticleDescriptionControlling {
    
    private let wikitextFetcher: WikitextFetcher
    private let sectionUploader: WikiTextSectionUploader
    
    private let articleURL: URL
    let article: WMFArticle
    let articleLanguageCode: String
    
    private let sectionID: Int = 0
    
    public var languageCode: String? = "en"
    
    let descriptionSource: ArticleDescriptionSource
    private weak var delegate: ShortDescriptionControllerDelegate?
    
    fileprivate static let templateRegex = "(\\{\\{\\s*[sS]hort description\\|(?:1=)?)([^}|]+)([^}]*\\}\\})"
    
// MARK: Public
    
    /// Inits for use of updating EN Wikipedia article description
    /// - Parameters:
    ///   - wikitextFetcher: fetcher that fetches the first section of wikitext. Injectable for unit tests.
    ///   - sectionUploader: section uploader that uploads the new section wikitext. Injectable for unit tests.
    ///   - article: WMFArticle from ArticleViewController
    ///   - articleLanguageCode: Language code of article that we want to update (from ArticleViewController)
    ///   - articleURL: URL of article that we want to update (from ArticleViewController)
    ///   - descriptionSource: ArticleDescriptionSource determined via .edit action across ArticleViewController js bridge
    ///   - delegate: Delegate that can extract the current description from the article content
    init(wikitextFetcher: WikitextFetcher = WikitextFetcher(), sectionUploader: WikiTextSectionUploader = WikiTextSectionUploader(), article: WMFArticle, articleLanguageCode: String, articleURL: URL, descriptionSource: ArticleDescriptionSource, delegate: ShortDescriptionControllerDelegate) {
        self.wikitextFetcher = wikitextFetcher
        self.sectionUploader = sectionUploader
        self.article = article
        self.articleURL = articleURL
        self.articleLanguageCode = articleLanguageCode
        self.descriptionSource = descriptionSource
        self.delegate = delegate
    }
    
    /// Publishes a new article description to article wikitext. Detects the existence of the {{Short description}} template in the first section and replaces the text within or prepends the section with the new template.
    /// - Parameters:
    ///   - description: The new description to insert into the wikitext
    ///   - completion: Completion called when updated section upload call is successful.
    func publishDescription(_ description: String, editType: ArticleDescriptionEditType, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        wikitextFetcher.fetchSection(with: sectionID, articleURL: articleURL) { [weak self] (result) in
            DispatchQueue.main.async {

                guard let self = self else {
                    completion(.failure(ShortDescriptionControllerError.missingSelf))
                    return
                }

                switch result {
                case .success(let response):

                    let wikitext = response.wikitext
                    let revisionID = response.revisionID

                    self.uploadNewDescriptionToWikitext(wikitext, baseRevisionID: revisionID, newDescription: description, editType: editType, completion: completion)

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func currentDescription(completion: @escaping (String?, MediaWikiAPIDisplayError?) -> Void) {
        
        let group = DispatchGroup()
        
        var blockedError: MediaWikiAPIDisplayError?
        var currentDescription: String?
        
        // Populate current description
        group.enter()
        delegate?.currentDescription(completion: { description in
            currentDescription = description
            group.leave()
        })
        
        // Populate blocked error
        group.enter()
        wikitextFetcher.fetchSection(with: sectionID, articleURL: articleURL) { (result) in
            
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let result):
                blockedError = result.apiError
            case .failure:
                break
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(currentDescription, blockedError)
        }
    }

    func learnMoreViewControllerWithTheme(_ theme: Theme) -> UIViewController? {
        guard let url = URL(string: "https://en.wikipedia.org/wiki/Wikipedia:Short_description") else {
            return nil
        }
        
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        
        return SinglePageWebViewController(configType: .standard(config), theme: theme)
    }
    
    func warningTypesForDescription(_ description: String?) -> ArticleDescriptionWarningTypes {
        return descriptionIsTooLong(description) ? [.length] : []
    }
}

// MARK: Private helpers

private extension ShortDescriptionController {
    
    func uploadNewDescriptionToWikitext(_ wikitext: String, baseRevisionID: Int, newDescription: String, editType: ArticleDescriptionEditType, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        do {
            guard try wikitext.containsShortDescription() else {
                
                prependNewDescriptionToWikitextAndUpload(wikitext, baseRevisionID: baseRevisionID, newDescription: newDescription, editType: editType, completion: completion)
                return
            }
                
            replaceDescriptionInWikitextAndUpload(wikitext, newDescription: newDescription, baseRevisionID: baseRevisionID, editType: editType, completion: completion)
            
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func prependNewDescriptionToWikitextAndUpload(_ wikitext: String, baseRevisionID: Int, newDescription: String, editType: ArticleDescriptionEditType, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        let newTemplateToPrepend = "{{Short description|\(newDescription)}}\n"
        
        let editTag = editType == .add ? WMFEditTag.appDescriptionAdd.rawValue : WMFEditTag.appDescriptionChange.rawValue

        sectionUploader.prepend(
            toSectionID: "\(sectionID)",
            text: newTemplateToPrepend,
            forArticleURL: articleURL,
            summary: CommonStrings.editSummaryShortDescriptionAdded(with: languageCode),
            isMinorEdit: true,
            baseRevID: baseRevisionID as NSNumber,
            editTags: [editTag],
            completion: { [weak self] (result, error) in

                guard let self = self else {
                    completion(.failure(ShortDescriptionControllerError.missingSelf))
                    return
                }
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result,
                      let revisionID = self.revisionIDFromResult(result: result) else {
                    completion(.failure(RequestError.unexpectedResponse))
                    return
                }
                
                completion(.success(ArticleDescriptionPublishResult(newRevisionID: revisionID, newDescription: newDescription)))
            }
        )
    }
    
    func replaceDescriptionInWikitextAndUpload(_ wikitext: String, newDescription: String, baseRevisionID: Int, editType: ArticleDescriptionEditType, completion: @escaping (Result<ArticleDescriptionPublishResult, Error>) -> Void) {
        
        do {
            
            let updatedWikitext = try wikitext.replacingShortDescription(with: newDescription)
            
            let editTag = editType == .add ? WMFEditTag.appDescriptionAdd.rawValue : WMFEditTag.appDescriptionChange.rawValue
            
            sectionUploader.uploadWikiText(
                updatedWikitext,
                forArticleURL: articleURL,
                section: "\(sectionID)",
                summary: CommonStrings.editSummaryShortDescriptionUpdated(with: languageCode),
                isMinorEdit: true,
                addToWatchlist: false,
                baseRevID: baseRevisionID as NSNumber,
                captchaId: nil,
                captchaWord: nil,
                editTags: [editTag],
                completion: { [weak self] (result, error) in
                
                    guard let self = self else {
                        completion(.failure(ShortDescriptionControllerError.missingSelf))
                        return
                    }
       
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let result = result,
                          let revisionID = self.revisionIDFromResult(result: result) else {
                        completion(.failure(RequestError.unexpectedResponse))
                        return
                    }
                    
                    completion(.success(ArticleDescriptionPublishResult(newRevisionID: revisionID, newDescription: newDescription)))
                }
            )
        } catch let error {
            completion(.failure(error))
        }
    }
    
    func revisionIDFromResult(result: [AnyHashable: Any]) -> UInt64? {
        guard let fetchedData = result as? [String: Any],
              let newRevID = fetchedData["newrevid"] as? UInt64 else {
            assertionFailure("Could not extract revisionID as UInt64")
            return nil
        }
        
        return newRevID
    }
}

private extension String {
    
    /// Detects if the message receiver contains a {{short description}} template or not
    /// - Throws: If short description NSRegularExpression fails to instantiate
    /// - Returns: Boolean indicating whether the message receiver contains a {{short description}} template or not
    func containsShortDescription() throws -> Bool {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionController.templateRegex) else {
            throw ShortDescriptionControllerError.failureConstructingRegexExpression
        }
        
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
        
        return matches.count > 0
    }
    
    /// Replaces the {{short description}} template value in message receiver with the new description.
    /// Assumes the {{short description}} template already exists. Does not insert a {{short description}} template if it doesn't exist.
    /// - Parameter newShortDescription: new short description value to replace existing with
    /// - Throws: If short description NSRegularExpression fails to instantiate
    /// - Returns: Message receiver with short description template within replaced.
    func replacingShortDescription(with newShortDescription: String) throws -> String {
        
        guard let regex = try? NSRegularExpression(pattern: ShortDescriptionController.templateRegex) else {
            throw ShortDescriptionControllerError.failureConstructingRegexExpression
        }
        
        return regex.stringByReplacingMatches(in: self, range: NSRange(self.startIndex..., in: self), withTemplate: "$1\(newShortDescription)$3")
    }
}

#if TEST

extension String {
    func testContainsShortDescription() throws -> Bool {
        return try containsShortDescription()
    }

    func testReplacingShortDescription(with newShortDescription: String) throws -> String {
        return try replacingShortDescription(with: newShortDescription)
    }
}

#endif
