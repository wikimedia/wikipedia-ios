import UIKit
import WMFData
import WMF

typealias InsertMediaSettings = InsertMediaSettingsViewController.Settings

protocol InsertMediaSettingsViewControllerDelegate: ViewController {
    func insertMediaSettingsViewControllerDidTapProgress(imageWikitext: String, caption: String?, altText: String?, localizedFileTitle: String)
}

protocol InsertMediaSettingsViewControllerLoggingDelegate: ViewController {
    func logInsertMediaSettingsViewControllerDidAppear()
    func logInsertMediaSettingsViewControllerDidTapFileName()
    func logInsertMediaSettingsViewControllerDidTapCaptionLearnMore()
    func logInsertMediaSettingsViewControllerDidTapAltTextLearnMore()
    func logInsertMediaSettingsViewControllerDidTapAdvancedSettings()
}

final class InsertMediaSettingsViewController: ViewController {
    
    private let fromImageRecommendations: Bool
    private weak var delegate: InsertMediaSettingsViewControllerDelegate?
    private weak var imageRecLoggingDelegate: InsertMediaSettingsViewControllerLoggingDelegate?
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let image: UIImage

    let searchResult: InsertMediaSearchResult
    let siteURL: URL
    private var nextButton: UIBarButtonItem?

    private var textViewHeightDelta: (value: CGFloat, row: Int)?
    private var textViewsGroupedByType = [TextViewType: UITextView]()

    struct Settings {
        let caption: String?
        let alternativeText: String?
        let advanced: Advanced

        struct Advanced {
            let wrapTextAroundImage: Bool
            let imagePosition: ImagePosition
            let imageType: ImageType
            let imageSize: ImageSize

            enum ImagePosition: String {
                case right
                case left
                case center
                case none

                var displayTitle: String {
                    switch self {
                    case .right:
                        return WMFLocalizedString("insert-media-image-position-setting-right", value: "Right", comment: "Title for image position setting that positions image on the right")
                    case .left:
                        return WMFLocalizedString("insert-media-image-position-setting-left", value: "Left", comment: "Title for image position setting that positions image on the left")
                    case .center:
                        return WMFLocalizedString("insert-media-image-position-setting-center", value: "Center", comment: "Title for image position setting that positions image in the center")
                    case .none:
                        return WMFLocalizedString("insert-media-image-position-setting-none", value: "None", comment: "Title for image position setting that doesn't set image's position")
                    }
                }

                static var displayTitle: String {
                    return WMFLocalizedString("insert-media-image-position-settings-title", value: "Image position", comment: "Display ritle for image position setting")
                }
            }

            enum ImageType: String {
                case thumbnail = "thumb"
                case frameless
                case frame
                case basic

                var displayTitle: String {
                    switch self {
                    case .thumbnail:
                        return WMFLocalizedString("insert-media-image-type-setting-thumbnail", value: "Thumbnail", comment: "Title for image type setting that formats image as thumbnail")
                    case .frameless:
                        return WMFLocalizedString("insert-media-image-type-setting-frameless", value: "Frameless", comment: "Title for image type setting that formats image as frameless")
                    case .frame:
                        return WMFLocalizedString("insert-media-image-type-setting-frame", value: "Frame", comment: "Title for image type setting that formats image as framed")
                    case .basic:
                        return WMFLocalizedString("insert-media-image-type-setting-basic", value: "Basic", comment: "Title for image type setting that formats image as basic")
                    }
                }

                static var displayTitle: String {
                    return WMFLocalizedString("insert-media-image-type-settings-title", value: "Image type", comment: "Display ritle for image type setting")
                }
            }

            enum ImageSize {
                case `default`
                case custom(width: Int, height: Int)

                var displayTitle: String {
                    switch self {
                    case .default:
                        return WMFLocalizedString("insert-media-image-size-setting-default", value: "Default", comment: "Title for image size setting that sizes image using default size")
                    case .custom:
                        return WMFLocalizedString("insert-media-image-size-setting-custom", value: "Custom", comment: "Title for image size setting that sizes image using custom size")
                    }
                }

