import UIKit

class TalkPageArchivesContentViewUIKit: SetupView {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()
    
    override func setup() {
        super.setup()
        
        addSubview(tableView)
        NSLayoutConstraint.activate([
            safeAreaLayoutGuide.topAnchor.constraint(equalTo: tableView.topAnchor),
            safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: tableView.bottomAnchor)
        ])
    }
}

class TalkPageArchivesViewController: CustomNavigationBarViewController {
    
    var items: [String] = []

    lazy var contentView: TalkPageArchivesContentViewUIKit = {
        let contentView = TalkPageArchivesContentViewUIKit(frame: UIScreen.main.bounds)
        return contentView
    }()
    
    override func loadView() {
        view = contentView
    }
    
    let redView = AdjustingView(color: .red, order: 2)
    let blueView = AdjustingView(color: .blue, order: 1)
    let greenView = AdjustingView(color: .green, order: 0)
    
    override var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
        return [redView, blueView, greenView]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicStyle")
        contentView.tableView.dataSource = self
        contentView.tableView.delegate = self
        
        for _ in 0..<100 {
            items.append("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
        }
        
        contentView.tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("🔴\(data.totalBarHeight)")
        print("💙\(contentView.tableView.contentOffset)")
        // todo: clean up
        if contentView.tableView.contentInset.top != data.totalBarHeight {
            contentView.tableView.contentInset = UIEdgeInsets(top: data.totalBarHeight, left: 0, bottom: 0, right: 0)
            if -1 * self.contentView.tableView.contentOffset.y < data.totalBarHeight {
                var contentOffset = self.contentView.tableView.contentOffset
                contentOffset.y = -1*data.totalBarHeight
                self.contentView.tableView.setContentOffset(contentOffset, animated: false)
            }
        }
        
    }
}

extension TalkPageArchivesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicStyle", for: indexPath)
        cell.textLabel!.text = items[indexPath.row]
        return cell
    }
}

extension TalkPageArchivesViewController: UITableViewDelegate {
    
}

extension TalkPageArchivesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Note - uiscrollview and scrollview produce different logic in their offsets.
        // Adjusting the uiviewcontroller way to better fit how the custom nav bar system expects it (which caters to a SwiftUI preferences key.)
        // What we should do is produce whatever value is clearest to handle in the adjustingheight subview. Before passing that value in, adjust as appropriate before it gets in.
        let newContentOffsetY = (scrollView.contentOffset.y + scrollView.contentInset.top) * -1
        self.data.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: newContentOffsetY)
    }
}
