import Foundation
import WMFData

extension WMFAnnouncementsContentSource {
    @objc func fetchMediaWikiBannerOptInForSiteURL(_ siteURL: URL) {
        let dataController = WMFFundraisingCampaignDataController.shared
        let wikimediaProject = WikimediaProject(siteURL: siteURL)
        guard let wmfProject = wikimediaProject?.wmfProject else {
            return
        }
        
        dataController.fetchMediaWikiBannerOptIn(project: wmfProject)
        
    }
}
