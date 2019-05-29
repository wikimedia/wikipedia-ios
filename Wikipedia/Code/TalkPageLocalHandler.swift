
import Foundation

class TalkPageLocalHandler {
    
    var dataStore: MWKDataStore
    
    required init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
    }
    
    func talkPage(for taskURL: URL) throws -> TalkPage? {
        
        guard let databaseKey = taskURL.wmf_talkPageDatabaseKey else {
            throw TalkPageError.talkPageDatabaseKeyCreationFailure
        }
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "key == %@", databaseKey)
        
        return try dataStore.viewContext.fetch(fetchRequest).first
    }
    
    func createEmptyTalkPage(with url: URL, languageCode: String, displayTitle: String) -> TalkPage? {
        guard let talkPageEntityDesc = NSEntityDescription.entity(forEntityName: "TalkPage", in: dataStore.viewContext) else {
                return nil
        }
        
        let talkPage = TalkPage(entity: talkPageEntityDesc, insertInto: dataStore.viewContext)
        talkPage.key = url.wmf_talkPageDatabaseKey
        talkPage.languageCode = languageCode
        talkPage.displayTitle = displayTitle
        talkPage.introText = nil
        
        do {
            try dataStore.viewContext.save()
            return talkPage
        } catch {
            return nil
        }
    }
    
    func createTalkPage(with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        guard let revisionID = networkTalkPage.revisionId,
            let talkPageEntityDesc = NSEntityDescription.entity(forEntityName: "TalkPage", in: dataStore.viewContext) else {
            return nil
        }
        
        let talkPage = TalkPage(entity: talkPageEntityDesc, insertInto: dataStore.viewContext)
        talkPage.key = networkTalkPage.url.wmf_talkPageDatabaseKey
        talkPage.revisionId = NSNumber(value: revisionID)
        talkPage.languageCode = networkTalkPage.languageCode
        talkPage.displayTitle = networkTalkPage.displayTitle
        talkPage.introText = networkTalkPage.introText
        
        addTalkPageTopics(to: talkPage, with: networkTalkPage)
        
        do {
            try dataStore.viewContext.save()
            return talkPage
        } catch {
            return nil
        }
    }
    
    func updateTalkPage(_ localTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        guard let revisionID = networkTalkPage.revisionId else {
            return nil
        }
        
        localTalkPage.revisionId = NSNumber(value: revisionID)
        localTalkPage.introText = networkTalkPage.introText
        
        guard let topicShas = (localTalkPage.topics as? Set<TalkPageTopic>)?.compactMap ({ return $0.textSha }) else {
            return nil
        }
        
        let oldTopicSetShas = Set(topicShas)
        let newTopicSetShas = Set(networkTalkPage.topics.map { $0.shas.text })
        
        //delete old topics
        let topicShasToDelete = oldTopicSetShas.subtracting(newTopicSetShas)
        
        for deleteSha in topicShasToDelete {
            if let localTopic = localTalkPage.topics?.filter({ ($0 as? TalkPageTopic)?.textSha == deleteSha }).first as? TalkPageTopic {
                dataStore.viewContext.delete(localTopic)
            }
        }
        
        //udpate common topics
        let commonTopicShas = oldTopicSetShas.intersection(newTopicSetShas)
        updateCommonTopics(localTalkPage: localTalkPage, with: networkTalkPage, commonTopicShas: commonTopicShas)
        
        //add new topics
        let topicShasToInsert = newTopicSetShas.subtracting(oldTopicSetShas)
        
        for insertSha in topicShasToInsert {
            if let networkTopic = networkTalkPage.topics.filter({ $0.shas.text == insertSha }).first {
                addTalkPageTopic(to: localTalkPage, with: networkTopic)
            }
        }
        
        do {
            try dataStore.viewContext.save()
            return localTalkPage
        } catch {
            return nil
        }
    }
}

//MARK: Private

private extension TalkPageLocalHandler {
    
