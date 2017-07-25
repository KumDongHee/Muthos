//
//  VersionCont.swift
//  Muthos
//
//  Created by 김성재 on 2016. 2. 22..
//
//

import UIKit

class SettingVersionCont: DefaultCont {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "버전정보"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.showLine()
    }
    
    // MARK: - Action
    override func touchLeftButton() {
        super.touchLeftButton()
        self.navigationController!.popViewController(animated: true)
    }
}
