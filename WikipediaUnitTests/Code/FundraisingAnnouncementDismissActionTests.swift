import Testing
@testable import Wikipedia

struct FundraisingAnnouncementDismissActionTests {

    @Test
    func secondaryButtonMapsToMaybeLaterWhenMaybeLaterIsShown() {
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedSecondary, showMaybeLater: true) == .maybeLater)
    }

    @Test
    func secondaryButtonMapsToAlreadyDonatedOnCampaignLastDay() {
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedSecondary, showMaybeLater: false) == .alreadyDonated)
    }

    @Test(arguments: [true, false])
    func remainingActionsMapIndependentlyOfMaybeLater(showMaybeLater: Bool) {
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedPrimary, showMaybeLater: showMaybeLater) == .donate)
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedOptional, showMaybeLater: showMaybeLater) == .alreadyDonated)
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedClose, showMaybeLater: showMaybeLater) == .close)
        #expect(FundraisingAnnouncementDismissAction(lastAction: .tappedBackground, showMaybeLater: showMaybeLater) == .other)
        #expect(FundraisingAnnouncementDismissAction(lastAction: ScrollableEducationPanelViewController.LastAction.none, showMaybeLater: showMaybeLater) == .other)
    }
}
