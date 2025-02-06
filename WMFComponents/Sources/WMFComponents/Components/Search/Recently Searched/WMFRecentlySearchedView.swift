import SwiftUI

public struct WMFRecentlySearchedView: View {
    let items: [String] = ["Recently Searched 1", "Recently Searched 2", "Recently Searched 3",
                           "Recently Searched 4",
                           "Recently Searched 5",
                           "Recently Searched 6",
                           "Recently Searched 7",
                           "Recently Searched 8",
                           "Recently Searched 9",
                           "Recently Searched 10",
                           "Recently Searched 11",
                           "Recently Searched 12",
                           "Recently Searched 13",
                           "Recently Searched 14"]
    
    public init() {
        
    }
    public var body: some View {
        if items.isEmpty {
            Text("No recent searches yet")
        } else {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .swipeActions {
                            Button("Delete") {
                                print("Delete recent search term")
                            }
                        }
                }
            }
            .listStyle(.grouped)
        }
        
    }
}