                static var displayTitle: String {
                    return WMFLocalizedString("insert-media-image-size-settings-title", value: "Image size", comment: "Display ritle for image size setting")
                }
                
                static var defaultSize: String {
                    "\(ImageSize.defaultWidth)x\(ImageSize.defaultHeight)px"
                }

                var rawValue: String {
                    switch self {
                    case .default:
                        return Self.defaultSize
                    case .custom(let width, let height):
                        return "\(width)x\(height)px"
                    }
                }

                static var unitName = WMFLocalizedString("insert-media-image-size-settings-px-unit-name", value: "px", comment: "Image size unit name, abbreviation for 'pixels'")

                static var defaultWidth = 220
                static var defaultHeight = 124
            }

            init(wrapTextAroundImage: Bool = false, imagePosition: ImagePosition = .right, imageType: ImageType = .thumbnail, imageSize: ImageSize = .default) {
                self.wrapTextAroundImage = wrapTextAroundImage
                self.imagePosition = imagePosition
                self.imageType = imageType
                self.imageSize = imageSize
            }
        }

        init(caption: String?, alternativeText: String?, advanced: Advanced = Advanced()) {
            self.caption = caption
            self.alternativeText = alternativeText
            self.advanced = advanced
        }
    }

    var settings: Settings? {
        let captionTextView = textViewsGroupedByType[.caption]
        let alternativeTextTextView = textViewsGroupedByType[.alternativeText]
        let caption = captionTextView?.text.wmf_hasNonWhitespaceText ?? false ? captionTextView?.text : nil
        let alternativeText = alternativeTextTextView?.text.wmf_hasNonWhitespaceText ?? false ? alternativeTextTextView?.text : nil
        return Settings(caption: caption, alternativeText: alternativeText, advanced: insertMediaAdvancedSettingsViewController.advancedSettings)
    }

    var imageTitle: URL? {
        return searchResult.filePageURL ?? searchResult.imageInfo?.filePageURL
    }

    private lazy var imageView: InsertMediaSettingsImageView = {
        let imageView = InsertMediaSettingsImageView.wmf_viewFromClassNib()!
        imageView.image = image
        imageView.imageDescription = searchResult.imageDescription ?? searchResult.imageInfo?.imageDescription
        imageView.title = searchResult.displayTitle
        imageView.titleURL = imageTitle
        imageView.titleAction = { [weak self] url in
            self?.imageRecLoggingDelegate?.logInsertMediaSettingsViewControllerDidTapFileName()
            self?.navigate(to: url, useSafari: false)
        }
        return imageView
    }()

    private lazy var insertMediaAdvancedSettingsViewController = InsertMediaAdvancedSettingsViewController()

    private lazy var buttonView: InsertMediaSettingsButtonView = {
        let buttonView = InsertMediaSettingsButtonView.wmf_viewFromClassNib()!
        let isRTL = UIApplication.shared.wmf_isRTL
        buttonView.buttonTitle = InsertMediaAdvancedSettingsViewController.title
        buttonView.buttonAction = { [weak self] _ in
            guard let self = self else {
                return
            }
            imageRecLoggingDelegate?.logInsertMediaSettingsViewControllerDidTapAdvancedSettings()
            self.insertMediaAdvancedSettingsViewController.apply(theme: self.theme)
            self.navigationController?.pushViewController(self.insertMediaAdvancedSettingsViewController, animated: true)
        }
        return buttonView
    }()

    private struct TextViewModel {
        let type: TextViewType
        let headerText: String
        let placeholder: String
        let footerText: String
        let learnMoreUrl: String

        init(type: TextViewType) {
            self.type = type
            switch type {
            case .caption:
                headerText = WMFLocalizedString("insert-media-caption-title", value: "Caption", comment: "Title for setting that allows users to add image captions")
                placeholder = WMFLocalizedString("insert-media-caption-caption-placeholder", value: "How does this image relate to the article?", comment: "Placeholder text for setting that allows users to add image captions")
                footerText = WMFLocalizedString("insert-media-caption-description", value: "Label that shows next to the item for all readers", comment: "Description for setting that allows users to add image captions")
                learnMoreUrl = "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Image_captions"
            case .alternativeText:
                headerText = WMFLocalizedString("insert-media-alternative-text-title", value: "Alternative text", comment: "Title for setting that allows users to add image alternative text")
                placeholder = WMFLocalizedString("insert-media-alternative-text-placeholder", value: "Describe this image", comment: "Placeholder text for setting that allows users to add image alternative text")
                footerText = WMFLocalizedString("insert-media-alternative-text-description", value: "Text description for readers who cannot see the image", comment: "Description for setting that allows users to add image alternative text")
                learnMoreUrl = "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits#Tips_for_creating_alt-text"
            }
        }
    }

