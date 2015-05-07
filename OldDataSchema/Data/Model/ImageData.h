//  Created by Monte Hurd on 1/12/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image;

@interface ImageData : NSManagedObject

@property (nonatomic, retain) NSData* data;
@property (nonatomic, retain) Image* imageData;

@end
