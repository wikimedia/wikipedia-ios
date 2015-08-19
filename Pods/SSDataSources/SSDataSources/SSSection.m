//
//  SSSection.m
//  ExampleSSDataSources
//
//  Created by Jonathan Hersh on 8/29/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSDataSources.h"

@interface SSSection ()

@property (nonatomic, assign, readwrite, getter=isExpanded) BOOL expanded;

@end

@implementation SSSection

- (id)init {
    if ((self = [super init])) {
        _items = [NSMutableArray new];
        _headerClass = [SSBaseHeaderFooterView class];
        _footerClass = [SSBaseHeaderFooterView class];
        _headerHeight = UITableViewAutomaticDimension;
        _footerHeight = UITableViewAutomaticDimension;
        _expanded = YES;
    }
    
    return self;
}

+ (instancetype)sectionWithItems:(NSArray *)items {
    return [self sectionWithItems:items
                           header:nil
                           footer:nil
                       identifier:nil];
}

+ (instancetype)sectionWithItems:(NSArray *)items
                          header:(NSString *)header
                          footer:(NSString *)footer
                      identifier:(id)identifier {
    
    SSSection *section = [SSSection new];
    
    if (items) {
        [section.items addObjectsFromArray:items];
    }
    
    section.header = header;
    section.footer = footer;
    section.sectionIdentifier = identifier;
  
    return section;
}

+ (instancetype)sectionWithNumberOfItems:(NSUInteger)numberOfItems {
    return [self sectionWithNumberOfItems:numberOfItems
                                   header:nil
                                   footer:nil
                               identifier:nil];
}

+ (instancetype)sectionWithNumberOfItems:(NSUInteger)numberOfItems
                                  header:(NSString *)header
                                  footer:(NSString *)footer
                              identifier:(id)identifier {
    
    NSMutableArray *array = [NSMutableArray new];
    
    for (NSUInteger i = 0; i < numberOfItems; i++) {
        [array addObject:@(i)];
    }
    
    return [self sectionWithItems:array
                           header:header
                           footer:footer
                       identifier:identifier];
}

- (NSUInteger)numberOfItems {
    return [self.items count];
}

- (id)itemAtIndex:(NSUInteger)index {
    return self.items[index];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SSSection *newSection = [SSSection sectionWithItems:self.items];
    newSection.header = self.header;
    newSection.footer = self.footer;
    newSection.headerClass = self.headerClass;
    newSection.footerClass = self.footerClass;
    newSection.headerHeight = self.headerHeight;
    newSection.footerHeight = self.footerHeight;
    newSection.sectionIdentifier = self.sectionIdentifier;
  
    return newSection;
}

@end