    private enum TextViewType: Int, Hashable {
        case caption
        case alternativeText
    }

    private lazy var viewModels: [TextViewModel] = {
        let captionViewModel = TextViewModel(type: .caption)
        let alternativeTextViewModel = TextViewModel(type: .alternativeText)
        return [captionViewModel, alternativeTextViewModel]
    }()
    
    private lazy var reachabilityNotifier: ReachabilityNotifier = {
        let notifier = ReachabilityNotifier(Configuration.current.defaultSiteDomain) { [weak self] (reachable, flags) in
            if reachable {
                DispatchQueue.main.async {
                    self?.hideOfflineAlertIfNeeded()
                }
            } else {
                DispatchQueue.main.async {
                    self?.showOfflineAlertIfNeeded()
                }
            }
        }
        return notifier
    }()

    init(image: UIImage, searchResult: InsertMediaSearchResult, fromImageRecommendations: Bool, delegate: InsertMediaSettingsViewControllerDelegate, imageRecLoggingDelegate: InsertMediaSettingsViewControllerLoggingDelegate?, theme: Theme, siteURL: URL) {
        self.image = image
        self.searchResult = searchResult
        self.fromImageRecommendations = fromImageRecommendations
        self.delegate = delegate
        self.imageRecLoggingDelegate = imageRecLoggingDelegate
        self.siteURL = siteURL
        super.init()
        self.theme = theme
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        scrollView = tableView
        super.viewDidLoad()
        navigationBar.isBarHidingEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(tableView)
        tableView.register(InsertMediaSettingsTextTableViewCell.wmf_classNib(), forCellReuseIdentifier: InsertMediaSettingsTextTableViewCell.identifier)
        tableView.separatorStyle = .none

        if fromImageRecommendations {
            title = WMFLocalizedString("insert-media-add-image-details-title", value: "Add image details", comment: "Title for add image details view")
            nextButton = UIBarButtonItem(title: WMFLocalizedString("next-action-title", value: "Next", comment: "Title for insert action indicating the user can go to the next step"), style: .done, target: self, action: #selector(tappedProgress(_:)))
            nextButton?.tintColor = theme.colors.secondaryText
            navigationItem.rightBarButtonItem = nextButton
        } else {
            title = WMFLocalizedString("insert-media-media-settings-title", value: "Media settings", comment: "Title for media settings view")
            let insertButton = UIBarButtonItem(title: WMFLocalizedString("insert-action-title", value: "Insert", comment: "Title for insert action"), style: .done, target: self, action:  #selector(tappedProgress(_:)))
            insertButton.tintColor = theme.colors.link
            navigationItem.rightBarButtonItem = insertButton
        }
        
        apply(theme: theme)
    }

    @objc private func tappedProgress(_ sender: UIBarButtonItem) {
        let searchResult = searchResult
        
        let info = Self.imageInsertInfo(searchResult: searchResult, settings: settings, siteURL: siteURL)
        
        let wikitext = info.wikitext
        let captionToSend = info.caption
        let altTextToSend = info.altText
        let localizedFileTitle = info.localizedFileTitle
        
        delegate?.insertMediaSettingsViewControllerDidTapProgress(imageWikitext: wikitext, caption: captionToSend, altText: altTextToSend, localizedFileTitle: localizedFileTitle)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reachabilityNotifier.start()
        
        UIAccessibility.post(notification: .screenChanged, argument: nil)
        
        imageRecLoggingDelegate?.logInsertMediaSettingsViewControllerDidAppear()
        
        if !reachabilityNotifier.isReachable {
            showOfflineAlertIfNeeded()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        reachabilityNotifier.stop()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard textViewHeightDelta != nil else {
            return
        }
        UIView.performWithoutAnimation {
            self.textViewHeightDelta = nil
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
    
    private func showOfflineAlertIfNeeded() {
        let title = CommonStrings.noInternetConnection
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: title)
        } else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(title, sticky: false, dismissPreviousAlerts: true)
        }
    }

    private func hideOfflineAlertIfNeeded() {
        WMFAlertManager.sharedInstance.dismissAllAlerts()
    }
    
    typealias Wikitext = String
    typealias Caption = String
    typealias AltText = String
    typealias LocalizedFileTitle = String
    
    static func imageInsertInfo(searchResult: InsertMediaSearchResult, settings: InsertMediaSettings?, siteURL: URL) -> (wikitext: Wikitext, caption: Caption?, altText: AltText?, localizedFileTitle: LocalizedFileTitle) {
        
        let fileTitle = localizedFileTitle(searchResult: searchResult, siteURL: siteURL)
        var wikitext: String
        var captionToSend: String?
        var altTextToSend: String?
        
        guard let mediaSettings = settings else {
            wikitext = "[[\(fileTitle)]]"
            return (wikitext, nil, nil, fileTitle)
        }
        
        var imageTypeName = localizedImageTypeName(imageType: mediaSettings.advanced.imageType, siteURL: siteURL)
        let imagePositionName = localizedImagePositionName(imagePosition: mediaSettings.advanced.imagePosition, siteURL: siteURL)
        let altTextFormat = localizedAltTextFormat(siteURL: siteURL)
        
        let imageSize = mediaSettings.advanced.imageSize.rawValue == InsertMediaSettings.Advanced.ImageSize.defaultSize ? "" : " | \(mediaSettings.advanced.imageSize.rawValue)"
        imageTypeName = imageTypeName == InsertMediaSettings.Advanced.ImageType.basic.rawValue ? "" : " | \(imageTypeName)"
        
        switch (mediaSettings.caption, mediaSettings.alternativeText) {
        case (let caption?, let alternativeText?):
            wikitext = """
            [[\(fileTitle)\(imageTypeName)\(imageSize) | \(imagePositionName) | \(String.localizedStringWithFormat(altTextFormat, alternativeText)) | \(caption)]]
            """
            captionToSend = caption
            altTextToSend = alternativeText
        case (let caption?, nil):
            wikitext = """
            [[\(fileTitle)\(imageTypeName)\(imageSize) | \(imagePositionName) | \(caption)]]
            """
            captionToSend = caption
        case (nil, let alternativeText?):
            wikitext = """
            [[\(fileTitle)\(imageTypeName)\(imageSize) | \(imagePositionName) |  \(String.localizedStringWithFormat(altTextFormat, alternativeText))]]
            """
            altTextToSend = alternativeText
        default:
            wikitext = """
            [[\(fileTitle)\(imageTypeName)\(imageSize) | \(imagePositionName)]]
            """
        }
        
        return (wikitext, captionToSend, altTextToSend, fileTitle)
        
    }
    
    private static func localizedFileTitle(searchResult: InsertMediaSearchResult, siteURL: URL) -> String {
        guard let languageCode = siteURL.wmf_languageCode,
              searchResult.fileTitle.hasPrefix("File:") else {
            return searchResult.fileTitle
        }
        
        let clippedTitle = searchResult.fileTitle.dropFirst(5)
        
        guard let magicWord = MagicWordUtils.getMagicWordForKey(.fileNamespace, languageCode: languageCode) else {
            return searchResult.fileTitle
        }
             
        return "\(magicWord):\(clippedTitle)"
    }
    
    private static func localizedImageTypeName(imageType: InsertMediaImageTypeSettingsViewController.ImageType, siteURL: URL) -> String {
        guard let languageCode = siteURL.wmf_languageCode else {
            return imageType.rawValue
        }
        
        let key: MagicWordKey
        switch imageType {
        case .thumbnail:
            key = .imageThumbnail
        case .frameless:
            key = .imageFrameless
        case .frame:
            key = .imageFramed
        case .basic:
            return imageType.rawValue
        }
        
        guard let magicWord = MagicWordUtils.getMagicWordForKey(key, languageCode: languageCode) else {
            return imageType.rawValue
        }
             
        return magicWord
    }
    
    private static func localizedImagePositionName(imagePosition: InsertMediaImageTypeSettingsViewController.ImagePosition, siteURL: URL) -> String {
        guard let languageCode = siteURL.wmf_languageCode else {
            return imagePosition.rawValue
        }
        
        let key: MagicWordKey
        switch imagePosition {
        case .center:
            key = .imageCenter
        case .left:
            key = .imageLeft
        case .right:
            key = .imageRight
        case .none:
            key = .imageNone
        }
        
        guard let magicWord = MagicWordUtils.getMagicWordForKey(key, languageCode: languageCode) else {
            return imagePosition.rawValue
        }
             
        return magicWord
    }
    
    private static func localizedAltTextFormat(siteURL: URL) -> String {
        let enFormat = "alt=%@"
        guard let languageCode = siteURL.wmf_languageCode else {
            return enFormat
        }
        
        guard let magicWord = MagicWordUtils.getMagicWordForKey(.imageAlt, languageCode: languageCode) else {
            return enFormat
        }
             
        return magicWord.replacingOccurrences(of: "$1", with: "%@")
    }

    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        tableView.backgroundColor = view.backgroundColor
        imageView.apply(theme: theme)
        buttonView.apply(theme: theme)
        tableView.reloadData()
    }
}

// MARK: - Table view data source

extension InsertMediaSettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: InsertMediaSettingsTextTableViewCell.identifier, for: indexPath) as? InsertMediaSettingsTextTableViewCell else {
            return UITableViewCell()
        }
        let viewModel = viewModels[indexPath.row]
        cell.headerText = viewModel.headerText
        textViewsGroupedByType[viewModel.type] = cell.textViewConfigured(with: self, placeholder: viewModel.placeholder, placeholderDelegate: self, clearDelegate: self, tag: indexPath.row)
        cell.footerText = viewModel.footerText
        cell.selectionStyle = .none
        cell.apply(theme: theme)
        cell.learnMoreURL = URL(string: viewModel.learnMoreUrl)
        cell.learnMoreAction = { [weak self] url in
            guard let self = self else {
                return
            }
            
            switch viewModel.type {
            case .caption:
                self.imageRecLoggingDelegate?.logInsertMediaSettingsViewControllerDidTapCaptionLearnMore()
            case .alternativeText:
                self.imageRecLoggingDelegate?.logInsertMediaSettingsViewControllerDidTapAltTextLearnMore()
            }
            
            self.navigate(to: url, useSafari: false)
        }
        
        return cell
    }

}

