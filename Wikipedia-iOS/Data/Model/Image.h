//
//  Image.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/11/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, GalleryImage, Section;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSDate * dateLastAccessed;
@property (nonatomic, retain) NSDate * dateRetrieved;
@property (nonatomic, retain) NSString * extension;
@property (nonatomic, retain) NSString * fileName;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * imageDescription;
@property (nonatomic, retain) NSString * mimeType;
@property (nonatomic, retain) NSString * sourceUrl;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSSet *article;
@property (nonatomic, retain) NSSet *galleryImage;
@property (nonatomic, retain) NSSet *section;
@end

@interface Image (CoreDataGeneratedAccessors)

- (void)addArticleObject:(Article *)value;
- (void)removeArticleObject:(Article *)value;
- (void)addArticle:(NSSet *)values;
- (void)removeArticle:(NSSet *)values;

- (void)addGalleryImageObject:(GalleryImage *)value;
- (void)removeGalleryImageObject:(GalleryImage *)value;
- (void)addGalleryImage:(NSSet *)values;
- (void)removeGalleryImage:(NSSet *)values;

- (void)addSectionObject:(Section *)value;
- (void)removeSectionObject:(Section *)value;
- (void)addSection:(NSSet *)values;
- (void)removeSection:(NSSet *)values;

@end
