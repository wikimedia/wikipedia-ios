//
//  PTEventEntity.h
//  PiwikTracker
//
//  Created by Mattias Levin on 8/6/13.
//  Copyright (c) 2013 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PTEventEntity : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSData * piwikRequestParameters;

@end
