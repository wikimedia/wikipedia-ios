import WMF
import CocoaLumberjackSwift
import WMFData
import WMFComponents

extension ArticleViewController {
    
    func showFundraisingCampaignAnnouncementIfNeeded() {
        
        // Tooltips might unintentionally suppress campaign modals
        guard !needsTooltips() else { return }
        
        guard let countryCode = Locale.current.region?.identifier,
           let wikimediaProject = WikimediaProject(siteURL: articleURL),
           let wmfProject = wikimediaProject.wmfProject else {
            return
        }
        
        let fundraisingDataController = WMFFundraisingCampaignDataController.shared
        
        Task {
            let isOptedIn = await fundraisingDataController.isOptedIn(project: wmfProject)
            
            guard let activeCampaignAsset = fundraisingDataController.loadActiveCampaignAsset(countryCode: countryCode, wmfProject: wmfProject, currentDate: .now) else {
                return
            }

            if !isOptedIn {
                if let project {
                    DonateFunnel.shared.logHiddenBanner(project: project, metricsID: activeCampaignAsset.metricsID)
                }
            }

            guard isOptedIn else {
                return
            }
            
            guard !userDonatedWithinLast250Days() else {
                return
            }
            

            willDisplayFundraisingBanner = true

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
        
        DonateFunnel.shared.logFundraisingCampaignModalImpression(project: project, metricsID: asset.metricsID)
        
        let dataController = WMFFundraisingCampaignDataController.shared
        
        let shouldShowMaybeLater = dataController.showShowMaybeLaterOption(asset: asset, currentDate: Date())

        wmf_showFundraisingAnnouncement(theme: theme, asset: asset, primaryButtonTapHandler: { [weak self] button, viewController in
            
            guard let self else {
                return
            }
            
            DonateFunnel.shared.logFundraisingCampaignModalDidTapDonate(project: project, metricsID: asset.metricsID)
            
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
            
        }, secondaryButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapMaybeLater(project: project, metricsID: asset.metricsID)
            
            if shouldShowMaybeLater {
                dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
                self.donateDidSetMaybeLater(metricsID: asset.metricsID)
            } else {
                DonateFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project, metricsID: asset.metricsID)
                self.donateAlreadyDonated()
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
            
        }, optionalButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project, metricsID: asset.metricsID)
            self.donateAlreadyDonated()
            dataController.markAssetAsPermanentlyHidden(asset: asset)
            
        }, footerLinkAction: { url in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapDonorPolicy(project: project, metricsID: asset.metricsID)
            self.navigate(to: url, useSafari: true)
        }, traceableDismissHandler: { action in
            
            if action == .tappedClose {
                DonateFunnel.shared.logFundraisingCampaignModalDidTapClose(project: project, metricsID: asset.metricsID)
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
        }, showMaybeLater: shouldShowMaybeLater)
    }

    func donateDidSetMaybeLater(metricsID: String) {
        
        let project = WikimediaProject(siteURL: articleURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-later-title", value: "We will remind you again tomorrow.", comment: "Title for toast shown when user clicks remind me later on fundraising banner")

            if let project {
                DonateFunnel.shared.logArticleDidSeeReminderToast(project: project, metricsID: metricsID)
            }
            
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: UIImage.init(systemName: "checkmark.circle.fill"), type: .custom, customTypeName: "watchlist-add-remove-success", duration: -1, dismissPreviousAlerts: true)
        }
    }

    func donateAlreadyDonated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-already-donated", value: "Thank you, dear donor! Your generosity helps keep Wikipedia and its and other free knowledge projects thriving.", comment: "Thank you toast shown when user clicks already donated on fundraising banner")

            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: UIImage.init(systemName: "checkmark.circle.fill"), type: .custom, customTypeName: "watchlist-add-remove-success", duration: -1, dismissPreviousAlerts: true)
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
