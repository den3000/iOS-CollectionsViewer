//
//  CollectionsViewer.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 13/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit

class CollectionsViewer: UICollectionViewController {

    public internal(set) var data: [Any]?

    public var cellIdentifier: String?
    public var cellNibName: String?
    public var funcConfigureCellCallback: ((UICollectionViewCell, IndexPath, CollectionsViewer) -> UICollectionViewCell)?
    public var funcCellSelectedCallback: ((IndexPath, CollectionsViewer) -> Void)?

    static public func create(for data: [Any]) -> CollectionsViewer {
        let layout = CollectionsViewerLayout()
        let vc = CollectionsViewer(collectionViewLayout: layout)
        vc.data = data
        return vc
    }

    public func show(in view: UIView?, of viewController: UIViewController?) -> CollectionsViewer {
        viewController?.addChildViewController(self)
        view?.addSubview(self.view)

        self.view.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = NSLayoutConstraint(item: self.view, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.view, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.view, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view?.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])

        return self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        self.collectionView!.backgroundColor = UIColor.white

        if cellNibName != nil && cellIdentifier != nil {
            collectionView?.register(UINib(nibName: cellNibName!, bundle: nil), forCellWithReuseIdentifier: cellIdentifier!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func cell(nibNameAndIdentifier: String) -> CollectionsViewer {
        self.cellIdentifier = nibNameAndIdentifier
        self.cellNibName = nibNameAndIdentifier
        return self
    }

    func cell(configuration: @escaping ((UICollectionViewCell, IndexPath, CollectionsViewer) -> UICollectionViewCell)) -> CollectionsViewer {
        self.funcConfigureCellCallback = configuration
        return self
    }

    func cell(selected: @escaping ((IndexPath, CollectionsViewer) -> Void)) -> CollectionsViewer {
        self.funcCellSelectedCallback = selected
        return self
    }

    func cellIdentifier(_ cellIdentifier: String) -> CollectionsViewer {
        self.cellIdentifier = cellIdentifier
        return self
    }

    func cellNibName(_ cellNibName: String) -> CollectionsViewer {
        self.cellNibName = cellNibName
        return self
    }

    func cell(viewAttributes callback: @escaping ((IndexPath, CGFloat) -> CollectionsViewerLayoutAttributes)) -> CollectionsViewer {
        if let layout = collectionView?.collectionViewLayout as? CollectionsViewerLayout {
            _ = layout.configureCellViewAttributes(callback)
        }
        return self
    }

    func columnsNum(_ callback: @escaping ((Void) -> Int)) -> CollectionsViewer {
        if let layout = collectionView?.collectionViewLayout as? CollectionsViewerLayout {
            _ = layout.configureColumnsNum(callback)
        }
        return self
    }

    func cell(padding: CGFloat) -> CollectionsViewer {
        if let layout = collectionView?.collectionViewLayout as? CollectionsViewerLayout {
            _ = layout.configureCellPadding(padding)
        }
        return self
    }
}

extension CollectionsViewer {
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellIdentifier ?? "", for: indexPath)
        return funcConfigureCellCallback?(cell, indexPath, self) ?? cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        funcCellSelectedCallback?(indexPath, self)
    }
}

extension CollectionsViewer {
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

    }
    */
}