//
//  ViewController.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 13/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var collectionsViewer: CollectionsViewer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.edgesForExtendedLayout = [];

        title = "Collections Viewer"
        if let nb = self.navigationController?.navigationBar {
            nb.isTranslucent = false
        }

        collectionsViewer = CollectionsViewer.show(in: self.view, of: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

