import AVFoundation
import Vision
import SwiftUI

public struct WMFWikiSnapView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {
        
    }
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
            }
            .navigationTitle("WikiSnap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

}
