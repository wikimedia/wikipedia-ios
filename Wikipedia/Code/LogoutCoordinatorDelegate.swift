import Foundation
import WMFTestKitchen

@MainActor
protocol LogoutCoordinatorDelegate: AnyObject {
    func didTapLogout(authInstrument: InstrumentImpl)
}

