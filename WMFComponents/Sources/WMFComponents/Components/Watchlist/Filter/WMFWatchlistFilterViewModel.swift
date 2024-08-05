import Foundation
import WMFData
import UIKit

public final class WMFWatchlistFilterViewModel: ObservableObject {

    // MARK: - Nested Types

    public struct LocalizedStrings {
        let title: String
        let doneTitle: String
        public var localizedProjectNames: [WMFProject: String]
        let wikimediaProjectsHeader: String
        let wikipediasHeader: String
        let commonAll: String
        let latestRevisionsHeader: String
        let latestRevisionsLatestRevision: String
        let latestRevisionsNotLatestRevision: String
        let watchlistActivityHeader: String
        let watchlistActivityUnseenChanges: String
        let watchlistActivitySeenChanges: String
        let automatedContributionsHeader: String
        let automatedContributionsBot: String
        let automatedContributionsHuman: String
        let significanceHeader: String
        let significanceMinorEdits: String
        let significanceNonMinorEdits: String
        let userRegistrationHeader: String
        let userRegistrationUnregistered: String
        let userRegistrationRegistered: String
        let typeOfChangeHeader: String
        let typeOfChangePageEdits: String
        let typeOfChangePageCreations: String
        let typeOfChangeCategoryChanges: String
        let typeOfChangeWikidataEdits: String
        let typeOfChangeLoggedActions: String
		let addLanguage: String

        public init(title: String, doneTitle: String, localizedProjectNames: [WMFProject : String], wikimediaProjectsHeader: String, wikipediasHeader: String, commonAll: String, latestRevisionsHeader: String, latestRevisionsLatestRevision: String, latestRevisionsNotLatestRevision: String, watchlistActivityHeader: String, watchlistActivityUnseenChanges: String, watchlistActivitySeenChanges: String, automatedContributionsHeader: String, automatedContributionsBot: String, automatedContributionsHuman: String, significanceHeader: String, significanceMinorEdits: String, significanceNonMinorEdits: String, userRegistrationHeader: String, userRegistrationUnregistered: String, userRegistrationRegistered: String, typeOfChangeHeader: String, typeOfChangePageEdits: String, typeOfChangePageCreations: String, typeOfChangeCategoryChanges: String, typeOfChangeWikidataEdits: String, typeOfChangeLoggedActions: String, addLanguage: String) {
            self.title = title
            self.doneTitle = doneTitle
            self.localizedProjectNames = localizedProjectNames
            self.wikimediaProjectsHeader = wikimediaProjectsHeader
            self.wikipediasHeader = wikipediasHeader
            self.commonAll = commonAll
            self.latestRevisionsHeader = latestRevisionsHeader
            self.latestRevisionsLatestRevision = latestRevisionsLatestRevision
            self.latestRevisionsNotLatestRevision = latestRevisionsNotLatestRevision
            self.watchlistActivityHeader = watchlistActivityHeader
            self.watchlistActivityUnseenChanges = watchlistActivityUnseenChanges
            self.watchlistActivitySeenChanges = watchlistActivitySeenChanges
            self.automatedContributionsHeader = automatedContributionsHeader
            self.automatedContributionsBot = automatedContributionsBot
            self.automatedContributionsHuman = automatedContributionsHuman
            self.significanceHeader = significanceHeader
            self.significanceMinorEdits = significanceMinorEdits
            self.significanceNonMinorEdits = significanceNonMinorEdits
            self.userRegistrationHeader = userRegistrationHeader
            self.userRegistrationUnregistered = userRegistrationUnregistered
            self.userRegistrationRegistered = userRegistrationRegistered
            self.typeOfChangeHeader = typeOfChangeHeader
            self.typeOfChangePageEdits = typeOfChangePageEdits
            self.typeOfChangePageCreations = typeOfChangePageCreations
            self.typeOfChangeCategoryChanges = typeOfChangeCategoryChanges
            self.typeOfChangeWikidataEdits = typeOfChangeWikidataEdits
            self.typeOfChangeLoggedActions = typeOfChangeLoggedActions
            self.addLanguage = addLanguage
        }
    }
    
