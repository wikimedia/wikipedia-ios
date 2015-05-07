//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class History;

@interface DiscoveryContext : NSManagedObject

@property (nonatomic, retain) NSNumber* isPrefix;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) History* history;

@end
