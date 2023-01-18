import SwiftUI

struct ShiftingScrollView<Content: View>: View {

    @EnvironmentObject var data: ShiftingTopViewsData

    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content

    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            ZStack(alignment:.topLeading) {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).origin
                    )
                }
                .frame(width: 0, height: 0)
                content
                    .padding(.top, data.totalHeight)
            }
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
    }

    func offsetChanged(_ offset: CGPoint) {
        data.scrollAmount = -offset.y
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero

    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