    private struct WMFProjectViewModel {
        let project: WMFProject
        let projectName: String?
        let icon: UIImage?
        let isSelected: Bool
    }
    
    // MARK: - Properties
    
    public var localizedStrings: LocalizedStrings
    private var projectViewModels: [WMFProjectViewModel]
    @Published var formViewModel: WMFFormViewModel
    weak var loggingDelegate: WMFWatchlistLoggingDelegate?
    private let dataController = WMFWatchlistDataController()
    let overrideUserInterfaceStyle: UIUserInterfaceStyle
	var addLanguageAction: (() -> Void)? {
		didSet {
			reloadSectionData()
		}
	}

    // MARK: - Public

    public init(localizedStrings: LocalizedStrings, overrideUserInterfaceStyle: UIUserInterfaceStyle, loggingDelegate: WMFWatchlistLoggingDelegate?) {
        self.localizedStrings = localizedStrings
        self.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        self.loggingDelegate = loggingDelegate
        
        let filterSettings = dataController.loadFilterSettings()
        let allProjects = dataController.allWatchlistProjects()
        let offProjects = dataController.offWatchlistProjects()
        self.projectViewModels = Self.projectViewModels(allProjects: allProjects, offProjects: offProjects, strings: localizedStrings)
        
        let allChangeTypes = dataController.allChangeTypes()
        let offChangeTypes = dataController.offChangeTypes()
        
        self.formViewModel = WMFFormViewModel(sections: [
            Self.section1(projectViewModels: Array(projectViewModels.prefix(2)), strings: localizedStrings),
            Self.section2(projectViewModels: Array(projectViewModels.suffix(from: 2)), strings: localizedStrings, addLanguageAction: addLanguageAction),
            Self.section3(strings: localizedStrings, filterSettings: filterSettings),
            Self.section4(strings: localizedStrings, filterSettings: filterSettings),
            Self.section5(strings: localizedStrings, filterSettings: filterSettings),
            Self.section6(strings: localizedStrings, filterSettings: filterSettings),
            Self.section7(strings: localizedStrings, filterSettings: filterSettings),
            Self.section8(allChangeTypes: allChangeTypes, offChangeTypes: offChangeTypes, strings: localizedStrings, filterSettings: filterSettings)
        ])
    }

	public func reloadWikipedias(localizedProjectNames: [WMFProject: String]?) {
		guard let localizedProjectNames = localizedProjectNames else {
			return
		}

		self.localizedStrings.localizedProjectNames = localizedProjectNames
		let allProjects = dataController.allWatchlistProjects()
		let offProjects = self.projectViewModels.filter { !$0.isSelected }.map { $0.project }

		self.projectViewModels = Self.projectViewModels(allProjects: allProjects, offProjects: offProjects, strings: localizedStrings)
		self.formViewModel.sections[1] = Self.section2(projectViewModels: Array(projectViewModels.suffix(from: 2)), strings: localizedStrings, addLanguageAction: addLanguageAction)
	}

    func saveNewFilterSettings() {
        let data = generateDataForNewFilterSettings()
        
        let newFilterSettings = data.filterSettings
        dataController.saveFilterSettings(newFilterSettings)
        
        let onProjects = data.onProjects
        loggingDelegate?.logWatchlistUserDidSaveFilterSettings(filterSettings: newFilterSettings, onProjects: onProjects)
    }
    
    private func generateDataForNewFilterSettings() -> (filterSettings: WMFWatchlistFilterSettings, onProjects: [WMFProject]) {
        guard let sectionSelectViewModels = formViewModel.sections as? [WMFFormSectionSelectViewModel],
              sectionSelectViewModels.count == 8 else {
            assertionFailure("Unexpected sections setup")
            return (WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: []), [])
        }

        var offProjects: [WMFProject] = []
        var onProjects: [WMFProject] = []
        let wikimediaProjectsSection = sectionSelectViewModels[0]
        let wikipediasSection = sectionSelectViewModels[1]

