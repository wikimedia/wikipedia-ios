import WebKit
import CocoaLumberjackSwift

class WKWebViewWithSettableInputViews: WKWebView {
    private var storedInputView: UIView?
    private var storedInputAccessoryView: UIView?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        WKWebViewWithSettableInputViews.overrideUserInteractionRequirementForElementFocusIfNecessary()
        overrideNestedContentViewGetters()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func reloadInputViews() {
        guard let contentView = nestedContentView() else {
            assertionFailure("Couldn't find content view")
            return
        }
        contentView.reloadInputViews()
    }
    
    override open var inputAccessoryView: UIView? {
        get {
            return trueSelf()?.storedInputAccessoryView
        }
        set {
            self.storedInputAccessoryView = newValue
        }
    }
    
    override open var inputView: UIView? {
        get {
            return trueSelf()?.storedInputView
        }
        set {
            self.storedInputView = newValue
        }
    }

    private func add(selector: Selector, to target: AnyClass, origin: AnyClass, originSelector: Selector) {
        guard
            !target.responds(to: selector),
            let newMethod = class_getInstanceMethod(origin, originSelector),
            let typeEncoding = method_getTypeEncoding(newMethod)
            else {
                assertionFailure("Couldn't add method")
                return
        }
        class_addMethod(target, selector, method_getImplementation(newMethod), typeEncoding)
    }

    private func nestedContentView() -> UIView? {
        return scrollView.subviews.first(where: {
            return String(describing: type(of: $0)).hasPrefix("WKContent")
        })
    }
    
    private func trueSelf() -> WKWebViewWithSettableInputViews? {
        return (NSStringFromClass(type(of: self)) == "WKContentView_withCustomInputViewGetterRelays" ? wmf_firstSuperviewOfType(SectionEditorWebView.self) : self)
    }
    
    private func overrideNestedContentViewGetters() {
        guard let contentView = nestedContentView() else {
            assertionFailure("Couldn't find content view")
            return
        }
        
        if let existingClass = NSClassFromString("WKContentView_withCustomInputViewGetterRelays") {
            object_setClass(contentView, existingClass)
            return
        }
        
        guard let newContentViewClass = objc_allocateClassPair(object_getClass(contentView), "WKContentView_withCustomInputViewGetterRelays", 0) else {
            assertionFailure("Couldn't get class")
            return
        }
        
        self.add(
            selector: #selector(getter: UIResponder.inputAccessoryView),
            to: newContentViewClass.self,
            origin: SectionEditorWebView.self,
            originSelector: #selector(getter: SectionEditorWebView.inputAccessoryView)
        )
        objc_registerClassPair(newContentViewClass)
        object_setClass(contentView, newContentViewClass)
    }
}


typealias ClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

private var didSetKeyboardRequiresUserInteraction = false

extension WKWebViewWithSettableInputViews {
    // Swizzle a WKWebView method to allow web elements to be focused without user interaction
    // Replace the method with an implementation that wraps the existing implementation and always passes true for `userIsInteracting`
    // https://stackoverflow.com/questions/32449870/programmatically-focus-on-a-form-in-a-webview-wkwebview
    static func overrideUserInteractionRequirementForElementFocusIfNecessary() {
        assert(Thread.isMainThread)
        guard !didSetKeyboardRequiresUserInteraction else {
            return
        }
        defer {
            didSetKeyboardRequiresUserInteraction = true
        }

        guard let WKContentView: AnyClass = NSClassFromString("WKContentView") else {
            DDLogError("keyboardDisplayRequiresUserAction extension: Cannot find the WKContentView class")
            return
        }
        
        // The method signature changed over time, try all of them to find the one for this platform
        let selectorStrings = [
            "_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:",
            "_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:",
            "_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:"
        ]
        
        #if DEBUG
        var found = false
        #endif
        for selectorString in selectorStrings {
            let sel = sel_getUid(selectorString)
            guard let method = class_getInstanceMethod(WKContentView, sel) else {
                continue
            }
            let originalImp = method_getImplementation(method)
            let original: ClosureType = unsafeBitCast(originalImp, to: ClosureType.self)
            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
                original(me, sel, arg0, true, arg2, arg3, arg4)
            }
            let imp = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
            #if DEBUG
            found = true
            #endif
            break
        }
        #if DEBUG
        assert(found, "Didn't find the method to swizzle. Maybe the signature changed.")
        #endif
    }
}
