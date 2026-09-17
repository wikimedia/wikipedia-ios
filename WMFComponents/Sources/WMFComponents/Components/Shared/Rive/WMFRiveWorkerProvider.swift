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

@MainActor
enum WMFRiveWorkerProvider {

    private static var worker: Worker?
    private static var failure: (any Error)?
    private static var buildTask: Task<Void, Never>?
    private static var suppliedFontAssets: Set<String> = []

    private static let systemFontSubstitutions: [String: UIFont] = [
        "SanSerifFont": .systemFont(ofSize: 17, weight: .bold)
    ]

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

    static func makeRive(for animation: WMFRiveAnimation) async throws -> Rive {
        let worker = try await sharedWorker()
        let file = try await File(source: .local(animation.resourceName, .module), worker: worker)

        await supplySystemFonts(for: file, on: worker, animation: animation)

        var artboard: Artboard?
        var stateMachine: StateMachine?

        if animation.artboardName != nil || animation.stateMachineName != nil {
            let resolved = try await file.createArtboard(animation.artboardName)
            artboard = resolved
            if let stateMachineName = animation.stateMachineName {
                stateMachine = try await resolved.createStateMachine(stateMachineName)
            }
        }

        return try await Rive(
            file: file,
            artboard: artboard,
            stateMachine: stateMachine,
            dataBind: .auto,
            fit: .contain(alignment: .center),
            backgroundColor: Color(red: 0, green: 0, blue: 0, alpha: 0)
        )
    }

    static func resourceExists(for animation: WMFRiveAnimation) -> Bool {
        return Bundle.module.url(forResource: animation.resourceName, withExtension: "riv") != nil
    }

    private static func supplySystemFonts(for file: File, on worker: Worker, animation: WMFRiveAnimation) async {
        let assets: [File.Asset]
        do {
            assets = try await file.getAssets()
        } catch {
            log(.font, animation, "Could not read the asset list: \(error.localizedDescription)")
            return
        }

        for asset in assets where asset.type == .font {
            guard let substitute = systemFontSubstitutions[asset.name] else { continue }
            guard !suppliedFontAssets.contains(asset.uniqueName) else { continue }

            do {
                let font = try await worker.decodeFont(from: substitute)
                worker.addGlobalFontAsset(font, name: asset.uniqueName)
                suppliedFontAssets.insert(asset.uniqueName)
            } catch {
                log(.font, animation, "Could not supply a system font for \"\(asset.uniqueName)\": \(error.localizedDescription)")
            }
        }
    }

    private static func log(_ stage: WMFRiveFailure.Stage, _ animation: WMFRiveAnimation, _ reason: String) {
        WMFRiveLogger.log(WMFRiveFailure(animation: animation, stage: stage, reason: reason))
    }
}
