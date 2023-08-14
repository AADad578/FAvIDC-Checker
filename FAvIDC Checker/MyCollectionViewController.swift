//
//  MyCollectionViewController.swift
//  CollectionViewPeekingPages
//
//  Created by Shai Balassiano on 06/04/2018.
//  Copyright © 2018 Shai Balassiano. All rights reserved.
//

import UIKit
class MyCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    
    override init(frame: CGRect) {
        super.init(frame:frame)
        imageView = UIImageView()
        addSubview(imageView)
    }
    required init?(coder: NSCoder){
        fatalError()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }
}

class MyCollectionViewController: HorizontalPeekingPagesCollectionViewController {
    
    @IBOutlet var dataSource = [UIImage]() {
        didSet {
            
            collectionView.register(MyCell.self, forCellWithReuseIdentifier: "cell")
            collectionView?.reloadData()
        }
    }
        override func calculateSectionInset() -> CGFloat {
        return 40
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let c = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? MyCell else{fatalError()}
        c.imageView.image = dataSource[indexPath.row]
        return c
    }
    
}
