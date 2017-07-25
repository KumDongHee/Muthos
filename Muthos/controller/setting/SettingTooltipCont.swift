//
//  SettingTooltipCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift

class SettingTooltipCont: CollapsableTableViewController {

    @IBOutlet weak var tableView: UITableView!
  
    let menu = ModelBuilder.buildMenu()
    let userViewModel = ApplicationContext.sharedInstance.userViewModel
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "툴팁"

        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.register(UINib(nibName: "TooltipCell", bundle: nil), forCellReuseIdentifier: "TooltipCell")
        self.tableView.separatorColor = UIColor(hexString: "e2e2e2")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navBarSetting()
    }
    
    func navBarSetting() {
        let leftButton = UIButton(type: UIButtonType.custom)
        
        if self.navigationController!.viewControllers.count == 1 {
            leftButton.setImage(UIImage(named: "gnb_top_icon_menu"), for: UIControlState())
        } else {
            leftButton.setImage(UIImage(named: "gnb_top_icon_back"), for: UIControlState())
        }
        
        leftButton.frame = CGRect(x: 0, y: 0, width: 21, height: 30)
        leftButton.addTarget(self, action: #selector(SettingTooltipCont.touchLeftButton), for: UIControlEvents.touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
        
        let cashButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SettingTooltipCont.touchRightButton))
        cashButton.tintColor = UIColor.black
        
        let iconButton = UIButton(type: UIButtonType.custom)
        iconButton.setImage(UIImage(named: "gnb_top_icon_coin"), for: UIControlState())
        iconButton.addTarget(self, action: #selector(SettingTooltipCont.touchRightButton), for: UIControlEvents.touchUpInside)
        iconButton.frame = CGRect(x: 0, y: 0, width: 16, height: 30)
        
        //cash
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        userViewModel.currentCash
            .subscribe(onNext: { (cash) -> Void in
            cashButton.title = formatter.string(from:(cash as NSNumber))!
        }).addDisposableTo(disposeBag)
        
        self.navigationItem.rightBarButtonItems = [cashButton, UIBarButtonItem(customView: iconButton)]
    }

    
    override func model() -> [CollapsableTableViewSectionModelProtocol]? {
        return menu
    }
    
    override func sectionHeaderNibName() -> String? {
        return "TooltipHeader"
    }
    
    override func singleOpenSelectionOnly() -> Bool {
        return true
    }
    
    override func collapsableTableView() -> UITableView? {
        return tableView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TooltipCell") as! TooltipCell
        
        if let model = model() {
            let menuSection = model[(indexPath as NSIndexPath).section]
            let item = menuSection.items[(indexPath as NSIndexPath).row] as! Tooltip
            
            cell.contentsLabel.text = item.contents
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if let model = model() {
            let menuSection = model[(indexPath as NSIndexPath).section]
            touchTooltip(menuSection, row: (indexPath as NSIndexPath).row)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }

    // MARK: - Action
    func touchLeftButton() {
        self.navigationController!.popViewController(animated: true)
    }
    
    func touchRightButton() {
        
    }
    
    func touchTooltip(_ section:CollapsableTableViewSectionModelProtocol, row:Int) {
        let storyboard = UIStoryboard(name: "Setting", bundle: nil)
        let cont = storyboard.instantiateViewController(withIdentifier: "SettingTooltipDetailCont") as! SettingTooltipDetailCont
        cont.section = section
        cont.row = row
        self.navigationController?.pushViewController(cont, animated: true)
    }
}
