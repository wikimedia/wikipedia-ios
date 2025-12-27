import Foundation
import WMFData

extension WMFAnnouncementsContentSource {
    @objc func fetchMediaWikiBannerOptInForSiteURL(_ siteURL: URL) {
        let dataController = WMFFundraisingCampaignDataControllerObjCBridge.shared
        let wikimediaProject = WikimediaProject(siteURL: siteURL)
        guard let wmfProject = wikimediaProject?.wmfProject else {
            return
        }
        
        dataController.fetchMediaWikiBannerOptIn(project: wmfProject, completion: {_ in })
        
    }
}
