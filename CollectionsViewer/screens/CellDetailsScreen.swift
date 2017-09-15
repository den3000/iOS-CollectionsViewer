//
//  CellDetailsScreen.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 15/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit

class CellDetailsScreen: UIViewController {

    @IBOutlet public weak var label: UILabel?
    public var text: String?

    static func show(in viewController: UIViewController?) -> CellDetailsScreen {
        let vc = CellDetailsScreen(nibName: nil, bundle: nil)
        viewController?.navigationController?.pushViewController(vc, animated: true)
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.edgesForExtendedLayout = [];
        title = "Cell Details"
        if let nb = self.navigationController?.navigationBar {
            nb.isTranslucent = false
        }

        label?.text = text
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
