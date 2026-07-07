import SwiftUI

// MARK: - Interactive Slide

/// Slide showing a question with 3-4 selectable options. No backend validation required.
public struct WMFYiR2026InteractiveSlideView: View {

    let data: WMFYiR2026InteractiveSlideData
    let selectedOptionIndex: Int?
    let onSelect: (Int) -> Void

    @State private var contentVisible = false
    @State private var pressedIndex: Int? = nil

    public var body: some View {
        ZStack {
            // MARK: Background
            LinearGradient(
                colors: [
                    data.accentColor,
                    data.accentColor.opacity(0.5),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // MARK: Lottie (decorative, top half)
            if let lottieName = data.lottieName {
                VStack {
                    WMFLottieView(animationName: lottieName, loopMode: .loop)
                        .frame(height: 260)
                        .allowsHitTesting(false)
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }

            // MARK: Content
            VStack(spacing: 0) {
                Spacer()

                // Question card
                VStack(spacing: 24) {
                    Text(data.question)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 24)

                    // Options grid (2 columns when 4 options, single column for 3)
                    let columns = data.options.count == 4
                        ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
                        : [GridItem(.flexible())]

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(data.options.enumerated()), id: \.element.id) { index, option in
                            optionButton(option: option, index: index)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 60)
            }
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 40)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentVisible)
        }
        .onAppear { contentVisible = true }
        .onDisappear { contentVisible = false }
    }

    // MARK: Option button

    @ViewBuilder
    private func optionButton(option: WMFYiR2026Option, index: Int) -> some View {
        let isSelected = selectedOptionIndex == index
        let isOtherSelected = selectedOptionIndex != nil && !isSelected

        Button {
            guard selectedOptionIndex == nil else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onSelect(index)
            }
        } label: {
            HStack(spacing: 10) {
                if let emoji = option.emoji {
                    Text(emoji)
                        .font(.system(size: 22))
                }
                Text(option.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isSelected ? data.accentColor : .white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(data.accentColor)
                        .font(.system(size: 18))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.25), lineWidth: 1)
            )
            .opacity(isOtherSelected ? 0.4 : 1.0)
            .scaleEffect(pressedIndex == index ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressedIndex = index }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.15)) { pressedIndex = nil }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: isOtherSelected)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WMFYiR2026InteractiveSlideView(
        data: .init(
            accentColor: Color(red: 0.85, green: 0.40, blue: 0.10),
            question: "What was your most-read topic this year?",
            options: [
                .init(label: "Science & Technology", emoji: "🔬"),
                .init(label: "History & Culture",    emoji: "🏛️"),
                .init(label: "Geography",             emoji: "🌍"),
                .init(label: "Sports & Games",        emoji: "⚽")
            ]
        ),
        selectedOptionIndex: nil,
        onSelect: { _ in }
    )
}
#endif
