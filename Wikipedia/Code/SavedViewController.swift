import UIKit
import WMF

@objc(WMFSavedViewController)
class SavedViewController: ArticleFetchedResultsViewController {
    
    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "savedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func canSave(at indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func canUnsave(at indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func delete(at indexPath: IndexPath) {
        guard let articleURL = self.articleURL(at: indexPath) else {
            return
        }
        dataStore.savedPageList.removeEntry(with: articleURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab\n{{Identical|Saved}}")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PiwikTracker.sharedInstance()?.wmf_logView(self)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_savedPagesView())
    }
    
    override var analyticsName: String {
        return "Saved"
    }
}

//
//    - (NSString *)deleteButtonText {
//        return WMFLocalizedStringWithDefaultValue(@"saved-clear-all", nil, nil, @"Clear", @"Text of the button shown at the top of saved pages which deletes all the saved pages\n{{Identical|Clear}}");
//        }
//
//        - (NSString *)deleteAllConfirmationText {
//            return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-confirmation-heading", nil, nil, @"Are you sure you want to delete all your saved pages?", @"Heading text of delete all confirmation dialog");
//            }
//
//            - (NSString *)deleteText {
//                return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-delete-all", nil, nil, @"Yes, delete all", @"Button text for confirming delete all action\n{{Identical|Delete all}}");
//                }
//
//                - (NSString *)deleteCancelText {
//                    return WMFLocalizedStringWithDefaultValue(@"saved-pages-clear-cancel", nil, nil, @"Cancel", @"Button text for cancelling delete all action\n{{Identical|Cancel}}");
//}
//
