import Foundation
import CoreData

public final class WMFYearInReviewDataController {

    private let coreDataStore: WMFCoreDataStore

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
    }

    // TODO: handle display logic in app resume

    public func saveYearInReviewReport(_ report: WMFYearInReviewReport) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", report.year)
            let cdReport = try self.coreDataStore.fetchOrCreate(
                entityType: CDYearInReviewReport.self,
                entityName: "CDYearInReviewReport",
                predicate: reportPredicate,
                in: backgroundContext
            )

            cdReport?.year = Int32(report.year)

            var cdSlidesSet = Set<CDYearInReviewSlide>()
            for slide in report.slides {
                let slidePredicate = NSPredicate(format: "year == %d", slide.year)
                let cdSlide = try self.coreDataStore.fetchOrCreate(
                    entityType: CDYearInReviewSlide.self,
                    entityName: "CDYearInReviewSlide",
                    predicate: slidePredicate,
                    in: backgroundContext
                )

                cdSlide?.year = Int32(slide.year)
                cdSlide?.id = slide.id.rawValue
                cdSlide?.evaluated = slide.evaluated
                cdSlide?.display = slide.display
                cdSlide?.data = slide.data

                if let cdSlide {
                    cdSlidesSet.insert(cdSlide)
                }
            }
            cdReport?.slides = cdSlidesSet as NSSet

            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }

    public func createNewYearInReviewReport(year: Int, slides: [WMFYearInReviewSlide]) async throws {
        let newReport = WMFYearInReviewReport(year: year, slides: slides)

        try await saveYearInReviewReport(newReport)
    }

    public func fetchYearInReviewReports() async throws -> [WMFYearInReviewReport] {
        let viewContext = try coreDataStore.viewContext
        let reports: [WMFYearInReviewReport] = try await viewContext.perform {
            let fetchRequest = NSFetchRequest<CDYearInReviewReport>(entityName: "CDYearInReviewReport")
            let cdReports = try viewContext.fetch(fetchRequest)

            var results: [WMFYearInReviewReport] = []
            for cdReport in cdReports {
                guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
                    continue
                }

                var slides: [WMFYearInReviewSlide] = []
                for cdSlide in cdSlides {

                    let slide = WMFYearInReviewSlide(year: Int(cdSlide.year), id: self.getSlideId(cdSlide.id), evaluated: cdSlide.evaluated, display: cdSlide.display)

                    slides.append(slide)
                }

                let report = WMFYearInReviewReport(
                    year: Int(cdReport.year),
                    slides: slides
                )
                results.append(report)
            }
            return results
        }
        return reports
    }

    private func getSlideId(_ idString: String?) -> WMFYearInReviewPersonalizedSlideID {
        switch idString {
        case "readCount":
            return .readCount
        case "editCount":
            return .editCount
        default:
            return .editCount // TODO: fix
        }

    }

    public func deleteYearInReviewReport(year: Int) async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform { [weak self] in
            guard let self else { return }

            let reportPredicate = NSPredicate(format: "year == %d", year)
            if let cdReport = try self.coreDataStore.fetch(
                entityType: CDYearInReviewReport.self,
                entityName: "CDYearInReviewReport",
                predicate: reportPredicate,
                fetchLimit: 1,
                in: backgroundContext
            )?.first {
                backgroundContext.delete(cdReport)
                try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
            }
        }
    }

    public func deleteAllYearInReviewReports() async throws {
        let backgroundContext = try coreDataStore.newBackgroundContext

        try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDYearInReviewReport")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            let result = try backgroundContext.execute(batchDeleteRequest) as? NSBatchDeleteResult

            if let objectIDArray = result?.result as? [NSManagedObjectID], !objectIDArray.isEmpty {
                let changes = [NSDeletedObjectsKey: objectIDArray]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [backgroundContext])
            }
            try self.coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
}
