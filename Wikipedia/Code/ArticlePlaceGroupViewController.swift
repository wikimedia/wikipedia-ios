import UIKit
import WMF.WMFTaskGroup

protocol ArticlePlaceGroupViewControllerDelegate: NSObjectProtocol {
    func articlePlaceGroupViewController(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController, didSelectPlaceView: ArticlePlaceView)
    func articlePlaceGroupViewController(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController, didDeselectPlaceView: ArticlePlaceView)
    func articlePlaceGroupViewControllerDidDismiss(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController)
    func articlePlaceGroupViewControllerDidSelectZoom(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController)

}

extension CGPoint {
    func distance(fromPoint: CGPoint) -> CGFloat {
        let dx = self.x - fromPoint.x
        let dy = self.y - fromPoint.y
        return sqrt(dx*dx + dy*dy)
    }
}


class ArticlePlaceGroupViewController: UIViewController {
    let articles: [WMFArticle]
    private let placeViews: [ArticlePlaceView]
    private let maxArticleCount = 8
    private let radius: Double
    public weak var delegate: ArticlePlaceGroupViewControllerDelegate?
    private let zoomPlaceView: ArticlePlaceView
    private let zoomPlaceViewScale: CGFloat
    
    required init(articles: [WMFArticle]) {
        self.articles = articles
        var placeViews = [ArticlePlaceView]()
        let maximum = min(maxArticleCount, articles.count)
        for article in articles[0..<maximum] {
            guard let coordinate = article.coordinate, let key = article.key else {
                continue
            }
            let place = ArticlePlace(coordinate: coordinate, nextCoordinate: nil, articles: [article], identifier: key)
            let placeView = ArticlePlaceView(annotation: place, reuseIdentifier: nil)
            placeView.set(alwaysShowImage: true, animated: false)
            placeViews.append(placeView)
        }
        let zoomPlace = ArticlePlace(coordinate: kCLLocationCoordinate2DInvalid, nextCoordinate: nil, articles: [], identifier: "zoom")
        zoomPlaceView = ArticlePlaceView(annotation: zoomPlace, reuseIdentifier: "zoom")
        zoomPlaceView.set(alwaysShowImage: true, animated: false)
        self.placeViews = placeViews
        radius = Double(zoomPlaceView.imageDimension + CGFloat((maximum + 1) * 4))
        zoomPlaceViewScale = zoomPlaceView.groupDimension / zoomPlaceView.imageDimension
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let tintView: UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tintView.frame = view.bounds
        tintView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tintView.alpha = 0
        view.addSubview(tintView)
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        view.addGestureRecognizer(tapGR)
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGR.require(toFail: tapGR)
        view.addGestureRecognizer(panGR)
        
        let pinchGR = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        panGR.require(toFail: tapGR)
        view.addGestureRecognizer(pinchGR)
    }
    
    func handlePinchGesture(_ pinchGR: UIPinchGestureRecognizer) {
        guard isHidden == false && pinchGR.state != .failed && pinchGR.state != .possible else {
            return
        }
        delegate?.articlePlaceGroupViewControllerDidDismiss(self)
    }
    
    
    func handlePanGesture(_ panGR: UIPanGestureRecognizer) {
        guard isHidden == false && panGR.state != .failed && panGR.state != .possible else {
            return
        }
        delegate?.articlePlaceGroupViewControllerDidDismiss(self)
    }
    
    func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        guard isHidden == false && tapGR.state == .recognized else {
            return
        }
        let point = tapGR.location(in: view)
        var didSelect = false
        for placeView in placeViews {
            let convertedRect = view.convert(placeView.imageView.frame, from: placeView.imageView.superview)
            guard convertedRect.contains(point) else {
                continue
            }
            didSelect = true
            selectPlaceView(placeView)
            break
        }
        
        guard !didSelect else {
            return
        }
    
        var didDeselect = false
        
        for placeView in placeViews {
            guard placeView.isSelected else {
                continue
            }
            didDeselect = true
            placeView.setSelected(false, animated: true)
            delegate?.articlePlaceGroupViewController(self, didDeselectPlaceView: placeView)
        }
        
        if let center = self.center {
            let distance = point.distance(fromPoint: center)
            guard distance > 0.5*zoomPlaceView.imageDimension else {
                delegate?.articlePlaceGroupViewControllerDidSelectZoom(self)
                return
            }
        }
        
        guard !didDeselect else {
            return
        }
        
