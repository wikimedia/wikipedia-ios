import SwiftUI
import UIKit
import WMFData
import Combine
import TipKit

public protocol WMFImageRecommendationsDelegate: AnyObject {
    func imageRecommendationsUserDidTapViewArticle(project: WMFProject, title: String)
    func imageRecommendationsUserDidTapImageLink(commonsURL: URL)
    func imageRecommendationsUserDidTapImage(project: WMFProject, data: WMFImageRecommendationsViewModel.WMFImageRecommendationData, presentingVC: UIViewController)
    func imageRecommendationsUserDidTapInsertImage(viewModel: WMFImageRecommendationsViewModel, title: String, with imageData: WMFImageRecommendationsViewModel.WMFImageRecommendationData)
    func imageRecommendationsUserDidTapLearnMore(url: URL?)
    func imageRecommendationsUserDidTapReportIssue()
    func imageRecommendationsDidTriggerError(_ error: Error)
    func imageRecommendationsDidTriggerTimeWarning()
}

public protocol WMFImageRecommendationsLoggingDelegate: AnyObject {
    func logOnboardingDidTapPrimaryButton()
    func logOnboardingDidTapSecondaryButton()
    func logTooltipsDidTapFirstNext()
    func logTooltipsDidTapSecondNext()
    func logTooltipsDidTapThirdOK()
    func logBottomSheetDidAppear()
    func logBottomSheetDidTapYes()
    func logBottomSheetDidTapNo()
    func logBottomSheetDidTapNotSure()
    func logOverflowDidTapLearnMore()
    func logOverflowDidTapTutorial()
    func logOverflowDidTapProblem()
    func logBottomSheetDidTapFileName()
    func logRejectSurveyDidAppear()
    func logRejectSurveyDidTapCancel()
    func logRejectSurveyDidTapSubmit(rejectionReasons: [String], otherReason: String?, fileName: String, recommendationSource: String)
    func logEmptyStateDidAppear()
    func logEmptyStateDidTapBack()
    func logDialogWarningMessageDidDisplay(fileName: String, recommendationSource: String)
}

