import UIKit
import WMF.WMFTaskGroup

protocol ArticlePlaceGroupViewControllerDelegate: NSObjectProtocol {
    func articlePlaceGroupViewController(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController, didSelectPlaceView: ArticlePlaceView)
    func articlePlaceGroupViewController(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController, didDeselectPlaceView: ArticlePlaceView)
    func articlePlaceGroupViewControllerDidDismiss(_ aticlePlaceGroupViewController: ArticlePlaceGroupViewController)
}


class ArticlePlaceGroupViewController: UIViewController {
    private let placeViews: [ArticlePlaceView]
    public weak var delegate: ArticlePlaceGroupViewControllerDelegate?
    required init(articles: [WMFArticle]) {
        var placeViews = [ArticlePlaceView]()
        for article in articles {
            guard let coordinate = article.coordinate, let key = article.key else {
                continue
            }
            let place = ArticlePlace(coordinate: coordinate, nextCoordinate: nil, articles: [article], identifier: key)
            let placeView = ArticlePlaceView(annotation: place, reuseIdentifier: nil)
            placeView.set(alwaysShowImage: true, animated: false)
            placeViews.append(placeView)
        }
        self.placeViews = placeViews
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
    }
    
    func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        guard tapGR.state == .recognized else {
            return
        }
        let point = tapGR.location(in: view)
        var didSelect = false
        for placeView in placeViews {
            guard placeView.frame.contains(point) else {
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
        
        guard !didDeselect else {
            return
        }
        
        delegate?.articlePlaceGroupViewControllerDidDismiss(self)
    }
    
    func selectPlaceView(_ placeView: ArticlePlaceView) {
        for placeView in placeViews {
            guard placeView.isSelected else {
                continue
            }
            placeView.setSelected(false, animated: true)
            delegate?.articlePlaceGroupViewController(self, didDeselectPlaceView: placeView)
        }
        placeView.setSelected(true, animated: true)
        delegate?.articlePlaceGroupViewController(self, didSelectPlaceView: placeView)
    }
    
    var center: CGPoint?
    func show(center: CGPoint) {
        self.center = center
        let radius: Double = 50
        //tintView.backgroundColor = UIColor(white: 0, alpha: 0.3)

        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 2)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        let maxDimension = max(view.bounds.size.width, view.bounds.size.height)
        let grayColor = UIColor(white: 0, alpha: 0.7).cgColor
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
        
        for placeView in placeViews {
            placeView.center = center
            placeView.alpha = 0
            placeView.transform = CGAffineTransform(rotationAngle: CGFloat(-1*M_PI))
            view.addSubview(placeView)
        }
       
        let count = placeViews.count
        var i = 1
        let delay: TimeInterval = 0.05
        for placeView in self.placeViews {
            UIView.animate(withDuration: 0.6, delay: delay * TimeInterval(i), usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
                    let theta = 2*M_PI / Double(count)
                    let angle = theta*Double(i) - 0.75*M_PI
                    let x = radius * cos(angle)
                    let y = radius * sin(angle)
                    placeView.center = CGPoint(x: center.x + CGFloat(x), y: center.y + CGFloat(y))
                    placeView.transform = CGAffineTransform.identity
            }) { (done) in
                
            }
            
            UIView.animate(withDuration: 0.2, delay: delay * TimeInterval(i), options: [], animations: {
                placeView.alpha = 1
            }, completion: nil)
            i += 1
        }
        
        UIView.animate(withDuration: 0.6, delay: 0, options: [], animations: {
            self.tintView.alpha = 1
        }, completion: nil)
    }
    
    func hide(completion: @escaping () -> Void) {
        guard let center = center else {
            completion()
            return
        }
        for placeView in placeViews {
            guard placeView.isSelected else {
                continue
            }
            placeView.setSelected(false, animated: true)
            delegate?.articlePlaceGroupViewController(self, didDeselectPlaceView: placeView)
        }
        let delay: TimeInterval = 0.05
        let group = WMFTaskGroup()
        var i = 1
        for placeView in placeViews.reversed() {
            group.enter()
            UIView.animate(withDuration: 0.3, delay: delay * TimeInterval(i), options: [], animations: {

                placeView.center = center
                placeView.transform = CGAffineTransform(rotationAngle: CGFloat(-1*M_PI))
            }) { (done) in
                group.leave()
            }
            
            UIView.animate(withDuration: 0.3, delay: delay * TimeInterval(i), options: [], animations: {
                placeView.alpha = 0
            }, completion: nil)
            i += 1
        }
        
        UIView.animate(withDuration: 0.3 + delay * TimeInterval(i - 1), delay: 0, options: [], animations: {
            self.tintView.alpha = 0
        }, completion: nil)
        
        group.waitInBackground(completion: completion)
    }

}
