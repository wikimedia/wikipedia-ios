import Foundation
import UIKit
import XCTest
@testable import WMF

public extension Bundle {
    static let test = Bundle(identifier: "org.wikimedia.WikipediaUnitTests")!
}

extension WMFArticle {
    public func oldUpdate(withSummary summary: [String: Any]) {
        if let originalImage = summary["originalimage"] as? [String: Any],
            let source = originalImage["source"] as? String,
            let width = originalImage["width"] as? Int,
            let height = originalImage["height"] as? Int{
            self.imageURLString = source
            self.imageWidth = NSNumber(value: width)
            self.imageHeight = NSNumber(value: height)
        }
        
        if let description = summary["description"] as? String {
            self.wikidataDescription = description
        }
        
        if let displaytitle = summary["displaytitle"] as? String {
            self.displayTitleHTML = displaytitle
        }
        
        if let extract = summary["extract"] as? String {
            self.snippet = extract.wmf_summaryFromText()
        }
        
        if let coordinate = summary["coordinates"] as? [String: Any] ?? (summary["coordinates"] as? [[String: Any]])?.first,
            let lat = coordinate["lat"] as? Double,
            let lon = coordinate["lon"] as? Double {
            self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
}

public extension NSManagedObjectContext {
    static let test: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let modelURL = Bundle.wmf.url(forResource: "Wikipedia", withExtension: "momd", subdirectory: nil)!
        let mom = NSManagedObjectModel(contentsOf: modelURL)!
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        moc.persistentStoreCoordinator = psc
        return moc
    }()
}

class SummaryParsingTests: XCTestCase {
    let summaryJSONData: Data = {
        let summaryJSONURL = Bundle.test.url(forResource: "Summary", withExtension: "json", subdirectory: "Fixtures")!
        return try! Data(contentsOf: summaryJSONURL)
    }()
    
    let moc: NSManagedObjectContext = NSManagedObjectContext.test
    
    let count = 10000
    
    func testSummaryParsing() {
        let decoder = JSONDecoder()
        var summaries: [ArticleSummary] = []
        summaries.reserveCapacity(count)
        let article = WMFArticle(context: moc)
        measure {
            for _ in 0..<count {
                let summary: ArticleSummary = try! decoder.decode(ArticleSummary.self, from: summaryJSONData)
                summaries.append(summary)
                article.update(withSummary: summary)
            }
        }
        XCTAssertTrue(summaries.first?.title == "Dog")
    }
    
    func testOldSummaryParsing() {
        var summaries: [[String: Any]] = []
        summaries.reserveCapacity(count)
        let article = WMFArticle(context: moc)
        measure {
            for _ in 0..<count {
                let summary: [String: Any] = try! JSONSerialization.jsonObject(with: summaryJSONData, options: []) as! [String: Any]
                summaries.append(summary)
                article.oldUpdate(withSummary: summary)
            }
        }
        XCTAssertTrue(summaries.first?["title"] as? String == "Dog")
    }
}
