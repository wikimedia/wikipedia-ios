//
//  LangaugeSelectionDelegate.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKLanguageLink;
@class LanguagesViewController;

// Protocol for notifying languageSelectionDelegate that selection was made.
@protocol LanguageSelectionDelegate <NSObject>

- (void)languageSelected:(MWKLanguageLink*)langData sender:(LanguagesViewController*)sender;

@end
