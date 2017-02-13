//
// VTAcknowledgement.h
//
// Copyright (c) 2013-2017 Vincent Tourraine (http://www.vtourraine.net)
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

NS_ASSUME_NONNULL_BEGIN

/**
 `VTAcknowledgement` is a subclass of `NSObject` that represents a single acknowledgement.
 */
@interface VTAcknowledgement : NSObject

/**
 The acknowledgement title (for instance the pod’s name).
 */
@property (nonatomic, copy) NSString *title;

/**
 The acknowledgement body text (for instance the pod’s license).
 */
@property (nonatomic, copy) NSString *text;

/**
 The acknowledgement license text (for instance the pod’s license type).
 */
@property (nonatomic, copy, nullable) NSString *license;


/**
 Initializes an acknowledgement with a title and a body text.

 @param title The acknowledgement title.
 @param text The acknowledgement body text.
 @param license The acknowledgement license type.

 @return The newly initialized acknowledgement.
 */
- (instancetype)initWithTitle:(NSString *)title
                         text:(NSString *)text
                      license:(nullable NSString *)license NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
