//
//  SimpleImageView.swift
//  Entropy
//
//  Created by Robin Thrift on 13/01/2019.
//  Copyright © 2019 Kodeshack. All rights reserved.
//

import Cocoa

class SimpleImageView: NSImageView {
    override var intrinsicContentSize: NSSize {
//        return .zero
        let original = super.intrinsicContentSize
        return NSSize(width: original.width, height: 0)
    }
}
