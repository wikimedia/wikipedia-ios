// This class simply makes Progress objects more easily accessible to nested VCs. Dependency injection would probably be better, but the wiring was getting a bit crazy.
@objcMembers class ProgressContainer: NSObject {
    static let shared = ProgressContainer()
    dynamic var articleFetcherProgress: Progress? = nil
}