    func updateCommonTopics(localTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage, commonTopicShas: Set<String>) {
        
        //create & zip limited set of topics
        let predicate = NSPredicate(format:"textSha IN %@", commonTopicShas)
        guard let sameLocalTopics = localTalkPage.topics?.filtered(using: predicate).sorted(by: { (item1, item2) -> Bool in
            guard let topic1 = item1 as? TalkPageTopic,
                let sha1 = topic1.textSha,
                let topic2 = item2 as? TalkPageTopic,
                let sha2 = topic2.textSha else {
                    return false
            }
            
            return sha1 < sha2
        }) as? [TalkPageTopic] else {
            return
        }
        
        let sameNetworkTopics = networkTalkPage.topics.filter ({ commonTopicShas.contains($0.shas.text) }).sorted(by: { $0.shas.text < $1.shas.text })
        
        guard (sameLocalTopics.count == sameNetworkTopics.count) else {
            return
        }
        
        let zippedTopics = zip(sameLocalTopics, sameNetworkTopics)
        
        for (localTopic, networkTopic) in zippedTopics {
            
            if let sort = networkTopic.sort {
                localTopic.sort = Int64(sort)
            } else {
                 assertionFailure("Network topic is missing sort.")
            }
            
            //todo possible performance, at one point we thought maybe having a 3rd separate "replies" at the topic level sha that represents only the replies text of a topic could improve performance here. Keeping it out now for simplicity but we could bring it back if we find it improves things.
            //if replies have not changed in any manner, no need to dig into replies diffing
//            guard localTopic.repliesSha != networkTopic.shas.replies else {
//                continue
//            }
            
            guard let replyShas = (localTopic.replies as? Set<TalkPageReply>)?.compactMap ({ return $0.sha }) else {
                continue
            }
            
            let oldSetReplyShas = Set(replyShas)
            let newSetReplyShas = Set(networkTopic.replies.map { $0.sha })
            
            //delete old replies
            let replyShasToDelete = oldSetReplyShas.subtracting(newSetReplyShas)
            
            for deleteSha in replyShasToDelete {
                if let localReply = localTopic.replies?.filter({ ($0 as? TalkPageReply)?.sha == deleteSha }).first as? TalkPageReply {
                    dataStore.viewContext.delete(localReply)
                }
            }
            
            //update common replies
            //note: not sure if this is possible anymore. reply shas now contain sort so a different ordering will be seen as new or deleted
            let commonReplyShas = oldSetReplyShas.intersection(newSetReplyShas)
            
            let predicate = NSPredicate(format:"sha IN %@", commonReplyShas)
            guard let sameLocalReplies = localTopic.replies?.filtered(using: predicate).sorted(by: { (item1, item2) -> Bool in
                guard let reply1 = item1 as? TalkPageReply,
                    let sha1 = reply1.sha,
                    let reply2 = item2 as? TalkPageReply,
                    let sha2 = reply2.sha else {
                        return false
                }
                
                return sha1 < sha2
            }) as? [TalkPageReply] else {
                return
            }
            
            let sameNetworkReplies = networkTopic.replies.filter ({ commonReplyShas.contains($0.sha) }).sorted(by: { $0.sha < $1.sha })
            
            guard sameLocalReplies.count == sameNetworkReplies.count else { continue }
            
            let zippedReplies = zip(sameLocalReplies, sameNetworkReplies)
            
            for (localReply, networkReply) in zippedReplies {
               localReply.sort = Int64(networkReply.sort)
            }
            
            //add new replies
            let replyShasToInsert = newSetReplyShas.subtracting(oldSetReplyShas)
            
            for insertSha in replyShasToInsert {
                if let networkReply = networkTopic.replies.filter({ $0.sha == insertSha }).first {
                    addTalkPageReply(to: localTopic, with: networkReply)
                }
            }
        }
    }
    
    func addTalkPageTopics(to talkPage: TalkPage, with networkTalkPage: NetworkTalkPage) {
        
        for networkTopic in networkTalkPage.topics {
            addTalkPageTopic(to: talkPage, with: networkTopic)
        }
    }
    
    func addTalkPageTopic(to talkPage: TalkPage, with networkTopic: NetworkTopic) {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageTopic", in: dataStore.viewContext) else {
            assertionFailure("Failure determining topic entity.")
            return
        }
        
        let topic = TalkPageTopic(entity: entityDesc, insertInto: dataStore.viewContext)
        topic.title = networkTopic.text
        topic.sectionID = Int64(networkTopic.sectionID)
        
        if let sort = networkTopic.sort {
            topic.sort = Int64(sort)
        } else {
            assertionFailure("Network topic is missing sort")
        }
        
        topic.textSha = networkTopic.shas.text
        topic.indicatorSha = networkTopic.shas.indicator
        
        for reply in networkTopic.replies {
            
            addTalkPageReply(to: topic, with: reply)
        }
        
        topic.talkPage = talkPage
    }
    
    func addTalkPageReply(to topic: TalkPageTopic, with networkReply: NetworkReply) {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "TalkPageReply", in: dataStore.viewContext) else {
            assertionFailure("Failure determining reply entity.")
            return
        }
        
        let reply = TalkPageReply(entity: entityDesc, insertInto: dataStore.viewContext)
        reply.depth = networkReply.depth
        reply.text = networkReply.text
        reply.sort = Int64(networkReply.sort)
        reply.topic = topic
        reply.sha = networkReply.sha
    }
}