fileprivate final class WMFImageRecommendationsHostingViewController: WMFComponentHostingController<WMFImageRecommendationsView> {

    init(viewModel: WMFImageRecommendationsViewModel, delegate: WMFImageRecommendationsDelegate, loggingDelegate: WMFImageRecommendationsLoggingDelegate, tooltipGeometryValues: WMFTooltipGeometryValues) {
        let rootView = WMFImageRecommendationsView(viewModel: viewModel, tooltipGeometryValues: tooltipGeometryValues, errorTryAgainAction: {
            
            viewModel.tryAgainAfterLoadingError()
            
        }, viewArticleAction: { [weak delegate] title in
            
            delegate?.imageRecommendationsUserDidTapViewArticle(project: viewModel.project, title: title)
            
        }, emptyViewAppearanceAction: { [weak loggingDelegate] in
            
            loggingDelegate?.logEmptyStateDidAppear()
            
        })
        super.init(rootView: rootView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class WMFImageRecommendationsViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    // MARK: - Properties

    fileprivate let hostingViewController: WMFImageRecommendationsHostingViewController
    private weak var delegate: WMFImageRecommendationsDelegate?
    private weak var loggingDelegate: WMFImageRecommendationsLoggingDelegate?
    @ObservedObject private var viewModel: WMFImageRecommendationsViewModel
    private var imageRecommendationBottomSheetController: WMFImageRecommendationsBottomSheetViewController
    private var cancellables = Set<AnyCancellable>()

    private var overflowMenu: UIMenu {

        let learnMore = UIAction(title: viewModel.localizedStrings.learnMoreButtonTitle, image: UIImage(systemName: "info.circle"), handler: { [weak self] _ in
            self?.loggingDelegate?.logOverflowDidTapLearnMore()
            self?.goToFAQ()
        })
        let tutorial = UIAction(title: viewModel.localizedStrings.tutorialButtonTitle, image: UIImage(systemName: "lightbulb.min"), handler: { [weak self] _ in
            self?.loggingDelegate?.logOverflowDidTapTutorial()
            self?.showTutorial()
        })

        let reportIssues = UIAction(title: viewModel.localizedStrings.problemWithFeatureButtonTitle, image: UIImage(systemName: "flag"), handler: { [weak self] _ in
            self?.loggingDelegate?.logOverflowDidTapProblem()
            self?.reportIssue()
        })

        let menuItems: [UIMenuElement] = [learnMore, tutorial, reportIssues]

        return UIMenu(title: String(), children: menuItems)
    }

    // MARK: Lifecycle

    private let dataController = WMFImageRecommendationsDataController()
    private let tooltipGeometryValues = WMFTooltipGeometryValues()
    
    fileprivate var autoTip1 = Tip1()
    fileprivate var autoTip2 = Tip2()
    fileprivate var autoTip3 = Tip3()
    fileprivate var autoTip1ObservationTask: Task<Void, Never>?
    fileprivate var autoTip2ObservationTask: Task<Void, Never>?
    fileprivate var autoTip3ObservationTask: Task<Void, Never>?

    public init(viewModel: WMFImageRecommendationsViewModel, delegate: WMFImageRecommendationsDelegate, loggingDelegate: WMFImageRecommendationsLoggingDelegate) {
        self.hostingViewController = WMFImageRecommendationsHostingViewController(viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate, tooltipGeometryValues: tooltipGeometryValues)
        self.delegate = delegate
        self.loggingDelegate = loggingDelegate
        self.viewModel = viewModel
        self.imageRecommendationBottomSheetController = WMFImageRecommendationsBottomSheetViewController(viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
        super.init()
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupOverflowMenu()
        addComponent(hostingViewController, pinToEdges: true, respectSafeArea: true)
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bindViewModel()

        if !dataController.hasPresentedOnboardingModal {
            presentOnboardingIfNecessary()
        } else {
            viewModel.fetchImageRecommendationsIfNeeded {

            }
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageRecommendationBottomSheetController.dismiss(animated: true)
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
        autoTip1ObservationTask?.cancel()
        autoTip1ObservationTask = nil
        autoTip2ObservationTask?.cancel()
        autoTip2ObservationTask = nil
        autoTip3ObservationTask?.cancel()
        autoTip3ObservationTask = nil
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if parent == nil {
            tappedBack()
        }
    }
    
    private func configureNavigationBar() {

        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    public func presentImageRecommendationBottomSheet() {
        imageRecommendationBottomSheetController.isModalInPresentation = true
        if let bottomSheet = imageRecommendationBottomSheetController.sheetPresentationController {
            bottomSheet.detents = [.medium(), .large()]
            bottomSheet.largestUndimmedDetentIdentifier = .medium
            bottomSheet.prefersGrabberVisible = true
            bottomSheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }

        navigationController?.present(imageRecommendationBottomSheetController, animated: true, completion: {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in

                guard let self else {
                    return
                }

                self.presentTooltipsIfNecessary(onBottomSheetViewController: self.imageRecommendationBottomSheetController)
            }

        })
    }

    // MARK: Private methods

    @objc private func tappedBack() {

        if viewModel.imageRecommendations.isEmpty && viewModel.loadingError == nil {
            loggingDelegate?.logEmptyStateDidTapBack()
        }
    }

    private func setupOverflowMenu() {
        let rightBarButtonItem = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        rightBarButtonItem.tintColor = theme.link
    }

    private func presentTooltipsIfNecessary(onBottomSheetViewController bottomSheetViewController: WMFImageRecommendationsBottomSheetViewController, force: Bool = false) {

        // Do not present tooltips in empty or loading state
        if viewModel.loading || viewModel.imageRecommendations.isEmpty || viewModel.loadingError != nil {
            return
        }
        
        guard let bottomSheetView = bottomSheetViewController.bottomSheetView else {
            return
        }
        
        let tooltip2DismissAction: () -> Void = { [weak self] in
            self?.listenToTooltip3(toolbarView: bottomSheetView.toolbar)
        }
        
        let tooltip1DismissAction: () -> Void = { [weak self] in
            self?.listenToTooltip2(bottomSheetView: bottomSheetView, dismissAction: tooltip2DismissAction)
        }
        
        if #available(iOS 26.0, *) {
            if force == true {
                Task {
                    Tip2.enableTip = false
                    Tip3.enableTip = false
                    await autoTip2.resetEligibility()
                    await autoTip3.resetEligibility()
                    
                    await autoTip1.resetEligibility()
                    
                    listenToTooltip1(dismissAction: tooltip1DismissAction)
                    return
                }
                
            }
        }

        listenToTooltip1(dismissAction: tooltip1DismissAction)
        
        
//        if !force && dataController.hasPresentedOnboardingTooltips {
//            return
//        }
//
//        guard let hostingView = hostingViewController.view,
//              let bottomSheetView = bottomSheetViewController.bottomSheetView else {
//            return
//        }
//
//        let divGlobalFrame = tooltipGeometryValues.articleSummaryDivGlobalFrame
//        let articleSummaryDivSourceRect: CGRect
//
//        // Article Summary div frame comes through as global / window coordinates. We need to offset them against the hosting view frame to send in an accurate sourceRect.
//        let hostingViewGlobalOrigin = hostingView.superview?.convert(hostingView.frame.origin, to: nil)
//        if let hostingViewGlobalOrigin {
//            let xOffset = CGFloat(25)
//            articleSummaryDivSourceRect = CGRect(x: (divGlobalFrame.minX - hostingViewGlobalOrigin.x) + xOffset, y: divGlobalFrame.maxY - hostingViewGlobalOrigin.y, width: 0, height: 0)
//        } else {
//            articleSummaryDivSourceRect = divGlobalFrame
//        }
//
//        let viewModel1 = WMFTooltipViewModel(localizedStrings: viewModel.localizedStrings.firstTooltipStrings, buttonNeedsDisclosure: true, sourceView: hostingView, sourceRect: articleSummaryDivSourceRect, permittedArrowDirections: .up) { [weak self] in
//            self?.loggingDelegate?.logTooltipsDidTapFirstNext()
//        }
//
//        let viewModel2 = WMFTooltipViewModel(localizedStrings: viewModel.localizedStrings.secondTooltipStrings, buttonNeedsDisclosure: true, sourceView: bottomSheetView, sourceRect: bottomSheetView.bounds) { [weak self] in
//            self?.loggingDelegate?.logTooltipsDidTapSecondNext()
//        }
//
//        let viewModel3 = WMFTooltipViewModel(localizedStrings: viewModel.localizedStrings.thirdTooltipStrings, buttonNeedsDisclosure: false, sourceView: bottomSheetView, sourceRect: bottomSheetView.toolbar.frame) { [weak self] in
//            self?.loggingDelegate?.logTooltipsDidTapThirdOK()
//        }
//
//        bottomSheetViewController.displayTooltips(tooltipViewModels: [viewModel1, viewModel2, viewModel3])
//
//        if !force {
//            dataController.hasPresentedOnboardingTooltips = true
//        }
    }
    
    private lazy var divTargetView: UIView = {
        
        let divGlobalFrame = tooltipGeometryValues.articleSummaryDivGlobalFrame
        
        let littleView = UIView()
        littleView.translatesAutoresizingMaskIntoConstraints = false
        littleView.backgroundColor = .green
        view.addSubview(littleView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: littleView.leadingAnchor, constant: -(divGlobalFrame.minX + CGFloat(25))),
            view.topAnchor.constraint(equalTo: littleView.topAnchor, constant: -divGlobalFrame.minY),
            littleView.widthAnchor.constraint(equalToConstant: 1),
            littleView.heightAnchor.constraint(equalToConstant: 1)
        ])
        return littleView
    }()
    
    private func listenToTooltip1(dismissAction: @escaping () -> Void) {
        
        autoTip1ObservationTask =  Task { @MainActor in
            for await status in autoTip1.statusUpdates {
                if status == .available {
                    let popoverController = TipUIPopoverViewController(autoTip1, sourceItem: divTargetView)
                    popoverController.popoverPresentationController?.permittedArrowDirections = .up
                    presentedViewController?.present(popoverController, animated: true) {
                        popoverController.presentationController?.delegate = self
                    }
                } else if case .invalidated = status {
                    print("here")
                    if self.presentedViewController?.presentedViewController is TipUIPopoverViewController {
                        presentedViewController?.presentedViewController?.dismiss(animated: true) {
                                dismissAction()
                        }
                    } else { // already dismissed by tapping background, we still need to call action to present the next tip.
                        dismissAction()
                    }
                    break
                }
            }
        }
    }
    
    private func listenToTooltip2(bottomSheetView: UIView, dismissAction: @escaping () -> Void) {
        autoTip2ObservationTask = Task { @MainActor in
            Tip2.enableTip = true
            for await status in self.autoTip2.statusUpdates {
                if status == .available {
                    let popoverController = TipUIPopoverViewController(self.autoTip2, sourceItem: bottomSheetView)
                    self.presentedViewController?.present(popoverController, animated: true) {
                        popoverController.presentationController?.delegate = self
                    }
                } else if case .invalidated = status {
                    print("here")
                    if self.presentedViewController?.presentedViewController is TipUIPopoverViewController {
                        presentedViewController?.presentedViewController?.dismiss(animated: true) {
                                dismissAction()
                        }
                    } else { // already dismissed by tapping background, we still need to call action to present the next tip.
                        dismissAction()
                    }
                    break
                }
            }
        }
    }
    
    private func listenToTooltip3(toolbarView: UIView) {
        autoTip3ObservationTask = Task { @MainActor in
            Tip3.enableTip = true
            for await status in self.autoTip3.statusUpdates {
                if status == .available {
                    let popoverController = TipUIPopoverViewController(self.autoTip3, sourceItem: toolbarView)
                    self.presentedViewController?.present(popoverController, animated: true) {
                        popoverController.presentationController?.delegate = self
                    }
                } else if case .invalidated = status {
                    print("here")
                    if self.presentedViewController?.presentedViewController is TipUIPopoverViewController {
                        presentedViewController?.presentedViewController?.dismiss(animated: true) {
                            self.autoTip1ObservationTask?.cancel()
                            self.autoTip1ObservationTask = nil
                            self.autoTip2ObservationTask?.cancel()
                            self.autoTip2ObservationTask = nil
                            self.autoTip3ObservationTask?.cancel()
                            self.autoTip3ObservationTask = nil
                        }
                    } else {
                        self.autoTip1ObservationTask?.cancel()
                        self.autoTip1ObservationTask = nil
                        self.autoTip2ObservationTask?.cancel()
                        self.autoTip2ObservationTask = nil
                        self.autoTip3ObservationTask?.cancel()
                        self.autoTip3ObservationTask = nil
                    }
                    break
                }
            }
        }
    }

    private func presentOnboardingIfNecessary() {
        guard !dataController.hasPresentedOnboardingModal else {
            return
        }

        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .photoOnRectangleAngled), title: viewModel.localizedStrings.onboardingStrings.firstItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.firstItemBody, fillIconBackground: true)

        let secondItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFSFSymbolIcon.for(symbol: .plusForwardSlashMinus), title: viewModel.localizedStrings.onboardingStrings.secondItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.secondItemBody, fillIconBackground: true)

        let thirdItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(icon: WMFIcon.commons, title: viewModel.localizedStrings.onboardingStrings.thirdItemTitle, subtitle: viewModel.localizedStrings.onboardingStrings.thirdItemBody, fillIconBackground: true)

        let onboardingViewModel = WMFOnboardingViewModel(title: viewModel.localizedStrings.onboardingStrings.title, cells: [firstItem, secondItem, thirdItem], primaryButtonTitle: viewModel.localizedStrings.onboardingStrings.continueButton, secondaryButtonTitle: viewModel.localizedStrings.onboardingStrings.learnMoreButton)

        let onboardingController = WMFOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.delegate = self
        present(onboardingController, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        })

        dataController.hasPresentedOnboardingModal = true
    }

    private func bindViewModel() {
        viewModel.$debouncedLoading
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                
                guard let self else {
                    return
                }
                
                
                if !isLoading {
                    if self.viewModel.currentRecommendation?.articleSummary != nil {
                        self.presentImageRecommendationBottomSheet()
                    }
                }
            }
            .store(in: &cancellables)
        
        viewModel.$loadingError
            .receive(on: RunLoop.main)
            .sink { [weak self] loadingError in
                if let loadingError {
                    self?.delegate?.imageRecommendationsDidTriggerError(loadingError)
                }
            }
            .store(in: &cancellables)
    }

    private func showTutorial() {
        presentTooltipsIfNecessary(onBottomSheetViewController: imageRecommendationBottomSheetController, force: true)
    }


    private func goToFAQ() {
        delegate?.imageRecommendationsUserDidTapLearnMore(url: viewModel.learnMoreURL)
    }

    private func reportIssue() {
        delegate?.imageRecommendationsUserDidTapReportIssue()
    }
}

