import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData

@objc(WMFYearInReviewCoordinator)
final class YearInReviewCoordinator: NSObject, Coordinator {
    
    let theme: Theme
    let dataStore: MWKDataStore

    var navigationController: UINavigationController
    private weak var viewModel: WMFYearInReviewViewModel?
    private let targetRects = WMFProfileViewTargetRects()
    let dataController: WMFYearInReviewDataController
    var donateCoordinator: DonateCoordinator?

    // Collective base numbers that will change for header
    var collectiveNumArticlesNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(63590000)
        return formatter.string(from: number) ?? "63,590,000"
    }

    var collectiveNumEditsNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(452257)
        return formatter.string(from: number) ?? "452,257"
    }

    var collectiveNumEditsPerMinuteNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(342)
        return formatter.string(from: number) ?? "342"
    }

    var collectiveNumViewsNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(1522941831)
        return formatter.string(from: number) ?? "1,522,941,831"
    }


    @objc public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFYearInReviewDataController) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
    }
    
    func formatNumber(_ number: NSNumber, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: number) ?? "\(number)"
    }

    var baseSlide1Title: String {
        WMFLocalizedString("year-in-review-base-reading-title", value: "Reading brought us together", comment: "Year in review, collective reading article count slide title")
    }

    var baseSlide1Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-reading-subtitle", value: "Wikipedia had %1$@ million articles across over %2$@ active languages this year. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review, collective reading count slide subtitle. %1$@ is replaced with a formatted number of articles available across Wikipedia, e.g. \"63.59\". %2$@ is replaced with the number of active languages available on Wikipedia, e.g. \"332\"")
        
        let numArticlesString = formatNumber(63.59, fractionDigits: 2)
        let numLanguagesString = formatNumber(332, fractionDigits: 0)
        
        return String.localizedStringWithFormat(format, numArticlesString, numLanguagesString)
    }

    var baseSlide2Title: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-title", value: "We have viewed Wikipedia articles %1$@ Billion times", comment: "Year in review, collective article view count slide title. %1$@ is replaced with the text representing the number of article views across Wikipedia, e.g. \"1.5\".")
        
        let numArticleViewsString = formatNumber(1.5, fractionDigits: 2)
        
        return String.localizedStringWithFormat(format, numArticleViewsString)
    }

    var baseSlide2Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-subtitle", value: "iOS app users have viewed Wikipedia articles %1$@ Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact.", comment: "Year in review, collective article view count subtitle, %1$@ is replaced with the number of article views text, e.g. \"1.5\"")
        
        let numArticleViewsString = formatNumber(1.5, fractionDigits: 2)
        
        return String.localizedStringWithFormat(format, numArticleViewsString)
    }

    var baseSlide3Title: String {
        let format = WMFLocalizedString("year-in-review-base-editors-title", value: "Editors on the iOS app made more than %1$@ edits", comment: "Year in review, collective edits count slide title, %1$@ is replaced with the number of edits text, e.g. \"452,257\".")
        
        let numEditsString = formatNumber(452257, fractionDigits: 0)
        
        return String.localizedStringWithFormat(format, numEditsString)
    }

    var baseSlide3Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-editors-subtitle", value: "Wikipedia's community of volunteer editors made more than %1$@ edits on the iOS app so far this year. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information.", comment: "Year in review, collective edits count slide subtitle, %1$@ is replaced with the number of edits text, e.g. \"452,257\"")
        
        let numEditsString = formatNumber(452257, fractionDigits: 0)
        
        return String.localizedStringWithFormat(format, numEditsString)
    }

    var baseSlide4Title: String {
        let format = WMFLocalizedString("year-in-review-base-edits-title", value: "Wikipedia was edited %1$@ times per minute", comment: "Year in review, collective edits per minute slide title, %1$@ is replaced with the number of edits per minute text, e.g. \"342\".")
        
        let numEditsPerMinString = formatNumber(342, fractionDigits: 0)
        
        return String.localizedStringWithFormat(format, numEditsPerMinString)
    }

    var baseSlide4Subtitle: String {
        let format = WMFLocalizedString("year-in-review-base-edits-subtitle", value: "This year, Wikipedia was edited at an average rate of %1$@ times per minute. Articles are collaboratively created and improved using reliable sources. Each edit plays a crucial role in improving and expanding Wikipedia.", comment: "Year in review, collective edits per minute slide subtitle, %1$@ is replaced with the number of edits per minute text, e.g. \"342\"")
        
        let numEditsPerMinString = formatNumber(342, fractionDigits: 0)
        
        return String.localizedStringWithFormat(format, numEditsPerMinString)
    }

    
    func personalizedSlide1Title(readCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-reading-title- format", value: "You read {{PLURAL:%1$d|%1$d article|%1$d articles}} this year", comment: "Year in review, personalized reading article count slide title for users that read articles. %1$d is replaced with the number of articles the user read.")
        return String.localizedStringWithFormat(format, readCount)
    }

    func personalizedSlide1Subtitle(readCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-reading-subtitle-format", value: "You read {{PLURAL:%1$d|%1$d article|%1$d articles}} this year. This year Wikipedia had %2$@ million articles available across over %3$@ active languages this year. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review, personalized reading article count slide subtitle for users that read articles. %1$d is replaced with the number of articles the user read. %2$@ is replaced with the number of articles available across Wikipedia, for example, \"63.59\". %3$@ is replaced with the number of active languages available on Wikipedia, for example \"332\"")
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let numArticles = NSNumber(63.59)
        let numArticlesString = formatter.string(from: numArticles) ?? "63.59"
        
        formatter.maximumFractionDigits = 0
        let numLanguages = NSNumber(332)
        let numLanguagesString = formatter.string(from: numLanguages) ?? "332"
        
        return String.localizedStringWithFormat(format, readCount, numArticlesString, numLanguagesString)
    }

    func personalizedSlide3Title(editCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-title-format", value: "You edited Wikipedia {{PLURAL:%1$d|%1$d time|%1$d times}}", comment: "Year in review, personalized editing article count slide title for users that edited articles. %1$d is replaced with the number of edits the user made.")
        return String.localizedStringWithFormat(format, editCount)
    }
    
    func personalizedSlide3Title500Plus() -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-title-format-500plus", value: "You edited Wikipedia 500+ times", comment: "Year in review, personalized editing article count slide title for users that edited articles 500+ times.")
        return String.localizedStringWithFormat(format)
    }
    
    func personalizedSlide3Subtitle(editCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-subtitle-format", value: "You edited Wikipedia {{PLURAL:%1$d|%1$d time|%1$d times}}. Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles. %1$d is replaced with the number of edits the user made.")
        return String.localizedStringWithFormat(format, editCount)
    }
    
    func personalizedSlide3Subtitle500Plus() -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-subtitle-format-500plus", value: "You edited Wikipedia 500+ times. Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles more than 500 times.")
        return String.localizedStringWithFormat(format)
    }

    private struct PersonalizedSlides {
        let readCount: YearInReviewSlideContent?
        let editCount: YearInReviewSlideContent?
        let donateCount: YearInReviewSlideContent?
    }

    private func getPersonalizedSlides() -> PersonalizedSlides {
        
        guard let dataController = try? WMFYearInReviewDataController(),
              let report = try? dataController.fetchYearInReviewReport(forYear: 2024) else {
            return PersonalizedSlides(readCount: nil, editCount: nil, donateCount: nil)
        }
        
        var readCountSlide: YearInReviewSlideContent? = nil
        var editCountSlide: YearInReviewSlideContent? = nil
        var donateCountSlide: YearInReviewSlideContent? = nil
        
        for slide in report.slides {
            switch slide.id {
            case .readCount:
                if slide.display == true,
                   let data = slide.data {
                    let decoder = JSONDecoder()
                    if let readCount = try? decoder.decode(Int.self, from: data) {
                        readCountSlide = YearInReviewSlideContent(
                            imageName: "read",
                            textOverlay: String.localizedStringWithFormat(
                                WMFLocalizedString(
                                    "year-in-review-personalized-read-count",
                                    value: "%1$@",
                                    comment: "Year in review, amount of articles read by the user, $1 is amount of articles."
                                ),
                                String(readCount)
                            ),
                            title: personalizedSlide1Title(readCount: readCount),
                            informationBubbleText: nil,
                            subtitle: personalizedSlide1Subtitle(readCount: readCount),
                            loggingID: "read_count_custom")
                    }
                }
            case .editCount:
                if slide.display == true,
                   let data = slide.data {
                    let decoder = JSONDecoder()
                    if let editCount = try? decoder.decode(Int.self, from: data) {
                        editCountSlide = YearInReviewSlideContent(
                            imageName: "edits",
                            textOverlay: String.localizedStringWithFormat(
                                WMFLocalizedString(
                                    "year-in-review-personalized-edit-count",
                                    value: "%1$@",
                                    comment: "Year in review, amount of edits made by the user. $1 is amount of edits."
                                ),
                                editCount >= 500 ? "500+" : String(editCount)
                            ),
                            title: editCount >= 500 ? personalizedSlide3Title500Plus() : personalizedSlide3Title(editCount: editCount),
                            informationBubbleText: nil,
                            subtitle: editCount >= 500 ? personalizedSlide3Subtitle500Plus() : personalizedSlide3Subtitle(editCount: editCount),
                            loggingID: "edit_count_custom")
                    }
                }
            case .donateCount:
                if slide.display == true,
                   let data = slide.data {
                    let decoder = JSONDecoder()
                    if let donateCount = try? decoder.decode(Int.self, from: data) {
                        donateCountSlide = nil
                        // TODO: Create personalized donate slide
                    }
                }
            }
        }
        return PersonalizedSlides(readCount: readCountSlide, editCount: editCountSlide, donateCount: donateCountSlide)
    }
    
    func start() {
               
       var firstSlide = YearInReviewSlideContent(
           imageName: "read",
           textOverlay: collectiveNumArticlesNumber,
           title: baseSlide1Title,
           informationBubbleText: nil,
           subtitle: baseSlide1Subtitle,
           loggingID: "read_count_base")
       
       var thirdSlide = YearInReviewSlideContent(
           imageName: "edits",
           textOverlay: collectiveNumEditsNumber,
           title: baseSlide3Title,
           informationBubbleText: nil,
           subtitle: baseSlide3Subtitle,
           loggingID: "edit_count_base")
       
       let personalizedSlides = getPersonalizedSlides()
       
       if let readCountSlide = personalizedSlides.readCount {
           firstSlide = readCountSlide
       }
       
       if let editCountSlide = personalizedSlides.editCount {
           thirdSlide = editCountSlide
       }
       
       let slides: [YearInReviewSlideContent] = [
           firstSlide,
           YearInReviewSlideContent(
               imageName: "viewed",
               textOverlay: collectiveNumViewsNumber,
               title: baseSlide2Title,
               informationBubbleText: nil,
               subtitle: baseSlide2Subtitle,
               loggingID: "read_view_base"),
           thirdSlide,
           YearInReviewSlideContent(
               imageName: "editedPerMinute",
               textOverlay: collectiveNumEditsPerMinuteNumber,
               title: baseSlide4Title,
               informationBubbleText: nil,
               subtitle: baseSlide4Subtitle,
               loggingID: "edit_rate_base")
           // TODO: Personalized or collective 5th donate slide here
       ]
        
       
       let localizedStrings = WMFYearInReviewViewModel.LocalizedStrings.init(
           donateButtonTitle: WMFLocalizedString("year-in-review-donate", value: "Donate", comment: "Year in review donate button"),
           doneButtonTitle: WMFLocalizedString("year-in-review-done", value: "Done", comment: "Year in review done button"),
           shareButtonTitle: WMFLocalizedString("year-in-review-share", value: "Share", comment: "Year in review share button"),
           nextButtonTitle: WMFLocalizedString("year-in-review-next", value: "Next", comment: "Year in review next button"),
           firstSlideTitle: WMFLocalizedString("year-in-review-title", value: "Explore your Wikipedia Year in Review", comment: "Year in review page title"),
           firstSlideSubtitle: WMFLocalizedString("year-in-review-subtitle", value: "See insights about which articles you read on the Wikipedia app and the edits you made. Share your journey and discover what stood out for you this year. Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Year in review page information"),
           firstSlideCTA: WMFLocalizedString("year-in-review-get-started", value: "Get Started", comment: "Button to continue to year in review"),
           firstSlideHide: WMFLocalizedString("year-in-review-hide", value: "Hide this feature", comment: "Button to hide year in review feature"),
           shareText: WMFLocalizedString("year-in-review-share-text", value: "Here's my Wikipedia year in review. Created with the Wikipedia iOS app", comment: "Text shared the Year In Review slides"),
           usernameTitle: CommonStrings.userTitle
       )
       
       let appShareLink = "https://apps.apple.com/app/apple-store/id324715238?pt=208305&ct=yir_2024_share&mt=8"
       let hashtag = "#WikipediaYearInReview"
       let viewModel = WMFYearInReviewViewModel(localizedStrings: localizedStrings, slides: slides, username: dataStore.authenticationManager.authStatePermanentUsername, shareLink: appShareLink, hashtag: hashtag, coordinatorDelegate: self, loggingDelegate: self)
       
       let yirview = WMFYearInReviewView(viewModel: viewModel)
       
       self.viewModel = viewModel
       let finalView = yirview.environmentObject(targetRects)
       let hostingController = UIHostingController(rootView: finalView)
       hostingController.modalPresentationStyle = .pageSheet
       
       if let sheetPresentationController = hostingController.sheetPresentationController {
           sheetPresentationController.detents = [.large()]
           sheetPresentationController.prefersGrabberVisible = false
       }
       
       hostingController.presentationController?.delegate = self
       
      (self.navigationController as? RootNavigationController)?.turnOnForcePortrait()
       navigationController.present(hostingController, animated: true, completion: nil)
   }
    
    private func presentSurveyIfNeeded() {
        if !self.dataController.hasPresentedYiRSurvey {
            let surveyVC = surveyViewController()
            navigationController.present(surveyVC, animated: true)
            self.dataController.hasPresentedYiRSurvey = true
        }
    }

    private func surveyViewController() -> UIViewController {
        let title = WMFLocalizedString("year-in-review-survey-title", value: "Satisfaction survey", comment: "Year in review survey title. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let subtitle = WMFLocalizedString("year-in-review-survey-subtitle", value: "Help improve the Wikipedia Year in Review. Are you satisfied with this feature? What would like to see next year?", comment: "Year in review survey subtitle. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let additionalThoughts = WMFLocalizedString("year-in-review-survey-additional-thoughts", value: "Any additional thoughts?", comment: "Year in review survey placeholder for additional thoughts textfield. Survey is displayed after user has viewed the last slide of their year in review feature.")
        
        let verySatisfied = WMFLocalizedString("year-in-review-survey-very-satisfied", value: "Very satisfied", comment: "Year in review survey option 1 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let satisfied = WMFLocalizedString("year-in-review-survey-satisfied", value: "Satisfied", comment: "Year in review survey option 2 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let neutral = WMFLocalizedString("year-in-review-survey-neutral", value: "Neutral", comment: "Year in review survey option 3 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let unsatisfied = WMFLocalizedString("year-in-review-survey-unsatisfied", value: "Unsatisfied", comment: "Year in review survey option 4 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let veryUnsatisfied = WMFLocalizedString("year-in-review-survey-very-unsatisfied", value: "Very unsatisfied", comment: "Year in review survey option 5 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        
        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: title,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            subtitle: subtitle,
            instructions: nil,
            otherPlaceholder: additionalThoughts
        )
        
        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: verySatisfied, apiIdentifer: "very_satisfied"),
            WMFSurveyViewModel.OptionViewModel(text: satisfied, apiIdentifer: "satisfied"),
            WMFSurveyViewModel.OptionViewModel(text: neutral, apiIdentifer: "neutral"),
            WMFSurveyViewModel.OptionViewModel(text: unsatisfied, apiIdentifer: "unsatisfied"),
            WMFSurveyViewModel.OptionViewModel(text: veryUnsatisfied, apiIdentifer: "very_unsatisfied")
        ]
        
        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single),
            cancelAction: { [weak self] in
            self?.navigationController.dismiss(animated: true)
        },
            submitAction: { [weak self] options, otherText in
            print("TODO: Send answer to DonateFunnel")
            self?.navigationController.dismiss(animated: true, completion: {
                let image = UIImage(systemName: "checkmark.circle.fill")
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
            })
        })

        let hostedView = WMFComponentHostingController(rootView: surveyView)
        return hostedView
    }
}

