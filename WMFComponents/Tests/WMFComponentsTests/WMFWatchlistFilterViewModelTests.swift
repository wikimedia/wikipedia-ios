import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

final class WMFWatchlistFilterViewModelTests: XCTestCase {

    override func setUpWithError() throws {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages:[
            enLanguage,
            esLanguage
        ])
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }
    
    var enLanguage: WMFLanguage {
        return WMFLanguage(languageCode: "en", languageVariantCode: nil)
    }
    
    var enProject: WMFProject {
        return .wikipedia(enLanguage)
    }
    
    var esLanguage: WMFLanguage {
        return WMFLanguage(languageCode: "es", languageVariantCode: nil)
    }
                          
    var esProject: WMFProject {
        return .wikipedia(esLanguage)
    }

    func testFilterViewModelInstantiatesWithCorrectDefaults() throws {
        let filterViewModel = WMFWatchlistFilterViewModel(localizedStrings: .demoStrings, overrideUserInterfaceStyle: .unspecified, loggingDelegate: nil)
        
        guard let selectSections = filterViewModel.formViewModel.sections as? [WMFFormSectionSelectViewModel] else {
            XCTFail("Invalid section view model type")
            return
        }
        
        XCTAssertEqual(selectSections.count, 8)
        
        let section1 = selectSections[0]
        XCTAssertEqual(section1.items.count, 2)
        let section1Item1 = section1.items[0]
        XCTAssertEqual(section1Item1.title, "Wikimedia Commons")
        XCTAssertTrue(section1Item1.isSelected)
        let section1Item2 = section1.items[1]
        XCTAssertEqual(section1Item2.title, "Wikidata")
        XCTAssertTrue(section1Item2.isSelected)
                      
        let section2 = selectSections[1]
        XCTAssertEqual(section2.items.count, 3)
        let section2Item1 = section2.items[0]
        XCTAssertEqual(section2Item1.title, "English Wikipedia")
        XCTAssertTrue(section2Item1.isSelected)
        let section2Item2 = section2.items[1]
        XCTAssertEqual(section2Item2.title, "Spanish Wikipedia")
        XCTAssertTrue(section2Item2.isSelected)
        
        let section3 = selectSections[2]
        XCTAssertEqual(section3.items.count, 2)
        let section3Item1 = section3.items[0]
        XCTAssertEqual(section3Item1.title, "Not the latest revision")
        XCTAssertTrue(section3Item1.isSelected)
        let section3Item2 = section3.items[1]
        XCTAssertEqual(section3Item2.title, "Latest revision")
        XCTAssertFalse(section3Item2.isSelected)
        
        let section4 = selectSections[3]
        XCTAssertEqual(section4.items.count, 3)
        let section4Item1 = section4.items[0]
        XCTAssertEqual(section4Item1.title, "All")
        XCTAssertTrue(section4Item1.isSelected)
        let section4Item2 = section4.items[1]
        XCTAssertEqual(section4Item2.title, "Unseen changes")
        XCTAssertFalse(section4Item2.isSelected)
        let section4Item3 = section4.items[2]
        XCTAssertEqual(section4Item3.title, "Seen changes")
        XCTAssertFalse(section4Item3.isSelected)
        
        let section5 = selectSections[4]
        XCTAssertEqual(section5.items.count, 3)
        let section5Item1 = section5.items[0]
        XCTAssertEqual(section5Item1.title, "All")
        XCTAssertTrue(section5Item1.isSelected)
        let section5Item2 = section5.items[1]
        XCTAssertEqual(section5Item2.title, "Bot")
        XCTAssertFalse(section5Item2.isSelected)
        let section5Item3 = section5.items[2]
        XCTAssertEqual(section5Item3.title, "Human (not bot)")
        XCTAssertFalse(section5Item3.isSelected)
        
        let section6 = selectSections[5]
        XCTAssertEqual(section6.items.count, 3)
        let section6Item1 = section6.items[0]
        XCTAssertEqual(section6Item1.title, "All")
        XCTAssertTrue(section6Item1.isSelected)
        let section6Item2 = section6.items[1]
        XCTAssertEqual(section6Item2.title, "Minor edits")
        XCTAssertFalse(section6Item2.isSelected)
        let section6Item3 = section6.items[2]
        XCTAssertEqual(section6Item3.title, "Non-minor edits")
        XCTAssertFalse(section6Item3.isSelected)
        
        let section7 = selectSections[6]
        XCTAssertEqual(section7.items.count, 3)
        let section7Item1 = section7.items[0]
        XCTAssertEqual(section7Item1.title, "All")
        XCTAssertTrue(section7Item1.isSelected)
        let section7Item2 = section7.items[1]
        XCTAssertEqual(section7Item2.title, "Unregistered")
        XCTAssertFalse(section7Item2.isSelected)
        let section7Item3 = section7.items[2]
        XCTAssertEqual(section7Item3.title, "Registered")
        XCTAssertFalse(section7Item3.isSelected)
        
        let section8 = selectSections[7]
        XCTAssertEqual(section8.items.count, 5)
        let section8Item1 = section8.items[0]
        XCTAssertEqual(section8Item1.title, "Page edits")
        XCTAssertTrue(section8Item1.isSelected)
        let section8Item2 = section8.items[1]
        XCTAssertEqual(section8Item2.title, "Page creations")
        XCTAssertTrue(section8Item2.isSelected)
        let section8Item3 = section8.items[2]
        XCTAssertEqual(section8Item3.title, "Category changes")
        XCTAssertTrue(section8Item3.isSelected)
        let section8Item4 = section8.items[3]
        XCTAssertEqual(section8Item4.title, "Wikidata edits")
        XCTAssertTrue(section8Item4.isSelected)
        let section8Item5 = section8.items[4]
        XCTAssertEqual(section8Item5.title, "Logged actions")
        XCTAssertTrue(section8Item5.isSelected)
    }
    
    func testFilterViewModelInstantiatesWithCorrectSavedSettings() throws {
        
        // First save some settings
        let dataController = WMFWatchlistDataController()
        let filterSettings = WMFWatchlistFilterSettings(offProjects: [.wikidata, esProject], latestRevisions: .latestRevision, activity: .unseenChanges, automatedContributions: .bot, significance: .nonMinorEdits, userRegistration: .registered, offTypes: [.categoryChanges, .pageCreations])
        dataController.saveFilterSettings(filterSettings)
        
        let filterViewModel = WMFWatchlistFilterViewModel(localizedStrings: .demoStrings, overrideUserInterfaceStyle: .unspecified, loggingDelegate: nil)
        
        guard let selectSections = filterViewModel.formViewModel.sections as? [WMFFormSectionSelectViewModel] else {
            XCTFail("Invalid section view model type")
            return
        }
        
        // Then check isSelected values
        XCTAssertEqual(selectSections.count, 8)
        
        let section1 = selectSections[0]
        XCTAssertEqual(section1.items.count, 2)
        let section1Item1 = section1.items[0]
        XCTAssertEqual(section1Item1.title, "Wikimedia Commons")
        XCTAssertTrue(section1Item1.isSelected)
        let section1Item2 = section1.items[1]
        XCTAssertEqual(section1Item2.title, "Wikidata")
        XCTAssertFalse(section1Item2.isSelected)
                      
        let section2 = selectSections[1]
        XCTAssertEqual(section2.items.count, 3)
        let section2Item1 = section2.items[0]
        XCTAssertEqual(section2Item1.title, "English Wikipedia")
        XCTAssertTrue(section2Item1.isSelected)
        let section2Item2 = section2.items[1]
        XCTAssertEqual(section2Item2.title, "Spanish Wikipedia")
        XCTAssertFalse(section2Item2.isSelected)
        
        let section3 = selectSections[2]
        XCTAssertEqual(section3.items.count, 2)
        let section3Item1 = section3.items[0]
        XCTAssertEqual(section3Item1.title, "Not the latest revision")
        XCTAssertFalse(section3Item1.isSelected)
        let section3Item2 = section3.items[1]
        XCTAssertEqual(section3Item2.title, "Latest revision")
        XCTAssertTrue(section3Item2.isSelected)
        
        let section4 = selectSections[3]
        XCTAssertEqual(section4.items.count, 3)
        let section4Item1 = section4.items[0]
        XCTAssertEqual(section4Item1.title, "All")
        XCTAssertFalse(section4Item1.isSelected)
        let section4Item2 = section4.items[1]
        XCTAssertEqual(section4Item2.title, "Unseen changes")
        XCTAssertTrue(section4Item2.isSelected)
        let section4Item3 = section4.items[2]
        XCTAssertEqual(section4Item3.title, "Seen changes")
        XCTAssertFalse(section4Item3.isSelected)
        
        let section5 = selectSections[4]
        XCTAssertEqual(section5.items.count, 3)
        let section5Item1 = section5.items[0]
        XCTAssertEqual(section5Item1.title, "All")
        XCTAssertFalse(section5Item1.isSelected)
        let section5Item2 = section5.items[1]
        XCTAssertEqual(section5Item2.title, "Bot")
        XCTAssertTrue(section5Item2.isSelected)
        let section5Item3 = section5.items[2]
        XCTAssertEqual(section5Item3.title, "Human (not bot)")
        XCTAssertFalse(section5Item3.isSelected)
        
        let section6 = selectSections[5]
        XCTAssertEqual(section6.items.count, 3)
        let section6Item1 = section6.items[0]
        XCTAssertEqual(section6Item1.title, "All")
        XCTAssertFalse(section6Item1.isSelected)
        let section6Item2 = section6.items[1]
        XCTAssertEqual(section6Item2.title, "Minor edits")
        XCTAssertFalse(section6Item2.isSelected)
        let section6Item3 = section6.items[2]
        XCTAssertEqual(section6Item3.title, "Non-minor edits")
        XCTAssertTrue(section6Item3.isSelected)
        
        let section7 = selectSections[6]
        XCTAssertEqual(section7.items.count, 3)
        let section7Item1 = section7.items[0]
        XCTAssertEqual(section7Item1.title, "All")
        XCTAssertFalse(section7Item1.isSelected)
        let section7Item2 = section7.items[1]
        XCTAssertEqual(section7Item2.title, "Unregistered")
        XCTAssertFalse(section7Item2.isSelected)
        let section7Item3 = section7.items[2]
        XCTAssertEqual(section7Item3.title, "Registered")
        XCTAssertTrue(section7Item3.isSelected)
        
        let section8 = selectSections[7]
        XCTAssertEqual(section8.items.count, 5)
        let section8Item1 = section8.items[0]
        XCTAssertEqual(section8Item1.title, "Page edits")
        XCTAssertTrue(section8Item1.isSelected)
        let section8Item2 = section8.items[1]
        XCTAssertEqual(section8Item2.title, "Page creations")
        XCTAssertFalse(section8Item2.isSelected)
        let section8Item3 = section8.items[2]
        XCTAssertEqual(section8Item3.title, "Category changes")
        XCTAssertFalse(section8Item3.isSelected)
        let section8Item4 = section8.items[3]
        XCTAssertEqual(section8Item4.title, "Wikidata edits")
        XCTAssertTrue(section8Item4.isSelected)
        let section8Item5 = section8.items[4]
        XCTAssertEqual(section8Item5.title, "Logged actions")
        XCTAssertTrue(section8Item5.isSelected)
    }
    
    func testFilterViewModelSavePersistsSettingsCorrectly() throws {
        let filterViewModel = WMFWatchlistFilterViewModel(localizedStrings: .demoStrings, overrideUserInterfaceStyle: .unspecified, loggingDelegate: nil)
        
        // Change some view model settings
        guard let selectSections = filterViewModel.formViewModel.sections as? [WMFFormSectionSelectViewModel] else {
            XCTFail("Invalid section view model type")
            return
        }
        
        // Unselect "Commons" and "EN"
        selectSections[0].items[0].isSelected = false
        selectSections[1].items[0].isSelected = false
        
        // Select "Latest revision"
        selectSections[2].items[1].isSelected = true
        
        // Select "Seen changes"
        selectSections[3].items[2].isSelected = true
        
        // Select "Human"
        selectSections[4].items[2].isSelected = true
        
        // Select "Minor edits"
        selectSections[5].items[1].isSelected = true
        
        // Select "Unregistered"
        selectSections[6].items[1].isSelected = true
        
        // Unselect "Page edits", "Wikidata edits" and "Logged actions"
        selectSections[7].items[0].isSelected = false
        selectSections[7].items[3].isSelected = false
        selectSections[7].items[4].isSelected = false
        
        // Tell view model to save
        filterViewModel.saveNewFilterSettings()
        
        // Load from data framework, confirm values are as expected
        let dataController = WMFWatchlistDataController()
        let filterSettings = dataController.loadFilterSettings()
        
        XCTAssertEqual(filterSettings.offProjects, [.commons, enProject])
        XCTAssertEqual(filterSettings.latestRevisions, .latestRevision)
        XCTAssertEqual(filterSettings.activity, .seenChanges)
        XCTAssertEqual(filterSettings.automatedContributions, .human)
        XCTAssertEqual(filterSettings.significance, .minorEdits)
        XCTAssertEqual(filterSettings.userRegistration, .unregistered)
        XCTAssertEqual(filterSettings.offTypes, [.pageEdits, .wikidataEdits, .loggedActions])
    }

}

