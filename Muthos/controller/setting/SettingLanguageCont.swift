//  SettingLanguageCont.swift
//  muthos
//
//  Created by 김성재 on 2016. 2. 21..
//
//

import UIKit
import RxSwift
import RxCocoa

class SettingLanguageCont: DefaultCont, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var table: UITableView!
    
    var lastSelectedIndexPath:IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "언어선택"
        
        settingTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
        
        //current language
        userViewModel.currentLanguage.subscribe(onNext: { [unowned self] (mode:LanguageMode) -> Void in
            self.tableView(self.table, didSelectRowAt: IndexPath(row: mode.rawValue, section: 0))
        }).addDisposableTo(disposeBag)
    }
    
    // MARK:- UI Setting
    func settingTableView() {
        self.automaticallyAdjustsScrollViewInsets = false
        table.register(UINib(nibName: "LanguageCell", bundle: nil), forCellReuseIdentifier: "LanguageCell")
        table.separatorColor = UIColor(hexString: "f1f1f1")
        table.tintColor = UIColor(red: 243, green: 79, blue: 53)
        table.rowHeight = 50
    }
    
    // MARK:- UITableViewDataSource, Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell") as! LanguageCell
        cell.accessoryType = ((lastSelectedIndexPath as NSIndexPath?)?.row == (indexPath as NSIndexPath).row) ? .checkmark : .none
       
        if let value = LanguageMode(rawValue: (indexPath as NSIndexPath).row)?.value {
            cell.titleLabel.text = value
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath as NSIndexPath).row != (lastSelectedIndexPath as NSIndexPath?)?.row {
            if let lastSelectedIndexPath = lastSelectedIndexPath {
                let oldCell = tableView.cellForRow(at: lastSelectedIndexPath)
                oldCell?.accessoryType = .none
            }
            
            let newCell = tableView.cellForRow(at: indexPath)
            newCell?.accessoryType = .checkmark
            
            lastSelectedIndexPath = indexPath
        }
    }
    
    // MARK: - Actions
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func touchConfirm(_ sender: AnyObject) {
        if let selectedIndex = (lastSelectedIndexPath as IndexPath?)?.row {
            userViewModel.updateLanguage(LanguageMode(rawValue: selectedIndex)!)
        }
        
        self.navigationController!.popViewController(animated: true)
    }
}
