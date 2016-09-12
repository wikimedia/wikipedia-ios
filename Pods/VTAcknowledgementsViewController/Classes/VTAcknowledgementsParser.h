//
// VTAcknowledgementsParser.h
//
// Copyright (c) 2013-2016 Vincent Tourraine (http://www.vtourraine.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

@class VTAcknowledgement;


/**
 `VTAcknowledgementsParser` is a subclass of `NSObject` that parses a CocoaPods
 acknowledgements plist file.
 */
@interface VTAcknowledgementsParser : NSObject

/**
 The header parsed from the plist file.
 */
@property (readonly, copy, nullable) NSString *header;

/**
 The footer parsed from the plist file.
 */
@property (readonly, copy, nullable) NSString *footer;

/**
 The acknowledgements parsed from the plist file.
 */
@property (readonly, copy, nullable) NSArray <VTAcknowledgement *> *acknowledgements;


/**
 Initializes a parser and parses the content of an acknowledgements plist file.

 @param acknowledgementsPlistPath The path to the acknowledgements plist file.

 @return A newly created `VTAcknowledgementsParser` instance.
 */
- (nonnull instancetype)initWithAcknowledgementsPlistPath:(nonnull NSString *)acknowledgementsPlistPath NS_DESIGNATED_INITIALIZER;

@end
