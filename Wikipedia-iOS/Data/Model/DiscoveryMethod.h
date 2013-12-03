//
//  DiscoveryMethod.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/3/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class History;

@interface DiscoveryMethod : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *history;
@end

@interface DiscoveryMethod (CoreDataGeneratedAccessors)

- (void)addHistoryObject:(History *)value;
- (void)removeHistoryObject:(History *)value;
- (void)addHistory:(NSSet *)values;
- (void)removeHistory:(NSSet *)values;

@end