extension YearInReviewCoordinator: WMFYearInReviewLoggingDelegate {
    
    func logYearInReviewSlideDidAppear(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewSlideImpression(slideLoggingID: slideLoggingID)
    }
    
    func logYearInReviewDidTapDone(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }
    
    func logYearInReviewIntroDidTapContinue() {
        DonateFunnel.shared.logYearInReviewDidTapIntroContinue()
    }
    
    func logYearInReviewIntroDidTapDisable() {
        DonateFunnel.shared.logYearInReviewDidTapIntroDisable()
    }
    
    func logYearInReviewDidTapNext(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapNext(slideLoggingID: slideLoggingID)
    }
}

extension YearInReviewCoordinator: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        viewModel?.logYearInReviewDidTapDone()
        (self.navigationController as? RootNavigationController)?.turnOffForcePortrait()
    }
}

extension YearInReviewCoordinator: YearInReviewCoordinatorDelegate {
    func handleYearInReviewAction(_ action: WMFComponents.YearInReviewCoordinatorAction) {
        switch action {
        case .donate(let rect, let slideLoggingID, let isLastSlide):
            
            if let metricsID = DonateCoordinator.metricsID(for: .yearInReview, languageCode: dataStore.languageLinkController.appLanguage?.languageCode) {
                DonateFunnel.shared.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID, metricsID: metricsID)
            }
            
            let donateCoordinator = DonateCoordinator(navigationController: navigationController, donateButtonGlobalRect: rect, source: .yearInReview, dataStore: dataStore, theme: theme, navigationStyle: .present, setLoadingBlock: {  [weak self] loading in
                guard let self,
                      let viewModel = self.viewModel else {
                    return
                }
                
                viewModel.isLoading = loading
            })
            
            self.donateCoordinator = donateCoordinator
            donateCoordinator.start()
            
            
        case .share(let image):

            guard let viewModel else { return }

            let text = "\(viewModel.localizedStrings.shareText) (\(viewModel.shareLink))\(viewModel.hashtag)"

            let activityItems: [Any] = [ShareAFactActivityImageItemProvider(image: image), text]

            let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityController.excludedActivityTypes = [.print, .assignToContact, .addToReadingList]

            if let visibleVC = self.navigationController.visibleViewController {
                if let popover = activityController.popoverPresentationController {
                    popover.sourceRect = visibleVC.view.bounds
                    popover.sourceView = visibleVC.view
                    popover.permittedArrowDirections = []
                }

                visibleVC.present(activityController, animated: true, completion: nil)
            }
        case .dismiss(let isLastSlide):
            (self.navigationController as? RootNavigationController)?.turnOffForcePortrait()
            navigationController.dismiss(animated: true, completion: { [weak self] in
                guard let self else { return }
                
                guard isLastSlide else { return }
                
                self.presentSurveyIfNeeded()
            })
        }
    }
}
