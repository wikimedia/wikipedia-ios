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

#define MOCKITO_SHORTHAND 1
#import <OCMockito/OCMockito.h>

#import "NSAttributedString+WMFModify.h"

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

- (UILabel*)getLabelWithAttributedStringFromBlock:(NSAttributedString* (^)(NSAttributedString*))block {
    UILabel* label = [[UILabel alloc] init];
    label.lineBreakMode   = NSLineBreakByWordWrapping;
    label.numberOfLines   = 0;
    label.backgroundColor = [UIColor whiteColor];
    label.attributedText  = block([self getTestAttrStr]);

    CGSize preHeightAdjustmentSize = (CGSize){320, 100};

    CGSize heightAdjustedSize = [label systemLayoutSizeFittingSize:preHeightAdjustmentSize withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];

    label.frame = (CGRect){CGPointZero, heightAdjustedSize};
    return label;
}

- (void)test0ReferenceOutput {
    UILabel* label = [self getLabelWithAttributedStringFromBlock:^(NSAttributedString* attrStr){
        return attrStr;
    }];

    FBSnapshotVerifyViewWithOptions(label, nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testRemoveAllStrikeThroughs {
    UILabel* label = [self getLabelWithAttributedStringFromBlock:^(NSAttributedString* attrStr){
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSStrikethroughStyleAttributeName
                                                       withBlock:^NSNumber*(NSNumber* strike){
            return nil;
        }];
        return attrStr;
    }];

    FBSnapshotVerifyViewWithOptions(label, nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testChangeGreenBackgroundColorsToBlue {
    UILabel* label = [self getLabelWithAttributedStringFromBlock:^(NSAttributedString* attrStr){
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSBackgroundColorAttributeName
                                                       withBlock:^UIColor*(UIColor* color){
            return [color isEqual:[UIColor greenColor]] ? [UIColor blueColor] : color;
        }];
        return attrStr;
    }];

    FBSnapshotVerifyViewWithOptions(label, nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testChangeReduceLineSpacing {
    UILabel* label = [self getLabelWithAttributedStringFromBlock:^(NSAttributedString* attrStr){
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSParagraphStyleAttributeName
                                                       withBlock:^NSParagraphStyle*(NSParagraphStyle* paragraphStyle){
            NSMutableParagraphStyle* mutablePStyle = paragraphStyle.mutableCopy;
            mutablePStyle.lineSpacing = 2;
            return mutablePStyle;
        }];
        return attrStr;
    }];

    FBSnapshotVerifyViewWithOptions(label, nil, [NSSet setWithObject:@"_64"], 0);
}

- (void)testRemovingLink {
    UILabel* label = [self getLabelWithAttributedStringFromBlock:^(NSAttributedString* attrStr){
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSLinkAttributeName
                                                       withBlock:^id (id link){
            return nil;
        }];
        attrStr = [attrStr wmf_attributedStringChangingAttribute:NSForegroundColorAttributeName
                                                       withBlock:^UIColor*(UIColor* color){
            return nil;
        }];
        return attrStr;
    }];

    FBSnapshotVerifyViewWithOptions(label, nil, [NSSet setWithObject:@"_64"], 0);
}

@end
