//
//  NSAttributedString+WMFModifyTests.m
//  Wikipedia
//
//  Created by Monte Hurd on 8/18/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "NSAttributedString+WMFModify.h"
#import "XCTestCase+WMFLabelConvenience.h"

@interface NSAttributedString_WMFModifyTests : FBSnapshotTestCase

@end

@implementation NSAttributedString_WMFModifyTests

- (void)setUp {
    [super setUp];
    //self.recordMode = YES;
}

- (NSAttributedString*)getTestAttrStr {
    NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:@"This is a test string which should help confirm that this is working the way we want it to. This is a test link to wikipedia."];

    [attributedText addAttribute:NSStrikethroughStyleAttributeName value:@1 range:[attributedText.string rangeOfString:@"This"]];
    [attributedText addAttribute:NSStrikethroughStyleAttributeName value:@1 range:[attributedText.string rangeOfString:@"test"]];
    [attributedText addAttribute:NSStrikethroughStyleAttributeName value:@1 range:[attributedText.string rangeOfString:@"which"]];
    [attributedText addAttribute:NSStrikethroughStyleAttributeName value:@1 range:[attributedText.string rangeOfString:@"help"]];

    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor greenColor] range:[attributedText.string rangeOfString:@"should"]];
    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor greenColor] range:[attributedText.string rangeOfString:@"working"]];
    [attributedText addAttribute:NSBackgroundColorAttributeName value:[UIColor grayColor] range:[attributedText.string rangeOfString:@"way"]];

    NSMutableParagraphStyle* p = [[NSMutableParagraphStyle alloc] init];
    p.lineSpacing = 20;

    [attributedText addAttribute:NSParagraphStyleAttributeName value:p range:NSMakeRange(0, attributedText.length)];

    NSURL* url = [NSURL URLWithString:@"http://www.wikipedia.org"];
    [attributedText addAttribute:NSLinkAttributeName value:url range:[attributedText.string rangeOfString:@"link"]];

    return attributedText;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test0ReferenceOutput {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        label.attributedText = [self getTestAttrStr];
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testRemoveAllStrikeThroughs {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        NSAttributedString* attrStr =
            [[self getTestAttrStr] wmf_attributedStringChangingAttribute:NSStrikethroughStyleAttributeName
                                                               withBlock:^NSNumber*(NSNumber* strike){
            return nil;
        }];
        label.attributedText = attrStr;
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testChangeGreenBackgroundColorsToBlue {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        NSAttributedString* attrStr =
            [[self getTestAttrStr] wmf_attributedStringChangingAttribute:NSBackgroundColorAttributeName
                                                               withBlock:^UIColor*(UIColor* color){
            return [color isEqual:[UIColor greenColor]] ? [UIColor blueColor] : color;
        }];
        label.attributedText = attrStr;
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testChangeReduceLineSpacing {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        NSAttributedString* attrStr =
            [[self getTestAttrStr] wmf_attributedStringChangingAttribute:NSParagraphStyleAttributeName
                                                               withBlock:^NSParagraphStyle*(NSParagraphStyle* paragraphStyle){
            NSMutableParagraphStyle* mutablePStyle = paragraphStyle.mutableCopy;
            mutablePStyle.lineSpacing = 2;
            return mutablePStyle;
        }];
        label.attributedText = attrStr;
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testRemovingLink {
    FBSnapshotVerifyViewWithOptions([self wmf_getLabelConfiguredWithBlock:^(UILabel* label){
        NSAttributedString* attrStr =
            [[self getTestAttrStr] wmf_attributedStringChangingAttribute:NSLinkAttributeName
                                                               withBlock:^id (id link){
            return nil;
        }];
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSForegroundColorAttributeName
                                                       withBlock:^UIColor*(UIColor* color){
            return nil;
        }];
        label.attributedText = attrStr;
    }], nil, [NSSet setWithObject:@"_64"], 0);
}

@end
