//
//  ImageData.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 1/12/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image;

@interface ImageData : NSManagedObject

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) Image *imageData;

@end
