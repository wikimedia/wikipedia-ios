import SwiftUI

// MARK: - Interactive Slide

struct WMFYiR2026InteractiveSlideView: View {

    let data: WMFYiR2026InteractiveSlideData
    let selectedOptionIndex: Int?
    let onSelect: (Int) -> Void

    @State private var contentVisible = false
    @State private var pressedIndex: Int? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // MARK: Background
                LinearGradient(
                    colors: [data.accentColor, data.accentColor.opacity(0.5), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // MARK: Lottie — top portion only
                if let lottieName = data.lottieName {
                    VStack {
                        WMFLottieView(animationName: lottieName, loopMode: .loop)
                            .frame(height: 200)
                            .clipped()
                            .allowsHitTesting(false)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                }

                // MARK: Card — hard-capped so it never overflows screen
                card
                    .frame(
                        width: geo.size.width - 32,   // 16pt inset each side
                        alignment: .center
                    )
                    .padding(.bottom, geo.safeAreaInsets.bottom + 12)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .opacity(contentVisible ? 1 : 0)
        .offset(y: contentVisible ? 0 : 40)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1), value: contentVisible)
        .onAppear { contentVisible = true }
        .onDisappear { contentVisible = false }
    }

    // MARK: Card

    private var card: some View {
        VStack(spacing: 12) {
            Text(data.question)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            optionsGrid
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Options

    @ViewBuilder
    private var optionsGrid: some View {
        if data.options.count == 4 {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    optionButton(option: data.options[0], index: 0)
                    optionButton(option: data.options[1], index: 1)
                }
                HStack(spacing: 8) {
                    optionButton(option: data.options[2], index: 2)
                    optionButton(option: data.options[3], index: 3)
                }
            }
        } else {
            VStack(spacing: 8) {
                ForEach(Array(data.options.enumerated()), id: \.element.id) { index, option in
                    optionButton(option: option, index: index)
                }
            }
        }
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
            HStack(spacing: 8) {
                if let emoji = option.emoji {
                    Text(emoji).font(.system(size: 18))
                }
                Text(option.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? data.accentColor : .white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(data.accentColor)
                        .font(.system(size: 15))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.25), lineWidth: 1)
            )
            .opacity(isOtherSelected ? 0.4 : 1.0)
            .scaleEffect(pressedIndex == index ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressedIndex = index }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.15)) { pressedIndex = nil } }
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
