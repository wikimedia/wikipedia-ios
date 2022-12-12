import UIKit

class TalkPageArchivesContentViewUIKit: SetupView {
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
    
    let redView = AdjustingView(color: .red, order: 0)
    let blueView = AdjustingView(color: .blue, order: 1)
    let greenView = AdjustingView(color: .green, order: 2)
    
    var customNavigationBarSubviews: [CustomNavigationBarSubviewHeightAdjusting] {
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
