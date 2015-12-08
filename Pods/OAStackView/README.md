# OAStackView

[![Build Status](https://travis-ci.org/oarrabi/OAStackView.svg)](https://travis-ci.org/oarrabi/OAStackView)
[![Version](https://img.shields.io/cocoapods/v/OAStackView.svg?style=flat)](http://cocoapods.org/pods/OAStackView)
[![License](https://img.shields.io/cocoapods/l/OAStackView.svg?style=flat)](http://cocoapods.org/pods/OAStackView)
[![Platform](https://img.shields.io/cocoapods/p/OAStackView.svg?style=flat)](http://cocoapods.org/pods/OAStackView)

iOS 9 introduced the very cool [UIStackView](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/), UIStackView can be used to easily create simple and complex layouts.

As expected `UIStackView` can only be used for iOS 9 and up. This project tries to port back the stackview to iOS 7+.

`OAStackView` aims at replicating all the features in `UIStackView`

<p align="center"><img src ="http://g.recordit.co/RPV2txRGLu.gif" /></p>

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Since `OAStackView` mimics the interface of `UIStackView`, the usage of `OAStackView` is similar to `UIStackView`.

`OAStackView` Can be either used from the Interface builder, or from code.

### Interface Builder

Drag a a UIView into your view controller, and add some views to it.


<p align="center"><img src="http://i1348.photobucket.com/albums/p740/o_abdelhafith/step1_zps2xxl75vw.png" border="0" alt=" photo step1_zps2xxl75vw.png" height="360px" width="200px"/></p>

Change the class to `OAStackView`

<p align="center"><img src="http://i1348.photobucket.com/albums/p740/o_abdelhafith/step2_zpsfgwirklz.png" border="0" alt=" photo step2_zpsfgwirklz.png" height="220px" width="200px"/></p>

(Optional) Change the stack Axis (set Axis Value to 0 for Horizontal or 1 for Vertical), Spacing, Alignment or distribution.

<p align="center"><img src="http://i1348.photobucket.com/albums/p740/o_abdelhafith/step3_zpsmk8xw3hz.png" border="0" alt=" photo step3_zpsmk8xw3hz.png" height="233 the viewpx" width="200px"/></p>

Run the project!

<p align="center"><img src="http://i1348.photobucket.com/albums/p740/o_abdelhafith/step4_zpsgl92oeoc.png" border="0" alt=" photo step4_zpsgl92oeoc.png" height="200px" width="200px"/> </p>


### From Code

To use `OAStackView` from code, Please refer to [UIStackView](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/) for proper documentation.

As a quick example on its usage do the following:

Create a couple of views to be stacked:

```objc
 UILabel *l1 = [[UILabel alloc] init];
 l1.text = @"Label 1";
 UILabel *l2 = [[UILabel alloc] init];
 l2.text = @"Label 2";
```

Create the stack view passing the array of views:

```objc
OAStackView *stackView = [[OAStackView alloc] initWithArrangedSubviews:@[l1, l2]];
stackView.translatesAutoresizingMaskIntoConstraints = NO;
```

Add the stack view to `self.view`

```objc
[self.view addSubview:stackView];

[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30-[stackView]"
                                                                  options:0
                                                                  metrics:0
                                                                    views:NSDictionaryOfVariableBindings(stackView)]];

[self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[stackView]"
                                                                  options:0
                                                                  metrics:0
                                                                    views:NSDictionaryOfVariableBindings(stackView)]];
```

## Installation

OAStackView is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OAStackView"
```

## Tests

Since `OAStackView` has been built from reverse engineering `UIStackView`, and since I intend to keep updating and refactoring `OAStackView`, tests was one of the requirements going forward.

The following a [human readable](https://raw.githubusercontent.com/oarrabi/OAStackView/master/Example/Tests/tests.transcript.txt?token=ABZLPOoXoCREu-BpaaIEVcTY5i1icbkrks5ViJ_9wA%3D%3D) text subscript (generated with [specipy](https://github.com/oarrabi/specipy)).

## Contribution

All contributions in any form are welcomed, if you find the project helpful, and you want to contribute then please do.

## Known Issues, and future improvements

### Missing functionality
`OAStackView` implements most of the features from `UIStackView` except the following:

- [ ] `baselineRelativeArrangement`   

	@property(nonatomic,getter=isBaselineRelativeArrangement) BOOL baselineRelativeArrangement;

- [x] `layoutMarginsRelativeArrangement`     


	@property(nonatomic,getter=isLayoutMarginsRelativeArrangement) BOOL layoutMarginsRelativeArrangement;    

`UIStackViewDistribution` is also partially implemented (2 elements out of 5 are still not implemented)    

- [x] `UIStackViewDistributionFill`
- [x] `UIStackViewDistributionFillEqually`    
- [x] `UIStackViewDistributionFillProportionally`   
- [ ] `UIStackViewDistributionEqualSpacing`    
- [ ] `UIStackViewDistributionEqualCentering`

Please refer to [UIStackView](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/) for proper documentation.

### Future improvements
The following would be nice to have for future versions

- [ ] Covering the remaining functionality from `UIStackView`
- [ ] Better Documentation
- [ ] Better test coverage for some edge cases
- [ ] Rewrite in swift, or more swift friendly

## Author

Omar Abdelhafith, o.arrabi@me.com

## License

OAStackView is available under the MIT license. See the LICENSE file for more info.
