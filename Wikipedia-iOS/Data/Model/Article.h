//
//  Article.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/9/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Domain, GalleryImage, History, Image, Saved, Section, Site;

@interface Article : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * lastScrollY;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * lastScrollX;
@property (nonatomic, retain) Domain *domain;
@property (nonatomic, retain) NSSet *galleryImage;
@property (nonatomic, retain) NSSet *history;
@property (nonatomic, retain) NSSet *saved;
@property (nonatomic, retain) NSSet *section;
@property (nonatomic, retain) Site *site;
@property (nonatomic, retain) Image *thumbnailImage;
@end

@interface Article (CoreDataGeneratedAccessors)

- (void)addGalleryImageObject:(GalleryImage *)value;
- (void)removeGalleryImageObject:(GalleryImage *)value;
- (void)addGalleryImage:(NSSet *)values;
- (void)removeGalleryImage:(NSSet *)values;

- (void)addHistoryObject:(History *)value;
- (void)removeHistoryObject:(History *)value;
- (void)addHistory:(NSSet *)values;
- (void)removeHistory:(NSSet *)values;

- (void)addSavedObject:(Saved *)value;
- (void)removeSavedObject:(Saved *)value;
- (void)addSaved:(NSSet *)values;
- (void)removeSaved:(NSSet *)values;

- (void)addSectionObject:(Section *)value;
- (void)removeSectionObject:(Section *)value;
- (void)addSection:(NSSet *)values;
- (void)removeSection:(NSSet *)values;

@end