private extension WMFWatchlistFilterViewModel.LocalizedStrings {
    static var demoStrings: WMFWatchlistFilterViewModel.LocalizedStrings {
        let localizedProjectNames: [WMFProject: String] = [
                    WMFProject.commons: "Wikimedia Commons",
                    WMFProject.wikidata: "Wikidata",
                    WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)): "English Wikipedia",
                    WMFProject.wikipedia(WMFLanguage(languageCode: "es", languageVariantCode: nil)): "Spanish Wikipedia"
                 ]
         return WMFWatchlistFilterViewModel.LocalizedStrings(title: "Filter",
                                         doneTitle: "Done",
                                         localizedProjectNames: localizedProjectNames,
                                         wikimediaProjectsHeader: "Wikimedia Projects",
                                         wikipediasHeader: "Wikipedias",
                                         commonAll: "All",
                                         latestRevisionsHeader: "Latest Revisions",
                                         latestRevisionsLatestRevision: "Latest revision",
                                         latestRevisionsNotLatestRevision: "Not the latest revision",
                                         watchlistActivityHeader: "Watchlist Activity",
                                         watchlistActivityUnseenChanges: "Unseen changes",
                                         watchlistActivitySeenChanges: "Seen changes",
                                         automatedContributionsHeader: "Automated Contributions",
                                         automatedContributionsBot: "Bot",
                                         automatedContributionsHuman: "Human (not bot)",
                                         significanceHeader: "Significance",
                                         significanceMinorEdits: "Minor edits",
                                         significanceNonMinorEdits: "Non-minor edits",
                                         userRegistrationHeader: "User registration and experience",
                                         userRegistrationUnregistered: "Unregistered",
                                         userRegistrationRegistered: "Registered",
                                         typeOfChangeHeader: "Type of change",
                                         typeOfChangePageEdits: "Page edits",
                                         typeOfChangePageCreations: "Page creations",
                                         typeOfChangeCategoryChanges: "Category changes",
                                         typeOfChangeWikidataEdits: "Wikidata edits",
                                         typeOfChangeLoggedActions: "Logged actions",
                                         addLanguage: "Add language..."
		 )
     }
 }
