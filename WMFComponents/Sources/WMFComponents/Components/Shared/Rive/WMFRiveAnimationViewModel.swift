import Foundation
import RiveRuntime

@MainActor
final class WMFRiveAnimationViewModel: ObservableObject {

    enum LoadState {
        case idle
        case loading
        case loaded
        case failed

        var isLoaded: Bool {
            if case .loaded = self { return true }
            return false
        }
    }

    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var rive: Rive?
    /// The value of `readBool` in the loaded file. `nil` until the file loads, or if the file has no such property.
    @Published private(set) var readBoolValue: Bool?
    /// Goes up by one each time the loaded file fires `watchedTrigger`.
    @Published private(set) var watchedEventCount = 0

    let animation: WMFRiveAnimation
    /// A boolean property to read from the bound instance after the file loads.
    let readBool: WMFRiveBool?
    let watchedTrigger: WMFRiveTrigger?
    /// For each image property, a boolean property that is true until an image is bound to it. A
    /// file that has no image keeps its sample image, so the flag lets it show a no-image design.
    let missingImageFlags: [WMFRiveImage: WMFRiveBool]

    /// The instance that the state machine binds when it is made, and the values it got.
    struct Bound {
        let main: ViewModelInstance?
        let text: [WMFRiveText: String]
        let numbers: [WMFRiveNumber: Double]
        let bools: [WMFRiveBool: Bool]
        let enums: [WMFRiveEnum: String]
    }

    /// The view model instance that the state machine binds. `nil` until the file loads.
    var boundInstance: ViewModelInstance? {
        bound?.main
    }

    private var text: [WMFRiveText: String]
    private var numbers: [WMFRiveNumber: Double]
    private var bools: [WMFRiveBool: Bool]
    private var enums: [WMFRiveEnum: String] = [:]
    private var images: [WMFRiveImage: Data]
    private var showsSettledState = false
    private var bound: Bound?
    /// The images that are bound to `bound.main`. A decoded image only, not the data.
    private var boundImages: Set<WMFRiveImage> = []
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private var triggerTask: Task<Void, Never>?
    private let loader: @MainActor (WMFRiveAnimation, WMFRiveBindingsMaker) async throws -> Rive
    private let imageDecoder: @MainActor (Data) async throws -> RiveRuntime.Image

    init(
        animation: WMFRiveAnimation,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        bools: [WMFRiveBool: Bool] = [:],
        images: [WMFRiveImage: Data] = [:],
        readBool: WMFRiveBool? = nil,
        watchedTrigger: WMFRiveTrigger? = nil,
        missingImageFlags: [WMFRiveImage: WMFRiveBool] = [:],
        loader: @escaping @MainActor (WMFRiveAnimation, WMFRiveBindingsMaker) async throws -> Rive = WMFRiveWorkerProvider.makeRive,
        imageDecoder: @escaping @MainActor (Data) async throws -> RiveRuntime.Image = WMFRiveWorkerProvider.decodeImage
    ) {
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.bools = bools
        self.images = images
        self.readBool = readBool
        self.watchedTrigger = watchedTrigger
        self.missingImageFlags = missingImageFlags
        self.loader = loader
        self.imageDecoder = imageDecoder
    }

