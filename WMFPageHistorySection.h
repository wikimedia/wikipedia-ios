//
//  WMFPageHistorySection.h
//  Wikipedia
//
//  Created by Nick DiStefano on 4/3/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WMFPageHistoryRevision;

@interface WMFPageHistorySection : NSObject

@property (nonatomic, copy, readwrite) NSString* _Nullable sectionTitle;
@property (nonatomic, strong, readwrite) NSMutableArray<WMFPageHistoryRevision*>* _Nullable items;

@end
