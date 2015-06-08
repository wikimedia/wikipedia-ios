//
//  LangaugesTableSectionViewModel.m
//  Wikipedia
//
//  Created by Brian Gerstle on 6/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "LanguagesTableSectionViewModel.h"
#import "NSObjectUtilities.h"

@interface LanguagesTableSectionViewModel ()
@property (readwrite, copy, nonatomic) NSArray* languages;
@property (readwrite, copy, nonatomic) NSString* title;
@end

@implementation LanguagesTableSectionViewModel

WMF_SYNTHESIZE_IS_EQUAL(LanguagesTableSectionViewModel, isEqualToLanguagesTableSection :)

- (instancetype)initWithTitle:(NSString*)title languages:(NSArray*)languages {
    self = [super init];
    if (self) {
        self.languages = languages;
        self.title     = title;
    }
    return self;
}

- (BOOL)isEqualToLanguagesTableSection:(LanguagesTableSectionViewModel*)rhs {
    return WMF_RHS_PROP_EQUAL(title, isEqualToString:) && WMF_RHS_PROP_EQUAL(languages, isEqualToArray:);
}

- (NSUInteger)hash {
    return self.title.hash ^ flipBitsWithAdditionalRotation(self.languages.hash, 1);
}

@end
