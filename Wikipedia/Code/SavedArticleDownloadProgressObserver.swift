import Foundation
import WMFComponents

/// Feeds the Saved tab's download pill from the shared article fetcher progress. The pill shows
/// only when a download is still running after `WMFMinProgressDurationBeforeShowingProgressUI`.
@MainActor
final class SavedArticleDownloadProgressObserver {

    private let viewModel: WMFSavedProgressViewModel
    private var progressObjectWasSetObservation: NSKeyValueObservation?
    private var progressObservation: NSKeyValueObservation?
    private var showTask: Task<Void, Never>?

    init(viewModel: WMFSavedProgressViewModel) {
        self.viewModel = viewModel
        beginProgressObservations()
    }

    private func beginProgressObservations() {
        // A Progress is not reusable, so track each one the container publishes.
        progressObjectWasSetObservation = ProgressContainer.shared.observe(\ProgressContainer.articleFetcherProgress, options: [.new, .initial]) { [weak self] progressContainer, _ in
            let progress = progressContainer.articleFetcherProgress
            Task { @MainActor [weak self] in
                self?.track(progress)
            }
        }
    }

    private func track(_ progress: Progress?) {
        progressObservation?.invalidate()
        progressObservation = nil
        hide()

        guard let progress else {
            return
        }

        progressObservation = progress.observe(\Progress.fractionCompleted, options: [.new, .initial]) { [weak self] progress, _ in
            let shouldShow = progress.wmf_shouldShowProgressUI()
            let fractionCompleted = progress.fractionCompleted
            Task { @MainActor [weak self] in
                self?.update(shouldShow: shouldShow, fractionCompleted: fractionCompleted)
            }
        }
    }

    private func update(shouldShow: Bool, fractionCompleted: Double) {
        viewModel.fractionCompleted = fractionCompleted

        guard shouldShow else {
            hide()
            return
        }

        guard showTask == nil, !viewModel.isVisible else {
            return
        }

        showTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(WMFMinProgressDurationBeforeShowingProgressUI))
            guard !Task.isCancelled else {
                return
            }
            self?.viewModel.isVisible = true
            self?.showTask = nil
        }
    }

    private func hide() {
        showTask?.cancel()
        showTask = nil
        viewModel.isVisible = false
    }
}
