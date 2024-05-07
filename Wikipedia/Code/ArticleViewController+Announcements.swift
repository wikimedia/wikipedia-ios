import WMF
import CocoaLumberjackSwift
import WKData
import Components

extension ArticleViewController {
    
    func showAnnouncementIfNeeded() {
        
        // New Donor Experience
        if let countryCode = Locale.current.regionCode,
           let wikimediaProject = WikimediaProject(siteURL: articleURL),
           let wkProject = wikimediaProject.wkProject,
           let activeCampaignAsset = WKFundraisingCampaignDataController().loadActiveCampaignAsset(countryCode: countryCode, wkProject: wkProject, currentDate: .now) {
            showNewDonateExperienceCampaignModal(asset: activeCampaignAsset, project: wikimediaProject)
            return
        }
    }
    
    private func showNewDonateExperienceCampaignModal(asset: WKFundraisingCampaignConfig.WKAsset, project: WikimediaProject) {
        
        AppInteractionFunnel.shared.logFundraisingCampaignModalImpression(project: project, metricsID: asset.metricsID)
        
        let dataController = WKFundraisingCampaignDataController()
        
        let shouldShowMaybeLater = dataController.showShowMaybeLaterOption(asset: asset, currentDate: Date())
        
        wmf_showFundraisingAnnouncement(theme: theme, asset: asset, primaryButtonTapHandler: { sender in
            
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapDonate(project: project)
            self.pushToDonateForm(asset: asset, sourceView: sender as? UIButton)
            dataController.markAssetAsPermanentlyHidden(asset: asset)
            
        }, secondaryButtonTapHandler: { sender in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapMaybeLater(project: project)
            
            
            if shouldShowMaybeLater {
                dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
                self.donateDidSetMaybeLater()
            } else {
                AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project)
                self.donateAlreadyDonated()
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
            
        }, optionalButtonTapHandler: { sender in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project)
            self.donateAlreadyDonated()
            dataController.markAssetAsPermanentlyHidden(asset: asset)
            
        }, footerLinkAction: { url in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapDonorPolicy(project: project)
            self.navigate(to: url, useSafari: true)
        }, traceableDismissHandler: { action in
            
            if action == .tappedClose {
                AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapClose(project: project)
                dataController.markAssetAsPermanentlyHidden(asset: asset)
            }
        }, showMaybeLater: shouldShowMaybeLater)
    }

    private func pushToDonateForm(asset: WKFundraisingCampaignConfig.WKAsset, sourceView: UIView?) {
        let firstAction = asset.actions[0]
        let donateURL = firstAction.url
        
        let utmSource = asset.utmSource
        let metricsID = asset.metricsID
        
        let appVersion = Bundle.main.wmf_debugVersion()
        
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
                AppInteractionFunnel.shared.logArticleDidSeeReminderToast(project: project)
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

extension ArticleViewController: WKDonateDelegate {
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

extension ArticleViewController: WKDonateLoggingDelegate {
    
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

extension WKFundraisingCampaignConfig.WKAsset {
    
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
