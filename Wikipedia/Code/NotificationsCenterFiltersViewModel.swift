
import Foundation
import WMF

struct NotificationsCenterFiltersViewModel {
    
    struct SectionViewModel {
        let title: String
        let items: [ItemViewModel]
    }
    
    struct ItemViewModel {
        
        enum SelectionType {
            case checkmark
            case toggle
        }
        
        let title: String
        let selectionType: SelectionType
        let isSelected: Bool
        //todo: must be one or the other. clean up.
        let readStatus: RemoteNotificationsFiltersSavedState.ReadStatus?
        let type: RemoteNotificationType?
    }
    
    let sections: [SectionViewModel]
    let remoteNotificationsController: RemoteNotificationsController
 
    init(remoteNotificationsController: RemoteNotificationsController) {
     
        self.remoteNotificationsController = remoteNotificationsController
        
        let savedState = remoteNotificationsController.filterSavedState
        let items1 = RemoteNotificationsFiltersSavedState.ReadStatus.allCases.map {
            
            return ItemViewModel(title: $0.title, selectionType: .checkmark, isSelected: $0 == savedState.readStatusSetting, readStatus: $0, type: nil)
            
        }
        
        let section1 = SectionViewModel(title: "Read Status", items: items1)
        
        let items2: [ItemViewModel] = RemoteNotificationType.orderingForFilters.map {
            
            let isSelected = savedState.filterTypeSetting.contains($0)
            return ItemViewModel(title: $0.title, selectionType:.toggle, isSelected: isSelected, readStatus: nil, type: $0)
            
        }
        
        let section2 = SectionViewModel(title: "Types of notifications", items: items2)
        
        self.sections = [section1, section2]
    }
    
    func setFilterReadStatus(newReadStatus: RemoteNotificationsFiltersSavedState.ReadStatus, languageLinkController: MWKLanguageLinkController, completion: @escaping () -> Void) {
        
        let currentSavedState = remoteNotificationsController.filterSavedState
        //get current list of wikis
        remoteNotificationsController.listAllProjectsFromLocalNotifications(languageLinkController: languageLinkController) { projects in
            let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: newReadStatus, filterTypeSetting: currentSavedState.filterTypeSetting, projectsSetting: projects)
            remoteNotificationsController.filterSavedState = newSavedState
            completion()
        }
    }
    
    func appendFilterType(_ type: RemoteNotificationType, languageLinkController: MWKLanguageLinkController, completion: @escaping () -> Void) {
        let currentSavedState = remoteNotificationsController.filterSavedState
        var newFilterTypeSetting = currentSavedState.filterTypeSetting
        newFilterTypeSetting.append(type)
        
        remoteNotificationsController.listAllProjectsFromLocalNotifications(languageLinkController: languageLinkController) { projects in
            let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: newFilterTypeSetting, projectsSetting: projects)
            remoteNotificationsController.filterSavedState = newSavedState
            completion()
        }
    }
    
    func removeFilterType(_ type: RemoteNotificationType, languageLinkController: MWKLanguageLinkController, completion: @escaping () -> Void) {
        let currentSavedState = remoteNotificationsController.filterSavedState
        var newFilterTypeSetting = currentSavedState.filterTypeSetting
        newFilterTypeSetting.removeAll { loopType in
            return loopType == type
        }
        
        remoteNotificationsController.listAllProjectsFromLocalNotifications(languageLinkController: languageLinkController) { projects in
            let newSavedState = RemoteNotificationsFiltersSavedState(readStatusSetting: currentSavedState.readStatusSetting, filterTypeSetting: newFilterTypeSetting, projectsSetting: projects)
            remoteNotificationsController.filterSavedState = newSavedState
            completion()
        }
    }
}

extension RemoteNotificationsFiltersSavedState.ReadStatus {
    var title: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .read: return "Read"
        }
    }
}

private extension RemoteNotificationType {
    static var orderingForFilters: [RemoteNotificationType] {
        return [
            .userTalkPageMessage,
            .editReverted,
            .mentionInTalkPage,
            .mentionInEditSummary,
            .thanks,
            .pageReviewed,
            .pageLinked,
            .connectionWithWikidata,
            .successfulMention,
            .failedMention,
            .emailFromOtherUser,
            .userRightsChange,
            .editMilestone,
            .translationMilestone(1), //for filters this represents other translation associated values as well (ten, hundred milestones).
            .loginFailKnownDevice, //for filters this represents any login-related notification (i.e. also loginFailUnknownDevice, loginSuccessUnknownDevice, etc.). todo: clean this up.
            .welcome
        ]
    }
    
    var title: String {
        switch self {
        case .userTalkPageMessage: return "Talk page message"
        case .editReverted: return "Edit reverted"
        case .mentionInTalkPage: return "Talk page mention"
        case .mentionInEditSummary: return "Edit summary mention"
        case .thanks: return "Thanks"
        case .pageReviewed: return "Page review"
        case .pageLinked: return "Page link"
        case .connectionWithWikidata: return "Connection with Wikidata"
        case .successfulMention: return "Sent mention success"
        case .failedMention: return "Sent mention failure"
        case .emailFromOtherUser: return "Email from other user"
        case .userRightsChange: return "User rights change"
        case .editMilestone: return "Edit milestone"
        case .translationMilestone: return "Translation milestone"
        case .loginFailKnownDevice: return "Login"
        case .welcome: return "Welcome"
        default:
            return ""
        }
    }
}

extension RemoteNotificationType: Equatable {
    public static func == (lhs: RemoteNotificationType, rhs: RemoteNotificationType) -> Bool {
        switch lhs {
        case .userTalkPageMessage:
            switch rhs {
            case .userTalkPageMessage:
                return true
            default:
                return false
            }
            
        case .editReverted:
            switch rhs {
            case .editReverted:
                return true
            default:
                return false
            }
            
        case .mentionInTalkPage:
            switch rhs {
            case .mentionInTalkPage:
                return true
            default:
                return false
            }
            
        case .mentionInEditSummary:
            switch rhs {
            case .mentionInEditSummary:
                return true
            default:
                return false
            }
            
        case .thanks:
            switch rhs {
            case .thanks:
                return true
            default:
                return false
            }
            
        case .pageReviewed:
            switch rhs {
            case .pageReviewed:
                return true
            default:
                return false
            }
            
        case .pageLinked:
            switch rhs {
            case .pageLinked:
                return true
            default:
                return false
            }
            
        case .connectionWithWikidata:
            switch rhs {
            case .connectionWithWikidata:
                return true
            default:
                return false
            }
            
        case .successfulMention:
            switch rhs {
            case .successfulMention:
                return true
            default:
                return false
            }
            
        case .failedMention:
            switch rhs {
            case .failedMention:
                return true
            default:
                return false
            }
        
        case .emailFromOtherUser:
            switch rhs {
            case .emailFromOtherUser:
                return true
            default:
                return false
            }
            
        case .userRightsChange:
            switch rhs {
            case .userRightsChange:
                return true
            default:
                return false
            }

        case .editMilestone:
            switch rhs {
            case .editMilestone:
                return true
            default:
                return false
            }

        case .translationMilestone:
            switch rhs {
            case .translationMilestone:
                return true
            default:
                return false
            }
            
        case .loginFailKnownDevice:
            switch rhs {
            case .loginFailKnownDevice:
                return true
            default:
                return false
            }
            
        case .welcome:
            switch rhs {
            case .welcome:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    
}
