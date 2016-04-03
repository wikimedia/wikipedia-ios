//
//  WMFRevision.h
//  Wikipedia
//
//  Created by Nick DiStefano on 4/2/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

@interface WMFRevision : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, readonly) NSString* user;
@property (nonatomic, copy, readonly) NSDate* revisionDate;
@property (nonatomic, copy, readonly) NSString* parsedComment;
@property (nonatomic, copy, readonly) NSString* authorIcon;
@property (nonatomic, assign, readonly) NSInteger parentID;
@property (nonatomic, assign, readonly) NSInteger revisionID;
@property (nonatomic, assign, readonly) NSInteger articleSizeAtRevision;
@property (nonatomic, assign, readonly) NSInteger revisionSize;

@end
