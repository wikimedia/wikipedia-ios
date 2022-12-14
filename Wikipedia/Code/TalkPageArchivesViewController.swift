import UIKit

class TalkPageArchivesViewController: CustomNavigationViewController {
    
    var items: [String] = []
    
    var archivesView: TalkPageArchivesViewUIKit {
        return view as! TalkPageArchivesViewUIKit
    }
    
    override func loadView() {
        let archivesView = TalkPageArchivesViewUIKit(frame: UIScreen.main.bounds)
        _scrollView = archivesView.tableView
        view = archivesView
    }
    
    var redView: TempShiftingView?
    let blueView = TempShiftingView(color: .blue, order: 1)
    let greenView = TempShiftingView(color: .green, order: 0)
    
    lazy var barView: ShiftingNavigationBarView = {
        var items: [UINavigationItem] = []
        navigationController?.viewControllers.forEach({ items.append($0.navigationItem) })
        let config = ShiftingNavigationBarView.Config(reappearOnScrollUp: false, shiftOnScrollUp: false)
        return ShiftingNavigationBarView(order: 2, config: config, navigationItems: items, popDelegate: self)
    }()
    
    override var customNavigationViewSubviews: [CustomNavigationViewShiftingSubview] {
        if let redView {
            return [barView, blueView, greenView, redView]
        } else {
            return [barView, blueView, greenView]
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Archives"
        
        archivesView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicStyle")
        archivesView.tableView.dataSource = self
        archivesView.tableView.delegate = self
        
        for _ in 0..<100 {
            items.append("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.")
        }
        
        archivesView.tableView.reloadData()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) { [self] in
            self.redView = TempShiftingView(color: .red, order: 3)
            self.appendShiftingSubview(self.redView!)
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
