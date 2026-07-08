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

                // MARK: Lottie — full bleed behind everything
                if let lottieName = data.lottieName {
                    WMFLottieView(animationName: lottieName, loopMode: .loop)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // MARK: Card
                VStack(spacing: 14) {
                    Text(data.question)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 10) {
                        ForEach(Array(data.options.enumerated()), id: \.element.id) { index, option in
                            optionButton(option: option, index: index, width: geo.size.width - 64)
                        }
                    }
                }
                .padding(20)
                .frame(width: geo.size.width - 32)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
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

    // MARK: Option button

    @ViewBuilder
    private func optionButton(option: WMFYiR2026Option, index: Int, width: CGFloat) -> some View {
        let isSelected = selectedOptionIndex == index
        let isOtherSelected = selectedOptionIndex != nil && !isSelected
        let hasCorrect = data.correctOptionIndex != nil
        let isCorrect = hasCorrect && index == data.correctOptionIndex
        let isWrong = isSelected && hasCorrect && !isCorrect

        // After selection: correct = green, wrong = red, others dim
        let bgColor: Color = {
            guard selectedOptionIndex != nil, hasCorrect else {
                return option.optionColor ?? Color.white.opacity(0.2)
            }
            if isCorrect { return Color(red: 0.18, green: 0.65, blue: 0.35) }
            if isWrong { return Color(red: 0.80, green: 0.20, blue: 0.20) }
            return option.optionColor?.opacity(0.4) ?? Color.white.opacity(0.1)
        }()

        let feedbackIcon: String = isWrong ? "xmark.circle.fill" : "checkmark.circle.fill"

        Button {
            guard selectedOptionIndex == nil else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onSelect(index)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if let imageName = option.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    // Show feedback icon on selected, or correct answer after wrong pick
                    if isSelected || (isCorrect && selectedOptionIndex != nil) {
                        Image(systemName: feedbackIcon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 48, height: 48)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(width: width, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(bgColor))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(isSelected || isCorrect ? 0.5 : 0.2), lineWidth: 1.5)
            )
            .opacity(isOtherSelected && !isCorrect ? 0.4 : 1.0)
            .scaleEffect(pressedIndex == index ? 0.97 : 1.0)
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
                .init(label: "Science & Technology", subtitle: "Physics, space & more",   optionColor: Color(red: 0.25, green: 0.45, blue: 0.85)),
                .init(label: "History & Culture",    subtitle: "People & civilizations",   optionColor: Color(red: 0.85, green: 0.55, blue: 0.15)),
                .init(label: "Geography",            subtitle: "Places around the world",  optionColor: Color(red: 0.20, green: 0.65, blue: 0.45)),
                .init(label: "Sports & Games",       subtitle: "Athletics & competition",  optionColor: Color(red: 0.75, green: 0.25, blue: 0.35))
            ]
        ),
        selectedOptionIndex: nil,
        onSelect: { _ in }
    )
}
#endif
