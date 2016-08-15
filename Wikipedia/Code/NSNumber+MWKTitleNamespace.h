//
//  NSNumber+MWKTitleNamespace.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  List of all built-in MediaWiki namespaces.
 *
 *  see https://www.mediawiki.org/wiki/Manual:Namespace#Built-in_namespaces
 */
typedef NS_ENUM(NSInteger, MWKTitleNamespace) {
    MWKTitleNamespaceUnknown = NSNotFound,
    MWKTitleNamespaceMedia = -2,
    MWKTitleNamespaceSpecial = -1,
    MWKTitleNamespaceMain = 0,
    MWKTitleNamespaceTalk = 1,
    MWKTitleNamespaceUser = 2,
    MWKTitleNamespaceUserTalk = 3,
    MWKTitleNamespaceProject = 4,
    MWKTitleNamespaceProjectTalk = 5,
    MWKTitleNamespaceFile = 6,
    MWKTitleNamespaceFileTalk = 7,
    MWKTitleNamespaceMediaWiki = 8,
    MWKTitleNamespaceMediaWikiTalk = 9,
    MWKTitleNamespaceTemplate = 10,
    MWKTitleNamespaceTemplateTalk = 11,
    MWKTitleNamespaceHelp = 12,
    MWKTitleNamespaceHelpTalk = 13,
    MWKTitleNamespaceCategory = 14,
    MWKTitleNamespaceCategoryTalk = 15
};

@interface NSNumber (MWKTitleNamespace)

/**
 *  Casts the receiver's value to a @c MWKTitleNamespace enum, performing additional range validation.
 *
 *  @return The receiver's integer value as a namespace enum, or if out of bounds, @c MWKTitleNamespaceUnknown.
 */
- (MWKTitleNamespace)wmf_titleNamespaceValue;

/**
 *  Convenience getter to check if the receiver belongs in the Main namespace.
 *
 *  @return @c YES if the receiver's integer value is @c MWKTitleNamespaceMain, otherwise @c NO.
 */
- (BOOL)wmf_isMainNamespace;

@end
