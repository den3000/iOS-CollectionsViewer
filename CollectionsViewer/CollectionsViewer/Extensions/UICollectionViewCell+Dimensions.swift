//
// Created by Denis Suprun on 10/08/17.
// Copyright (c) 2017 Razeware LLC. All rights reserved.
//

import UIKit
import AVFoundation

extension UICollectionViewCell {
    public class func heightFor(_ comment: String, with font: UIFont, and width: CGFloat) -> CGFloat {
        let rect = NSString(string: comment).boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return ceil(rect.height)
    }

    public class func rectFor(_ image: UIImage, with width: CGFloat, and height: CGFloat) -> CGRect {
        let imageBoundingRect = CGRect(x: 0, y: 0, width: width, height: height)
        return AVMakeRect(aspectRatio: image.size, insideRect: imageBoundingRect)
    }
}
