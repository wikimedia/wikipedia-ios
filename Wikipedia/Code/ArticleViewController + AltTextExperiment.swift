import WMFComponents
import WMF
import CocoaLumberjackSwift
import WMFData

// MARK: - ArticleViewController + AltTextExperiment

extension ArticleViewController {
    func setup() {
        if let altTextExperimentViewModel {
            self.navigationItem.titleView = nil
            self.title = altTextExperimentViewModel.localizedStrings.articleNavigationBarTitle

            let rightBarButtonItem =
                UIBarButtonItem(
                    image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle),
                    primaryAction: nil,
                    menu: overflowMenu
                )
            navigationItem.rightBarButtonItem = rightBarButtonItem
            rightBarButtonItem.tintColor = theme.colors.link

            self.navigationBar.updateNavigationItems()
        } else {
            setupWButton()
            setupSearchButton()
        }
        
        addNotificationHandlers()
        setupWebView()
        setupMessagingController()
    }

    private var overflowMenu: UIMenu {
        let learnMore = UIAction(title: CommonStrings.learnMoreTitle(), image: WMFSFSymbolIcon.for(symbol: .infoCircle), handler: { [weak self] _ in
            if let project = self?.project {
                EditInteractionFunnel.shared.logAltTextEditingInterfaceOverflowLearnMore(project: project)
            }
            self?.goToFAQ()
        })
        
        let tutorial = UIAction(title: CommonStrings.tutorialTitle, image: WMFSFSymbolIcon.for(symbol: .lightbulbMin), handler: { [weak self] _ in
            if let project = self?.project {
                EditInteractionFunnel.shared.logAltTextEditingInterfaceOverflowTutorial(project: project)
            }
            self?.showTutorial()
        })

        let reportIssues = UIAction(title: CommonStrings.problemWithFeatureTitle, image: WMFSFSymbolIcon.for(symbol: .flag), handler: { [weak self] _ in
            if let project = self?.project {
                EditInteractionFunnel.shared.logAltTextEditingInterfaceOverflowReport(project: project)
            }
            self?.reportIssue()
        })

        let menuItems: [UIMenuElement] = [learnMore, tutorial, reportIssues]

        return UIMenu(title: String(), children: menuItems)
    }

    private func goToFAQ() {
        if let altTextExperimentViewModel {
            isReturningFromFAQ = true
            navigate(to: altTextExperimentViewModel.learnMoreURL, useSafari: false)
        }
    }

    private func showTutorial() {
        presentAltTextTooltipsIfNecessary(force: true)
    }

    private func reportIssue() {
        let emailAddress = "ios-support@wikimedia.org"
        let emailSubject = WMFLocalizedString("alt-text-email-title", value: "Issue Report - Alt Text Feature", comment: "Title text for Alt Text pre-filled issue report email")
        let emailBodyLine1 = WMFLocalizedString("alt-text-email-first-line", value: "I've encountered a problem with the Alt Text feature:", comment: "Text for Alt Text pre-filled issue report email")
        let emailBodyLine2 = WMFLocalizedString("alt-text-email-second-line", value: "- [Describe specific problem]", comment: "Text for Alt Text pre-filled issue report email. This text is intended to be replaced by the user with a description of the problem they are encountering")
        let emailBodyLine3 = WMFLocalizedString("alt-text-email-third-line", value: "The behavior I would like to see is:", comment: "Text for Alt Text pre-filled issue report email")
        let emailBodyLine4 = WMFLocalizedString("alt-text-email-fourth-line", value: "- [Describe proposed solution]", comment: "Text for Alt Text pre-filled issue report email. This text is intended to be replaced by the user with a description of a user suggested solution")
        let emailBodyLine5 = WMFLocalizedString("alt-text-email-fifth-line", value: "[Screenshots or Links]", comment: "Text for Alt Text pre-filled issue report email. This text is intended to be replaced by the user with a screenshot or link.")
        let emailBody = "\(emailBodyLine1)\n\n\(emailBodyLine2)\n\n\(emailBodyLine3)\n\n\(emailBodyLine4)\n\n\(emailBodyLine5)"
        let mailto = "mailto:\(emailAddress)?subject=\(emailSubject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let encodedMailto = mailto, let mailtoURL = URL(string: encodedMailto), UIApplication.shared.canOpenURL(mailtoURL) else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(CommonStrings.noEmailClient, sticky: false, dismissPreviousAlerts: false)
            return
        }
        UIApplication.shared.open(mailtoURL)
    }
}
