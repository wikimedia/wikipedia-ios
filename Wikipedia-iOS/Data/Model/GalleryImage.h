//
//  GalleryImage.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/3/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, Image;

@interface GalleryImage : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Article *article;
@property (nonatomic, retain) Image *image;

@end
