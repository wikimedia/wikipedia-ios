import WMFData
import SwiftUI

public final class WMFTabsViewModel: ObservableObject {
    struct WMFTabViewModel: Equatable, Identifiable {
        let id = UUID()
        let tab: WMFData.Tab
        let topArticleTitle: String
        
        init(tab: WMFData.Tab, topArticleTitle: String) {
            self.tab = tab
            self.topArticleTitle = topArticleTitle
        }
    }
    
    @Published var tabViewModels: [WMFTabViewModel] = []
    let tappedAddTabAction: (() -> Void)?
    let tappedTabAction: ((WMFData.Tab) -> Void)?
    private(set) var tappedCloseTabAction: ((WMFData.Tab) -> Void)?
    
    public init(tappedAddTabAction: @escaping () -> Void, tappedTabAction: @escaping (WMFData.Tab, Bool) -> Void, tappedCloseTabAction: @escaping (WMFData.Tab, Bool) -> Void) {
        self.tappedAddTabAction = {
            let dataController = TabsDataController.shared
            dataController.currentTab = nil
            tappedAddTabAction()
        }
        
        self.tappedTabAction = { tab in
            
            let dataController = TabsDataController.shared
            let alreadyCurrentTab = tab == dataController.currentTab
            if !alreadyCurrentTab {
                dataController.currentTab = tab
            }
            
            tappedTabAction(tab, alreadyCurrentTab)
        }
        
        self.tappedCloseTabAction = { [weak self] tab in
            guard let self else { return }
            
            let dataController = TabsDataController.shared
            dataController.removeTab(tab: tab)
            
            var mutableTabViewModels = self.tabViewModels
            for (index, tabViewModel) in self.tabViewModels.enumerated() {
                if tabViewModel.tab == tab {
                    mutableTabViewModels.remove(at: index)
                }
            }
            
            self.tabViewModels = mutableTabViewModels
            let currentTabClosed = dataController.currentTab == nil
            tappedCloseTabAction(tab, currentTabClosed)
        }
    }
    
    func fetchTabs() {
        let dataController = TabsDataController.shared
        let dataTabs = dataController.tabs
        
        for dataTab in dataTabs {
            guard let topArticleTitle = dataTab.articles.last?.title else {
                continue
            }
            
            tabViewModels.append(WMFTabViewModel(tab: dataTab, topArticleTitle: topArticleTitle))
        }
    }
    
}
