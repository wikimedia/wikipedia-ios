import WMF
import CocoaLumberjackSwift
import WKData
import Components

extension ArticleViewController {
    
    func showAnnouncementIfNeeded() {
        
        let dataController = WKFundraisingCampaignDataController()
        
        // New Donor Experience if they qualify
        if let countryCode = Locale.current.regionCode,
           let wikimediaProject = WikimediaProject(siteURL: articleURL),
           let wkProject = wikimediaProject.wkProject,
           dataController.hasActivelyRunningCampaigns(countryCode: countryCode, currentDate: .now),
           let activeCampaignAsset = WKFundraisingCampaignDataController().loadActiveCampaignAsset(countryCode: countryCode, wkProject: wkProject, currentDate: .now) {
            showNewDonateExperienceCampaignModal(asset: activeCampaignAsset, project: wikimediaProject)
            return
        }

        guard (isInValidSurveyCampaignAndArticleList && userHasSeenSurveyPrompt) || !isInValidSurveyCampaignAndArticleList else {
            return
        }
        let predicate = NSPredicate(format: "placement == 'article' && isVisible == YES")
        let contentGroups = dataStore.viewContext.orderedGroups(of: .announcement, with: predicate)
        let currentDate = Date()
        
        // get the first content group with a valid date
        let contentGroup = contentGroups?.first(where: { (group) -> Bool in
            guard group.contentType == .announcement,
                  let announcement = group.contentPreview as? WMFAnnouncement,
                  let startDate = announcement.startTime,
                  let endDate = announcement.endTime
                  else {
                return false
            }
            
            return (startDate...endDate).contains(currentDate)
        })
        
        guard
            !isBeingPresentedAsPeek,
            let contentGroupURL = contentGroup?.url,
            let announcement = contentGroup?.contentPreview as? WMFAnnouncement,
            let actionURL = announcement.actionURL
        else {
            return
        }
        
        let dismiss = {
            // re-fetch since time has elapsed
            let contentGroup = self.dataStore.viewContext.contentGroup(for: contentGroupURL)
            contentGroup?.markDismissed()
            contentGroup?.updateVisibilityForUserIsLogged(in: self.session.isAuthenticated)
            do {
                try self.dataStore.viewContext.save()
            } catch let saveError {
                DDLogError("Error saving after marking article announcement as dismissed: \(saveError)")
            }
        }
        
        guard !articleURL.isThankYouDonationURL else {
            dismiss()
            return
        }

        wmf_showAnnouncementPanel(announcement: announcement, primaryButtonTapHandler: { (sender) in
            self.navigate(to: actionURL, useSafari: true)
            // dismiss handler is called
        }, secondaryButtonTapHandler: { (sender) in
            // dismiss handler is called
        }, footerLinkAction: { (url) in
             self.navigate(to: url, useSafari: true)
            // intentionally don't dismiss
        }, traceableDismissHandler: { _ in
            dismiss()
        }, theme: theme)
    }
    
    private func showNewDonateExperienceCampaignModal(asset: WKFundraisingCampaignConfig.WKAsset, project: WikimediaProject) {
        
        AppInteractionFunnel.shared.logFundraisingCampaignModalImpression(project: project)
        
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
        
        var utmSource: String? = nil
        if let donateURL = firstAction.url,
           let queryItems = URLComponents(url: donateURL, resolvingAgainstBaseURL: false)?.queryItems {
            for queryItem in queryItems {
                if queryItem.name == "utm_source" {
                    utmSource = queryItem.value
                }
            }
        }
        
        let appVersion = Bundle.main.wmf_debugVersion()
        
        if canOfferNativeDonateForm(countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, bannerID: utmSource, appVersion: appVersion),
           let donateURL = donateURL {
            presentNewDonorExperiencePaymentMethodActionSheet(donateSource: .articleCampaignModal, countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, donateURL: donateURL, bannerID: utmSource, appVersion: appVersion, articleURL: articleURL, sourceView: sourceView, loggingDelegate: self)
        } else {
            self.navigate(to: donateURL, userInfo: [
                RoutingUserInfoKeys.campaignArticleURL: articleURL as Any,
                RoutingUserInfoKeys.campaignBannerID: utmSource as Any
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
    
    func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, presetIsSelected: Bool, recurringMonthlyIsSelected: Bool, donorEmail: String?, bannerID: String?) {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL) else {
            return
        }
        
        sharedLogDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: amount, presetIsSelected: presetIsSelected, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail, project: wikimediaProject, bannerID: bannerID)
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
