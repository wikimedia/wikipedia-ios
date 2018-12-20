import WebKit

class WKWebViewWithSettableInputViews: WKWebView {
    private var storedInputView: UIView?
    private var storedInputAccessoryView: UIView?
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setKeyboardRequiresUserInteraction(false)
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
        self.add(
            selector: #selector(getter: UIResponder.inputView),
            to: newContentViewClass.self,
            origin: SectionEditorWebView.self,
            originSelector: #selector(getter: SectionEditorWebView.inputView)
        )

        objc_registerClassPair(newContentViewClass)
        object_setClass(contentView, newContentViewClass)
    }
}

private typealias ClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void
private typealias BlockType =  @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void
private extension WKWebViewWithSettableInputViews {
    private func setKeyboardRequiresUserInteraction(_ value: Bool) {
        guard let WKContentView: AnyClass = NSClassFromString("WKContentView") else {
            DDLogError("Could not get class")
            return
        }
        let sel = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
        guard let method = class_getInstanceMethod(WKContentView, sel) else {
            DDLogError("Could not get method")
            return
        }
        let originalImp = method_getImplementation(method)
        let original = unsafeBitCast(originalImp, to: ClosureType.self)
        let block: BlockType = { (me, arg0, arg1, arg2, arg3, arg4) in
            original(me, sel, arg0, !value, arg2, arg3, arg4)
        }
        method_setImplementation(method, imp_implementationWithBlock(block))
    }
}
