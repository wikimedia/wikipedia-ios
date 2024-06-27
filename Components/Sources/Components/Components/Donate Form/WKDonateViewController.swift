import Foundation

@objc public protocol WKDonateLoggingDelegate: AnyObject {
    func logDonateFormDidAppear()
    func logDonateFormUserDidTriggerError(error: Error)
    func logDonateFormUserDidTapAmountPresetButton()
    func logDonateFormUserDidEnterAmountInTextfield()
    func logDonateFormUserDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: NSNumber?)
    func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, metricsID: String?)
    func logDonateFormUserDidTapProblemsDonatingLink()
    func logDonateFormUserDidTapOtherWaysToGiveLink()
    func logDonateFormUserDidTapFAQLink()
    func logDonateFormUserDidTapTaxInfoLink()
}

public final class WKDonateViewController: WKCanvasViewController {
    
    // MARK: - Properties

    fileprivate let hostingViewController: WKDonateHostingViewController
    private let viewModel: WKDonateViewModel
    private weak var loggingDelegate: WKDonateLoggingDelegate?
    
    // MARK: - Lifecycle
    
    public init(viewModel: WKDonateViewModel, delegate: WKDonateDelegate?, loggingDelegate: WKDonateLoggingDelegate?) {
        self.viewModel = viewModel
        self.hostingViewController = WKDonateHostingViewController(viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
        self.loggingDelegate = loggingDelegate
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = viewModel.localizedStrings.title
        addComponent(hostingViewController, pinToEdges: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loggingDelegate?.logDonateFormDidAppear()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

fileprivate final class WKDonateHostingViewController: WKComponentHostingController<WKDonateView> {

    init(viewModel: WKDonateViewModel, delegate: WKDonateDelegate?, loggingDelegate: WKDonateLoggingDelegate?) {
        super.init(rootView: WKDonateView(viewModel: viewModel, delegate: delegate))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
