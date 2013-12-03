//
//  Section.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/3/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article, Image;

@interface Section : NSManagedObject

@property (nonatomic, retain) NSDate * dateRetrieved;
@property (nonatomic, retain) NSString * html;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) Article *article;
@property (nonatomic, retain) Image *thumbnailImage;

@end
