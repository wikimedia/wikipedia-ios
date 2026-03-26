import Foundation
import WMFTestKitchen

protocol LogoutCoordinatorDelegate: AnyObject {
    func didTapLogout(authInstrument: InstrumentImpl)
}

