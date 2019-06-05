@objc public enum EditFunnelSource: Int {
    case titleDescription
    case pencil
    case highlight
    case unknown
    
    var stringValue: String? {
        switch self {
        case .titleDescription:
            return "title_description"
        case .pencil:
            return "pencil"
        case .highlight:
            return "highlight"
        case .unknown:
            return nil
        }
    }
}

// https://meta.wikimedia.org/wiki/Schema:MobileWikiAppEdit
@objc final class EditFunnel: EventLoggingFunnel, EventLoggingStandardEventProviding {
    @objc public static let shared = EditFunnel()

    var sessionToken: String?

    private override init() {
        super.init(schema: "MobileWikiAppEdit", version: 19082700)
    }

    enum Action: String {
        case start
        case preview
        case saved
        case captchaShown
        case captchaFailure
        case abuseFilterWarning
        case abuseFilterError
        case editSummaryTap
        case abuseFilterWarningIgnore
        case abuseFilterWarningBack
        case saveAttempt
        case error
        case ready
        case onboarding
        case editSummaryShown
    }

    private enum WikidataDescriptionEdit: String {
        case new
        case existing

        init(isAddingNewTitleDescription: Bool) {
            self = isAddingNewTitleDescription ? .new : .existing
        }
    }

    private func event(action: Action, source: EditFunnelSource? = nil, sessionToken: String? = nil, wikidataDescriptionEdit: WikidataDescriptionEdit? = nil, editSummaryType: EditSummaryViewCannedButtonType? = nil, abuseFilterName: String? = nil, errorText: String? = nil, revision: Int?) -> Dictionary<String, Any> {
        var event: [String : Any] = ["action": action.rawValue]

        if let source = source, let stringValue = source.stringValue {
            event["source"] = stringValue
        }
        if let revision = revision {
            event["revID"] = revision
        }
        if let editSummaryType = editSummaryType {
            event["editSummaryTapped"] = editSummaryType.eventLoggingKey
        }
        if let abuseFilterName = abuseFilterName {
            event["abuseFilterName"] = abuseFilterName
        }
        if let sessionToken = sessionToken {
            event["session_token"] = sessionToken
        }
        if let wikidataDescriptionEdit = wikidataDescriptionEdit {
            event["wikidataDescriptionEdit"] = wikidataDescriptionEdit.rawValue
        }
        if let errorText = errorText {
            event["errorText"] = errorText
        }

        return event
    }

    override func preprocessData(_ eventData: [AnyHashable : Any]) -> [AnyHashable : Any] {
        guard
            let sessionID = sessionID,
            let appInstallID = appInstallID
        else {
            assertionFailure("Missing required properties (sessionID or appInstallID); event won't be logged")
            return eventData
        }
        guard let event = eventData as? [String: Any] else {
            assertionFailure("Expected dictionary with keys of type String")
            return eventData
        }

        let requiredData: [String: Any] = ["session_token": sessionID, "anon": isAnon, "app_install_id": appInstallID, "client_dt": timestamp]

        return requiredData.merging(event, uniquingKeysWith: { (first, _) in first })
    }

    // MARK: Start

    @objc(logSectionEditingStartFromSource:revision:language:)
    public func logSectionEditingStart(from source: EditFunnelSource, revision: Int, language: String) {
        logStart(source: source, revision: revision, language: language)
    }

    @objc(logTitleDescriptionEditingStartFromSource:revision:language:)
    public func logTitleDescriptionEditingStart(from source: EditFunnelSource, revision: Int, language: String) {
        let wikidataDescriptionEdit: WikidataDescriptionEdit
        if source == .titleDescription {
            wikidataDescriptionEdit = .new
        } else {
            wikidataDescriptionEdit = .existing
        }
        logStart(source: source, wikidataDescriptionEdit: wikidataDescriptionEdit, revision: revision, language: language)
    }

    private func logStart(source: EditFunnelSource, wikidataDescriptionEdit: WikidataDescriptionEdit? = nil, revision: Int, language: String) {
        // session token should be regenerated at every 'start' event
        sessionToken = singleUseUUID()
        log(event(action: .start, source: source, sessionToken: sessionToken, wikidataDescriptionEdit: wikidataDescriptionEdit, revision: revision), language: language)
    }

