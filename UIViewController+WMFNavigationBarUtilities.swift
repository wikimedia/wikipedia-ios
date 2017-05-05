import UIKit

extension UIViewController {
    
    // TODO: make a static func?
    public func wmf_addBottomShadow(view: UIView) {
        // Setup extended navigation bar
        //   Borrowed from https://developer.apple.com/library/content/samplecode/NavBar/Introduction/Intro.html
        view.shadowOffset = CGSize(width: 0, height: CGFloat(1) / UIScreen.main.scale)
        view.shadowRadius = 0
        view.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        view.shadowOpacity = 0.25
    }
    
    public func wmf_updateNavigationBar(removeUnderline: Bool) {
        if (removeUnderline) {
            navigationController!.navigationBar.isTranslucent = false
            navigationController!.navigationBar.shadowImage = #imageLiteral(resourceName: "transparent-pixel")
            navigationController!.navigationBar.setBackgroundImage(#imageLiteral(resourceName: "pixel"), for: .default)
        } else {
            navigationController!.navigationBar.isTranslucent = false
            navigationController!.navigationBar.shadowImage = nil
            navigationController!.navigationBar.setBackgroundImage(nil, for: .default)
        }
        
        // this little dance is to force the navigation bar to redraw. Without it,
        // the underline would not be removed until the view fully animated, instead of
        // before
        // http://stackoverflow.com/a/40948889
        navigationController!.isNavigationBarHidden = true;
        navigationController!.isNavigationBarHidden = false;
    }
}
