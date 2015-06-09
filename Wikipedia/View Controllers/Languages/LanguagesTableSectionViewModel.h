//
//  LangaugesTableSectionViewModel.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LanguagesTableSectionViewModel : NSObject
@property (readonly, copy, nonatomic) NSArray* languages;
@property (readonly, copy, nonatomic) NSString* title;

- (instancetype)initWithTitle:(NSString*)title languages:(NSArray*)languages;

- (BOOL)isEqualToLanguagesTableSection:(LanguagesTableSectionViewModel*)rhs;

@end
