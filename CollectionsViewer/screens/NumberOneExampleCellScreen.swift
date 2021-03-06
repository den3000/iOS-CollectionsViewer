//
//  NumberOneExampleCellScreen.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 13/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit

class NumberOneExampleCellScreen: UIViewController {

    public internal(set) var isReversed = false
    private var page = 0
    private let len = 7
    private let allData = [
        "01 text",
        "02 text text",
        "03 text text text ",
        "04 text text text text",
        "05 text text text text text",
        "06 text text text text text text",
        "07 text text text text text text text",
        "08 text text text text text text text text",
        "09 text text text text text text text text text",
        "10 text text text text text text text text text text",
        "11 text text text text text text text text text text text",
        "12 text text text text text text text text text text text text",
        "13 text text text text text text text text text text text text text",
        "14 text text text text text text text text text text text text text text",
        "15 text text text text text text text text text text text text text text text",
        "16 text text text text text text text text text text text text text text text text",
        "17 text text text text text text text text text text text text text text text text text",
        "18 text text text text text text text text text text text text text text text text text text",
        "19 text text text text text text text text text text text text text text text text text text text",
        "20 text text text text text text text text text text text text text text text text text text text text",
        "21 text text text text text text text text text text text text text text text text text text text text text",
        "22 text text text text text text text text text text text text text text text text text text text text text text",
        "23 text text text text text text text text text text text text text text text text text text text text text text text",
        "24 text text text text text text text text text text text text text text text text text text text text text text text text",
        "25 text text text text text text text text text text text text text text text text text text text text text text text text text",
        "26 text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "27 text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "28 text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "29 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "30 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "31 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "32 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "33 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "34 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "35 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "36 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "37 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "38 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "39 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "40 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "41 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "42 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "43 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "44 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "45 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "46 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "47 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
        "48 text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text text",
    ]
    
    var collectionsViewer: CollectionsViewer?

    static func show(in viewController: UIViewController?, reverse: Bool) {
        let vc = NumberOneExampleCellScreen(nibName: nil, bundle: nil)
        vc.isReversed = reverse
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.edgesForExtendedLayout = [];

        title = "Cell Number One Example"
        if let nb = self.navigationController?.navigationBar {
            nb.isTranslucent = false
        }

        page = 1
        collectionsViewer = CollectionsViewer.create(for: Array(allData[0..<len]), reverse: isReversed)
            .configureCollectionView { collectionView in
                collectionView.backgroundColor = UIColor.white
            }
            .cell(nibNameAndIdentifier: NumberOneExampleCell.NIB_NAME)
            .cell(padding: 6)
            .cell(configuration: { cell, indexPath, viewer in
                let cell = cell as! NumberOneExampleCell
                cell.text = viewer.data?[indexPath.row] as? String
                return cell
            }).cell(selected: { indexPath, viewer in
                let text: String = viewer.data?[indexPath.row] as? String ?? ""
                CellDetailsScreen.show(in: self).text = text
            }).cell(viewAttributes: {
                let text = self.collectionsViewer?.data?[$0.row] as? String
                return NumberOneExampleCell.attrsFrom(indexPath: $0, width: $1, text: text)
            }).columnsNum {
                if UIDevice.current.orientation == .portrait {
                    return UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
                } else {
                    return UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
                }
            }.enablePullToRefresh { _ in self.isReversed ? self.onNeedMore() : self.onRefresh() }
            .enablePushToRefresh { _ in self.isReversed ? self.onRefresh() : self.onNeedMore() }
            .show(in: self.view, of: self)
    }

    private func onRefresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.page = 0

            print("Refresh, page = \(self.page)")
            sleep(3)

            self.collectionsViewer?.set(data: Array(self.allData[0..<self.len])) {
                if !self.isReversed {self.collectionsViewer?.stopPullToRefresh()}
                else {self.collectionsViewer?.stopPushToRefresh()}

                self.page += 1
            }
        }
    }

    private func onNeedMore() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("Append, page = \(self.page)")
            sleep(3)

            let from = self.page * self.len
            var to = from + self.len
            if from < self.allData.count {
                if to > self.allData.count {
                    to = self.allData.count
                }
                self.collectionsViewer?.append(data: Array(self.allData[from..<to])) {
                    if !self.isReversed {self.collectionsViewer?.stopPushToRefresh()}
                    else {self.collectionsViewer?.stopPullToRefresh()}
                    self.page += 1
                }
            } else {
                print("No more data")
                if !self.isReversed {self.collectionsViewer?.stopPushToRefresh()}
                else {self.collectionsViewer?.stopPullToRefresh()}
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class NumberOneExampleCell: UICollectionViewCell {

    public static let NIB_NAME = "NumberOneExampleCell"
    public static let TEXTVIEWHEIGHT = "textLabelHeight"

    @IBOutlet public weak var textLabel: UILabel?
    @IBOutlet public weak var textLabelHeightLayoutConstraint: NSLayoutConstraint?

    var text: String? {
        didSet {
            if let text = text {
                textLabel?.text = text
            }
        }
    }

    public static func attrsFrom(indexPath: IndexPath, width: CGFloat, text: String?) -> CollectionsViewerLayoutAttributes {
        let text = text ?? ""

        let font = UIFont.systemFont(ofSize: 17.0)
        let textHeight = UICollectionViewCell.heightFor(text, with: font, and: width)
        let totalHeight = textHeight

        let attrs = CollectionsViewerLayoutAttributes(forCellWith: indexPath)
        attrs.frame = CGRect(x: 0, y: 0, width: width, height: totalHeight)
        attrs.dimensions = [
            NumberOneExampleCell.TEXTVIEWHEIGHT : textHeight
        ]
        return attrs
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }

    func setup() {
        backgroundColor = UIColor.gray
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let attrs = layoutAttributes as? CollectionsViewerLayoutAttributes {
            textLabelHeightLayoutConstraint?.constant = attrs.dimensions[NumberOneExampleCell.TEXTVIEWHEIGHT] ?? 0
        }
    }
}
