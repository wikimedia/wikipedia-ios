//
//  SectionImage.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image, Section;

@interface SectionImage : NSManagedObject

@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) Image *image;
@property (nonatomic, retain) Section *section;

@end
