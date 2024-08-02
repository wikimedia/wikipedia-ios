import Foundation
import SwiftUI
import Combine

public final class WMFFormSectionSelectViewModel: WMFFormSectionViewModel {
    public enum SelectType {
        case single
        case multi
		case multiWithAccessoryRows
    }
    
    let items: [WMFFormItemSelectViewModel]
    let selectType: SelectType
    private var subscribers: Set<AnyCancellable> = []

    public init(header: String? = nil, footer: String? = nil, items: [WMFFormItemSelectViewModel], selectType: SelectType) {
        self.items = items
        self.selectType = selectType
        
        super.init(header: header, footer: footer)

        for item in items {
            item.$isSelected.sink { [weak self] isSelected in

                guard let self else {
                    return
                }

                if isSelected {
                    self.didSelectSelectItem(item: item)
                }
            }.store(in: &subscribers)
        }
    }

    func didSelectSelectItem(item: WMFFormItemSelectViewModel) {

        guard selectType == .single else {
            return
        }

        for loopItem in items {
            if loopItem != item {
                loopItem.isSelected = false
            }
        }
    }
}
