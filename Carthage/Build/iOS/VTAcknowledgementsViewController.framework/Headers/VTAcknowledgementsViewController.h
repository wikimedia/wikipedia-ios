//
// VTAcknowledgementsViewController.h
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
@import UIKit;
#else
#import <UIKit/UIKit.h>
#endif

#import "VTAcknowledgementsParser.h"
#import "VTAcknowledgement.h"

/**
 `VTAcknowledgementsViewController` is a subclass of `UITableViewController` that displays
 a list of acknowledgements.
 */
@interface VTAcknowledgementsViewController : UITableViewController

/**
 Array of `VTAcknowledgement`.
 */
@property (nonatomic, strong, nullable) NSArray <VTAcknowledgement *> *acknowledgements;

/**
 Header text to be displayed above the list of the acknowledgements. 
 It needs to get set before `viewDidLoad` gets called.
 Its value can be defined in the header of the plist file.
 */
@property (nonatomic, copy, nullable) IBInspectable NSString *headerText;

/**
 Footer text to be displayed below the list of the acknowledgements.
 It needs to get set before `viewDidLoad` gets called.
 Its value can be defined in the header of the plist file.
 */
@property (nonatomic, copy, nullable) IBInspectable NSString *footerText;

/**
 Acknowledgements plist file name whose contents to be loaded.
 It expects to get set by "User Defined Runtime Attributes" in Interface Builder.
 */
@property (nonatomic, copy, nullable) IBInspectable NSString *acknowledgementsPlistName;


/**
 Creates an acknowledgements view controller with the content of the `Pods-acknowledgements.plist`.

 @return A newly created `VTAcknowledgementsViewController` instance.
 */
+ (nullable instancetype)acknowledgementsViewController NS_SWIFT_NAME(acknowledgementsViewController());

/**
 The localized version of “Acknowledgements”.
 You can use this value for the button presenting the `VTAcknowledgementsViewController`, for instance.

 @return The localized title.
 */
+ (nonnull NSString *)localizedTitle;

/**
 **Deprecated** Initializes an acknowledgements view controller with the content of an acknowledgements file (by its path).

 @param acknowledgementsPlistPath The path to the acknowledgements `.plist` file.

 @return A newly created `VTAcknowledgementsViewController` instance.

 @see -initWithPlistPath:
 */
- (nullable instancetype)initWithAcknowledgementsPlistPath:(nullable NSString *)acknowledgementsPlistPath DEPRECATED_MSG_ATTRIBUTE("use -initWithPath: method instead");

/**
 Initializes an acknowledgements view controller with the content of an acknowledgements file (by its path).

 @param acknowledgementsPlistPath The path to the acknowledgements `.plist` file.

 @return A newly created `VTAcknowledgementsViewController` instance.
 */
- (nullable instancetype)initWithPath:(nullable NSString *)acknowledgementsPlistPath;

/**
 **Deprecated** Initializes an acknowledgements view controller with the content of an acknowledgements file (by its name).

 @param acknowledgementsFileName The file name for the acknowledgements `.plist` file from the main bundle.

 @return A newly created `VTAcknowledgementsViewController` instance.

 @see -initWithFileNamed:
 */
- (nullable instancetype)initWithAcknowledgementsFileNamed:(nullable NSString *)acknowledgementsFileName DEPRECATED_MSG_ATTRIBUTE("use -initWithFileNamed: method instead");

/**
 Initializes an acknowledgements view controller with the content of an acknowledgements file (by its name).

 @param acknowledgementsFileName The file name for the acknowledgements `.plist` file from the main bundle.

 @return A newly created `VTAcknowledgementsViewController` instance.
 */
- (nullable instancetype)initWithFileNamed:(nonnull NSString *)acknowledgementsFileName;

@end
