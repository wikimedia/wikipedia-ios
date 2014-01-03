//
//  History.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, DiscoveryContext;

@interface History : NSManagedObject

@property (nonatomic, retain) NSDate * dateVisited;
@property (nonatomic, retain) NSString * discoveryMethod;
@property (nonatomic, retain) Article *article;
@property (nonatomic, retain) NSSet *discoveryContext;
@end

@interface History (CoreDataGeneratedAccessors)

- (void)addDiscoveryContextObject:(DiscoveryContext *)value;
- (void)removeDiscoveryContextObject:(DiscoveryContext *)value;
- (void)addDiscoveryContext:(NSSet *)values;
- (void)removeDiscoveryContext:(NSSet *)values;

@end