extension WMFImageRecommendationsViewController: WMFOnboardingViewDelegate {

    public func onboardingViewDidClickPrimaryButton() {
        presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.viewModel.fetchImageRecommendationsIfNeeded {

            }
        })

        loggingDelegate?.logOnboardingDidTapPrimaryButton()
    }

    public func onboardingViewDidClickSecondaryButton() {
        guard let url = viewModel.learnMoreURL else {
            return
        }

        UIApplication.shared.open(url)

        loggingDelegate?.logOnboardingDidTapSecondaryButton()
    }

    public func onboardingViewWillSwipeToDismiss() {
        viewModel.fetchImageRecommendationsIfNeeded {

        }
    }
}

private struct Tip1: Tip {
    
    var title: Text {
        Text("Tip 1")
    }
    
    var message: Text? {
        Text("Tip 1 Message")
    }
    
    var image: SwiftUI.Image? {
        return nil
    }
}

private struct Tip2: Tip {
    
    @Parameter static var enableTip: Bool = false
    
    var title: Text {
        Text("Tip 2")
    }
    
    var message: Text? {
        Text("Tip 2 Message")
    }
    
    var image: SwiftUI.Image? {
        return nil
    }
    
    var rules: [Rule] {
            [
                #Rule(Self.$enableTip) { $0 == true }
            ]
        }
}

private struct Tip3: Tip {
    
    @Parameter static var enableTip: Bool = false
    
    var title: Text {
        Text("Tip 3")
    }
    
    var message: Text? {
        Text("Tip 3 Message")
    }
    
    var image: SwiftUI.Image? {
        return nil
    }
    
    var rules: [Rule] {
            [
                #Rule(Self.$enableTip) { $0 == true }
            ]
        }
}

extension WMFImageRecommendationsViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is TipUIPopoverViewController {
            if autoTip3ObservationTask != nil {
                autoTip3.invalidate(reason: .tipClosed)
            } else if autoTip2ObservationTask != nil {
                autoTip2.invalidate(reason: .tipClosed)
            } else {
                autoTip1.invalidate(reason: .tipClosed)
            }
            
        }
    }
}
