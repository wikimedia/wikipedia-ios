import Foundation

final class AltTextExperimentModalSheetViewModel {
    var altTextViewModel: AltTextExperimentViewModel
    var localizedStrings: BottomSheetStrings

    struct BottomSheetStrings {
        var title: String
        var buttonTitle: String
        var textViewPlaceholder: String
    }

    init(altTextViewModel: AltTextExperimentViewModel, localizedStrings: BottomSheetStrings) {
        self.altTextViewModel = altTextViewModel
        self.localizedStrings = localizedStrings
    }

}
