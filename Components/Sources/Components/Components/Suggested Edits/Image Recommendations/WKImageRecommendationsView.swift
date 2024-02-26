//
//  SwiftUIView.swift
//  
//
//  Created by Toni Sevener on 2/26/24.
//

import SwiftUI

struct WKImageRecommendationsView: View {
    
    @ObservedObject var viewModel: WKImageRecommendationsViewModel
    @State private var loading: Bool = false
    
    var body: some View {
        Group {
            if let articleSummary = viewModel.currentRecommendation?.articleSummary {
                VStack {
                    Text(articleSummary.displayTitle)
                    Button(action: {
                        loading = true
                        viewModel.next {
                            loading = false
                        }
                    }, label: {
                        Text("Next")
                    })
                }
            } else {
                if !loading {
                    Text("Empty")
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            loading = true
            viewModel.fetchImageRecommendations {
                loading = false
            }
        }
    }
}
