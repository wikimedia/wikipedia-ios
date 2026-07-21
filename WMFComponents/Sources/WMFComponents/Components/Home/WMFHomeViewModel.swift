import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

extension WMFLanguage: Identifiable {
    public var id: String { [languageCode, languageVariantCode].compactMap { $0 }.joined(separator: "-") }
}

@MainActor
public final class WMFHomeViewModel: ObservableObject {

    public var didTapForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didSaveForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didTapUnsaveForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var didShareForYouCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var isArticleSaved: ((WMFForYouArticleCardViewModel) -> Bool)?

    public enum Tab: Int, CaseIterable {
        case forYou
        case community
    }

    let forYouTabTitle = WMFLocalizedString("home-for-you-tab-title", value: "For You", comment: "Title for the For You segment within the Home tab.")
    let communityTabTitle = WMFLocalizedString("home-community-tab-title", value: "Community", comment: "Title for the Community segment within the Home tab.")
    let editLanguagesTitle = WMFLocalizedString("home-edit-languages-title", value: "Add or edit languages", comment: "Title for the option at the bottom of the Home language menu that opens the languages settings screen.")

    @Published public var selectedTab: Tab = .community
    @Published public var languages: [WMFLanguage]
    @Published public var selectedLanguage: WMFLanguage? {
        didSet {
            guard let newValue = selectedLanguage, newValue.id != oldValue?.id else { return }
            forYouViewModel = nil
            communityPages = []
            loadCurrentTabFeedIfNeeded()
        }
    }
    @Published public var forYouViewModel: WMFForYouViewModel? {
        didSet { configureForYouViewModel() }
    }
    @Published public var isLoadingForYou: Bool = false
    @Published public var communityPages: [WMFHomeCommunityViewModel] = []
    @Published public var communityFeedError: Error?
    @Published public var isLoadingCommunity: Bool = false
    @Published public var isLoadingCommunityPreviousPage: Bool = false
    @Published public var communityModuleVisibility: WMFCommunityModuleVisibility = WMFCommunityModuleVisibility(
        featuredArticle: true, topRead: true, inTheNews: true, onThisDay: true, pictureOfDay: true
    )
    @Published public var hiddenCardKeys: Set<String> = []
    @Published public var isUsingColorTestForYou: Bool = WMFDeveloperSettingsDataController.shared.isUsingColorTestForYou

    let dataController: WMFHomeDataController

    public var didSelectLanguage: ((WMFLanguage) -> Void)?
    public var didTapEditLanguages: (() -> Void)?
    public var didTapCustomizeInterests: (() -> Void)?

    // MARK: - For You view model configuration

    private func configureForYouViewModel() {
        guard let forYouViewModel else { return }
        forYouViewModel.moduleVisibility = WMFForYouModuleVisibility(
            basedOnInterests: dataController.forYouBasedOnInterestsIsOn(),
            becauseYouRead: dataController.forYouBecauseYouReadIsOn(),
            continueReading: dataController.forYouContinueReadingIsOn()
        )
        forYouViewModel.hiddenCardKeys = hiddenCardKeys
        forYouViewModel.onRefresh = { [weak self] in await self?.refreshForYouFeed() }
        forYouViewModel.onHideModule = { [weak self] in self?.hideForYouModule($0) }
        forYouViewModel.onHideCard = { [weak self] card in
            self?.hideForYouCard(card)
        }
        forYouViewModel.onCustomizeInterests = { [weak self] in self?.didTapCustomizeInterests?() }
        forYouViewModel.onTapCard = { [weak self] in self?.didTapForYouCard?($0) }
        forYouViewModel.onSaveCard = { [weak self] in self?.didSaveForYouCard?($0) }
        forYouViewModel.onShareCard = { [weak self] in self?.didShareForYouCard?($0) }
        forYouViewModel.onUnsaveCard = { [weak self] in self?.didTapUnsaveForYouCard?($0) }
    }

    // MARK: - For You

