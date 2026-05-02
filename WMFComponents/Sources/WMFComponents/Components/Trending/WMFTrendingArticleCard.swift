import SwiftUI
import WMFData

struct WMFTrendingArticleCard: View {

    let row: WMFTrendingViewModel.ArticleRowViewModel
    let rank: Int
    let country: String
    let projectPageViews: Int?
    let onTap: () -> Void

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var formattedPageViews: String? {
        guard let views = projectPageViews else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        if views >= 1_000_000 {
            formatter.positiveSuffix = "M"
            return formatter.string(from: NSNumber(value: Double(views) / 1_000_000))
        } else if views >= 1_000 {
            formatter.positiveSuffix = "K"
            return formatter.string(from: NSNumber(value: Double(views) / 1_000))
        }
        return formatter.string(from: NSNumber(value: views))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                imageSection
                textSection
            }
            .background(Color(uiColor: theme.midBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(uiColor: theme.border), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Image section with gradient overlay and title

    @ViewBuilder
    private var imageSection: some View {
        ZStack(alignment: .bottom) {
            imageView
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

            // Gradient so title text is always legible over any image
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(Font(WMFFont.for(.semiboldTitle3)))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)

                if let description = row.description, !description.isEmpty {
                    Text(description)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let image = row.uiImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color(uiColor: theme.midBackground))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundColor(Color(uiColor: theme.secondaryText).opacity(0.4))
                )
        }
    }

    // MARK: - Bottom row: trending badge + rank on left, stats on right

    private var textSection: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                trendingBadge
                rankLabel
            }

            Spacer()

            statsColumn
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var trendingBadge: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("Trending in \(country)")
                .font(Font(WMFFont.for(.caption1)))
                .foregroundColor(Color(uiColor: theme.link))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(uiColor: theme.link).opacity(0.12))
        .clipShape(Capsule())
    }

    private var rankLabel: some View {
        Text("#\(rank + 1) in \(country) this week")
            .font(Font(WMFFont.for(.caption2)))
            .foregroundColor(Color(uiColor: theme.secondaryText))
    }

    @ViewBuilder
    private var statsColumn: some View {
        if let formatted = formattedPageViews {
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatted)
                    .font(Font(WMFFont.for(.semiboldHeadline)))
                    .foregroundColor(Color(uiColor: theme.text))
                Text("page views")
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
                Text("yesterday")
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }
        }
    }
}
