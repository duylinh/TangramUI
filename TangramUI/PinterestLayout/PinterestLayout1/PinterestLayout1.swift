//
//  PinterestLayout1.swift
//  TangramUI
//
//  Created by 黄伯驹 on 2018/6/3.
//  Copyright © 2018 黄伯驹. All rights reserved.
//

/**
 PinterestLayout.
 */
public class PinterestLayout1: UICollectionViewLayout {
    
    /// Delegate
    public weak var delegate: PinterestLayoutDelegate1? {
        return collectionView.delegate as? PinterestLayoutDelegate1
    }

    public var numberOfColumns: Int = 2

    public var cellPadding: CGFloat = 5
    
    
    private var cachedAttributes = [PinterestLayoutAttributes]()
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        let bounds = collectionView.bounds
        let insets = collectionView.contentInset
        return bounds.width - insets.left - insets.right
    }
    
    override public var collectionViewContentSize: CGSize {
        return CGSize(
            width: contentWidth,
            height: contentHeight
        )
    }
    
    override public class var layoutAttributesClass: AnyClass {
        return PinterestLayoutAttributes.self
    }
    
    override public var collectionView: UICollectionView {
        return super.collectionView!
    }
    
    private var numberOfSections: Int {
        return collectionView.numberOfSections
    }
    
    private func numberOfItems(inSection section: Int) -> Int {
        return collectionView.numberOfItems(inSection: section)
    }
    
    /**
     Invalidates layout.
     */
    override public func invalidateLayout() {
        cachedAttributes.removeAll()
        contentHeight = 0
        
        super.invalidateLayout()
    }
    
    override public func prepare() {
        guard cachedAttributes.isEmpty else {
            return
        }
        let collumnWidth = contentWidth / CGFloat(numberOfColumns)
        let cellWidth = collumnWidth - (cellPadding * 2)
        
        var xOffsets = [CGFloat]()
        
        for collumn in 0..<numberOfColumns {
            xOffsets.append(CGFloat(collumn) * collumnWidth)
        }
        
        for section in 0..<numberOfSections {
            let numberOfItems = self.numberOfItems(inSection: section)
            
            if let headerSize = delegate?.collectionView?(
                collectionView: collectionView,
                sizeForSectionHeaderViewForSection: section
                ) {
                let headerX = (contentWidth - headerSize.width) / 2
                let headerFrame = CGRect(
                    origin: CGPoint(
                        x: headerX,
                        y: contentHeight
                    ),
                    size: headerSize
                )
                let headerAttributes = PinterestLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    with: IndexPath(item: 0, section: section)
                )
                headerAttributes.frame = headerFrame
                cachedAttributes.append(headerAttributes)
                
                contentHeight = headerFrame.maxY
            }
            
            var yOffsets = [CGFloat](
                repeating: contentHeight,
                count: numberOfColumns
            )
            
            for item in 0..<numberOfItems {
                let indexPath = IndexPath(item: item, section: section)
                
                let column = yOffsets.firstIndex(of: yOffsets.min() ?? 0) ?? 0
                
                let imageHeight = delegate?.collectionView(
                    collectionView: collectionView,
                    heightForImageAt: indexPath,
                    withWidth: cellWidth
                ) ?? 0
                let annotationHeight = delegate?.collectionView(
                    collectionView: collectionView,
                    heightForAnnotationAt: indexPath,
                    withWidth: cellWidth
                ) ?? 0
                let cellHeight = cellPadding + imageHeight + annotationHeight + cellPadding
                
                let frame = CGRect(
                    x: xOffsets[column],
                    y: yOffsets[column],
                    width: collumnWidth,
                    height: cellHeight
                )
                
                let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                let attributes = PinterestLayoutAttributes(
                    forCellWith: indexPath
                )
                attributes.frame = insetFrame
                attributes.imageHeight = imageHeight
                cachedAttributes.append(attributes)
                
                contentHeight = max(contentHeight, frame.maxY)
                yOffsets[column] = yOffsets[column] + cellHeight
            }
            
            if let footerSize = delegate?.collectionView?(
                collectionView: collectionView,
                sizeForSectionFooterViewForSection: section
                ) {
                let footerX = (contentWidth - footerSize.width) / 2
                let footerFrame = CGRect(
                    origin: CGPoint(
                        x: footerX,
                        y: contentHeight
                    ),
                    size: footerSize
                )
                let footerAttributes = PinterestLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    with: IndexPath(item: 0, section: section)
                )
                footerAttributes.frame = footerFrame
                cachedAttributes.append(footerAttributes)
                
                contentHeight = footerFrame.maxY
            }
        }
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        let layoutAttributes = cachedAttributes.filter { $0.frame.intersects(rect) }
        return layoutAttributes
    }
}
