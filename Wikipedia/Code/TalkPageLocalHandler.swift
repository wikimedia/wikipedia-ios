
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
    
    func updateExistingTalkPage(existingTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        existingTalkPage.revisionId = networkTalkPage.revisionId
        
        guard let discussionIds = (existingTalkPage.discussions as? Set<TalkPageDiscussion>)?.compactMap ({ return $0.textSha }) else {
            return nil
        }
        
        let oldDiscussionSetIds = Set(discussionIds)
        let newDiscussionSetIds = Set(networkTalkPage.discussions.map { $0.shas.text })
        
        //delete old discussions
        let discussionIdsToDelete = oldDiscussionSetIds.subtracting(newDiscussionSetIds)
        
        for deleteSha in discussionIdsToDelete {
            if let existingDiscussion = existingTalkPage.discussions?.filter({ ($0 as? TalkPageDiscussion)?.textSha == deleteSha }).first as? TalkPageDiscussion {
                dataStore.viewContext.delete(existingDiscussion)
            }
        }
        
        //udpate common discussions
        let commonDiscussionShas = oldDiscussionSetIds.intersection(newDiscussionSetIds)
        updateCommonDiscussions(existingTalkPage: existingTalkPage, with: networkTalkPage, commonDiscussionShas: commonDiscussionShas)
        
        //add new discussions
        let discussionsToInsert = newDiscussionSetIds.subtracting(oldDiscussionSetIds)
        
        for insertSha in discussionsToInsert {
            if let networkDiscussion = networkTalkPage.discussions.filter({ $0.shas.text == insertSha }).first {
                addTalkPageDiscussion(to: existingTalkPage, with: networkDiscussion)
            }
        }
        
        try? dataStore.viewContext.save() //todo: no try?
        return existingTalkPage
    }
    
    private func updateCommonDiscussions(existingTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage, commonDiscussionShas: Set<String>) {
        
        //create & zip limited set of discussions
        let predicate = NSPredicate(format:"textSha IN %@", commonDiscussionShas)
        guard let sameLocalDiscussions = existingTalkPage.discussions?.filtered(using: predicate).sorted(by: { (item1, item2) -> Bool in
            guard let discussion1 = item1 as? TalkPageDiscussion,
                let sha1 = discussion1.textSha,
                let discussion2 = item2 as? TalkPageDiscussion,
                let sha2 = discussion2.textSha else {
                    return false
            }
            
            return sha1 < sha2
        }) as? [TalkPageDiscussion] else {
            return
        }
        
        let sameNetworkDiscussions = networkTalkPage.discussions.filter ({ commonDiscussionShas.contains($0.shas.text) }).sorted(by: { $0.shas.text < $1.shas.text })
        
        guard (sameLocalDiscussions.count == sameNetworkDiscussions.count) else {
            return
        }
        
        let zippedDiscussions = zip(sameLocalDiscussions, sameNetworkDiscussions)
        
        for (localDiscussion, networkDiscussion) in zippedDiscussions {
            
            localDiscussion.sort = Int64(networkDiscussion.sort)
            
            //if replies have not changed in any manner, no need to dig into replies diffing
            guard localDiscussion.repliesSha != networkDiscussion.shas.replies else {
                continue
            }
            
            guard let replyIds = (localDiscussion.items as? Set<TalkPageDiscussionItem>)?.compactMap ({ return $0.sha }) else {
                continue
            }
            
            let oldSetReplyIds = Set(replyIds)
            let newSetReplyIds = Set(networkDiscussion.items.map { $0.sha })
            
            //delete old replies
            let repliesToDelete = oldSetReplyIds.subtracting(newSetReplyIds)
            
            for deleteSha in repliesToDelete {
                if let existingReply = localDiscussion.items?.filter({ ($0 as? TalkPageDiscussionItem)?.sha == deleteSha }).first as? TalkPageDiscussionItem {
                    dataStore.viewContext.delete(existingReply)
                }
            }
            
            //update common replies
            let commonReplyShas = oldSetReplyIds.intersection(newSetReplyIds)
            
            let predicate = NSPredicate(format:"sha IN %@", commonReplyShas)
            guard let sameLocalReplies = localDiscussion.items?.filtered(using: predicate).sorted(by: { (item1, item2) -> Bool in
                guard let reply1 = item1 as? TalkPageDiscussionItem,
                    let sha1 = reply1.sha,
                    let reply2 = item2 as? TalkPageDiscussionItem,
                    let sha2 = reply2.sha else {
                        return false
                }
                
                return sha1 < sha2
            }) as? [TalkPageDiscussionItem] else {
                return
            }
            
            let sameNetworkReplies = networkDiscussion.items.filter ({ commonReplyShas.contains($0.sha) }).sorted(by: { $0.sha < $1.sha })
            
            guard sameLocalReplies.count == sameNetworkReplies.count else { continue }
            
            let zippedReplies = zip(sameLocalReplies, sameNetworkReplies)
            
            for (localReply, networkReply) in zippedReplies {
               localReply.sort = Int64(networkReply.sort)
            }
            
            //add new replies
            let repliesToInsert = newSetReplyIds.subtracting(oldSetReplyIds)
            
            for insertSha in repliesToInsert {
                if let networkReply = networkDiscussion.items.filter({ $0.sha == insertSha }).first {
                    addTalkPageReply(to: localDiscussion, with: networkReply)
                }
            }
        }
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
        discussion.textSha = networkDiscussion.shas.text
        discussion.repliesSha = networkDiscussion.shas.replies
        
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
