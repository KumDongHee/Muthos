//
//  FindPwdCont.swift
//  Muthos
//
//  Created by 김성재 on 2017. 1. 22..
//
//

import UIKit

class FindPwdConfirmCont: UIViewController {

    @IBOutlet weak var confirmButton: UIButton!
    
    var confirm: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        confirmButton.layer.cornerRadius = 3.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func confirm(_ sender: Any) {
        confirm?()
    }
}
