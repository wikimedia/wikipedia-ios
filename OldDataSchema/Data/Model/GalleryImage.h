//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, Image;

@interface GalleryImage : NSManagedObject

@property (nonatomic, retain) NSNumber* index;
@property (nonatomic, retain) Article* article;
@property (nonatomic, retain) Image* image;

@end
