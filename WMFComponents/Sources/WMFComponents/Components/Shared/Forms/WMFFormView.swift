import SwiftUI

public struct WMFFormView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    @ObservedObject public var viewModel: WMFFormViewModel

    public init(viewModel: WMFFormViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                if let selectSection = section as? WMFFormSectionSelectViewModel {
                    WMFFormSectionSelectView(viewModel: selectSection)
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
