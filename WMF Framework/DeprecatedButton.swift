import Foundation

// https://forums.swift.org/t/suppressing-deprecated-warnings/53970/6

public protocol DeprecatedButton {
    var deprecatedContentEdgeInsets: UIEdgeInsets { get set }
    var deprecatedImageEdgeInsets: UIEdgeInsets { get set }
    var deprecatedTitleEdgeInsets: UIEdgeInsets { get set }
    var deprecatedAdjustsImageWhenHighlighted: Bool { get set }
    var deprecatedAdjustsImageWhenDisabled: Bool { get set }
}

extension UIButton: DeprecatedButton {
    
    @available(iOS, deprecated: 15.0)
    public var deprecatedAdjustsImageWhenHighlighted: Bool {
        get {
            return self.adjustsImageWhenHighlighted
        }
        set {
            self.adjustsImageWhenHighlighted = newValue
        }
    }
    
    @available(iOS, deprecated: 15.0)
    public var deprecatedAdjustsImageWhenDisabled: Bool {
        get {
            return self.adjustsImageWhenDisabled
        }
        set {
            self.adjustsImageWhenDisabled = newValue
        }
    }
    
    @available(iOS, deprecated: 15.0)
    public var deprecatedContentEdgeInsets: UIEdgeInsets {
        get {
            return self.contentEdgeInsets
        }
        set {
            self.contentEdgeInsets = newValue
        }
    }
    
    @available(iOS, deprecated: 15.0)
    public var deprecatedImageEdgeInsets: UIEdgeInsets {
        get {
            return self.imageEdgeInsets
        }
        set {
            self.imageEdgeInsets = newValue
        }
    }
    
    @available(iOS, deprecated: 15.0)
    public var deprecatedTitleEdgeInsets: UIEdgeInsets {
        get {
            return self.titleEdgeInsets
        }
        set {
            self.titleEdgeInsets = newValue
        }
    }
}
