import Foundation

@objc public protocol WMFDonateLoggingDelegate: AnyObject {
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

public final class WMFDonateViewController: WMFCanvasViewController {
    
    // MARK: - Properties

    fileprivate let hostingViewController: WMFDonateHostingViewController
    private let viewModel: WMFDonateViewModel
    private weak var loggingDelegate: WMFDonateLoggingDelegate?
    
    // MARK: - Lifecycle
    
    public init(viewModel: WMFDonateViewModel, delegate: WMFDonateDelegate?, loggingDelegate: WMFDonateLoggingDelegate?) {
        self.viewModel = viewModel
        self.hostingViewController = WMFDonateHostingViewController(viewModel: viewModel, delegate: delegate, loggingDelegate: loggingDelegate)
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

fileprivate final class WMFDonateHostingViewController: WMFComponentHostingController<WMFDonateView> {

    init(viewModel: WMFDonateViewModel, delegate: WMFDonateDelegate?, loggingDelegate: WMFDonateLoggingDelegate?) {
        super.init(rootView: WMFDonateView(viewModel: viewModel, delegate: delegate))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
