//
//  Article+ConvenienceAccessors.m
//  Wikipedia
//
//  Created by Brian Gerstle on 3/23/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "Article+ConvenienceAccessors.h"
#import <BlocksKit/BlocksKit.h>
#import "Section.h"
#import "SectionImage.h"
#import "Image.h"

@implementation Article (DefaultSortedAccessors)

- (NSArray*)sectionsBySectionId {
    NSArray* sectionIdSortDesc = @[[NSSortDescriptor sortDescriptorWithKey:@"sectionId" ascending:YES]];
    return [self.section sortedArrayUsingDescriptors:sectionIdSortDesc];
}

- (NSArray*)allImages {
    return [[[self sectionsBySectionId] bk_map:^NSArray*(Section* section) {
        NSArray* sectionImageIndexSortDesc = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
        NSArray* sectionImages = [section.sectionImage sortedArrayUsingDescriptors:sectionImageIndexSortDesc];
        return [sectionImages bk_map:^Image*(SectionImage* sectionImage) {
            return sectionImage.image;
        }];
    }]
            bk_reduce:[NSMutableArray new] withBlock:^NSArray*(NSMutableArray* flattenedImages,
                                                               NSArray* sectionImages) {
        [flattenedImages addObjectsFromArray:sectionImages];
        return flattenedImages;
    }];
}

@end

@implementation Section (DefaultSortedImages)

- (NSArray*)sectionImagesByIndex {
    NSArray* sectionImageIndexSortDesc = @[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]];
    return [self.sectionImage sortedArrayUsingDescriptors:sectionImageIndexSortDesc];
}

@end