        guard wikimediaProjectsSection.items.count == 2,
              wikipediasSection.items.count == projectViewModels.count - 1 else {
            assertionFailure("Unexpected projects section counts")

            return  (WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: []),[])
        }

        for (index, item) in wikimediaProjectsSection.items.enumerated() {
            if !item.isSelected {
                offProjects.append(projectViewModels[index].project)
            } else {
                onProjects.append(projectViewModels[index].project)
            }
        }

		for (index, item) in wikipediasSection.items.enumerated().filter({ !$0.element.isAccessoryRow }) {
            let offsetIndex = index + (wikimediaProjectsSection.items.count)
            if !item.isSelected {
                offProjects.append(projectViewModels[offsetIndex].project)
            } else {
                onProjects.append(projectViewModels[offsetIndex].project)
            }
        }

        let latestRevisionsSection = sectionSelectViewModels[2]
        let activitySection = sectionSelectViewModels[3]
        let automatedContributionsSection = sectionSelectViewModels[4]
        let significanceSection = sectionSelectViewModels[5]
        let userRegistrationSection = sectionSelectViewModels[6]
        let typeOfChangeSection = sectionSelectViewModels[7]

        guard latestRevisionsSection.items.count == 2,
              activitySection.items.count == 3,
              automatedContributionsSection.items.count == 3,
              significanceSection.items.count == 3,
              userRegistrationSection.items.count == 3,
              typeOfChangeSection.items.count == 5 else {
            assertionFailure("Unexpected items count")

            return (WMFWatchlistFilterSettings(offProjects: [], latestRevisions: .notTheLatestRevision, activity: .all, automatedContributions: .all, significance: .all, userRegistration: .all, offTypes: []),[])
        }

        let latestRevisionsRequest: WMFWatchlistFilterSettings.LatestRevisions
        if latestRevisionsSection.items[0].isSelected {
            latestRevisionsRequest = .notTheLatestRevision
        } else if latestRevisionsSection.items[1].isSelected {
            latestRevisionsRequest = .latestRevision
        } else {
            latestRevisionsRequest = .notTheLatestRevision
        }

        let activityRequest: WMFWatchlistFilterSettings.Activity
        if activitySection.items[0].isSelected {
            activityRequest = .all
        } else if activitySection.items[1].isSelected {
            activityRequest = .unseenChanges
        } else if activitySection.items[2].isSelected {
            activityRequest = .seenChanges
        } else {
            activityRequest = .all
        }

        let automatedContributionsRequest: WMFWatchlistFilterSettings.AutomatedContributions
        if automatedContributionsSection.items[0].isSelected {
            automatedContributionsRequest = .all
        } else if automatedContributionsSection.items[1].isSelected {
            automatedContributionsRequest = .bot
        } else if automatedContributionsSection.items[2].isSelected {
            automatedContributionsRequest = .human
        } else {
            automatedContributionsRequest = .all
        }

        let significanceRequest: WMFWatchlistFilterSettings.Significance
        if significanceSection.items[0].isSelected {
            significanceRequest = .all
        } else if significanceSection.items[1].isSelected {
            significanceRequest = .minorEdits
        } else if significanceSection.items[2].isSelected {
            significanceRequest = .nonMinorEdits
        } else {
            significanceRequest = .all
        }

        let userRegistrationRequest: WMFWatchlistFilterSettings.UserRegistration
        if userRegistrationSection.items[0].isSelected {
            userRegistrationRequest = .all
        } else if userRegistrationSection.items[1].isSelected {
            userRegistrationRequest = .unregistered
        } else if userRegistrationSection.items[2].isSelected {
            userRegistrationRequest = .registered
        } else {
            userRegistrationRequest = .all
        }

        var offTypesRequest: [WMFWatchlistFilterSettings.ChangeType] = []
        if !typeOfChangeSection.items[0].isSelected {
            offTypesRequest.append(.pageEdits)
        }

        if !typeOfChangeSection.items[1].isSelected {
            offTypesRequest.append(.pageCreations)
        }

        if !typeOfChangeSection.items[2].isSelected {
            offTypesRequest.append(.categoryChanges)
        }

        if !typeOfChangeSection.items[3].isSelected {
            offTypesRequest.append(.wikidataEdits)
        }

        if !typeOfChangeSection.items[4].isSelected {
            offTypesRequest.append(.loggedActions)
        }

        return (WMFWatchlistFilterSettings(offProjects: offProjects,
                                        latestRevisions: latestRevisionsRequest,
                                        activity: activityRequest,
                                        automatedContributions: automatedContributionsRequest,
                                        significance: significanceRequest,
                                        userRegistration: userRegistrationRequest,
                                        offTypes: offTypesRequest), onProjects)
    }

	// MARK: - Private

	private func reloadSectionData() {
		let filterSettings = dataController.loadFilterSettings()
		let allProjects = dataController.allWatchlistProjects()
		let offProjects = dataController.offWatchlistProjects()
		self.projectViewModels = Self.projectViewModels(allProjects: allProjects, offProjects: offProjects, strings: localizedStrings)

		let allChangeTypes = dataController.allChangeTypes()
		let offChangeTypes = dataController.offChangeTypes()

		self.formViewModel = WMFFormViewModel(sections: [
			Self.section1(projectViewModels: Array(projectViewModels.prefix(2)), strings: localizedStrings),
			Self.section2(projectViewModels: Array(projectViewModels.suffix(from: 2)), strings: localizedStrings, addLanguageAction: addLanguageAction),
			Self.section3(strings: localizedStrings, filterSettings: filterSettings),
			Self.section4(strings: localizedStrings, filterSettings: filterSettings),
			Self.section5(strings: localizedStrings, filterSettings: filterSettings),
			Self.section6(strings: localizedStrings, filterSettings: filterSettings),
			Self.section7(strings: localizedStrings, filterSettings: filterSettings),
			Self.section8(allChangeTypes: allChangeTypes, offChangeTypes: offChangeTypes, strings: localizedStrings, filterSettings: filterSettings)
		])
	}

}

