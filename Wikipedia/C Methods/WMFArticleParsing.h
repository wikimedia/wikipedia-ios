//
//  WMFArticleParsing.h
//  Wikipedia
//
//  Created by Brian Gerstle on 3/19/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MWKArticle;

extern NSString* WMFImgTagsFromHTML(NSString* html);

extern void WMFInjectArticleWithImagesFromSection(MWKArticle* article, NSString* sectionHTML, int sectionID);
