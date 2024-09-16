import SwiftUI
import CoreData
import WMFData
import SwiftData

// Begin WMFData abstraction

public protocol PageViewsViewDelegate: AnyObject {
    func didTapPage(page: WMFPage)
}

 public struct PageViewsView: View {
    
    @State var pageViewCounts: [WMFPageViewCount]
     weak var delegate: PageViewsViewDelegate?
    
     public init(pageViewCounts: [WMFPageViewCount] = [], delegate: PageViewsViewDelegate?) {
        self.pageViewCounts = pageViewCounts
         self.delegate = delegate
    }
    
    public var body: some View {
        List(pageViewCounts) { pageViewCount in
            HStack {
                Button(pageViewCount.page.title) {
                    delegate?.didTapPage(page: pageViewCount.page)
                }
                Text(String(pageViewCount.count))
            }
//                .swipeActions {
//                            Button("Delete", systemImage: "trash", role: .destructive) {
//                                Task {
//                                    do {
//                                        try await WMFWikiWrappedDataController().deletePageView(pageView: pageViewCount.page)
//                                    } catch {
//                                        print(error)
//                                    }
//                                }
//                            }
//                        }
        }
        .onAppear {
            Task {
                do {
                    let pageViewsCounts = try WMFWikiWrappedDataController().fetchPageViewCounts()
                    self.pageViewCounts = pageViewsCounts
                } catch {
                    print(error)
                }
            }
        }
    }
 }

// End: WMFData abstraction

// Begin: CoreData

// public struct PageViewsViewCoreData: View {
//    
//    let moc: NSManagedObjectContext
//    
//    public init(moc: NSManagedObjectContext) {
//        self.moc = moc
//    }
//
//    public var body: some View {
//        PageViewsViewList()
//            .environment(\.managedObjectContext, moc)
//    }
// }
//
// struct PageViewsViewList: View {
//    
//    @FetchRequest(sortDescriptors: []) var pageViews: FetchedResults<CDPageView>
//    @Environment(\.managedObjectContext) var moc
//    
//    var body: some View {
//        List(pageViews) { pageView in
//            Text(pageView.page?.title ?? "")
//                .swipeActions {
//                            Button("Delete", systemImage: "trash", role: .destructive) {
//                                moc.delete(pageView)
//                                try? moc.save()
//                            }
//                        }
//        }
//    }
// }

// End: CoreData

// Begin: SwiftData

// @available(iOS 17, *)
// @Model
// public final class WMFPage {
//   var namespace: Int
//   var projectID: String
//   public var title: String
//   var pageViews: [WMFPageView]
//   
//   init(namespace: Int, projectID: String, title: String) {
//       self.namespace = namespace
//       self.projectID = projectID
//       self.title = title
//       self.pageViews = []
//   }
// }
//
// @available(iOS 17, *)
// @Model
// public final class WMFPageView {
//   public var timestamp: Date
//   public var page: WMFPage
//
//   init(timestamp: Date, page: WMFPage) {
//       self.timestamp = timestamp
//       self.page = page
//   }
// }
//
// @available(iOS 17, *)
// public struct PageViewsViewSwiftData: View {
//    
//    @State var pageViews: [WMFPageView]
//    private let modelContainer: ModelContainer?
//    
//    public init(pageViews: [WMFPageView]) {
//        self.pageViews = pageViews
//        
//        guard let appContainerURL = WMFDataEnvironment.current.appContainerURL else {
//            self.modelContainer = nil
//            return
//        }
//        
//        let url = appContainerURL.appendingPathComponent("WMFData.sqlite")
//        
//        guard let modelContainer = try? ModelContainer(for: WMFPageView.self, configurations: ModelConfiguration(url: url)) else {
//            self.modelContainer = nil
//            return
//        }
//
//        self.modelContainer = modelContainer
//    }
//    
//    
//    public var body: some View {
//        List(pageViews) { pageView in
//            Text(pageView.page.title)
//                .swipeActions {
//                            Button("Delete", systemImage: "trash", role: .destructive) {
//                                modelContainer?.mainContext.delete(pageView)
//                            }
//                        }
//        }
//            .onAppear {
//                Task { @MainActor in
//                    
//                    let fetchDescriptor = FetchDescriptor(sortBy: [SortDescriptor(\WMFPageView.timestamp, order: .forward)])
//                    
//                    if let pageViews = try? modelContainer?.mainContext.fetch(fetchDescriptor) {
//                        self.pageViews = pageViews
//                    }
//                }
//            }
//    }
// }

// End: SwiftData
