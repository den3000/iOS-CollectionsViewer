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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if self.isPushToRefreshEnabled && self.isPushingToRefresh {
            self.hideProgressIndicator()
            coordinator.animate(alongsideTransition: nil) { context in
                if self.isPushToRefreshEnabled && self.isPushingToRefresh {
                    self.showProgressIndicator()
                }
            }
        }
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

    public func startPullToRefresh(){
        if isPushingToRefresh { return }

        refreshControl?.beginRefreshing()
    }

    public func stopPullToRefresh(){
        refreshControl?.endRefreshing()
    }

    @objc internal func onPullToRefresh(sender:AnyObject) {
        if isPushingToRefresh {
            stopPullToRefresh()
            return
        }

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

    public func startPushToRefresh(){
        if refreshControl?.isRefreshing ?? false { return }
        if isPushingToRefresh == true { return }

        isPushingToRefresh = true

        showProgressIndicator()

        contentInset = collectionView!.contentInset;
        contentInset?.bottom += indicatorInset;

        // In almost all cases we need to schedule scrollView inset
        // changes until scrollViewWillBeginDecelerating. But if
        // scrolling manner itself is very aggressive then we need
        // to trigger it right now. All this stuff is necessary to
        // avoid 'content jump _UP_' when scrollView contentInset changed
        if (collectionView?.isDecelerating ?? false) && contentInset != nil {
            setScrollView(contentInset: contentInset!, animated: false) { finished in
            }
            self.contentInset = nil
        }

        // It might looks like logically to call 'funcPushToRefreshCallback'
        // right here, but it is not. In some cases, when time interval between
        // 'startPushToRefresh' and 'stopPushToRefresh' is too short it could
        // cause undesirable content overscrolling and other UI glitches. That's
        // why 'funcPushToRefreshCallback' should be called in 'scrollViewDidEndDecelerating'
//        funcPushToRefreshCallback?(self)
    }

    public func stopPushToRefresh(){
        if refreshControl?.isRefreshing ?? false { return }
        if isPushingToRefresh == false { return }

        isPushingToRefresh = false

        hideProgressIndicator()

        if self.contentInset != nil {
            // This happens when content was held up during
            // all process of showing animation, and this means
            // contentInset of scrollView was not changed, so we
            // don't need to change them back
            self.contentInset = nil
            return
        }

        var contentInset = self.collectionView!.contentInset;
        contentInset.bottom -= self.indicatorInset;

        self.setScrollView(contentInset: contentInset, animated: false) { finished in
            // Sometimes for some reason contentHeight values might have too many
            // numbers after coma, something like '3182.00439372935', and this breaks
            // condition that defines should we scroll to bottom or not. That's why
            // it is safer to use here 'round' function for each value
            let contentHeight = round((self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0)
            let contentOffset = round(self.collectionView?.contentOffset.y ?? 0)
            let collectionHeight = round(self.collectionView?.frame.height ?? 0)

            if (contentHeight > collectionHeight) && (contentOffset + collectionHeight >= contentHeight + self.indicatorInset) {
                let contentOffset = CGPoint(x: self.collectionView!.contentOffset.x, y: self.collectionView!.contentOffset.y - self.indicatorInset)
                self.collectionView?.setContentOffset(contentOffset, animated: true)
            }
        }
    }

    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if data == nil {return}

        let contentHeight = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0
        let contentOffset = self.collectionView?.contentOffset.y ?? 0
        let collectionHeight = collectionView?.frame.height ?? 0
        if (contentHeight + pushToRefreshThreshold) <= collectionHeight {
            // This old code could used for switching back to
            // post-scroll triggering in case of reversed ordering
            // if contentOffset > pushToRefreshThreshold && isPushToRefreshEnabled && !isPushingToRefresh {
            if contentOffset > 0.3 * pushToRefreshThreshold && isPushToRefreshEnabled && !isPushingToRefresh {
                startPushToRefresh()
            }
        } else {
            // This old code could used for switching back to
            // post-scroll triggering in case of reversed ordering
            //  if contentOffset + collectionHeight > contentHeight + pushToRefreshThreshold && isPushToRefreshEnabled && !isPushingToRefresh {
            if contentOffset + collectionHeight + pushToRefreshThreshold >= contentHeight && isPushToRefreshEnabled && !isPushingToRefresh {
                startPushToRefresh()
            }
        }
    }

    // In almost all cases we need to schedule scrollView inset
    // changes until here, in scrollViewWillBeginDecelerating.
    // This stuff is necessary to avoid 'content jump _UP_' when
    // scrollView contentInset changed
    override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if let contentInset = self.contentInset {
            self.setScrollView(contentInset: contentInset, animated: false) { finished in
                self.contentInset = nil
            }
        }
    }

    // It might looks like logically to call 'funcPushToRefreshCallback'
    // right at the end of 'startPushToRefresh', but it is not. In some
    // cases, when time interval between 'startPushToRefresh' and
    // 'stopPushToRefresh' is too short it could cause undesirable content
    // overscrolling and other UI glitches. That's why 'funcPushToRefreshCallback'
    // should be called in here
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isPushingToRefresh {
            funcPushToRefreshCallback?(self)
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

    fileprivate func showProgressIndicator() {
        let contentWidth = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentWidth ?? 0
        let contentHeight = (self.collectionView?.collectionViewLayout as? CollectionsViewerLayout)?.contentHeight ?? 0

        if self.bottomProgressIndicator == nil { self.bottomProgressIndicator = BottomProgressIndicator() }
        self.bottomProgressIndicator?.frame = CGRect(
                x: 0, y: contentHeight,
                width: contentWidth, height: self.indicatorInset)

        if self.bottomProgressIndicator?.superview == nil {
            self.collectionView?.addSubview(self.bottomProgressIndicator!)
        }
    }

    fileprivate func hideProgressIndicator() {
        self.bottomProgressIndicator?.removeFromSuperview()
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
