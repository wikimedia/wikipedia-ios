import WMF


extension ArticleViewController {
    func showAnnouncementIfNeeded() {
        guard UserDefaults.standard.shouldCheckForArticleAnnouncements else {
            return
        }
        let predicate = NSPredicate(format: "placement == %@", "article")
        let contentGroup = dataStore.viewContext.newestVisibleGroup(of: .announcement, with: predicate)
        guard
            let announcement = contentGroup?.contentPreview as? WMFAnnouncement,
            let actionURL = announcement.actionURL
        else {
            UserDefaults.standard.shouldCheckForArticleAnnouncements = false
            return
        }
        let dismiss = {
            UserDefaults.standard.shouldCheckForArticleAnnouncements = false
            contentGroup?.markDismissed()
            contentGroup?.updateVisibilityForUserIsLogged(in: self.session.isAuthenticated)
            do {
                try self.dataStore.viewContext.save()
            } catch let saveError {
                DDLogError("Error saving after marking article announcement as dismissed: \(saveError)")
            }
        }
        let context = FeedFunnelContext(contentGroup)
        FeedFunnel.shared.logFeedImpression(for: context)
        wmf_showAnnouncementPanel(announcement: announcement, primaryButtonTapHandler: { (sender) in
            self.navigate(to: actionURL, useSafari: true)
            dismiss()
        }, secondaryButtonTapHandler: { (sender) in
            dismiss()
        }, footerLinkAction: { (url) in
             self.navigate(to: url, useSafari: true)
        }, dismissHandler: {
            dismiss()
        }, theme: theme)
    }
}
