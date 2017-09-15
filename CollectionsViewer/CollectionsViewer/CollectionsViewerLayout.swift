//
// Created by Denis Suprun on 15/09/17.
// Copyright (c) 2017 daxh. All rights reserved.
//

import UIKit

class CollectionsViewerLayoutAttributes: UICollectionViewLayoutAttributes {

    // 1. Custom attribute
    var dimensions: [String : CGFloat] = [String : CGFloat]()

    // 2. Override copyWithZone to conform to NSCopying protocol
    override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! CollectionsViewerLayoutAttributes
        copy.dimensions = dimensions
        return copy
    }

    // 3. Override isEqual
    override func isEqual(_ object: Any?) -> Bool {
        if let attributtes = object as? CollectionsViewerLayoutAttributes {
            if( attributtes.dimensions == dimensions) {
                return super.isEqual(object)
            }
        }
        return false
    }
}

class CollectionsViewerLayout: UICollectionViewLayout {

    // 1
    var configuredCellViewAttributes: ((IndexPath, CGFloat) -> (CollectionsViewerLayoutAttributes))!

    // 2
    var numberOfColumns: ((Void) -> Int)? = nil
    var cellPadding: CGFloat = 6.0
    private var columnsNum = 1

    // 3
    private var cache = [CollectionsViewerLayoutAttributes]()

    // 4
    private var contentHeight: CGFloat  = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - (insets.left + insets.right)
    }

    func configureCellViewAttributes(_ configuredCellViewAttributes: @escaping ((IndexPath, CGFloat) -> (CollectionsViewerLayoutAttributes))) -> CollectionsViewerLayout {
        self.configuredCellViewAttributes = configuredCellViewAttributes
        return self
    }

    func configureColumnsNum(_ numberOfColumns: @escaping ((Void) -> Int)) -> CollectionsViewerLayout {
        self.numberOfColumns = numberOfColumns
        return self
    }

    func configureCellPadding(_ cellPadding: CGFloat) -> CollectionsViewerLayout {
        self.cellPadding = cellPadding
        return self
    }

    override class var layoutAttributesClass : AnyClass {
        return CollectionsViewerLayoutAttributes.self
    }

    override func prepare() {
        // 1
        if cache.isEmpty {
            // 2
            columnsNum = numberOfColumns?() ?? columnsNum
            let columnWidth = contentWidth / CGFloat(columnsNum)
            var xOffset = [CGFloat]()
            for column in 0 ..< columnsNum {
                xOffset.append(CGFloat(column) * columnWidth)
            }
            var column = 0
            var yOffset = [CGFloat](repeating: 0, count: columnsNum)

            // 3
            let itemsNum = collectionView!.numberOfItems(inSection: 0)
            for item in 0 ..< itemsNum {
                let indexPath = IndexPath(item: item, section: 0)

                // 4.1
                let left : CGFloat = column == 0 ? 1.0 : 0.5
                let right : CGFloat = column == columnsNum-1 ? 1.0 : 0.5
                let top : CGFloat = yOffset[column] == 0 ? 1.0 : 0.5
                let btm : CGFloat = (item > itemsNum - columnsNum - 1) ? 1.0 : 0.5

                // 4.2
                let width = columnWidth - cellPadding * (left + right)
                let attributes = configuredCellViewAttributes(indexPath, width)
                let height = attributes.frame.height + cellPadding * (top + btm)
                let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
                let insetFrame = CGRect(x: frame.origin.x + cellPadding * left,
                        y: frame.origin.y + cellPadding * top,
                        width: frame.width  - cellPadding * left - cellPadding * right,
                        height: frame.height - cellPadding * top - cellPadding * btm)
                // 5
                attributes.frame = insetFrame
                cache.append(attributes)

                // 6
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[column] = yOffset[column] + height

                column = column >= (columnsNum - 1) ? 0 : (column+1)
            }
        }
    }

    override var collectionViewContentSize : CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var layoutAttributes = [UICollectionViewLayoutAttributes]()

        // Loop through the cache and look for items in the rect
        for attributes  in cache {
            if attributes.frame.intersects(rect ) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        contentHeight = 0.0
        cache.removeAll()
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return !(collectionView?.bounds.size.equalTo(newBounds.size) ?? false)
    }
}
