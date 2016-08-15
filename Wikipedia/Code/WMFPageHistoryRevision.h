//
//  WMFRevision.h
//  Wikipedia
//
//  Created by Nick DiStefano on 4/2/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface WMFPageHistoryRevision : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* _Nullable user;
@property (nonatomic, copy, readonly) NSDate* _Nullable revisionDate;
@property (nonatomic, copy, readonly) NSString* _Nullable parsedComment;
@property (nonatomic, copy, readonly) NSString* _Nonnull authorIcon;
@property (nonatomic, assign, readonly) NSInteger parentID;
@property (nonatomic, assign, readonly) NSInteger revisionID;
@property (nonatomic, assign, readonly) NSInteger articleSizeAtRevision;
@property (nonatomic, assign, readwrite) NSInteger revisionSize;

- (NSInteger)daysFromToday;

@end
