//  Created by Monte Hurd on 7/30/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <Masonry/Masonry.h>

@interface WMFSectionHeaderModel : NSObject

@property (nonatomic, strong) MASConstraint* topConstraint;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* anchor;
@property (nonatomic) CGFloat yOffset;
@property (nonatomic) NSNumber* sectionId;

@end
