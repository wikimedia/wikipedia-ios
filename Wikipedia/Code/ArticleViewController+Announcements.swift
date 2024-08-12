import WMF
import CocoaLumberjackSwift
import WMFData
import WMFComponents

extension ArticleViewController {
    
    func showAnnouncementIfNeeded() {
        
        guard let countryCode = Locale.current.regionCode,
           let wikimediaProject = WikimediaProject(siteURL: articleURL),
           let wmfProject = wikimediaProject.wmfProject else {
            return
        }
        
        let dataController = WMFFundraisingCampaignDataController.shared
        
        Task {
            let isOptedIn = await dataController.isOptedIn(project: wmfProject)
            
            guard isOptedIn,
            let activeCampaignAsset = dataController.loadActiveCampaignAsset(countryCode: countryCode, wmfProject: wmfProject, currentDate: .now) else {
                return
            }
            
            showNewDonateExperienceCampaignModal(asset: activeCampaignAsset, project: wikimediaProject)
        }
    }
    
    private func showNewDonateExperienceCampaignModal(asset: WMFFundraisingCampaignConfig.WMFAsset, project: WikimediaProject) {
        
        DonateFunnel.shared.logFundraisingCampaignModalImpression(project: project, metricsID: asset.metricsID)
        
        let dataController = WMFFundraisingCampaignDataController.shared
        
        let shouldShowMaybeLater = dataController.showShowMaybeLaterOption(asset: asset, currentDate: Date())
        
        wmf_showFundraisingAnnouncement(theme: theme, asset: asset, primaryButtonTapHandler: { button, _ in
            
            DonateFunnel.shared.logFundraisingCampaignModalDidTapDonate(project: project, campaignID: asset.utmSource)
            self.pushToDonateForm(asset: asset, sourceView: button)
            dataController.markAssetAsPermanentlyHidden(asset: asset)
            
        }, secondaryButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapMaybeLater(project: project, campaignID: asset.utmSource)
            
            
            if shouldShowMaybeLater {
                dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
                self.donateDidSetMaybeLater()
            } else {
                DonateFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project, campaignID: asset.utmSource)
                self.donateAlreadyDonated()
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
            
        }, optionalButtonTapHandler: { _, _ in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project, campaignID: asset.utmSource)
            self.donateAlreadyDonated()
            dataController.markAssetAsPermanentlyHidden(asset: asset)
            
        }, footerLinkAction: { url in
            DonateFunnel.shared.logFundraisingCampaignModalDidTapDonorPolicy(project: project)
            self.navigate(to: url, useSafari: true)
        }, traceableDismissHandler: { action in
            
            if action == .tappedClose {
                DonateFunnel.shared.logFundraisingCampaignModalDidTapClose(project: project, campaignID: asset.utmSource)
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
        }, showMaybeLater: shouldShowMaybeLater)
    }

    private func pushToDonateForm(asset: WMFFundraisingCampaignConfig.WMFAsset, sourceView: UIView?) {
        let firstAction = asset.actions[0]
        
        let utmSource = asset.utmSource
        let metricsID = asset.metricsID

        let appVersion = Bundle.main.wmf_debugVersion()
        let donateURL = firstAction.url?.appendingAppVersion(appVersion: appVersion)

        if canOfferNativeDonateForm(countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, bannerID: utmSource, metricsID: metricsID, appVersion: appVersion),
           let donateURL = donateURL {
            presentNewDonorExperiencePaymentMethodActionSheet(donateSource: .articleCampaignModal, countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, donateURL: donateURL, bannerID: utmSource, metricsID: metricsID, appVersion: appVersion, articleURL: articleURL, sourceView: sourceView, loggingDelegate: self)
        } else {
            self.navigate(to: donateURL, userInfo: [
                RoutingUserInfoKeys.campaignArticleURL: articleURL as Any,
                RoutingUserInfoKeys.campaignMetricsID: metricsID as Any
            ], useSafari: false)
        }
    }

    func donateDidSetMaybeLater() {
        
        let project = WikimediaProject(siteURL: articleURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-later-title", value: "We will remind you again tomorrow.", comment: "Title for toast shown when user clicks remind me later on fundraising banner")

            if let project {
                DonateFunnel.shared.logArticleDidSeeReminderToast(project: project)
            }
            
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: UIImage.init(systemName: "checkmark.circle.fill"), type: .custom, customTypeName: "watchlist-add-remove-success", duration: -1, dismissPreviousAlerts: true)
        }
    }

    func donateAlreadyDonated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let title = WMFLocalizedString("donate-already-donated", value: "Thank you, dear donor! Your generosity helps keep Wikipedia and its sister sites thriving.", comment: "Thank you toast shown when user clicks already donated on fundraising banner")

            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: UIImage.init(systemName: "checkmark.circle.fill"), type: .custom, customTypeName: "watchlist-add-remove-success", duration: -1, dismissPreviousAlerts: true)
        }
    }
}

