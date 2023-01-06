import Foundation
import UIKit
import SwiftUI
import Combine
import WMF

class TalkPageArchivesViewController: UIViewController, Themeable, ShiftingTopViewsContaining {

    private var observableTheme: ObservableTheme
    var shiftingTopViewsStack: ShiftingTopViewsStack?
    
    lazy var barView: ShiftingNavigationBarView = {
        let items = navigationController?.viewControllers.map({ $0.navigationItem }) ?? []
        return ShiftingNavigationBarView(shiftOrder: 1, navigationItems: items, popDelegate: self)
    }()
    
    lazy var demoHeaderView: DemoShiftingThreeLineHeaderView = {
        return DemoShiftingThreeLineHeaderView(shiftOrder: 0, theme: observableTheme.theme)
    }()

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
        
        setup(shiftingTopViews: [barView, demoHeaderView], swiftuiView: archivesView, observableTheme: observableTheme)

        apply(theme: observableTheme.theme)
    }

    func apply(theme: Theme) {
        observableTheme.theme = theme
        view.backgroundColor = theme.colors.paperBackground
        shiftingTopViewsStack?.apply(theme: theme)
    }
}
