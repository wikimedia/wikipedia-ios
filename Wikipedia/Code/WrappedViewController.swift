import Foundation

final class WrappedViewController: ViewController {
    
    let wrappedView = WrappedView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        let fetcher = WikiWrappedFetcher()

        fetcher.fetchWikiWrapped { result in
            switch result {
            case .success(let response):
                print(response)
                let vm = WikiWrappedViewModel()
                let count  = vm.getTopicCount(articles: response.articles)
                DispatchQueue.main.async {
                    self.wrappedView.configure(topics: count)
                }
                
            case .failure(let error):
                print(error)
            }
        }

        
        wrappedView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wrappedView)
        
        let shareButton = UIButton(type: .custom)
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        view.addSubview(shareButton)
        
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrappedView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            wrappedView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 25),
            wrappedView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -25),
            wrappedView.bottomAnchor.constraint(equalTo: shareButton.topAnchor, constant: -50),
            
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        shareButton.addTarget(self, action: #selector(userDidTapShare), for: .primaryActionTriggered)
        
    }
    
    override func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
    }
    
    
    @objc func userDidTapShare() {
        let shareItem = wrappedView.wmf_snapshotImage(afterScreenUpdates: true)
        let activityViewController = UIActivityViewController(activityItems: [shareItem as Any], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
    
}

final class WrappedView: SetupView {
    
    lazy var headerStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var verticalStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named:"W")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .black
        return imageView
    }()
    
    lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        label.text = "Recap[2023]"
        return label
    }()
    
    override func setup() {
        layer.cornerCurve = .continuous
        layer.cornerRadius = 16
        layer.masksToBounds = true
        layer.borderWidth = 1
        layer.shadowColor = UIColor.gray100.cgColor
        layer.shadowRadius = 20
        layer.borderColor = UIColor.red.cgColor
        
        backgroundColor = .white
        
        addSubview(verticalStack)
        
        NSLayoutConstraint.activate([
            headerImageView.widthAnchor.constraint(equalToConstant: 55),
            headerImageView.heightAnchor.constraint(equalToConstant: 55)
        ])
    
//        headerStack.addArrangedSubview(headerImageView)
//        headerStack.addArrangedSubview(headerTitleLabel)
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    
    }
    
    func configure(topics: [String: Int]) {        
        for topic in topics {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            label.numberOfLines = 0
            label.text = "\(topic)"
            verticalStack.addArrangedSubview(label)
        }
    
    }
    
}
