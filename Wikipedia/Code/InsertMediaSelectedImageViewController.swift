import PhotosUI

protocol InsertMediaSelectedImageViewControllerDelegate: AnyObject {
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, didSetSelectedImage selectedImage: UIImage?, from searchResult: InsertMediaSearchResult)
    func insertMediaSelectedImageViewController(_ insertMediaSelectedImageViewController: InsertMediaSelectedImageViewController, willSetSelectedImageFrom searchResult: InsertMediaSearchResult)
}

final class InsertMediaSelectedImageViewController: UIViewController {
    private let selectedView = InsertMediaSelectedImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var theme = Theme.standard
    weak var delegate: InsertMediaSelectedImageViewControllerDelegate?
    
    var image: UIImage? {
        return selectedView.image
    }

    var searchResult: InsertMediaSearchResult? {
        return selectedView.searchResult
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
        view.addCenteredSubview(activityIndicator)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            wmf_showEmptyView(of: .noSelectedImageToInsert, target: self, action: #selector(goToImagePicker), theme: theme, frame: view.bounds)
        } else {
            wmf_hideEmptyView()
        }
    }

    private func startActivityIndicator() {
        wmf_hideEmptyView()
        cancelPreviousActivityIndicatorSelectors()
        selectedView.isHidden = true
        perform(#selector(_startActivityIndicator), with: nil, afterDelay: 0.3)
    }
    
    @objc private func _startActivityIndicator() {
        activityIndicator.startAnimating()
    }

    @objc private func stopActivityIndicator() {
        cancelPreviousActivityIndicatorSelectors()
        selectedView.isHidden = false
        activityIndicator.stopAnimating()
    }

    @objc private func cancelPreviousActivityIndicatorSelectors() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_startActivityIndicator), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(stopActivityIndicator), object: nil)
    }
}

extension InsertMediaSelectedImageViewController: InsertMediaSearchResultsCollectionViewControllerDelegate {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult) {
        delegate?.insertMediaSelectedImageViewController(self, willSetSelectedImageFrom: searchResult)
        startActivityIndicator()
        guard let imageURL = searchResult.imageURL(for: view.bounds.width) else {
            stopActivityIndicator()
            return
        }
        if selectedView.moreInformationAction == nil {
            selectedView.moreInformationAction = { [weak self] url in
                self?.navigate(to: url, useSafari: true)
            }
        }
        selectedView.configure(with: imageURL, searchResult: searchResult, theme: theme) { error in
            guard error == nil else {
                self.stopActivityIndicator()
                return
            }
            self.stopActivityIndicator()
            if self.selectedView.superview == nil {
                self.view.wmf_addSubviewWithConstraintsToEdges(self.selectedView)
            }
            self.delegate?.insertMediaSelectedImageViewController(self, didSetSelectedImage: self.image, from: searchResult)
        }
    }
}

extension InsertMediaSelectedImageViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        wmf_applyTheme(toEmptyView: theme)
        view.backgroundColor = theme.colors.baseBackground
        activityIndicator.color = theme.isDark ? .white : .gray
    }
}

extension InsertMediaSelectedImageViewController {

    @objc func goToImagePicker() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                self.presentImagePicker(source: .camera)
            })
        }

        sheet.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            self.presentImagePicker(source: .photoLibrary)
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(
            x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0
        )
        sheet.popoverPresentationController?.permittedArrowDirections = []

        present(sheet, animated: true)
    }

    private func presentImagePicker(source: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = source
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    private func goToCommonsUpload(image: UIImage, coordinate: CLLocationCoordinate2D) {
        guard let navController = self.navigationController else {
            return
        }
        let coordinator = CommonsUploadCoordinator(navigationController: navController, image: image, coordinate: coordinate)
        coordinator.start()
    }

}

extension InsertMediaSelectedImageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {

        guard let picked = info[.originalImage] as? UIImage else {
            return
        }

        picker.dismiss(animated: true) {
            let coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self.goToCommonsUpload(image: picked, coordinate: coordinate)
        }

//        wmf_hideEmptyView()

        stopActivityIndicator()

//        selectedView.image = picked
        // actually it should update from search result - it would be already in commons after upload,
        // check how long it would take, if a different spinner would be needed
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

}

extension InsertMediaSelectedImageViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        // we know selectionLimit = 1, so just take the first
        guard let result = results.first,
              result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            DispatchQueue.main.async {
                guard let self = self,
                      let uiImage = object as? UIImage else {
                    return
                }
                // self.handleCommonsUpload(uiImage, metadata)
                // call a coodinator?
            }
        }
    }
}
