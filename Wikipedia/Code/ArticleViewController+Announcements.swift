import WMF
import CocoaLumberjackSwift
import WKData
import Components

extension ArticleViewController {
    
    func showAnnouncementIfNeeded() {
        
        let dataController = WKFundraisingCampaignDataController()
        
        // New Donor Experience if they qualify
        if let countryCode = Locale.current.regionCode,
           let wkProject = WikimediaProject(siteURL: articleURL)?.wkProject,
           dataController.hasActivelyRunningCampaigns(countryCode: countryCode, currentDate: .now),
           let activeCampaignAsset = WKFundraisingCampaignDataController().loadActiveCampaignAsset(countryCode: countryCode, wkProject: wkProject, currentDate: .now) {
            showNewDonateExperienceCampaignModal(asset: activeCampaignAsset)
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
    
    private func showNewDonateExperienceCampaignModal(asset: WKFundraisingCampaignConfig.WKAsset) {

        let dataController = WKFundraisingCampaignDataController()

        let shouldShowMaybeLater = dataController.showShowMaybeLaterOption(asset: asset, currentDate: Date())

        let dismiss = {
            dataController.markAssetAsPermanentlyHidden(asset: asset)
        }

        wmf_showFundraisingAnnouncement(theme: theme, asset: asset, primaryButtonTapHandler: { sender in
            if let url = asset.actions[0].url {
                self.navigate(to: url, useSafari: false)
            }
            dismiss()
        }, secondaryButtonTapHandler: { sender in
            if shouldShowMaybeLater {
                dataController.markAssetAsMaybeLater(asset: asset, currentDate: Date())
            }
            self.sharedDonateDidSetMaybeLater()
        }, optionalButtonTapHandler: { sender in
            self.sharedDonateAlreadyDonated()
            dismiss()
        }, footerLinkAction: { url in
            self.navigate(to: url, useSafari: false)
        }, traceableDismissHandler: { _ in
            dismiss()

        }, showMaybeLater: shouldShowMaybeLater)
    }


    private func pushToDonateForm(asset: WKFundraisingCampaignConfig.WKAsset) {
        let firstAction = asset.actions[0]
        let donateURL = firstAction.url
        
        if canOfferNativeDonateForm(countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode),
           let donateURL = donateURL {
            presentNewDonorExperiencePaymentMethodActionSheet(countryCode: asset.countryCode, currencyCode: asset.currencyCode, languageCode: asset.languageCode, donateURL: donateURL)
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
        sharedDonateDidSuccessfullSubmitPayment()
    }
}