// MARK: - Static Init Helper Methods

private extension WMFWatchlistFilterViewModel {
    private static func projectViewModels(allProjects: [WMFProject], offProjects: [WMFProject], strings: WMFWatchlistFilterViewModel.LocalizedStrings) -> [WMFProjectViewModel] {

        var projectViewModels: [WMFProjectViewModel] = []
        
        let wikipediaProjects = allProjects.filter {
            switch $0 {
            case .wikipedia:
                return true
            default:
                return false
            }
        }
        
        let otherProjects = allProjects.filter {
            switch $0 {
            case .wikipedia:
                return false
            default:
                return true
            }
        }
        
        for project in otherProjects {
            var icon: UIImage? = nil
            switch project {
            case .commons:
                icon = WMFIcon.commons
            case .wikidata:
                icon = WMFIcon.wikidata
            default:
                break
            }
            
            projectViewModels.append(WMFProjectViewModel(project: project, projectName: strings.localizedProjectNames[project], icon: icon, isSelected: !offProjects.contains(project)))
        }
        
        for project in wikipediaProjects {
            projectViewModels.append(WMFProjectViewModel(project: project, projectName: strings.localizedProjectNames[project], icon: nil, isSelected: !offProjects.contains(project)))
        }

        return projectViewModels
    }
    
    private static func section1(projectViewModels: [WMFProjectViewModel], strings: WMFWatchlistFilterViewModel.LocalizedStrings) -> WMFFormSectionSelectViewModel {

        let items = projectViewModels.map { projectViewModel in
            return WMFFormItemSelectViewModel(image: projectViewModel.icon, title: projectViewModel.projectName, isSelected: projectViewModel.isSelected)

        }

        return WMFFormSectionSelectViewModel(header: strings.wikimediaProjectsHeader, items: items, selectType: .multi)
    }

	private static func section2(projectViewModels: [WMFProjectViewModel], strings: WMFWatchlistFilterViewModel.LocalizedStrings, addLanguageAction: (() -> Void)?) -> WMFFormSectionSelectViewModel {

        var items = projectViewModels.map { projectViewModel in
            return WMFFormItemSelectViewModel(image: projectViewModel.icon, title: projectViewModel.projectName, isSelected: projectViewModel.isSelected)
        }

		let accessoryRow = WMFFormItemSelectViewModel(title: strings.addLanguage, isSelected: false, isAccessoryRow: true)
		accessoryRow.accessoryRowSelectionAction = addLanguageAction
		items.append(accessoryRow)

        return WMFFormSectionSelectViewModel(header: strings.wikipediasHeader, items: items, selectType: .multiWithAccessoryRows)
    }

