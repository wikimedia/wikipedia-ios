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
            self.navigate(to: actionURL, useSafari: false)
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

        let dismiss = {
            dataController.markAssetAsPermanentlyHidden(asset: asset)
        }

        wmf_showFundraisingAnnouncement(theme: theme, object: asset, primaryButtonTapHandler: { [weak self] sender in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapDonate(project: project)
            
            self?.pushToDonateForm(asset: asset)
        }, secondaryButtonTapHandler: { sender in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapMaybeLater(project: project)
            
            if shouldShowMaybeLater {
                dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
            }
            dismiss()
            
            // TODO: Display "We will remind you again tomorrow" toast, and log this with it
            // AppInteractionFunnel.shared.logArticleDidSeeReminderToast(project: project)
        }, optionalButtonTapHandler: { sender in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapAlreadyDonated(project: project)
            
            dismiss()
        }, footerLinkAction: { url in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapDonorPolicy(project: project)
            
            self.navigate(to: url, useSafari: false)
        }, traceableDismissHandler: { _ in
            AppInteractionFunnel.shared.logFundraisingCampaignModalDidTapClose(project: project)
            
            dismiss()
        }, showMaybeLater: shouldShowMaybeLater)
    }


    private func pushToDonateForm(asset: WKFundraisingCampaignConfig.WKAsset) {
        let firstAction = asset.actions[0]
        let donateURL = firstAction.url
        
        if canOfferNativeDonateForm(countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode),
           let donateURL = donateURL {
            presentNewDonorExperiencePaymentMethodActionSheet(source: DonateSource.article, countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, donateURL: donateURL, articleURL: articleURL, loggingDelegate: self)
        } else {
            self.navigate(to: donateURL, useSafari: false)
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
        sharedDonateDidSuccessfullSubmitPayment(source: .article, articleURL: articleURL)
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
    
    func logDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: Decimal, recurringMonthlyIsSelected: Bool, donorEmail: String?) {
        guard let wikimediaProject = WikimediaProject(siteURL: articleURL),
              let wkProject = wikimediaProject.wkProject,
        let countryCode = Locale.current.regionCode else {
            return
        }
        
        let activeCampaignID = WKFundraisingCampaignDataController().loadActiveCampaignAsset(countryCode: countryCode, wkProject: wkProject, currentDate: .now)?.id
        
        sharedLogDonateFormUserDidAuthorizeApplePayPaymentSheet(amount: amount, recurringMonthlyIsSelected: recurringMonthlyIsSelected, donorEmail: donorEmail, campaignID: activeCampaignID, project: wikimediaProject)
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
