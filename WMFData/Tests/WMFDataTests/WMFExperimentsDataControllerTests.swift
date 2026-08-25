import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

final class WMFExperimentsDataControllerTests {

    @Test
    func donationReminderBucketBoundaries() throws {
        let expectations: [(roll: Int, bucket: WMFExperimentsDataController.BucketValue)] = [
            (1, .donationReminderControl),
            (33, .donationReminderControl),
            (34, .donationReminderGroupB),
            (66, .donationReminderGroupB),
            (67, .donationReminderGroupC),
            (100, .donationReminderGroupC)
        ]

        for expectation in expectations {
            let controller = WMFExperimentsDataController(store: WMFMockKeyValueStore())
            let bucket = try controller.determineBucketForExperiment(.donationReminder, withPercentage: 33, randomIntProvider: { expectation.roll })
            #expect(bucket == expectation.bucket, "roll \(expectation.roll)")
        }
    }

    @Test
    func donationReminderBucketPersistsAcrossRolls() throws {
        let store = WMFMockKeyValueStore()
        let controller = WMFExperimentsDataController(store: store)

        let firstBucket = try controller.determineBucketForExperiment(.donationReminder, withPercentage: 33, randomIntProvider: { 34 })
        let secondBucket = try controller.determineBucketForExperiment(.donationReminder, withPercentage: 33, randomIntProvider: { 100 })

        #expect(firstBucket == .donationReminderGroupB)
        #expect(secondBucket == firstBucket)
    }
}
