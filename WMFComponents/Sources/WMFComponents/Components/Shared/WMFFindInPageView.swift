import SwiftUI
import Combine


@available(iOS 26.0, *)
public class WMFFindInPageHostingController: UIHostingController<WMFFindInPageView> {
    
    public init(viewModel: WMFFindInPageViewModel) {
        super.init(rootView: WMFFindInPageView(viewModel: viewModel))
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
    }
}

// MARK: - View Model
@available(iOS 26.0, *)
@MainActor
public class WMFFindInPageViewModel: ObservableObject {
    
    // Published properties
    @Published public var searchText: String = ""
    @Published public var isPresented: Bool = false
    @Published public var currentMatch: Int = 0
    @Published public var totalMatches: Int = 0
    
    // Callbacks for actions
    public var onDone: () -> Void = {}
    public var onPrevious: () -> Void = {}
    public var onNext: () -> Void = {}
    public var onClear: () -> Void = {}
    
    public init() {}
    
    // MARK: - Actions
    public func handleDone() {
        onDone()
    }
    
    public func handlePrevious() {
        onPrevious()
    }
    
    public func handleNext() {
        onNext()
    }
    
    public func handleClear() {
        searchText = ""
        onClear()
    }
}

// MARK: - WMFFindInPageView
// A Liquid Glass find-in-document toolbar matching iOS 26 design language.
// Requirements: iOS 26+, Xcode 26+

@available(iOS 26.0, *)
public struct WMFFindInPageView: View {
    @ObservedObject var viewModel: WMFFindInPageViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    @Namespace private var glassNamespace
    @FocusState private var isSearchFocused: Bool

    init(viewModel: WMFFindInPageViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 8) {

            // MARK: Done / Confirm button
            if let image = WMFSFSymbolIcon.for(symbol: .checkmark, font: .caption1) {
                Button(action: viewModel.handleDone) {
                    Image(uiImage: image)
                        .frame(width: 22, height: 22)
                }
                
                .buttonStyle(.glassProminent)
                .glassEffect(.regular.tint(Color(theme.link)))
            }

            // MARK: Search field + match count
            GlassEffectContainer(spacing: 0) {
                HStack(spacing: 6) {
                    // Magnifier icon
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    // Text field
                    TextField("Find in page", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .frame(height: 24)

                    // Match count + clear
                    if !viewModel.searchText.isEmpty {
                        HStack(spacing: 4) {
                            Text("\(viewModel.currentMatch) of \(viewModel.totalMatches)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.secondary)
                                .fixedSize()

                            Button(action: viewModel.handleClear) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.opacity.combined(with: .scale(0.8)))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassEffect(.regular.interactive(), in: Capsule())
            }

            // MARK: Up / Down navigation
            GlassEffectContainer(spacing: 0) {
                HStack(spacing: 0) {
                    // Previous match
                    Button(action: viewModel.handlePrevious) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .glassEffectID("nav-prev", in: glassNamespace)

                    Divider()
                        .frame(height: 22)
                        .opacity(0.3)

                    // Next match
                    Button(action: viewModel.handleNext) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .glassEffectID("nav-next", in: glassNamespace)
                }
                .glassEffect(.regular.interactive(), in: Capsule())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.clear)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isSearchFocused = true
            }
        }
    }
}
