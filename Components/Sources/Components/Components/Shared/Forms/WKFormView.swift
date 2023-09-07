import SwiftUI

public struct WKFormView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var theme: WKTheme {
        return appEnvironment.theme
    }

    public let viewModel: WKFormViewModel
    
    public init(viewModel: WKFormViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                if let selectSection = section as? WKFormSectionSelectViewModel {
                    WKFormSectionSelectView(viewModel: selectSection)
                        .listRowBackground(Color(theme.paperBackground).edgesIgnoringSafeArea([.all]))
                }
                
            }
        }
        .listStyle(GroupedListStyle())
        .listBackgroundColor(Color(theme.baseBackground))
        .onAppear(perform: {
            if #unavailable(iOS 16) {
                UITableView.appearance().backgroundColor = UIColor.clear
            }
        })
        .onDisappear(perform: {
            if #unavailable(iOS 16) {
                UITableView.appearance().backgroundColor = UIColor.systemGroupedBackground
            }
        })
    }
}
