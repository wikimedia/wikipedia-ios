import UIKit

class TalkPageArchivesViewController: ThemeableViewController, CustomNavigationContaining, UITableViewDelegate {
    var items: [String] = []
    
    var navigationViewChildViewController: CustomNavigationChildViewController?
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    var redView: TempShiftingView?
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: false, shiftOnScrollUp: false)
        return ShiftingNavigationBarView(order: 0, config: config, navigationItems: items, popDelegate: self)
    }()
    
    init(theme: Theme) {
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archives"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicStyle")
        tableView.dataSource = self
        tableView.delegate = self
        
        setup(shiftingSubviews: [barView, blueView, greenView], shadowBehavior: .showUponScroll, scrollView: tableView, theme: theme)
        
        self.navigationViewChildViewController?.data.isLoading = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [self] in
            self.navigationViewChildViewController?.data.isLoading = false
            
            let redView = TempShiftingView(color: .red, order: 3)
            self.redView = redView
            self.navigationViewChildViewController?.addShiftingSubviews(views: [redView])
            
            for _ in 0..<100 {
                items.append("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
            }
            
            tableView.reloadData()
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        tableView.backgroundColor = theme.colors.paperBackground
        navigationViewChildViewController?.apply(theme: theme)
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

extension TalkPageArchivesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        navigationViewChildViewController?.scrollViewDidScroll(scrollView)
    }
}