    public func refreshForYouModuleVisibility() {
        forYouViewModel?.moduleVisibility = WMFForYouModuleVisibility(
            basedOnInterests: dataController.forYouBasedOnInterestsIsOn(),
            becauseYouRead: dataController.forYouBecauseYouReadIsOn(),
            continueReading: dataController.forYouContinueReadingIsOn()
        )
    }

    public func refreshSavedStates() {
        guard let isArticleSaved else { return }
        forYouViewModel?.pages.forEach { page in
            page.articleViewModels.forEach { card in
                card.refreshSavedState(isSaved: isArticleSaved(card))
            }
        }
    }

    public func hideForYouModule(_ module: WMFForYouModule) {
        switch module {
        case .basedOnInterests:
            dataController.setForYouBasedOnInterestsIsOn(false)
        case .becauseYouRead:
            dataController.setForYouBecauseYouReadIsOn(false)
        case .continueReading:
            dataController.setForYouContinueReadingIsOn(false)
        }
        withAnimation {
            refreshForYouModuleVisibility()
        }
    }

    public func hideForYouCard(_ card: WMFForYouArticleCardViewModel) {
        guard !hiddenCardKeys.contains(card.hideKey) else { return }
        dataController.hideCard(key: card.hideKey)
        withAnimation {
            hiddenCardKeys.insert(card.hideKey)
            forYouViewModel?.hiddenCardKeys.insert(card.hideKey)
        }
    }

    public func refreshForYouFeed() async {
        isUsingColorTestForYou = WMFDeveloperSettingsDataController.shared.isUsingColorTestForYou

        if isUsingColorTestForYou {
            forYouViewModel = WMFForYouViewModel(response: .colorTest)
            refreshSavedStates()
            return
        }

        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        do {
            let response = try await dataController.fetchForYou(project: project, forceFetch: true)
            self.forYouViewModel = WMFForYouViewModel(response: response)
            self.refreshSavedStates()
        } catch {
            // TODO: surface error
        }
    }

    public func loadCurrentTabFeedIfNeeded() {
        switch selectedTab {
        case .forYou:
            loadForYouFeedIfNeeded()
        case .community:
            loadCommunityFeedIfNeeded()
        }
    }

    public func loadForYouFeedIfNeeded() {
        guard forYouViewModel == nil, !isLoadingForYou else { return }
        isLoadingForYou = true
        isUsingColorTestForYou = WMFDeveloperSettingsDataController.shared.isUsingColorTestForYou
        hiddenCardKeys = Set(dataController.hiddenCardKeys())

        if isUsingColorTestForYou {
            forYouViewModel = WMFForYouViewModel(response: .colorTest)
            refreshSavedStates()
            isLoadingForYou = false
            return
        }

        guard let language = selectedLanguage else {
            isLoadingForYou = false
            return
        }
        let project = WMFProject.wikipedia(language)
        Task {
            do {
                let response = try await dataController.fetchForYou(project: project)
                self.forYouViewModel = WMFForYouViewModel(response: response)
                self.refreshSavedStates()
            } catch {
                // TODO: surface error
            }
            self.isLoadingForYou = false
        }
    }

    // MARK: - Community

    public func refreshCommunityFeed() async {
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        do {
            let response = try await dataController.fetchCommunity(project: project, forceFetch: true)
            self.communityPages = [WMFHomeCommunityViewModel(response: response, project: project)]
        } catch {
            self.communityFeedError = error
        }
    }

    public func loadCommunityFeedIfNeeded() {
        guard communityPages.isEmpty, !isLoadingCommunity else { return }
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunity = true
        communityModuleVisibility = WMFCommunityModuleVisibility(
            featuredArticle: dataController.communityFeaturedArticleIsOn(),
            topRead: dataController.communityTopReadIsOn(),
            inTheNews: dataController.communityInTheNewsIsOn(),
            onThisDay: dataController.communityOnThisDayIsOn(),
            pictureOfDay: dataController.communityPictureOfTheDayIsOn()
        )
        hiddenCardKeys = Set(dataController.hiddenCardKeys())
        Task {
            do {
                let response = try await dataController.fetchCommunity(project: project)
                self.communityPages = [WMFHomeCommunityViewModel(response: response, project: project)]
            } catch {
                self.communityFeedError = error
            }
            self.isLoadingCommunity = false
        }
    }