extension ArticleViewController: WMFDonateDelegate {
    public func donateDidTapProblemsDonatingLink() {
        sharedDonateDidTapProblemsDonatingLink()
    }
    
    public func donateDidTapOtherWaysToGive() {
        sharedDonateDidTapOtherWaysToGive()
    }
    
    public func donateDidTapFrequentlyAskedQuestions() {
        sharedDonateDidTapFrequentlyAskedQuestions()
    }
    
    public func donateDidTapTaxDeductibilityInformation() {
        sharedDonateDidTapTaxDeductibilityInformation()
    }
    
    public func donateDidSuccessfullySubmitPayment() {
        sharedDonateDidSuccessfullSubmitPayment(source: .articleCampaignModal, articleURL: articleURL)
    }
}

extension ArticleViewController: WMFDonateLoggingDelegate {
    
    func logDonateFormDidAppear() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormDidAppear(project: wikimediaProject)
    }
    
    func logDonateFormUserDidTriggerError(error: Error) {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTriggerError(error: error, project: wikimediaProject)
    }
    
    func logDonateFormUserDidTapAmountPresetButton() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapAmountPresetButton(project: wikimediaProject)
    }
    
    func logDonateFormUserDidEnterAmountInTextfield() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidEnterAmountInTextfield(project: wikimediaProject)
    }
    
    func logDonateFormUserDidTapApplePayButton(transactionFeeIsSelected: Bool, recurringMonthlyIsSelected: Bool, emailOptInIsSelected: NSNumber?) {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapApplePayButton(transactionFeeIsSelected: transactionFeeIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, emailOptInIsSelected: emailOptInIsSelected?.boolValue, project: wikimediaProject)
    }
    
    func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, metricsID: String?) {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: amount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail, project: wikimediaProject, metricsID: metricsID)
    }
    
    func logDonateFormUserDidTapProblemsDonatingLink() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapProblemsDonatingLink(project: wikimediaProject)
    }
    
    func logDonateFormUserDidTapOtherWaysToGiveLink() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapOtherWaysToGiveLink(project: wikimediaProject)
    }
    
    func logDonateFormUserDidTapFAQLink() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapFAQLink(project: wikimediaProject)
    }
    
    func logDonateFormUserDidTapTaxInfoLink() {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidTapTaxInfoLink(project: wikimediaProject)
    }
    
    
}

extension WMFFundraisingCampaignConfig.WMFAsset {
    
    var utmSource: String? {
        
        guard actions.count > 0 else {
            return nil
        }
        
        let firstAction = actions[0]
        var utmSource: String? = nil
        if let donateURL = firstAction.url,
           let queryItems = URLComponents(url: donateURL, resolvingAgainstBaseURL: false)?.queryItems {
            for queryItem in queryItems {
                if queryItem.name == "utm_source" {
                    utmSource = queryItem.value
                }
            }
        }
        
        return utmSource
    }
    
    var metricsID: String {
        return "\(languageCode)\(id)_iOS"
    }
}

fileprivate extension URL {
    func appendingAppVersion(appVersion: String?) -> URL {
        
        guard let appVersion,
              var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
        var queryItems = components.queryItems else {
            return self
        }
        
        
        queryItems.append(URLQueryItem(name: "app_version", value: appVersion))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return self
        }
        
        return url
    }
}
