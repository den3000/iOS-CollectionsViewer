//
//  NumberOneExampleCellScreen.swift
//  CollectionsViewer
//
//  Created by Denis Suprun on 13/09/17.
//  Copyright © 2017 daxh. All rights reserved.
//

import UIKit
import AVFoundation

class NumberTwoExampleCellScreen: UIViewController {

    public internal(set) var isReversed = false
    private var page = 0;
    private let len = 3
    private let allItems = ExampleTwoItem.allItems();

    var collectionsViewer: CollectionsViewer?

    static func show(in viewController: UIViewController?, reverse: Bool) {
        let vc = NumberTwoExampleCellScreen(nibName: nil, bundle: nil)
        vc.isReversed = reverse
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.edgesForExtendedLayout = [];
        title = "Cell Number Two Example"
        if let nb = self.navigationController?.navigationBar {
            nb.isTranslucent = false
        }

        page = 1
        collectionsViewer = CollectionsViewer.create(for: Array(allItems[0..<len]))
            .configureCollectionView { collectionView in
                if let patternImage = UIImage(named: "pattern") {
                    collectionView.backgroundColor = UIColor(patternImage: patternImage)
                }
            }
            .cell(nibNameAndIdentifier: NumberTwoExampleCell.NIB_NAME)
            .cell(padding: 6)
            .cell(configuration: { cell, indexPath, viewer in
                let cell = cell as! NumberTwoExampleCell
                cell.exampleTwoItem = viewer.data?[indexPath.row] as? ExampleTwoItem
                return cell
            }).cell(selected: { indexPath, viewer in
                let text: String = (viewer.data?[indexPath.row] as? ExampleTwoItem)?.text ?? ""
                CellDetailsScreen.show(in: self).text = text
            }).cell(viewAttributes: {
                let exampleTwoItem = self.collectionsViewer?.data?[$0.row] as! ExampleTwoItem
                return NumberTwoExampleCell.attrsFrom(indexPath: $0, width: $1, exampleTwoItem: exampleTwoItem)
            }).columnsNum {
                if UIDevice.current.orientation == .portrait {
                    return UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
                } else {
                    return UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
                }
            }.enablePullToRefresh { _ in self.onRefresh() }
            .enablePushToRefresh { _ in self.onNeedMore() }
            .show(in: self.view, of: self)
    }

    private func onRefresh() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.page = 0

            print("Refresh, page = \(self.page)")
            sleep(2)

            self.collectionsViewer?.set(data: Array(self.allItems[0..<self.len])) {
                self.collectionsViewer?.stopPullToRefresh()
                self.page += 1
            }
        }
    }

    private func onNeedMore() {
        DispatchQueue.global(qos: .userInitiated).async {
            print("Append, page = \(self.page)")
            sleep(2)
            let from = self.page * self.len
            var to = from + self.len
            if from < self.allItems.count {
                if to > self.allItems.count {
                    to = self.allItems.count
                }
                self.collectionsViewer?.append(data: Array(self.allItems[from..<to])) {
                    self.collectionsViewer?.stopPushToRefresh()
                    self.page += 1
                }
            } else {
                print("No more data")
                self.collectionsViewer?.stopPushToRefresh()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension UIImage {
    var decompressedImage: UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        draw(at: CGPoint.zero)
        let decompressedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return decompressedImage!
    }
}

class ExampleTwoItem {

    class func allItems() -> [ExampleTwoItem] {
        var items = [ExampleTwoItem]()
        if let URL = Bundle.main.url(forResource: "NumberTwoExampleCellData", withExtension: "plist") {
            if let itemsFromPlist = NSArray(contentsOf: URL) {
                for dictionary in itemsFromPlist {
                    let photo = ExampleTwoItem(dictionary: dictionary as! NSDictionary)
                    items.append(photo)
                }
            }
        }
        return items
    }

    var title: String
    var text: String
    var image: UIImage
    var scaledImage: UIImage

    init(caption: String, comment: String, image: UIImage) {
        self.title = caption
        self.text = comment
        self.image = image
        self.scaledImage = image
    }

    convenience init(dictionary: NSDictionary) {
        let caption = dictionary["Title"] as? String
        let comment = dictionary["Text"] as? String
        let imageName = dictionary["Image"] as? String
        let image = UIImage(named: imageName!)?.decompressedImage
        self.init(caption: caption!, comment: comment!, image: image!)
    }
}

class NumberTwoExampleCell: UICollectionViewCell {

    public static let NIB_NAME = "NumberTwoExampleCell"

    public static let IMAGEVIEWHEIGHT = "imageHeight"
    public static let TEXTVIEWHEIGHT = "textLabelHeight"

    @IBOutlet public weak var image: UIImageView?
    @IBOutlet public weak var imageHeightLayoutConstraint: NSLayoutConstraint?
    @IBOutlet public weak var titleLabel: UILabel?
    @IBOutlet public weak var textLabel: UILabel?
    @IBOutlet public weak var textLabelHeightLayoutConstraint: NSLayoutConstraint?

    var exampleTwoItem: ExampleTwoItem? {
        didSet {
            if let exampleTwoItem = exampleTwoItem {
                titleLabel?.text = exampleTwoItem.title
                textLabel?.text = exampleTwoItem.text
                image?.image = exampleTwoItem.image
            }
        }
    }

    public static func attrsFrom(indexPath: IndexPath, width: CGFloat, exampleTwoItem: ExampleTwoItem) -> CollectionsViewerLayoutAttributes {
        let imageRect = UICollectionViewCell.rectFor(exampleTwoItem.image, with: width, and: CGFloat.greatestFiniteMagnitude)
        var totalHeight = imageRect.height

        var font = UIFont.systemFont(ofSize: 17.0)
        let titleHeight = UICollectionViewCell.heightFor(exampleTwoItem.title , with: font, and: width)
        totalHeight += titleHeight

        font = UIFont.systemFont(ofSize: 15.0)
        let textHeight = UICollectionViewCell.heightFor(exampleTwoItem.text , with: font, and: width)
        totalHeight += textHeight

        let attrs = CollectionsViewerLayoutAttributes(forCellWith: indexPath)
        attrs.frame = CGRect(x: 0, y: 0, width: width, height: totalHeight)
        attrs.dimensions = [
            NumberTwoExampleCell.IMAGEVIEWHEIGHT : imageRect.height,
            NumberTwoExampleCell.TEXTVIEWHEIGHT : textHeight,
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
        backgroundColor = UIColor.white
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        if let attrs = layoutAttributes as? CollectionsViewerLayoutAttributes {
            imageHeightLayoutConstraint?.constant = attrs.dimensions[NumberTwoExampleCell.IMAGEVIEWHEIGHT] ?? 0
            textLabelHeightLayoutConstraint?.constant = attrs.dimensions[NumberTwoExampleCell.TEXTVIEWHEIGHT] ?? 0
        }
    }
}