        delegate?.articlePlaceGroupViewControllerDidDismiss(self)
    }
    
    func selectPlaceView(_ placeView: ArticlePlaceView) {
        guard !isHidden else {
            return
        }
        for placeView in placeViews {
            guard placeView.isSelected else {
                continue
            }
            placeView.setSelected(false, animated: true)
            delegate?.articlePlaceGroupViewController(self, didDeselectPlaceView: placeView)
        }
        guard placeView.reuseIdentifier != "zoom" else {
            delegate?.articlePlaceGroupViewControllerDidSelectZoom(self)
            return
        }
        placeView.setSelected(true, animated: true)
        delegate?.articlePlaceGroupViewController(self, didSelectPlaceView: placeView)
    }
    
    func layoutForCenter(center: CGPoint) {
        let count = placeViews.count
        var i = 1
        for placeView in placeViews {
            let theta = 2*M_PI / Double(count)
            let angle = -1*M_PI_2 + theta*Double(i - 1)
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            placeView.center = CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y))
            placeView.transform = CGAffineTransform.identity
            i += 1
        }
        
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, traitCollection.displayScale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let maxDimension = max(view.bounds.size.width, view.bounds.size.height)
        let grayColor = UIColor(white: 0, alpha: 0.5).cgColor
        let clearColor = UIColor.clear.cgColor
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, CGFloat(radius)/maxDimension, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: [clearColor, grayColor, grayColor] as CFArray, locations: locations) else {
            return
        }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 10, endCenter: center, endRadius: maxDimension, options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        tintView.image = image
        UIGraphicsEndImageContext()
    }
    
    var center: CGPoint?
    
    func show(center: CGPoint) {
        self.center = center
        //tintView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        let scale = traitCollection.displayScale
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, scale)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let maxDimension = max(view.bounds.size.width, view.bounds.size.height)
        let grayColor = UIColor(white: 0, alpha: 0.5).cgColor
        let clearColor = UIColor.clear.cgColor
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, CGFloat(radius)/maxDimension, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: [clearColor, grayColor, grayColor] as CFArray, locations: locations) else {
            return
        }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 10, endCenter: center, endRadius: maxDimension, options: [])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        tintView.image = image
        UIGraphicsEndImageContext()
        
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(-1*M_PI))
        let scaleTransform = CGAffineTransform(scaleX: zoomPlaceViewScale, y: zoomPlaceViewScale)
        let transform = rotationTransform.concatenating(scaleTransform)
        
        for placeView in placeViews {
            placeView.center = center
            view.addSubview(placeView)
            placeView.alpha = 0
            placeView.transform = transform
        }
        
        zoomPlaceView.transform = transform
        zoomPlaceView.center = center
        zoomPlaceView.alpha = 0
        view.addSubview(zoomPlaceView)

        let count = placeViews.count
        var i = 1
        let delay: TimeInterval = 0.05
        for placeView in self.placeViews {
            UIView.animate(withDuration: 0.6, delay: delay * TimeInterval(i), usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
                    let theta = 2*M_PI / Double(count)
                    let angle = -1*M_PI_2 + theta*Double(i - 1)
                    let x = self.radius * cos(angle)
                    let y = self.radius * sin(angle)
                    placeView.center = CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y))
                    placeView.transform = CGAffineTransform.identity
            }) { (done) in
//                placeView.layer.shouldRasterize = false
            }
            
            UIView.animate(withDuration: 0.15, delay: delay * TimeInterval(i), options: [.allowUserInteraction], animations: {
                placeView.alpha = 1
            }, completion: nil)
            i += 1
        }
        
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: {
            self.zoomPlaceView.transform = CGAffineTransform.identity
        }) { (done) in
            //                placeView.layer.shouldRasterize = false
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction], animations: {
            self.zoomPlaceView.alpha = 1
        }, completion: nil)
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [.allowUserInteraction], animations: {
            self.tintView.alpha = 1
        }, completion: nil)
    }
    
    var isHidden = false
    
    func hide(completion: @escaping () -> Void) {
        isHidden = true
        guard let center = center else {
            completion()
            return
        }
        //let scale = traitCollection.displayScale
        for placeView in placeViews {
//            placeView.layer.rasterizationScale = scale
//            placeView.layer.shouldRasterize = true
            guard placeView.isSelected else {
                continue
            }
            placeView.setSelected(false, animated: true)
            delegate?.articlePlaceGroupViewController(self, didDeselectPlaceView: placeView)
        }
        let delay: TimeInterval = 0.05
        let group = WMFTaskGroup()
        var i = 1
        let rotationTransform = CGAffineTransform(rotationAngle: CGFloat(-1*M_PI))
        let scaleTransform = CGAffineTransform(scaleX: zoomPlaceViewScale, y: zoomPlaceViewScale)
        let transform = rotationTransform.concatenating(scaleTransform)
        for placeView in placeViews.reversed() {
            group.enter()
            UIView.animate(withDuration: 0.3, delay: delay * TimeInterval(i), options: [.allowUserInteraction], animations: {
                placeView.center = center
                placeView.transform = transform
            }) { (done) in
//                placeView.layer.shouldRasterize = false
                group.leave()
            }
            
            UIView.animate(withDuration: 0.3, delay: delay * TimeInterval(i), options: [.allowUserInteraction], animations: {
                placeView.alpha = 0
            }, completion: nil)
            i += 1
        }
        
        UIView.animate(withDuration: 0.3, delay:  delay * TimeInterval(i - 1), options: [.allowUserInteraction], animations: {
            self.zoomPlaceView.transform = transform
            self.zoomPlaceView.alpha = 0
        }, completion: nil)
        
        UIView.animate(withDuration: 0.3 + delay * TimeInterval(i - 1), delay: 0, options: [.allowUserInteraction], animations: {
            self.tintView.alpha = 0
        }, completion: nil)
        
        group.waitInBackground(completion: completion)
    }

}
