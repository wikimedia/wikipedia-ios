import WMF
import CocoaLumberjackSwift
import WMFData
import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {

    func showFundraisingCampaignAnnouncementIfNeeded(onNothingShown: (() -> Void)? = nil) {

        guard let countryCode = Locale.current.region?.identifier,
           let wikimediaProject = WikimediaProject(siteURL: articleURL),
           let wmfProject = wikimediaProject.wmfProject else {
            willDisplayCampaignModal = false
            onNothingShown?()
            return
        }

        let fundraisingDataController = WMFFundraisingCampaignDataController.shared
        let isForcingBannerForDevelopment = WMFDeveloperSettingsDataController.shared.forceFundraisingCampaignBanner

        Task {
            let isOptedIn = await fundraisingDataController.isOptedIn(project: wmfProject)

            guard let activeCampaignAsset = fundraisingDataController.loadActiveCampaignAsset(countryCode: countryCode, wmfProject: wmfProject, currentDate: .now) else {
                willDisplayCampaignModal = false
                onNothingShown?()
                return
            }

            if !isOptedIn {
                if let project {
                    DonateFunnel.shared.logHiddenBanner(project: project, metricsID: activeCampaignAsset.metricsID)
                }
            }

            let isFirstAppSession = UserDefaults.standard.wmf_appResignActiveDate() == nil
            let hasDonationReminderOutcome = WMFDeveloperSettingsDataController.shared.enableDonationReminder && WMFDonationReminderDataController.shared.loadReminder() != nil

            guard (isOptedIn && !userDonatedWithinLast250Days() && !isFirstAppSession && !hasDonationReminderOutcome) || isForcingBannerForDevelopment else {
                willDisplayCampaignModal = false
                onNothingShown?()
                return
            }


            willDisplayCampaignModal = true

            showNewDonateExperienceCampaignModal(asset: activeCampaignAsset, project: wikimediaProject)
        }
    }

    private func userDonatedWithinLast250Days() -> Bool {

        let donateDataController = WMFDonateDataController.shared

        let currentDate = Date()
        let twoFiftyDaysTimeInterval = TimeInterval(60*60*24*250)
        let twoFiftyDaysAgo = currentDate.addingTimeInterval(-twoFiftyDaysTimeInterval)
        let localDonationHistory = donateDataController.loadLocalDonationHistory(startDate: twoFiftyDaysAgo, endDate: Date())

        if let localDonationHistory,
           !localDonationHistory.isEmpty {
            return true
        }

        return false
    }

    private func showNewDonateExperienceCampaignModal(asset: WMFFundraisingCampaignConfig.WMFAsset, project: WikimediaProject) {

        if WMFDeveloperSettingsDataController.shared.enableDonationReminder {
            let experimentAssignment = try? WMFDonationReminderDataController.shared.assignExperimentIfNeeded(campaignID: asset.id, campaignCurrencyCode: asset.currencyCode)
            if let experimentAssignment {
                DonateFunnel.shared.logDonationReminderGroupAssigned(experimentAssignment, project: project)
                #if DEBUG
                showDebugExperimentAssignmentToast(experimentAssignment)
                #endif
            }
        }

        DonateFunnel.shared.logFundraisingCampaignModalImpression(project: project, metricsID: asset.metricsID)

        let dataController = WMFFundraisingCampaignDataController.shared

        let shouldShowMaybeLater = dataController.showShowMaybeLaterOption(asset: asset, currentDate: Date())

        wmf_showFundraisingAnnouncement(theme: theme, asset: asset, showMaybeLater: shouldShowMaybeLater, donateButtonTapHandler: { [weak self] button, viewController in

            guard let self else {
                return
            }

            if WMFDeveloperSettingsDataController.shared.enableDonationReminder {
                DonateFunnel.shared.logDonationReminderCampaignModalDidTapDonate(project: project, metricsID: asset.metricsID)
            } else {
                DonateFunnel.shared.logFundraisingCampaignModalDidTapDonate(project: project, metricsID: asset.metricsID)
            }

            guard let navigationController = self.navigationController,
            let globalPoint = button.superview?.convert(button.frame.origin, to: navigationController.view),
            let donateURL =  asset.actions[0].url else {
                return
            }

            let globalRect = CGRect(x: globalPoint.x, y: globalPoint.y, width: button.frame.width, height: button.frame.height)

            let getDonateButtonGlobalRect: () -> CGRect = { globalRect }

            let donateCoordinator = DonateCoordinator(navigationController: navigationController, source: .articleCampaignModal(articleURL, asset.metricsID, donateURL), dataStore: dataStore, theme: theme, navigationStyle: .dismissThenPush, setLoadingBlock: { isLoading in
                guard let fundraisingPanelVC = viewController as? FundraisingAnnouncementPanelViewController else {
                    return
                }

                fundraisingPanelVC.isLoading = isLoading
            }, getDonateButtonGlobalRect: getDonateButtonGlobalRect)

            self.donateCoordinator = donateCoordinator
            donateCoordinator.start()

            dataController.markAssetAsPermanentlyHidden(asset: asset)

        }, maybeLaterButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapMaybeLater(project: project, metricsID: asset.metricsID)
        }, alreadyDonatedButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project, metricsID: asset.metricsID)
            self.donateAlreadyDonated()
            dataController.markAssetAsPermanentlyHidden(asset: asset)
        }, footerLinkAction: { url in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapDonorPolicy(project: project, metricsID: asset.metricsID)
            self.navigate(to: url, useSafari: true)
        }, dismissHandler: { action in
            switch action {
            case .close:
                DonateFunnel.shared.logFundraisingCampaignModalDidTapClose(project: project, metricsID: asset.metricsID)
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            case .maybeLater:
                let experimentAssignment: WMFDonationReminderDataController.ExperimentAssignment?
                if WMFDeveloperSettingsDataController.shared.enableDonationReminder {
                    experimentAssignment = WMFDonationReminderDataController.shared.experimentAssignment
                } else {
                    experimentAssignment = nil
                }

                if let experimentAssignment,
                   experimentAssignment != .control,
                   let navigationController = self.navigationController {
                    let coordinator = DonationReminderSetupCoordinator(
                        navigationController: navigationController,
                        currencyCode: asset.currencyCode,
                        theme: self.theme,
                        origin: .banner
                    )
                    self.donationReminderSetupCoordinator = coordinator
                    coordinator.start()
                } else {
                    dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
                    self.donateDidSetMaybeLater(metricsID: asset.metricsID)
                }
            case .donate, .alreadyDonated, .other:
                break
            }
        })
    }

    #if DEBUG
    private func showDebugExperimentAssignmentToast(_ experimentAssignment: WMFDonationReminderDataController.ExperimentAssignment) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            WMFToastManager.sharedInstance.showRichToast("[Debug] Experiment group: \(experimentAssignment.rawValue)", dismissPreviousToasts: false)
        }
    }
    #endif

    func donateDidSetMaybeLater(metricsID: String) {

        let project = WikimediaProject(siteURL: articleURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-later-title", value: "We will remind you again tomorrow.", comment: "Title for toast shown when user clicks remind me later on fundraising banner")

            if let project {
                if WMFDeveloperSettingsDataController.shared.enableDonationReminder {
                    DonateFunnel.shared.logDonationReminderMaybeLaterToastImpression(project: project, metricsID: metricsID)
                } else {
                    DonateFunnel.shared.logArticleDidSeeReminderToast(project: project, metricsID: metricsID)
                }
            }

            WMFToastManager.sharedInstance.showRichToast(title, subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill), duration: nil, dismissPreviousToasts: true)
        }
    }

    func donateAlreadyDonated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-already-donated", value: "Thank you, dear donor! Your generosity helps keep Wikipedia and its and other free knowledge projects thriving.", comment: "Thank you toast shown when user clicks already donated on fundraising banner")

            WMFToastManager.sharedInstance.showRichToast(title, subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill), duration: nil, dismissPreviousToasts: true)
        }
    }

    func needsYearInReviewAnnouncement() -> Bool {

        if UIDevice.current.userInterfaceIdiom == .pad && (navigationController?.navigationBar.isHidden ?? false) {
            return false
        }

        guard let yirDataController = try? WMFYearInReviewDataController() else {
            return false
        }

        guard yirDataController.shouldShowYearInReviewFeatureAnnouncement() else {
            return false
        }

        return true
    }

    func presentYearInReviewAnnouncement() {

        guard let yirDataController = try? WMFYearInReviewDataController() else {
            return
        }

        yirCoordinator?.setupForFeatureAnnouncement(introSlideLoggingID: "article_prompt")
        self.yirCoordinator?.start()
        yirDataController.hasPresentedYiRFeatureAnnouncementModel = true

    }
}

extension WMFFundraisingCampaignConfig.WMFAsset {
    var metricsID: String {
        if let assetID {
            return "\(languageCode)\(countryCode)_\(id)_\(assetID)_iOS"
        } else {
            return "\(languageCode)\(countryCode)_\(id)_iOS"
        }
    }
}

extension ArticleViewController: WMFFeatureAnnouncing { }
