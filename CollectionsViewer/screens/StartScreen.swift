//
//  StartScreen.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 15/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit

class StartScreen: UIViewController {

    @IBOutlet var swReverseLists: UISwitch?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = [];
        title = "Examples"
        if let nb = self.navigationController?.navigationBar {
            nb.isTranslucent = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onNumberOneExampleCellPressed(sender: UIButton) {
        NumberOneExampleCellScreen.show(in: self, reverse: swReverseLists?.isOn ?? false)
    }

    @IBAction func onNumberTwoExampleCellPressed(sender: UIButton) {
        NumberTwoExampleCellScreen.show(in: self, reverse: swReverseLists?.isOn ?? false)
    }
}
