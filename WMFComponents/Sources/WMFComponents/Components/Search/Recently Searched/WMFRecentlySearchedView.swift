import SwiftUI

public struct WMFRecentlySearchedView: View {
    let items: [String] = ["Recently Searched 1", "Recently Searched 2", "Recently Searched 3"]
    
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
