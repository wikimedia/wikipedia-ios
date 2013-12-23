//
//  Saved.h
//  Wikipedia-iOS
//
//  Created by Monte Hurd on 12/19/13.
//  Copyright (c) 2013 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Article;

@interface Saved : NSManagedObject

@property (nonatomic, retain) NSDate * dateSaved;
@property (nonatomic, retain) Article *article;

@end
