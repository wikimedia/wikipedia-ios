import UIKit
import WMFData

final public class WMFImageRecommendationsBottomSheetViewController: WMFCanvasViewController {

    // MARK: Properties

    public var viewModel: WMFImageRecommendationsViewModel
    public var tooltipViewModels: [WMFTooltipViewModel] = []
    weak var delegate: WMFImageRecommendationsDelegate?
    weak var loggingDelegate: WMFImageRecommendationsLoggingDelegate?
    private(set) var bottomSheetView: WMFImageRecommendationBottomSheetView?

    // MARK: Lifecycle

    public init(viewModel: WMFImageRecommendationsViewModel, delegate: WMFImageRecommendationsDelegate, loggingDelegate: WMFImageRecommendationsLoggingDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.loggingDelegate = loggingDelegate
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let bottomViewModel = populateImageSheetRecommendationViewModel(for: viewModel.currentRecommendation?.imageData) {
            let bottomSheetView = WMFImageRecommendationBottomSheetView(frame: UIScreen.main.bounds, viewModel: bottomViewModel)
            bottomSheetView.delegate = self
            addComponent(bottomSheetView, pinToEdges: true)
            self.bottomSheetView = bottomSheetView
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loggingDelegate?.logBottomSheetDidAppear()
    }

    // MARK: Methods

    private func populateImageSheetRecommendationViewModel(for image: WMFImageRecommendationsViewModel.WMFImageRecommendationData?) -> WMFImageRecommendationBottomSheetViewModel? {

        if let image {
            let viewModel = WMFImageRecommendationBottomSheetViewModel(
                pageId: image.pageId,
                headerTitle: viewModel.localizedStrings.bottomSheetTitle,
                imageThumbnail: image.uiImage,
                imageLink: image.fullUrl,
                thumbLink: image.thumbUrl,
                imageTitle: image.displayFilename,
                imageDescription: image.description, 
                reason: image.reason,
                yesButtonTitle: viewModel.localizedStrings.yesButtonTitle,
                noButtonTitle: viewModel.localizedStrings.noButtonTitle,
                notSureButtonTitle: viewModel.localizedStrings.notSureButtonTitle
            )
            return viewModel
        }
        return nil
    }

}
extension WMFImageRecommendationsBottomSheetViewController: WMFImageRecommendationsToolbarViewDelegate {
    func goToGallery() {
        guard let currentRecommendation = viewModel.currentRecommendation else {
            return
        }
        
        delegate?.imageRecommendationsUserDidTapImage(project: viewModel.project, data: currentRecommendation.imageData, presentingVC: self)
    }
    
    func goToImageCommonsPage() {
        
        loggingDelegate?.logBottomSheetDidTapFileName()

        guard let currentRecommendation = viewModel.currentRecommendation,
        let url = URL(string: currentRecommendation.imageData.descriptionURL) else {
            return
        }
        
        delegate?.imageRecommendationsUserDidTapImageLink(commonsURL: url)
    }
    
    func didTapYesButton() {
        if let startTime = viewModel.startTime {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(startTime)
            if timeInterval <= 5 {
                delegate?.imageRecommendationsDidTriggerTimeWarning()
                
                if let currentRecommendation = viewModel.currentRecommendation {
                    loggingDelegate?.logDialogWarningMessageDidDisplay(fileName: currentRecommendation.imageData.filename, recommendationSource: currentRecommendation.imageData.source)
                }
                
                return
            }

        }

        if let imageData = viewModel.currentRecommendation?.imageData, let title = viewModel.currentRecommendation?.title {
            self.dismiss(animated: true) {
                self.delegate?.imageRecommendationsUserDidTapInsertImage(viewModel: self.viewModel, title: title, with: imageData)
                self.loggingDelegate?.logBottomSheetDidTapYes()
            }
        }
    }

    func didTapNoButton() {
        loggingDelegate?.logBottomSheetDidTapNo()
        
		let surveyView = WMFSurveyView(
            viewModel: WMFSurveyViewModel(localizedStrings: viewModel.localizedStrings.surveyLocalizedStrings, options: viewModel.surveyOptions, selectionType: .multi),
			cancelAction: { [weak self] in
                self?.loggingDelegate?.logRejectSurveyDidTapCancel()
                
				self?.dismiss(animated: true)
			},
            submitAction: { [weak self] options, otherText  in
                
                guard let self,
                let currentRecommendation = self.viewModel.currentRecommendation else {
                    return
                }
                
                // Logging
                self.loggingDelegate?.logRejectSurveyDidTapSubmit(rejectionReasons: options, otherReason: otherText, fileName: currentRecommendation.imageData.filename, recommendationSource: currentRecommendation.imageData.source)
                
                // Send feedback API call
                self.viewModel.sendFeedback(editRevId: nil, accepted: false, reasons: options, caption: nil, completion: { [weak self] result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        self?.delegate?.imageRecommendationsDidTriggerError(error)
                    }
                    
                })
                // Dismisses Survey View
                self.dismiss(animated: true, completion: { [weak self] in
                    // Dismisses Bottom Sheet
                    self?.dismiss(animated: true, completion: { [weak self] in
                        self?.viewModel.next {
                            
                        }
                    })
                })
		})

		let hostedView = WMFComponentHostingController(rootView: surveyView)
		present(hostedView, animated: true)
        
        loggingDelegate?.logRejectSurveyDidAppear()
    }

    func didTapSkipButton() {
        loggingDelegate?.logBottomSheetDidTapNotSure()
        
        self.dismiss(animated: true) {
            self.viewModel.next {

            }
        }
    }
}

extension WMFImageRecommendationsBottomSheetViewController: WMFTooltipPresenting {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        
        // Tooltips are only allowed to dismiss via Next buttons
        if presentationController.presentedViewController is WMFTooltipViewController {
            return false
        }
        
        return true
    }
}
