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
    public var funcConfigureCollectionViewCallback: ((UICollectionView) -> Void)?

    internal var refreshControl: UIRefreshControl?
    internal var funcPullToRefreshCallback: ((CollectionsViewer) -> ())?

    internal var pushToRefreshThreshold: CGFloat = 100
    internal var isPushToRefreshEnabled = false;
    internal var isPushingToRefresh = false;
    internal var funcPushToRefreshCallback: ((CollectionsViewer) -> ())?
    internal var bottomProgressIndicator: BottomProgressIndicator?
    internal var indicatorInset: CGFloat = 50.0
    internal var contentInset: UIEdgeInsets?

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

        if cellNibName != nil && cellIdentifier != nil {
            collectionView?.register(UINib(nibName: cellNibName!, bundle: nil), forCellWithReuseIdentifier: cellIdentifier!)
        }

        // This is required to force UICollectionView scroll
        // normally when number of items is insufficient
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(BottomProgressIndicator.self, forCellWithReuseIdentifier: "progress")

        funcConfigureCollectionViewCallback?(collectionView!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Mutate Data
extension CollectionsViewer {
    public func set(data: [Any], callback: (() -> ())?) {
        self.data = data

        DispatchQueue.main.async {
            self.collectionView?.reloadData()

            // Prevent crashes on iOS10+
            self.collectionViewLayout.invalidateLayout()

            callback?()
        }
    }

    public func append(data: [Any], callback: (() -> ())?) {
        if self.data == nil {
            set(data: data, callback: callback)
        } else {
            let start = self.data!.count
            self.data!.append(contentsOf: data)
            let idxs = Array(start..<self.data!.count).map { IndexPath(row: $0, section: 0) }

            DispatchQueue.main.async {
                self.collectionView?.insertItems(at: idxs)
                callback?()
            }
        }
    }
}

// MARK: Pull To Refresh
extension CollectionsViewer {
    public func enablePullToRefresh(with callback: @escaping ((CollectionsViewer) -> ())) -> CollectionsViewer {
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
            collectionView?.addSubview(refreshControl!)
        }
        funcPullToRefreshCallback = callback
        return self
    }

    public func beginPullToRefresh(){
        refreshControl?.beginRefreshing()
    }

    public func endPullToRefresh(){
        refreshControl?.endRefreshing()
    }

    @objc internal func onPullToRefresh(sender:AnyObject) {
        funcPullToRefreshCallback?(self)
    }
}

// MARK: Push To Refresh
extension CollectionsViewer {
    public func enablePushToRefresh(with callback: @escaping ((CollectionsViewer) -> ())) -> CollectionsViewer {
        if !isPushToRefreshEnabled {
            isPushToRefreshEnabled = true
        }
        funcPushToRefreshCallback = callback
        return self
    }

    public func beginPushToRefresh(){
        DispatchQueue.main.async {
            self.isPushingToRefresh = true

            let contentWidth = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentWidth ?? 0
            let contentHeight = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0

            if self.bottomProgressIndicator == nil {
                self.bottomProgressIndicator = BottomProgressIndicator(frame: CGRect(
                        x: 0, y: contentHeight,
                        width: contentWidth, height: self.indicatorInset))
            } else {
                self.bottomProgressIndicator?.frame.origin = CGPoint(x: 0, y: contentHeight)
            }
            self.collectionView?.addSubview(self.bottomProgressIndicator!)

            self.contentInset = self.collectionView!.contentInset;
            self.contentInset?.bottom += self.indicatorInset;

            // In almost all cases we need to schedule scrollView inset
            // changes until scrollViewWillBeginDecelerating. But if
            // scrolling manner itself is very aggressive then we need
            // to trigger it right now. All this stuff is necessary to
            // avoid 'content jump _UP_' when scrollView contentInset changed
            if (self.collectionView?.isDecelerating ?? false) && self.contentInset != nil {
                self.setScrollView(contentInset: self.contentInset!, animated: false) { finished in
                }
                self.contentInset = nil
            }
        }
    }

    public func endPushToRefresh(){
        DispatchQueue.main.async {
            self.isPushingToRefresh = false

            self.bottomProgressIndicator?.removeFromSuperview()

            var contentInset = self.collectionView!.contentInset;
            contentInset.bottom -= self.indicatorInset;

            self.setScrollView(contentInset: contentInset, animated: false) { finished in
                let contentHeight = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0
                let contentOffset = self.collectionView?.contentOffset.y ?? 0
                let collectionHeight = self.collectionView?.frame.height ?? 0

                if contentOffset + collectionHeight >= contentHeight + self.indicatorInset {
                    let contentOffset = CGPoint(x: self.collectionView!.contentOffset.x, y: self.collectionView!.contentOffset.y - self.indicatorInset)
                    self.collectionView?.setContentOffset(contentOffset, animated: true)
                }
            }
        }
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if data == nil {return}

        let contentHeight = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0
        let contentOffset = self.collectionView?.contentOffset.y ?? 0
        let collectionHeight = collectionView?.frame.height ?? 0
        if contentHeight < collectionHeight {
            if contentOffset > pushToRefreshThreshold && isPushToRefreshEnabled && !isPushingToRefresh {
                beginPushToRefresh()
                funcPushToRefreshCallback?(self)
            }
        } else {
            if contentOffset + collectionHeight > contentHeight + pushToRefreshThreshold && isPushToRefreshEnabled && !isPushingToRefresh {
                beginPushToRefresh()
                funcPushToRefreshCallback?(self)
            }
        }
    }

    // In almost all cases we need to schedule scrollView inset
    // changes until here = inscrollViewWillBeginDecelerating.
    // This stuff is necessary to avoid 'content jump _UP_' when
    // scrollView contentInset changed
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if let contentInset = self.contentInset {
            self.setScrollView(contentInset: contentInset, animated: false) { finished in
                self.contentInset = nil
            }
        }
    }

    func setScrollView(contentInset: UIEdgeInsets, animated: Bool, completion: @escaping ((Bool) -> Void)) {
        let animation: () -> () = {
            // This stuff is necessary to avoid 'content jump _DOWN_'
            // when scrollView contentInset changed
            // Step 1 - saving contentOffset before contentInset changed
            let contentOffset = self.collectionView?.contentOffset

            self.collectionView?.contentInset = contentInset

            if let contentOffset = contentOffset {
                // This condition is necessary to prevent undesirable reduction of
                // total content height in case when scrollView is scroll back to top
                if contentOffset.y > 0 {
                    // Step 2 - restoring contentOffset after contentInset changed
                    self.collectionView?.contentOffset = contentOffset
                }
            }
        }

        if animated {
            UIView.animate(withDuration: 0.2,
                    delay: 0.0,
                    options: [.allowUserInteraction, .beginFromCurrentState],
                    animations: animation,
                    completion: completion)
        } else {
            UIView.performWithoutAnimation(animation)
            completion(true)
        }
    }
}

// MARK: UICollectionViewDataSource
extension CollectionsViewer {
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

// MARK: UICollectionViewDelegate
extension CollectionsViewer {

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

// MARK: Configuration
extension CollectionsViewer {

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

    func configureCollectionView(_ callback: @escaping ((UICollectionView) -> Void)) -> CollectionsViewer {
        self.funcConfigureCollectionViewCallback = callback
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

class BottomProgressIndicator: UICollectionViewCell {

    var indicator: UIActivityIndicatorView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }

    func setup() {
        indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator?.center = CGPoint(x: frame.width/2, y: frame.height/2)
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        indicator?.startAnimating()

        addSubview(indicator!)

        indicator?.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        indicator?.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        setNeedsLayout()
    }
}
