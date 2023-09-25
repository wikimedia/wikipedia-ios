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
    
    private func showNewDonateExperienceCampaignModal(asset: WKFundraisingCampaignConfig.WKAsset) {
        
        // Just using alert view for now, will replace with new campaign modal
        let alert = UIAlertController(title: nil, message: asset.textHtml, preferredStyle: .alert)
        let controller = WKFundraisingCampaignDataController()
        
        let firstAction = asset.actions[0]
        let donateAction = UIAlertAction(title: firstAction.title, style: .default, handler: { [weak self] action in
            controller.markAssetAsPermanentlyHidden(asset: asset)
            self?.pushToDonateForm(donateURL: firstAction.url)
        })
        
        let maybeLaterAction = UIAlertAction(title: asset.actions[1].title, style: .default) { action in
            controller.markAssetAsMaybeLater(asset: asset, currentDate: .now)
        }
        
        let alreadyDonatedAction = UIAlertAction(title: asset.actions[2].title, style: .default) { action in
            
            controller.markAssetAsPermanentlyHidden(asset: asset)
            
            // todo: donate reason action sheet
        }
        
        let closeAction = UIAlertAction(title: "Close", style: .cancel) { action in
            let controller = WKFundraisingCampaignDataController()
            controller.markAssetAsPermanentlyHidden(asset: asset)
        }
        
        alert.addAction(donateAction)
        alert.addAction(maybeLaterAction)
        alert.addAction(alreadyDonatedAction)
        alert.addAction(closeAction)
        
        present(alert, animated: true)
    }
    
    private func pushToDonateForm(donateURL: URL?) {
        if canOfferNativeDonateForm(), let donateURL = donateURL {
            presentNewDonorExperiencePaymentMethodActionSheet(donateURL: donateURL)
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