    // MARK: Onboarding

    @objc(logOnboardingPresentationInitiatedBySource:revision:language:)
    public func logOnboardingPresentation(initiatedBy source: EditFunnelSource, revision: Int, language: String) {
        logOnboardingPresentation(source: source, revision: revision, language: language)
    }

    private func logOnboardingPresentation(source: EditFunnelSource, revision: Int, language: String) {
        log(event(action: .onboarding, source: source, revision: revision), language: language)
    }

    // MARK: Ready

    @objc(logTitleDescriptionReadyToEditFromSource:isAddingNewTitleDescription:revision:language:)
    public func logTitleDescriptionReadyToEditFrom(from source: EditFunnelSource, isAddingNewTitleDescription: Bool, revision: Int, language: String) {
        log(event(action: .ready, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription), revision: revision), language: language)
    }

    public func logSectionReadyToEdit(from source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .ready, source: source, revision: revision), language: language)
    }

    // MARK: Preview

    public func logEditPreviewForArticle(withRevision revision: Int?, language: String?) {
        log(event(action: .preview, revision: revision), language: language)
    }

    // MARK: Save attempt

    public func logTitleDescriptionSaveAttempt(source: EditFunnelSource, isAddingNewTitleDescription: Bool, revision: Int?, language: String?) {
        log(event(action: .saveAttempt, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription), revision: revision), language: language)
    }

    public func logSectionSaveAttempt(source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .saveAttempt, source: source, revision: revision), language: language)
    }

    // MARK: Saved

    public func logTitleDescriptionSaved(source: EditFunnelSource, isAddingNewTitleDescription: Bool, revision: Int?, language: String?) {
        log(event(action: .saved, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription), revision: revision), language: language)
    }

    public func logSectionSaved(source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .saved, source: source, revision: revision), language: language)
    }

    // MARK: Error

    public func logTitleDescriptionSaveError(source: EditFunnelSource, isAddingNewTitleDescription: Bool, revision: Int?, language: String?, errorText: String) {
        log(event(action: .error, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription), errorText: errorText, revision: revision), language: language)
    }

    public func logSectionSaveError(source: EditFunnelSource, revision: Int?, language: String?, errorText: String) {
        log(event(action: .error, source: source, errorText: errorText, revision: revision), language: language)
    }

    public func logSectionHighlightToEditError(revision: Int?, language: String?) {
        log(event(action: .error, source: .highlight, errorText: "non-editable", revision: revision), language: language)
    }

    // MARK: Section edit summary tap

    public func logSectionEditSummaryTap(source: EditFunnelSource, editSummaryType: EditSummaryViewCannedButtonType, revision: Int?, language: String?) {
        log(event(action: .editSummaryTap, source: source, editSummaryType: editSummaryType, revision: revision), language: language)
    }

    // MARK: Captcha

    public func logCaptchaShownForSectionEdit(source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .captchaShown, source: source, revision: revision), language: language)
    }

    public func logCaptchaFailedForSectionEdit(source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .captchaFailure, source: source, revision: revision), language: language)
    }

    // MARK: Abuse filter

    public func logAbuseFilterWarningForSectionEdit(abuseFilterName: String, source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .abuseFilterWarning, source: source, abuseFilterName: abuseFilterName, revision: revision), language: language)
    }

    public func logAbuseFilterWarningBackForSectionEdit(abuseFilterName: String, source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .abuseFilterWarningBack, source: source, abuseFilterName: abuseFilterName, revision: revision), language: language)
    }

    public func logAbuseFilterWarningIgnoreForSectionEdit(abuseFilterName: String, source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .abuseFilterWarningIgnore, source: source, abuseFilterName: abuseFilterName, revision: revision), language: language)
    }

    public func logAbuseFilterErrorForSectionEdit(abuseFilterName: String, source: EditFunnelSource, revision: Int?, language: String?) {
        log(event(action: .abuseFilterError, source: source, abuseFilterName: abuseFilterName, revision: revision), language: language)
    }
}
