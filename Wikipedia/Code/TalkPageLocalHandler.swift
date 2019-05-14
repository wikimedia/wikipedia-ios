
import Foundation

class TalkPageLocalHandler {
    
    var dataStore: MWKDataStore
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    func existingTalkPage(for taskURL: URL) throws -> TalkPage? {
        
        guard let databaseKey = taskURL.wmf_talkPageDatabaseKey else {
            throw TalkPageError.talkPageDatabaseKeyCreationFailure
        }
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "key == %@", databaseKey)
        
        return try dataStore.viewContext.fetch(fetchRequest).first
    }
    
    func updateExistingTalkPage(existingTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        existingTalkPage.revisionId = networkTalkPage.revisionId
        
        guard let discussionIds = (existingTalkPage.discussions as? Set<TalkPageDiscussion>)?.compactMap ({ return $0.sha }) else {
            return nil
        }
        
        let oldDiscussionSetIds = Set(discussionIds)
        let newDiscussionSetIds = Set(networkTalkPage.discussions.map { $0.sha })
        
        //delete old discussions
        let discussionIdsToDelete = oldDiscussionSetIds.subtracting(newDiscussionSetIds)
        
        for deleteSha in discussionIdsToDelete {
            if let existingDiscussion = existingTalkPage.discussions?.filter({ ($0 as? TalkPageDiscussion)?.sha == deleteSha }).first as? TalkPageDiscussion {
                dataStore.viewContext.delete(existingDiscussion)
            }
        }
        
        //loop through discussions existing in both
        let remainingDiscussionIds = oldDiscussionSetIds.intersection(newDiscussionSetIds)
        
        for discussionSha in remainingDiscussionIds {
            if let existingDiscussion = existingTalkPage.discussions?.filter({ ($0 as? TalkPageDiscussion)?.sha == discussionSha }).first as? TalkPageDiscussion,
                let networkDiscussion = networkTalkPage.discussions.filter({ $0.sha == discussionSha }).first {
                
                //update discussion sort
                existingDiscussion.sort = Int64(networkDiscussion.sort)
                
                guard let replyIds = (existingDiscussion.items as? Set<TalkPageDiscussionItem>)?.compactMap ({ return $0.sha }) else {
                    continue
                }
                
                let oldSetReplyIds = Set(replyIds)
                let newSetReplyIds = Set(networkDiscussion.items.map { $0.sha })
                
                //delete old replies
                let repliesToDelete = oldSetReplyIds.subtracting(newSetReplyIds)
                
                for deleteSha in repliesToDelete {
                    if let existingReply = existingDiscussion.items?.filter({ ($0 as? TalkPageDiscussionItem)?.sha == deleteSha }).first as? TalkPageDiscussionItem {
                        dataStore.viewContext.delete(existingReply)
                    }
                }
                
                //loop through replies existing in both, update sort
                let sameReplies = oldSetReplyIds.intersection(newSetReplyIds)
                for sameSha in sameReplies {
                    if let existingReply = existingDiscussion.items?.filter({ ($0 as? TalkPageDiscussionItem)?.sha == sameSha }).first as? TalkPageDiscussionItem,
                        let networkReply = networkDiscussion.items.filter({ $0.sha == sameSha }).first {
                        existingReply.sort = Int64(networkReply.sort)
                    }
                }
                
                //add new replies
                let repliesToInsert = newSetReplyIds.subtracting(oldSetReplyIds)
                
                for insertSha in repliesToInsert {
                    if let networkReply = networkDiscussion.items.filter({ $0.sha == insertSha }).first {
                        addTalkPageReply(to: existingDiscussion, with: networkReply)
                    }
                }
            }
        }
        
        //add new discussions
        let discussionsToInsert = newDiscussionSetIds.subtracting(oldDiscussionSetIds)
        
        for insertSha in discussionsToInsert {
            if let networkDiscussion = networkTalkPage.discussions.filter({ $0.sha == insertSha }).first {
                addTalkPageDiscussion(to: existingTalkPage, with: networkDiscussion)
            }
        }
        
        try? dataStore.viewContext.save() //todo: no try?
        return existingTalkPage
    }
    
    func createTalkPage(with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        guard let talkPageEntityDesc = NSEntityDescription.entity(forEntityName: "TalkPage", in: dataStore.viewContext) else {
            return nil
        }
        
        let talkPage = TalkPage(entity: talkPageEntityDesc, insertInto: dataStore.viewContext)
        talkPage.key = networkTalkPage.url.wmf_talkPageDatabaseKey
        talkPage.revisionId = networkTalkPage.revisionId
        talkPage.languageCode = networkTalkPage.languageCode
        talkPage.displayTitle = networkTalkPage.displayTitle
        
        addTalkPageDiscussions(to: talkPage, with: networkTalkPage)
    
        try? dataStore.viewContext.save() //todo: no try?
        return talkPage
    }
    
    private func addTalkPageDiscussions(to talkPage: TalkPage, with networkTalkPage: NetworkTalkPage) {
        
        for networkDiscussion in networkTalkPage.discussions {
            addTalkPageDiscussion(to: talkPage, with: networkDiscussion)
        }
    }
    
    private func addTalkPageDiscussion(to talkPage: TalkPage, with networkDiscussion: NetworkDiscussion) {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussion", in: dataStore.viewContext) else {
            return
        }
        
        let discussion = TalkPageDiscussion(entity: entityDesc, insertInto: dataStore.viewContext)
        discussion.title = networkDiscussion.text
        discussion.sectionID = Int64(networkDiscussion.sectionID)
        discussion.sort = Int64(networkDiscussion.sort)
        discussion.sha = networkDiscussion.sha
        
        for networkItem in networkDiscussion.items {
            
            addTalkPageReply(to: discussion, with: networkItem)
        }
        
        discussion.talkPage = talkPage
    }
    
    private func addTalkPageReply(to discussion: TalkPageDiscussion, with networkItem: NetworkDiscussionItem) {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageDiscussionItem", in: dataStore.viewContext) else {
            return
        }
        
        let discussionItem = TalkPageDiscussionItem(entity: entityDesc, insertInto: dataStore.viewContext)
        discussionItem.depth = networkItem.depth
        discussionItem.text = networkItem.text
        discussionItem.sort = Int64(networkItem.sort)
        discussionItem.discussion = discussion
        discussionItem.sha = networkItem.sha
    }
}
