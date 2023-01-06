import Foundation
import UIKit
import SwiftUI
import Combine
import WMF

class TalkPageArchivesViewController: UIViewController, Themeable, ShiftingTopViewsContaining {

    private var observableTheme: ObservableTheme
    var shiftingTopViewsStack: ShiftingTopViewsStack?

    init(theme: Theme) {
        self.observableTheme = ObservableTheme(theme: theme)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = WMFLocalizedString("talk-pages-archives-view-title", value: "Archives", comment: "Title of talk page archive list view.")

        let archivesView = TalkPageArchivesView()
        
        setup(swiftuiView: archivesView, observableTheme: observableTheme)

        apply(theme: observableTheme.theme)
    }

    func apply(theme: Theme) {
        observableTheme.theme = theme
        view.backgroundColor = theme.colors.paperBackground
        shiftingTopViewsStack?.apply(theme: theme)
    }
}
