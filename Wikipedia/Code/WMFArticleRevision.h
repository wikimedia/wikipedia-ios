//
//  WMFArticleRevision.h
//  Wikipedia
//
//  Created by Brian Gerstle on 12/16/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleRevision : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSNumber* revisionId;

@property (nonatomic, assign, readonly, getter = isMinorEdit) BOOL minorEdit;

@property (nonatomic, assign, readonly) NSNumber* sizeInBytes;

@end

NS_ASSUME_NONNULL_END
