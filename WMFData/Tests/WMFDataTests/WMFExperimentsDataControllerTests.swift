import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

final class WMFExperimentsDataControllerTests {
    private static let directory = "Experiments"

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

    // MARK: - Signatures and pruning

    @Test
    func bucketPersistedBeforeSignaturesGetsTheCurrentSignature() throws {
        let store = WMFMockKeyValueStore()
        try store.save(key: Self.directory, "homeTabBucket", value: "HomeTab_GroupB")
        try store.save(key: Self.directory, "homeTabPercent", value: 50)
        let controller = WMFExperimentsDataController(store: store)

        #expect(controller.bucketForExperiment(.homeTab) == .homeTabGroupB)
        let bucket = try controller.determineBucketForExperiment(.homeTab, withPercentage: 50, randomIntProvider: { 1 })
        #expect(bucket == .homeTabGroupB)

        let signature: String? = try store.load(key: Self.directory, "homeTabBucketSignature")
        #expect(signature == WMFExperimentsDataController.Experiment.homeTab.config.signature)
    }

    @Test
    func bucketOfAnotherExperimentIsDiscarded() throws {
        let store = WMFMockKeyValueStore()
        try store.save(key: Self.directory, "homeTabBucket", value: "ActivityTab_Control")
        try store.save(key: Self.directory, "homeTabPercent", value: 50)
        let controller = WMFExperimentsDataController(store: store)

        #expect(controller.bucketForExperiment(.homeTab) == nil)
        #expect(try store.keys(inDirectory: Self.directory).isEmpty)
    }

    @Test
    func bucketWithAStaleSignatureIsDiscardedAndReRolled() throws {
        let store = WMFMockKeyValueStore()
        try store.save(key: Self.directory, "homeTabBucket", value: "HomeTab_GroupB")
        try store.save(key: Self.directory, "homeTabPercent", value: 50)
        try store.save(key: Self.directory, "homeTabBucketSignature", value: "homeTabBucket|HomeTab_Control,HomeTab_GroupB,HomeTab_GroupC")
        let controller = WMFExperimentsDataController(store: store)

        #expect(controller.bucketForExperiment(.homeTab) == nil)
        let bucket = try controller.determineBucketForExperiment(.homeTab, withPercentage: 50, randomIntProvider: { 1 })
        #expect(bucket == .homeTabControl)

        let signature: String? = try store.load(key: Self.directory, "homeTabBucketSignature")
        #expect(signature == WMFExperimentsDataController.Experiment.homeTab.config.signature)
    }

    @Test
    func resetRemovesEveryFileOfTheExperiment() throws {
        let store = WMFMockKeyValueStore()
        let controller = WMFExperimentsDataController(store: store)
        _ = try controller.determineBucketForExperiment(.donationReminder, withPercentage: 33)
        #expect(try store.keys(inDirectory: Self.directory).count == 3)

        try controller.resetExperiment(.donationReminder)

        #expect(try store.keys(inDirectory: Self.directory).isEmpty)
        #expect(controller.bucketForExperiment(.donationReminder) == nil)
    }

    @Test
    func pruneRemovesEveryFileNoActiveExperimentUses() throws {
        let store = WMFMockKeyValueStore()
        try store.save(key: Self.directory, "activityTabBucket", value: "ActivityTab_Control")
        try store.save(key: Self.directory, "activityTabPercent", value: 50)
        try store.save(key: Self.directory, "articleSearchBarBucket", value: "ArticleSearchBar_Test")
        try store.save(key: Self.directory, "homeTabBucket", value: "HomeTab_GroupB")
        try store.save(key: Self.directory, "homeTabPercent", value: 50)
        let controller = WMFExperimentsDataController(store: store)
        let activeBucket = try controller.determineBucketForExperiment(.donationReminder, withPercentage: 33)
        try store.save(key: "Developer Settings", "AppsFeatureConfig", value: "untouched")

        WMFExperimentsDataController.pruneRetiredExperiments(store: store)

        #expect(try store.keys(inDirectory: Self.directory) == ["donationReminderBucket", "donationReminderBucketSignature", "donationReminderPercent", "homeTabBucket", "homeTabPercent"])
        #expect(controller.bucketForExperiment(.homeTab) == .homeTabGroupB)
        #expect(controller.bucketForExperiment(.donationReminder) == activeBucket)
        let otherDirectoryValue: String? = try store.load(key: "Developer Settings", "AppsFeatureConfig")
        #expect(otherDirectoryValue == "untouched")
    }

    /// Simulates a reader who updates the app in the middle of every active experiment: the bucket
    /// and percentage files on disk stay as they are, the reader keeps the same bucket, and the only
    /// change is the new signature file.
    @Test
    func updatingTheAppKeepsEveryPersistedBucket() throws {
        let percentages: [WMFExperimentsDataController.Experiment: Int] = [
            .moreDynamicTabsV2: 50,
            .yirLoginPrompt: 50,
            .homeTab: 50,
            .donationReminder: 33,
            .semanticSearch: 50
        ]

        for experiment in WMFExperimentsDataController.Experiment.allCases {
            let config = experiment.config
            let percentage = try #require(percentages[experiment])

            for persistedBucket in config.bucketValues {
                let store = WMFMockKeyValueStore()
                try store.save(key: Self.directory, config.bucketFileName.rawValue, value: persistedBucket.rawValue)
                try store.save(key: Self.directory, config.percentageFileName.rawValue, value: percentage)
                let controller = WMFExperimentsDataController(store: store)

                #expect(controller.bucketForExperiment(experiment) == persistedBucket, "\(experiment) \(persistedBucket)")
                let bucketAfterUpdate = try controller.determineBucketForExperiment(experiment, withPercentage: percentage, randomIntProvider: { 100 })
                #expect(bucketAfterUpdate == persistedBucket, "\(experiment) \(persistedBucket)")

                let bucketOnDisk: String? = try store.load(key: Self.directory, config.bucketFileName.rawValue)
                let percentageOnDisk: Int? = try store.load(key: Self.directory, config.percentageFileName.rawValue)
                let signatureOnDisk: String? = try store.load(key: Self.directory, config.signatureFileName)
                #expect(bucketOnDisk == persistedBucket.rawValue)
                #expect(percentageOnDisk == percentage)
                #expect(signatureOnDisk == config.signature)
                #expect(try store.keys(inDirectory: Self.directory).count == 3)
            }
        }
    }

    @Test
    func everyExperimentHasUniqueFileNamesAndSignature() {
        let configs = WMFExperimentsDataController.Experiment.allCases.map { $0.config }
        let fileNames = configs.flatMap { $0.fileNames }
        let signatures = Set(configs.map { $0.signature })

        #expect(Set(fileNames).count == fileNames.count)
        #expect(signatures.count == configs.count)
    }
}
