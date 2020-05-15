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
        case editSummaryShown
        case abuseFilterWarningIgnore
        case abuseFilterWarningBack
        case saveAttempt
        case error
        case ready
        case onboarding
    }

    private enum WikidataDescriptionEdit: String {
        case new
        case existing

        init(isAddingNewTitleDescription: Bool) {
            self = isAddingNewTitleDescription ? .new : .existing
        }
    }

    private func event(action: Action, source: EditFunnelSource? = nil, sessionToken: String? = nil, wikidataDescriptionEdit: WikidataDescriptionEdit? = nil, editSummaryType: EditSummaryViewCannedButtonType? = nil, abuseFilterName: String? = nil, errorText: String? = nil, revision: UInt64? = nil) -> Dictionary<String, Any> {
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

    @objc(logSectionEditingStartFromSource:language:)
    public func logSectionEditingStart(from source: EditFunnelSource, language: String) {
        logStart(source: source, language: language)
    }

    @objc(logTitleDescriptionEditingStartFromSource:language:)
    public func logTitleDescriptionEditingStart(from source: EditFunnelSource, language: String) {
        let wikidataDescriptionEdit: WikidataDescriptionEdit
        if source == .titleDescription {
            wikidataDescriptionEdit = .new
        } else {
            wikidataDescriptionEdit = .existing
        }
        logStart(source: source, wikidataDescriptionEdit: wikidataDescriptionEdit, language: language)
    }

    private func logStart(source: EditFunnelSource, wikidataDescriptionEdit: WikidataDescriptionEdit? = nil, language: String) {
        // session token should be regenerated at every 'start' event
        sessionToken = singleUseUUID()
        log(event(action: .start, source: source, sessionToken: sessionToken, wikidataDescriptionEdit: wikidataDescriptionEdit), language: language)
    }

    // MARK: Onboarding

    @objc(logOnboardingPresentationInitiatedBySource:language:)
    public func logOnboardingPresentation(initiatedBy source: EditFunnelSource, language: String) {
        logOnboardingPresentation(source: source, language: language)
    }

    private func logOnboardingPresentation(source: EditFunnelSource, language: String) {
        log(event(action: .onboarding, source: source), language: language)
    }

    // MARK: Ready

    @objc(logTitleDescriptionReadyToEditFromSource:isAddingNewTitleDescription:language:)
    public func logTitleDescriptionReadyToEditFrom(from source: EditFunnelSource, isAddingNewTitleDescription: Bool, language: String) {
        log(event(action: .ready, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription)), language: language)
    }

    public func logSectionReadyToEdit(from source: EditFunnelSource, language: String?) {
        log(event(action: .ready, source: source), language: language)
    }

    // MARK: Preview

    public func logEditPreviewForArticle(from source: EditFunnelSource, language: String?) {
        log(event(action: .preview, source: source), language: language)
    }

    // MARK: Save attempt

    public func logTitleDescriptionSaveAttempt(source: EditFunnelSource, isAddingNewTitleDescription: Bool, language: String?) {
        log(event(action: .saveAttempt, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription)), language: language)
    }

    public func logSectionSaveAttempt(source: EditFunnelSource, language: String?) {
        log(event(action: .saveAttempt, source: source), language: language)
    }

    // MARK: Saved

    public func logTitleDescriptionSaved(source: EditFunnelSource, isAddingNewTitleDescription: Bool, language: String?) {
        log(event(action: .saved, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription)), language: language)
    }

    public func logSectionSaved(source: EditFunnelSource, revision: UInt64?, language: String?) {
        log(event(action: .saved, source: source, revision: revision), language: language)
    }

    // MARK: Error

    public func logTitleDescriptionSaveError(source: EditFunnelSource, isAddingNewTitleDescription: Bool, language: String?, errorText: String) {
        log(event(action: .error, source: source, wikidataDescriptionEdit: WikidataDescriptionEdit(isAddingNewTitleDescription: isAddingNewTitleDescription), errorText: errorText), language: language)
    }

    public func logSectionSaveError(source: EditFunnelSource, language: String?, errorText: String) {
        log(event(action: .error, source: source, errorText: errorText), language: language)
    }

    public func logSectionHighlightToEditError(language: String?) {
        log(event(action: .error, source: .highlight, errorText: "non-editable"), language: language)
    }

    // MARK: Section edit summary

    public func logSectionEditSummaryTap(source: EditFunnelSource, editSummaryType: EditSummaryViewCannedButtonType, language: String?) {
        log(event(action: .editSummaryTap, source: source, editSummaryType: editSummaryType), language: language)
    }

    public func logSectionEditSummaryShown(source: EditFunnelSource, language: String?) {
        log(event(action: .editSummaryShown, source: source), language: language)
    }

    // MARK: Captcha

    public func logCaptchaShownForSectionEdit(source: EditFunnelSource, language: String?) {
        log(event(action: .captchaShown, source: source), language: language)
    }

    public func logCaptchaFailedForSectionEdit(source: EditFunnelSource, language: String?) {
        log(event(action: .captchaFailure, source: source), language: language)
    }

    // MARK: Abuse filter

    public func logAbuseFilterWarningForSectionEdit(abuseFilterName: String, source: EditFunnelSource, language: String?) {
        log(event(action: .abuseFilterWarning, source: source, abuseFilterName: abuseFilterName), language: language)
    }

    public func logAbuseFilterWarningBackForSectionEdit(abuseFilterName: String, source: EditFunnelSource, language: String?) {
        log(event(action: .abuseFilterWarningBack, source: source, abuseFilterName: abuseFilterName), language: language)
    }

    public func logAbuseFilterWarningIgnoreForSectionEdit(abuseFilterName: String, source: EditFunnelSource, language: String?) {
        log(event(action: .abuseFilterWarningIgnore, source: source, abuseFilterName: abuseFilterName), language: language)
    }

    public func logAbuseFilterErrorForSectionEdit(abuseFilterName: String, source: EditFunnelSource, language: String?) {
        log(event(action: .abuseFilterError, source: source, abuseFilterName: abuseFilterName), language: language)
    }
}