    deinit {
        loadTask?.cancel()
        imageTask?.cancel()
        triggerTask?.cancel()
    }

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard loadTask == nil, !loadState.isLoaded else { return nil }
        let task = Task { [weak self] in
            guard let self else { return }
            await self.load()
        }
        loadTask = task
        return task
    }

    /// Makes a new state machine, so the animation plays again from its first frame. A state machine
    /// cannot go back to its start. The animation on screen stays until the new one is ready.
    @discardableResult
    func restart() -> Task<Void, Never>? {
        guard loadState.isLoaded else { return nil }
        loadTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.load(showsLoading: false)
        }
        loadTask = task
        return task
    }

    /// - Parameter showsLoading: `false` keeps the current animation on screen during the load.
    func load(showsLoading: Bool = true) async {
        if showsLoading {
            loadState = .loading
        }
        do {
            var made: Bound?
            let rive = try await loader(animation) { file, artboard in
                let bound = await self.makeBound(file: file, artboard: artboard)
                made = bound
                return bound.main
            }
            guard !Task.isCancelled else { return }
            self.rive = rive
            self.bound = made
            boundImages = []
            if let made, made.text != text || made.numbers != numbers || made.bools != bools || made.enums != enums {
                // The values changed while the file loaded.
                applyCurrentValues()
            }
            if showsSettledState {
                advanceToSettledState(rive)
            }
            validatePathsInDebug()
            applyImages()
            watchTrigger()
            self.loadState = .loaded
            await readBoolFromFile()
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.rive = nil
            self.bound = nil
            self.loadTask = nil
            self.loadState = .failed
            WMFRiveLogger.log(
                WMFRiveFailure(animation: animation, stage: stage(for: error), reason: error.localizedDescription)
            )
        }
    }

    func unload() {
        loadTask?.cancel()
        loadTask = nil
        imageTask?.cancel()
        imageTask = nil
        triggerTask?.cancel()
        triggerTask = nil
        rive = nil
        bound = nil
        boundImages = []
        readBoolValue = nil
        loadState = .idle
    }

    /// Writes the new values on the instances that are bound. It does not bind new instances. See `makeBound`.
    func update(text newText: [WMFRiveText: String], numbers newNumbers: [WMFRiveNumber: Double]) {
        guard newText != text || newNumbers != numbers else { return }
        text = newText
        numbers = newNumbers
        applyCurrentValues()
    }

    func update(bools newBools: [WMFRiveBool: Bool]) {
        guard newBools != bools else { return }
        bools = newBools
        applyCurrentValues()
    }

    /// Sets enum properties, for example the layout direction. Call it before `loadIfNeeded()` so the
    /// first frame already has the values.
    func update(enums newEnums: [WMFRiveEnum: String]) {
        guard newEnums != enums else { return }
        enums = newEnums
        applyCurrentValues()
    }

    /// `true` shows the animation at the end of its intro, for Reduce Motion. The first frame of most
    /// intros is empty, so a paused animation shows nothing. Call it before `loadIfNeeded()`.
    func update(showsSettledState newValue: Bool) {
        guard newValue != showsSettledState else { return }
        showsSettledState = newValue
        if newValue {
            restart()
        }
    }

    func update(images newImages: [WMFRiveImage: Data]) {
        guard newImages != images else { return }
        images = newImages
        applyImages()
    }

    /// Makes the instance that the state machine binds when it is made, with the values already set.
    /// A script in the .riv gets its view models in its `init`, which runs when the state machine is
    /// made. The script does not see an instance that is bound after that (T441488).
    ///
    /// The templates set the values of each artboard, for example the maximum line counts, on the
    /// instance that has the name of the artboard. The default instance has zeros. Other files have no
    /// such instance, so they get the default instance.
    private func makeBound(file: File, artboard: Artboard) async -> Bound {
        var main: ViewModelInstance?
        if let artboardName = animation.artboardName {
            main = try? await file.createViewModelInstance(.name(artboardName, from: .artboardDefault(artboard)))
        }
        if main == nil {
            main = try? await file.createViewModelInstance(.viewModelDefault(from: .artboardDefault(artboard)))
        }
        if let main {
            applyValues(to: main, boundImages: [])
        }
        return Bound(main: main, text: text, numbers: numbers, bools: bools, enums: enums)
    }

    private func applyCurrentValues() {
        guard let bound else { return }
        if let main = bound.main {
            applyValues(to: main, boundImages: boundImages)
        }
    }

    private func applyValues(to instance: ViewModelInstance, boundImages: Set<WMFRiveImage>) {
        for (property, value) in text {
            instance.setValue(of: StringProperty(path: property.path), to: value)
        }
        for (property, value) in numbers {
            instance.setValue(of: NumberProperty(path: property.path), to: Float(value))
        }
        for (property, value) in bools {
            instance.setValue(of: BoolProperty(path: property.path), to: value)
        }
        for (property, value) in enums {
            instance.setValue(of: EnumProperty(path: property.path), to: value)
        }
        for (image, flag) in missingImageFlags {
            instance.setValue(of: BoolProperty(path: flag.path), to: !boundImages.contains(image))
        }
    }

    /// Small steps, because one advance does at most one state transition, and the glyph scripts
    /// count their time in advances.
    private func advanceToSettledState(_ rive: Rive) {
        let step: TimeInterval = 0.1
        let duration: TimeInterval = 10
        for _ in 0..<Int(duration / step) {
            rive.stateMachine.advance(by: step)
        }
    }

    /// A restart binds a new instance, so this watches the new instance.
    private func watchTrigger() {
        triggerTask?.cancel()
        guard let watchedTrigger, let instance = bound?.main else { return }
        let property = TriggerProperty(path: watchedTrigger.path)
        triggerTask = Task { [weak self] in
            do {
                for try await _ in instance.stream(of: property) {
                    guard let self, !Task.isCancelled else { return }
                    self.watchedEventCount += 1
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                WMFRiveLogger.log(WMFRiveFailure(animation: self.animation, stage: .binding, reason: "Could not watch \"\(watchedTrigger.path)\": \(error.localizedDescription)"))
            }
        }
    }

    /// Decoding is async, so the images arrive after the text. An image that does not decode keeps
    /// the placeholder inside the .riv, and its missing-image flag stays true.
    private func applyImages() {
        imageTask?.cancel()
        guard let instance = bound?.main, !images.isEmpty else { return }
        let images = images
        imageTask = Task { [weak self] in
            for (property, data) in images {
                guard let self else { return }
                do {
                    let image = try await self.imageDecoder(data)
                    guard !Task.isCancelled else { return }
                    instance.setValue(of: ImageProperty(path: property.path), to: image)
                    self.boundImages.insert(property)
                    if let flag = self.missingImageFlags[property] {
                        instance.setValue(of: BoolProperty(path: flag.path), to: false)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    WMFRiveLogger.log(WMFRiveFailure(animation: self.animation, stage: .binding, reason: "Could not decode the image for \"\(property.path)\": \(error.localizedDescription)"))
                }
            }
        }
    }

    private func readBoolFromFile() async {
        guard let readBool, let main = bound?.main else { return }
        let value = try? await main.value(of: BoolProperty(path: readBool.path))
        guard !Task.isCancelled else { return }
        readBoolValue = value
    }

    private func stage(for error: any Error) -> WMFRiveFailure.Stage {
        if error is WorkerError || error is WMFRiveError {
            return .worker
        }
        return .file
    }

    private func validatePathsInDebug() {
        #if DEBUG
        guard let instance = bound?.main, !text.isEmpty || !numbers.isEmpty else { return }
        let stringPaths = text.keys.map(\.path)
        let numberPaths = numbers.keys.map(\.path)
        Task { [animation] in
            for path in stringPaths where (try? await instance.value(of: StringProperty(path: path))) == nil {
                report(path: path, type: "string", animation: animation)
            }

            for path in numberPaths where (try? await instance.value(of: NumberProperty(path: path))) == nil {
                report(path: path, type: "number", animation: animation)
            }
        }
        #endif
    }

    #if DEBUG
    private func report(path: String, type: String, animation: WMFRiveAnimation) {
        let failure = WMFRiveFailure(
            animation: animation,
            stage: .binding,
            reason: "No \(type) data binding property at path \"\(path)\"."
        )
        WMFRiveLogger.log(failure)
        assertionFailure(failure.reason)
    }
    #endif
}