    public func refreshCommunityModuleVisibility() {
        communityModuleVisibility = WMFCommunityModuleVisibility(
            featuredArticle: dataController.communityFeaturedArticleIsOn(),
            topRead: dataController.communityTopReadIsOn(),
            inTheNews: dataController.communityInTheNewsIsOn(),
            onThisDay: dataController.communityOnThisDayIsOn(),
            pictureOfDay: dataController.communityPictureOfTheDayIsOn()
        )
    }

    public func hideCard(key: String) {
        guard !hiddenCardKeys.contains(key) else { return }
        dataController.hideCard(key: key)
        withAnimation {
            hiddenCardKeys.insert(key)
            forYouViewModel?.hiddenCardKeys.insert(key)
        }
    }

    public func hideModule(_ module: WMFCommunityModule) {
        withAnimation {
            switch module {
            case .featuredArticle:
                dataController.setCommunityFeaturedArticleIsOn(false)
                communityModuleVisibility.featuredArticle = false
            case .topRead:
                dataController.setCommunityTopReadIsOn(false)
                communityModuleVisibility.topRead = false
            case .inTheNews:
                dataController.setCommunityInTheNewsIsOn(false)
                communityModuleVisibility.inTheNews = false
            case .onThisDay:
                dataController.setCommunityOnThisDayIsOn(false)
                communityModuleVisibility.onThisDay = false
            case .pictureOfDay:
                dataController.setCommunityPictureOfTheDayIsOn(false)
                communityModuleVisibility.pictureOfDay = false
            }
        }
    }

    public func loadCommunityPreviousPage() {
        guard !isLoadingCommunityPreviousPage else { return }
        guard let language = selectedLanguage else { return }
        let project = WMFProject.wikipedia(language)
        isLoadingCommunityPreviousPage = true
        Task {
            do {
                let response = try await dataController.fetchCommunityPreviousPage(project: project)
                self.communityPages.append(WMFHomeCommunityViewModel(response: response, project: project))
            } catch {
                self.communityFeedError = error
            }
            self.isLoadingCommunityPreviousPage = false
        }
    }

    // MARK: - Init

    public init(dataController: WMFHomeDataController = .shared, languages: [WMFLanguage] = [], selectedLanguage: WMFLanguage? = nil, didSelectLanguage: ((WMFLanguage) -> Void)? = nil, didTapEditLanguages: (() -> Void)? = nil) {
        self.dataController = dataController
        self.languages = languages
        self.selectedLanguage = selectedLanguage
        self.didSelectLanguage = didSelectLanguage
        self.didTapEditLanguages = didTapEditLanguages
        self.selectedTab = dataController.seeFirstContent() == .personalized ? .forYou : .community

        NotificationCenter.default.addObserver(self, selector: #selector(handleVisibilityChange), name: WMFNSNotification.communityModuleVisibilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleCoreDataStoreSetup), name: WMFNSNotification.coreDataStoreSetup, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForYouVisibilityChange), name: WMFNSNotification.forYouModuleVisibilityDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForYouInterestsDidChange), name: WMFNSNotification.forYouInterestsDidChange, object: nil)
    }

    // MARK: - Notification handlers

    @objc private func handleVisibilityChange() {
        refreshCommunityModuleVisibility()
    }

    @objc private func handleCoreDataStoreSetup() {
        loadCurrentTabFeedIfNeeded()
    }

    @objc private func handleForYouVisibilityChange() {
        refreshForYouModuleVisibility()
    }

    @objc private func handleForYouInterestsDidChange() {
        forYouViewModel = nil
        Task { await refreshForYouFeed() }
    }

    // MARK: - Helpers

    var languageButtonTitle: String {
        selectedLanguage?.languageCode.uppercased() ?? ""
    }
}