// MARK: - UITableViewDelegate

extension InsertMediaSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return imageView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return buttonView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 300
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - UITextViewDelegate

extension InsertMediaSettingsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateTextViewHeight(textView)

        let point = textView.convert(CGPoint.zero, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: point), indexPath.row == 0 {

            let isTextViewEmpty = textView.text.isEmpty
            nextButton?.tintColor = isTextViewEmpty ? theme.colors.secondaryText : theme.colors.link
        }
    }

    private func updateTextViewHeight(_ textView: UITextView) {
        let oldHeight = textView.frame.size.height
        let newHeight = textView.systemLayoutSizeFitting(textView.frame.size).height
        guard oldHeight != newHeight else {
            return
        }
        textViewHeightDelta = (newHeight - oldHeight, textView.tag)
        UIView.performWithoutAnimation {
            textView.frame.size.height = newHeight
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

extension InsertMediaSettingsViewController: ThemeableTextViewPlaceholderDelegate {
    func themeableTextViewPlaceholderDidHide(_ themeableTextView: UITextView, isPlaceholderHidden: Bool) {
        updateTextViewHeight(themeableTextView)
    }
}

extension InsertMediaSettingsViewController: ThemeableTextViewClearDelegate {
    func themeableTextViewDidClear(_ themeableTextView: UITextView) {
        updateTextViewHeight(themeableTextView)
    }
}
