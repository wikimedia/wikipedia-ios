
import Foundation
import CocoaLumberjackSwift

extension NSManagedObjectContext {
    func talkPage(with managedObjectID: NSManagedObjectID) -> TalkPage? {
        return try? existingObject(with: managedObjectID) as? TalkPage
    }
    
    func talkPageTopic(with managedObjectID: NSManagedObjectID) -> TalkPageTopic? {
        return try? existingObject(with: managedObjectID) as? TalkPageTopic
    }

    func talkPage(for taskURL: URL) throws -> TalkPage? {
        
        guard let databaseKey = taskURL.wmf_databaseKey else {
            throw TalkPageError.talkPageDatabaseKeyCreationFailure
        }
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "key == %@", databaseKey)
        
        return try fetch(fetchRequest).first
    }

    func createMissingTalkPage(with url: URL, displayTitle: String) -> TalkPage? {
        
        let talkPage = TalkPage(context: self)
        talkPage.key = url.wmf_databaseKey
        talkPage.displayTitle = displayTitle
        
        do {
            try save()
            return talkPage
        } catch {
            return nil
        }
    }
    
    func createTalkPage(with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        guard let revisionID = networkTalkPage.revisionId else {
            return nil
        }
        
        let talkPage = TalkPage(context: self)
        talkPage.key = networkTalkPage.url.wmf_databaseKey
        talkPage.revisionId = NSNumber(value: revisionID)
        talkPage.displayTitle = networkTalkPage.displayTitle
        
        do {
            try addTalkPageTopics(to: talkPage, with: networkTalkPage)
            try save()
            return talkPage
        } catch let error {
            DDLogError("error creating talk page: \(error)")
            delete(talkPage)
            return nil
        }
    }
    
    func updateTalkPage(_ localTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage) -> TalkPage? {
        
        
        guard let revisionID = networkTalkPage.revisionId else {
            return nil
        }
        
        localTalkPage.revisionId = NSNumber(value: revisionID)
        
        guard let topicShas = (localTalkPage.topics as? Set<TalkPageTopic>)?.compactMap ({ return $0.textSha }) else {
            return nil
        }
        
        let oldTopicSetShas = Set(topicShas)
        let newTopicSetShas = Set(networkTalkPage.topics.map { $0.shas.html })

        //delete old topics
        let topicShasToDelete = oldTopicSetShas.subtracting(newTopicSetShas)

        let localTopicsToDelete = localTalkPage.topics?.filter({ (item) -> Bool in
            guard let topic = item as? TalkPageTopic,
                let textSha = topic.textSha else {
                    return false
            }

            return topicShasToDelete.contains(textSha)
        })

        if let localTopicsToDelete = localTopicsToDelete {
            for topic in localTopicsToDelete {
                guard let topic = topic as? TalkPageTopic else {
                    continue
                }

                delete(topic)
            }
        }
        
        //update common topics
        let commonTopicShas = oldTopicSetShas.intersection(newTopicSetShas)
        do  {
            try updateCommonTopics(localTalkPage: localTalkPage, with: networkTalkPage, commonTopicShas: commonTopicShas)
        
            //add new topics
            let topicShasToInsert = newTopicSetShas.subtracting(oldTopicSetShas)
            
            let insertNetworkTopics = networkTalkPage.topics.filter { topicShasToInsert.contains($0.shas.html) }
            for insertNetworkTopic in insertNetworkTopics {
                try addTalkPageTopic(to: localTalkPage, with: insertNetworkTopic)
            }
            
            try? removeUnlinkedTalkPageTopicContent()
            
            try save()
            
            return localTalkPage
        } catch {
            delete(localTalkPage)
            return nil
        }
        
        
    }
    
    func fetchOrCreateTalkPageTopicContent(with sha: String, for topic: TalkPageTopic) throws {
        guard topic.content?.sha != sha else {
            return
        }
        
        let request: NSFetchRequest<TalkPageTopicContent> = TalkPageTopicContent.fetchRequest()
        request.predicate = NSPredicate(format: "sha == %@", sha)
        let results = try fetch(request)
        var content = results.first
        if content == nil {
            content = TalkPageTopicContent(context: self)
            content?.sha = sha
        }
        topic.relatedObjectsVersion += 1
        topic.content = content
    }
    
    func removeUnlinkedTalkPageTopicContent() throws {
        let request: NSFetchRequest<NSFetchRequestResult> = TalkPageTopicContent.fetchRequest()
        request.predicate = NSPredicate(format: "topics.@count == 0")
        let batchRequest = NSBatchDeleteRequest(fetchRequest: request)
        batchRequest.resultType = .resultTypeObjectIDs
        
        let result = try execute(batchRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes: [AnyHashable : Any] = [NSDeletedObjectsKey : objectIDArray as Any]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}

//MARK: Private

private extension NSManagedObjectContext {
    
    func updateCommonTopics(localTalkPage: TalkPage, with networkTalkPage: NetworkTalkPage, commonTopicShas: Set<String>) throws {
        
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
        
        let sameNetworkTopics = networkTalkPage.topics.filter ({ commonTopicShas.contains($0.shas.html) }).sorted(by: { $0.shas.html < $1.shas.html })
        
        guard (sameLocalTopics.count == sameNetworkTopics.count) else {
            return
        }
        
        let zippedTopics = zip(sameLocalTopics, sameNetworkTopics)
        
        for (localTopic, networkTopic) in zippedTopics {
            
            if let sort = networkTopic.sort, localTopic.sort != sort {
                localTopic.sort = Int64(sort)
            } else {
                assert(networkTopic.sort != nil, "Network topic is missing sort.")
            }
            
            let sectionID = Int64(networkTopic.sectionID)
            if localTopic.sectionID != sectionID {
                localTopic.sectionID = sectionID
            }

            try fetchOrCreateTalkPageTopicContent(with: networkTopic.shas.indicator, for: localTopic)

            guard let replyShas = (localTopic.replies as? Set<TalkPageReply>)?.compactMap ({ return $0.sha }) else {
                continue
            }
            
            let oldSetReplyShas = Set(replyShas)
            let newSetReplyShas = Set(networkTopic.replies.map { $0.sha })
            
            //delete old replies
            let replyShasToDelete = oldSetReplyShas.subtracting(newSetReplyShas)

            let localRepliesToDelete = localTopic.replies?.filter({ (item) -> Bool in
                guard let reply = item as? TalkPageReply,
                    let textSha = reply.sha else {
                        return false
                }

                return replyShasToDelete.contains(textSha)
            })

            if let localRepliesToDelete = localRepliesToDelete {
                for reply in localRepliesToDelete {
                    guard let reply = reply as? TalkPageTopic else {
                        continue
                    }

                    delete(reply)
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
            
            let insertNetworkReplies = networkTopic.replies.filter { replyShasToInsert.contains($0.sha) }
            for insertNetworkReply in insertNetworkReplies {
                addTalkPageReply(to: localTopic, with: insertNetworkReply)
            }

        }
    }
    
    func addTalkPageTopics(to talkPage: TalkPage, with networkTalkPage: NetworkTalkPage) throws {
        for networkTopic in networkTalkPage.topics {
            try addTalkPageTopic(to: talkPage, with: networkTopic)
        }
    }
    
    func addTalkPageTopic(to talkPage: TalkPage, with networkTopic: NetworkTopic) throws {

        let topic = TalkPageTopic(context: self)
        topic.title = networkTopic.html
        topic.sectionID = Int64(networkTopic.sectionID)
        
        if let sort = networkTopic.sort {
            topic.sort = Int64(sort)
            topic.isIntro = networkTopic.sort == 0 && networkTopic.html.count == 0
        } else {
            assertionFailure("Network topic is missing sort")
        }
        
        topic.textSha = networkTopic.shas.html
        
        try fetchOrCreateTalkPageTopicContent(with: networkTopic.shas.indicator, for: topic)

        for reply in networkTopic.replies {
            addTalkPageReply(to: topic, with: reply)
        }

        topic.talkPage = talkPage
    }
    
    func addTalkPageReply(to topic: TalkPageTopic, with networkReply: NetworkReply) {
        let reply = TalkPageReply(context: self)
        reply.depth = networkReply.depth
        reply.text = networkReply.html
        reply.sort = Int64(networkReply.sort)
        reply.topic = topic
        reply.sha = networkReply.sha
    }
}
