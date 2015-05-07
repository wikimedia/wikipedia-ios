//  Created by Monte Hurd on 4/29/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, Image, SectionImage;

@interface Section : NSManagedObject

@property (nonatomic, retain) NSString* anchor;
@property (nonatomic, retain) NSDate* dateRetrieved;
@property (nonatomic, retain) NSString* html;
@property (nonatomic, retain) NSString* index;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSNumber* tocLevel;
@property (nonatomic, retain) NSString* level;
@property (nonatomic, retain) NSNumber* sectionId;
@property (nonatomic, retain) NSString* number;
@property (nonatomic, retain) NSString* fromTitle;
@property (nonatomic, retain) Article* article;
@property (nonatomic, retain) NSSet* sectionImage;
@property (nonatomic, retain) Image* thumbnailImage;
@end

@interface Section (CoreDataGeneratedAccessors)

- (void)addSectionImageObject:(SectionImage*)value;
- (void)removeSectionImageObject:(SectionImage*)value;
- (void)addSectionImage:(NSSet*)values;
- (void)removeSectionImage:(NSSet*)values;

@end
