//
//  Article+ConvenienceAccessors.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "Article.h"
#import "Section.h"

@interface Article (DefaultSortedAccessors)

- (NSArray*)sectionsBySectionId;

- (NSArray*)allImages;

@end

@interface Section (DefaultSortedImages)

- (NSArray*)sectionImagesByIndex;

@end