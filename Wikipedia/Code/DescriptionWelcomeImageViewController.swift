class DescriptionWelcomeImageViewController: UIViewController {
    var pageType:DescriptionWelcomePageType = .intro

    private lazy var imageForWelcomePageType: UIImage? = {
        switch pageType {
        case .intro:
            return UIImage(named: "description-cat")
        case .exploration:
            return UIImage(named: "description-planet")
        }
    }()

    private var image: UIImage? {
        return imageForWelcomePageType
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image = image else {
            return
        }
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        view.wmf_addSubviewWithConstraintsToEdges(imageView)
    }
}
