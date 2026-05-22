import XCTest
@testable import WMFComponents

final class WMFEmptyViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeLocalizedStrings(
        attributedFilterString: ((Int) -> AttributedString)? = nil
    ) -> WMFEmptyViewModel.LocalizedStrings {
        return WMFEmptyViewModel.LocalizedStrings(
            title: "No results",
            subtitle: "Try adjusting your filters.",
            titleFilter: nil,
            buttonTitle: nil,
            attributedFilterString: attributedFilterString
        )
    }

    private func makeViewModel(numberOfFilters: Int?) -> WMFEmptyViewModel {
        return WMFEmptyViewModel(
            localizedStrings: makeLocalizedStrings(),
            image: nil,
            imageColor: nil,
            numberOfFilters: numberOfFilters
        )
    }

    // MARK: - Tests

    func testFilterStringReturnsNilWhenNumberOfFiltersIsNil() {
        let viewModel = makeViewModel(numberOfFilters: nil)
        let strings = makeLocalizedStrings(attributedFilterString: { _ in
            XCTFail("attributedFilterString closure should not be invoked when numberOfFilters is nil")
            return AttributedString("unreachable")
        })
        XCTAssertNil(viewModel.filterString(localizedStrings: strings))
    }

    func testFilterStringReturnsNilWhenClosureIsNil() {
        let viewModel = makeViewModel(numberOfFilters: 3)
        let strings = makeLocalizedStrings(attributedFilterString: nil)
        XCTAssertNil(viewModel.filterString(localizedStrings: strings))
    }

    func testFilterStringPassesNumberOfFiltersToClosure() {
        let viewModel = makeViewModel(numberOfFilters: 5)
        var capturedCount: Int?
        let strings = makeLocalizedStrings(attributedFilterString: { count in
            capturedCount = count
            return AttributedString("filters: \(count)")
        })

        let result = viewModel.filterString(localizedStrings: strings)

        XCTAssertEqual(capturedCount, 5)
        XCTAssertEqual(result, AttributedString("filters: 5"))
    }

    func testFilterStringReflectsUpdatedNumberOfFilters() {
        // numberOfFilters is @Published; assigning a new value should be picked up
        // by subsequent calls to filterString(localizedStrings:).
        let viewModel = makeViewModel(numberOfFilters: 1)
        let strings = makeLocalizedStrings(attributedFilterString: { count in
            return AttributedString("count=\(count)")
        })

        XCTAssertEqual(viewModel.filterString(localizedStrings: strings), AttributedString("count=1"))

        viewModel.numberOfFilters = 7
        XCTAssertEqual(viewModel.filterString(localizedStrings: strings), AttributedString("count=7"))

        viewModel.numberOfFilters = nil
        XCTAssertNil(viewModel.filterString(localizedStrings: strings))
    }
}