    private static func section3(strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionSelectViewModel {
        let items = [
            WMFFormItemSelectViewModel(title: strings.latestRevisionsNotLatestRevision, isSelected: filterSettings.latestRevisions == .notTheLatestRevision),
            WMFFormItemSelectViewModel(title: strings.latestRevisionsLatestRevision, isSelected: filterSettings.latestRevisions == .latestRevision)
        ]
        return WMFFormSectionSelectViewModel(header: strings.latestRevisionsHeader, items: items, selectType: .single)
    }

    private static func section4(strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionSelectViewModel {
        let items = [
            WMFFormItemSelectViewModel(title: strings.commonAll, isSelected: filterSettings.activity == .all),
            WMFFormItemSelectViewModel(title: strings.watchlistActivityUnseenChanges, isSelected: filterSettings.activity == .unseenChanges),
            WMFFormItemSelectViewModel(title: strings.watchlistActivitySeenChanges, isSelected: filterSettings.activity == .seenChanges)
        ]
        return WMFFormSectionSelectViewModel(header: strings.watchlistActivityHeader, items: items, selectType: .single)
    }

    private static func section5(strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionSelectViewModel {
        let items = [
            WMFFormItemSelectViewModel(title: strings.commonAll, isSelected: filterSettings.automatedContributions == .all),
            WMFFormItemSelectViewModel(title: strings.automatedContributionsBot, isSelected: filterSettings.automatedContributions == .bot),
            WMFFormItemSelectViewModel(title: strings.automatedContributionsHuman, isSelected: filterSettings.automatedContributions == .human)
        ]
        return WMFFormSectionSelectViewModel(header: strings.automatedContributionsHeader, items: items, selectType: .single)
    }

    private static func section6(strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionSelectViewModel {
        let items = [
            WMFFormItemSelectViewModel(title: strings.commonAll, isSelected: filterSettings.significance == .all),
            WMFFormItemSelectViewModel(title: strings.significanceMinorEdits, isSelected: filterSettings.significance == .minorEdits),
            WMFFormItemSelectViewModel(title: strings.significanceNonMinorEdits, isSelected: filterSettings.significance == .nonMinorEdits)
        ]
        return WMFFormSectionSelectViewModel(header: strings.significanceHeader, items: items, selectType: .single)
    }

    private static func section7(strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionSelectViewModel {
        let items = [
            WMFFormItemSelectViewModel(title: strings.commonAll, isSelected: filterSettings.userRegistration == .all),
            WMFFormItemSelectViewModel(title: strings.userRegistrationUnregistered, isSelected: filterSettings.userRegistration == .unregistered),
            WMFFormItemSelectViewModel(title: strings.userRegistrationRegistered, isSelected: filterSettings.userRegistration == .registered)
        ]
        return WMFFormSectionSelectViewModel(header: strings.userRegistrationHeader, items: items, selectType: .single)
    }

    private static func section8(allChangeTypes: [WMFWatchlistFilterSettings.ChangeType], offChangeTypes: [WMFWatchlistFilterSettings.ChangeType], strings: WMFWatchlistFilterViewModel.LocalizedStrings, filterSettings: WMFWatchlistFilterSettings) -> WMFFormSectionViewModel {

        var items: [WMFFormItemSelectViewModel] = []
        for changeType in allChangeTypes {
            
            var title: String
            
            switch changeType {
            case .categoryChanges:
                title = strings.typeOfChangeCategoryChanges
            case .loggedActions:
                title = strings.typeOfChangeLoggedActions
            case .pageCreations:
                title = strings.typeOfChangePageCreations
            case .pageEdits:
                title = strings.typeOfChangePageEdits
            case .wikidataEdits:
                title = strings.typeOfChangeWikidataEdits
            }
            
            items.append(WMFFormItemSelectViewModel(title: title, isSelected: !offChangeTypes.contains(changeType)))
        }

        return WMFFormSectionSelectViewModel(header: strings.typeOfChangeHeader, items: items, selectType: .multi)
    }
}
