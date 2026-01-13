import SwiftUI
import WMFData
import Charts
import Foundation

struct CombinedImpactView: View {
    let allTimeImpactViewModel: AllTimeImpactViewModel?
    let recentActivityViewModel: RecentActivityViewModel?
    let articleViewsViewModel: ArticleViewsViewModel?
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let allTimeImpactViewModel {
                AllTimeImpactView(viewModel: allTimeImpactViewModel)
                
                Divider()
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color(uiColor: theme.baseBackground))
                            .frame(height: 1)
                    )
                    .padding(0)
            }
            
            if let recentActivityViewModel {
                RecentActivityView(viewModel: recentActivityViewModel)
                
                Divider()
                    .frame(height: 1)
                    .overlay(
                        Rectangle()
                            .fill(Color(uiColor: theme.baseBackground))
                            .frame(height: 1)
                    )
                    .padding(0)
            }
        }
        .padding(16)
        .background(Color(theme.paperBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(theme.baseBackground), lineWidth: 0.5)
        )
    }
}

private struct AllTimeImpactView: View {
    let viewModel: AllTimeImpactViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("All time impact") // TODO: Localize
                    .foregroundStyle(Color(theme.text))
                    .font(Font(WMFFont.for(.boldCaption1)))
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                Spacer()
            }
            .padding(.bottom, 16)
            
            // TODO: TEMP UI
            if let totalEdits = viewModel.totalEdits {
                Text("Total edits: \(totalEdits)")
            } else {
                Text("Total edits: 0")
            }
            if let thanks = viewModel.thanksCount {
                Text("Thanks count: \(thanks)")
            } else {
                Text("Thanks count: 0")
            }
            if let streak = viewModel.bestStreak {
                Text("Best streak: \(streak)")
            } else {
                Text("Best streak: -")
            }
            if let lastEdited = viewModel.lastEdited {
                Text("Last edited: \(lastEdited)")
            } else {
                Text("Last edited: -")
            }
        }
    }
}

struct YourImpactHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let title: String
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var body: some View {
            Text(title)
                .font(Font(WMFFont.for(.boldHeadline)))
                .foregroundColor(Color(uiColor: theme.text))
                .textCase(.none)
                .padding(.horizontal, 16)
                .accessibilityAddTraits(.isHeader)
    }
}
