import Foundation
import RiveRuntime
import UIKit

enum WMFRiveError: LocalizedError {
    case workerUnavailable

    var errorDescription: String? {
        switch self {
        case .workerUnavailable:
            return "Rive could not make a Metal worker on this device."
        }
    }
}

/// Makes the instance that the state machine binds, after the file and the artboard load and before
/// the state machine is made. `nil` gets the default instance of the file.
typealias WMFRiveBindingsMaker = @MainActor (File, Artboard) async -> ViewModelInstance?

@MainActor
enum WMFRiveWorkerProvider {

    private static var worker: Worker?
    private static var failure: (any Error)?
    private static var buildTask: Task<Void, Never>?
    private static var suppliedFontAssets: Set<String> = []

    // TEMPORARY: drop with the inventory dump below once the .riv paths are settled.
    private static var didDumpInventory = false

    /// The files export SF Pro, which the app must not bundle. Thus the app supplies the system font.
    private static let systemFontSubstitutions: [String: UIFont] = [
        "SanSerifFont": .systemFont(ofSize: 17, weight: .bold),
        // The list subtitles use this face. The export renames SF Pro Regular.
        "SanSerifFont-Regular": .systemFont(ofSize: 17, weight: .regular)
    ]

    /// EB Garamond Medium, under the SIL Open Font License, for the "SerifFont" of the export. It is
    /// the static Medium of Google Fonts, the font that the templates file shows since v7.
    private static let bundledFontURLs: [String: URL] = [
        "SerifFont": Bundle.module.url(forResource: "EBGaramond-Medium", withExtension: "ttf")
    ].compactMapValues { $0 }

    static func sharedWorker() async throws -> Worker {
        if let worker {
            return worker
        }

        if let buildTask {
            await buildTask.value
        } else {
            failure = nil
            let task = Task<Void, Never> {
                do {
                    worker = try await Worker()
                } catch {
                    worker = nil
                    failure = error
                }
            }
            buildTask = task
            await task.value
            buildTask = nil
        }

        if let worker {
            return worker
        }

        throw failure ?? WMFRiveError.workerUnavailable
    }

    /// Decodes image data on the worker that draws the files, so a view model can bind it.
    static func decodeImage(from data: Data) async throws -> RiveRuntime.Image {
        try await sharedWorker().decodeImage(from: data)
    }

    /// Loads the file and binds the instance from `bindings` when it makes the state machine.
    /// A `nil` artboard or state machine name gives the default of the file.
    ///
    /// Do not bind other instances after this. A script in the .riv gets its view models in its
    /// `init`, which runs when the state machine is made, and it keeps them. Write new values on the
    /// instance that `bindings` returned.
    static func makeRive(for animation: WMFRiveAnimation, bindings: WMFRiveBindingsMaker) async throws -> Rive {
        let worker = try await sharedWorker()
        let file = try await File(source: .local(animation.resourceName, .module), worker: worker)

        await supplyFonts(for: file, on: worker, animation: animation)

        #if DEBUG
        // TEMPORARY: prints the file's artboards, view models and property paths.
        await dumpInventory(of: file, named: animation.resourceName)
        #endif

        let artboard = try await file.createArtboard(animation.artboardName)
        let main = await bindings(file, artboard)
        let stateMachine = try await artboard.createStateMachine(animation.stateMachineName, binding: main)

        return try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            fit: .layout(scaleFactor: .automatic),
            backgroundColor: Color(red: 0, green: 0, blue: 0, alpha: 0)
        )
    }

    static func resourceExists(for animation: WMFRiveAnimation) -> Bool {
        return Bundle.module.url(forResource: animation.resourceName, withExtension: "riv") != nil
    }

    private static func supplyFonts(for file: File, on worker: Worker, animation: WMFRiveAnimation) async {
        let assets: [File.Asset]
        do {
            assets = try await file.getAssets()
        } catch {
            log(.font, animation, "Could not read the asset list: \(error.localizedDescription)")
            return
        }

        for asset in assets where asset.type == .font {
            guard !suppliedFontAssets.contains(asset.uniqueName) else { continue }

            do {
                let font: RiveRuntime.Font
                if let systemFont = systemFontSubstitutions[asset.name] {
                    font = try await worker.decodeFont(from: systemFont)
                } else if let url = bundledFontURLs[asset.name] {
                    font = try await worker.decodeFont(from: Data(contentsOf: url))
                } else {
                    continue
                }
                worker.addGlobalFontAsset(font, name: asset.uniqueName)
                suppliedFontAssets.insert(asset.uniqueName)
            } catch {
                log(.font, animation, "Could not supply a font for \"\(asset.uniqueName)\": \(error.localizedDescription)")
            }
        }
    }

    private static func log(_ stage: WMFRiveFailure.Stage, _ animation: WMFRiveAnimation, _ reason: String) {
        WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: stage, reason: reason))
    }

    #if DEBUG
    // TEMPORARY: remove once the binding paths are recorded in the slide view models.
    private static func dumpInventory(of file: File, named resourceName: String) async {
        guard !didDumpInventory else { return }
        didDumpInventory = true

        func emit(_ line: String) {
            print("[RiveInventory] \(line)")
        }

        emit("file \"\(resourceName)\"")

        do {
            let artboardNames = try await file.getArtboardNames()
            emit("artboards: \(artboardNames)")

            for artboardName in artboardNames {
                let artboard = try await file.createArtboard(artboardName)
                let stateMachines = try await artboard.getStateMachineNames()
                let defaultInfo = try? await file.getDefaultViewModelInfo(for: artboard)
                let described = defaultInfo.map { "\($0.viewModelName) / \($0.instanceName)" } ?? "none"
                emit("  artboard \"\(artboardName)\" stateMachines=\(stateMachines) defaultViewModel=\(described)")
            }

            for viewModelName in try await file.getViewModelNames() {
                emit("  viewModel \"\(viewModelName)\"")
                for property in try await file.getProperties(of: viewModelName) {
                    emit("    \(property.name) : \(property.type) meta=\"\(property.metaData)\"")
                }
            }

            for viewModelEnum in try await file.getViewModelEnums() {
                emit("  enum \"\(viewModelEnum.name)\" = \(viewModelEnum.values)")
            }

            for asset in try await file.getAssets() {
                emit("  asset \"\(asset.uniqueName)\" type=\(asset.type) ext=\"\(asset.fileExtension)\" cdn=\(asset.cdn != nil)")
            }
        } catch {
            emit("failed: \(error)")
        }
    }
    #endif
}
