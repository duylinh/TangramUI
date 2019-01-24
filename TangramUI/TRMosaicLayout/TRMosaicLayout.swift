//
//  TRMosaicLayout.swift
//  TangramUI
//
//  Created by 黄伯驹 on 2018/6/3.
//  Copyright © 2018 黄伯驹. All rights reserved.
//

public enum TRMosaicCellType {
    case big
    case small
}

public protocol TRMosaicLayoutDelegate: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, mosaicCellSizeTypeAt indexPath: IndexPath) -> TRMosaicCellType
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: TRMosaicLayout, insetAtSection: Int) -> UIEdgeInsets
    
    func heightForSmallMosaicCell() -> CGFloat
}

public class TRMosaicLayout: UICollectionViewLayout {
    
    public weak var delegate: TRMosaicLayoutDelegate? {
        return collectionView?.delegate as? TRMosaicLayoutDelegate
    }
    
    var columns = TRMosaicColumns()
    
    var cachedCellLayoutAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    
    let numberOfColumnsInSection = 3
    
    var contentWidth: CGFloat {
        return collectionView!.bounds.width
    }
    
    // MARK: UICollectionViewLayout Implementation
    
    override public func prepare() {
        super.prepare()
        
        resetLayoutState()
        configureMosaicLayout()
    }
    
    /**
     Iterates throught all items in section and
     creates new layouts for each item as a mosaic cell
     */
    func configureMosaicLayout() {
        // Queue containing cells that have yet to be added due to column constraints
        var smallCellIndexPathBuffer = [IndexPath]()
        
        var lastBigCellOnLeftSide = false
        // Loops through all items in the first section, this layout has only one section
        for cellIndex in 0..<collectionView!.numberOfItems(inSection: 0) {
            
            (lastBigCellOnLeftSide, smallCellIndexPathBuffer) = createCellLayout(withIndexPath: cellIndex,
                                                                                 bigCellSide: lastBigCellOnLeftSide,
                                                                                 cellBuffer: smallCellIndexPathBuffer)
        }
        
        if !smallCellIndexPathBuffer.isEmpty {
            addSmallCellLayout(atIndexPath: smallCellIndexPathBuffer[0], atColumn: indexOfShortestColumn())
            smallCellIndexPathBuffer.removeAll()
        }
    }
    
    /**
     Creates new layout for the cell at specified index path
     
     - parameter index:       index path of cell
     - parameter bigCellSide: specifies which side to place big cell
     - parameter cellBuffer:  buffer containing small cell
     
     - returns: tuple containing cellSide and cellBuffer, only one of which will be mutated
     */
    func createCellLayout(withIndexPath index: Int, bigCellSide: Bool, cellBuffer: [IndexPath]) -> (Bool, [IndexPath]) {
        let cellIndexPath = IndexPath(row: index, section: 0)
        let cellType = mosaicCellType(index: cellIndexPath)
        
        var newBuffer = cellBuffer
        var newSide = bigCellSide
        
        if cellType == .big {
            newSide = createBigCellLayout(withIndexPath: cellIndexPath, cellSide: bigCellSide)
        } else if cellType == .small {
            newBuffer = createSmallCellLayout(withIndexPath: cellIndexPath, buffer: newBuffer)
        }
        return (newSide, newBuffer)
    }
    
    /**
     Creates new layout for the big cell at specified index path
     - returns: returns new cell side
     */
    func createBigCellLayout(withIndexPath indexPath:IndexPath, cellSide: Bool) -> Bool {
        addBigCellLayout(atIndexPath: indexPath, atColumn: cellSide ? 1 : 0)
        return !cellSide
    }
    
    /**
     Creates new layout for the small cell at specified index path
     - returns: returns new cell buffer
     */
    func createSmallCellLayout(withIndexPath indexPath:IndexPath, buffer: [IndexPath]) -> [IndexPath] {
        var newBuffer = buffer
        newBuffer.append(indexPath)
        if newBuffer.count >= 2 {
            let column = indexOfShortestColumn()
            
            addSmallCellLayout(atIndexPath: newBuffer[0], atColumn: column)
            addSmallCellLayout(atIndexPath: newBuffer[1], atColumn: column)
            
            newBuffer.removeAll()
        }
        return newBuffer
    }
    
    /**
     Returns the entire content view of the collection view
     */
    public override var collectionViewContentSize: CGSize {
        let height = columns.smallestColumn.columnHeight
        return CGSize(width: contentWidth, height: height)
    }
    
    /**
     Returns all layout attributes within the given rectangle
     */
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributesInRect = cachedCellLayoutAttributes.filter { $1.frame.intersects(rect) }
        return Array(attributesInRect.values)
    }

    // MARK: Layout
    
    /**
     Configures the layout for cell type: Big
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addBigCellLayout(atIndexPath indexPath:IndexPath, atColumn column:Int) {
        let cellHeight = layoutAttributes(withCellType: .big, indexPath: indexPath, atColumn: column)
        
        columns[column].appendToColumn(withHeight: cellHeight)
        columns[column + 1].appendToColumn(withHeight: cellHeight)
    }
    
    /**
     Configures the layout for cell type: Small
     Adds the new layout to cache
     Updates the column heights for each effected column
     */
    func addSmallCellLayout(atIndexPath indexPath: IndexPath, atColumn column:Int) {
        let cellHeight = layoutAttributes(withCellType: .small, indexPath: indexPath, atColumn: column)
        
        columns[column].appendToColumn(withHeight: cellHeight)
    }
    
    /**
     Creates layout attribute with the given parameter and adds it to cache
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: new cell height from layout
     */
    func layoutAttributes(withCellType type:TRMosaicCellType, indexPath: IndexPath, atColumn column:Int) -> CGFloat {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame = mosaicCellRect(withType: type, atIndexPath: indexPath, atColumn: column)
        
        layoutAttributes.frame = frame
        
        let cellHeight = layoutAttributes.frame.height + insetForMosaicCell().top
        
        cachedCellLayoutAttributes[indexPath] = layoutAttributes
        
        return cellHeight
    }
    
    // MARK: Cell Sizing
    
    /**
     Creates the bounding rectangle for the given cell type
     
     - parameter type:      Cell type
     - parameter indexPath: Index of cell
     - parameter column:    Index of column
     
     - returns: Bounding rectangle
     */
    func mosaicCellRect(withType type: TRMosaicCellType, atIndexPath indexPath:IndexPath, atColumn column:Int) -> CGRect {
        var cellHeight = cellContentHeightFor(mosaicCellType: type)
        var cellWidth = cellContentWidthFor(mosaicCellType: type)
        
        var originX = CGFloat(column) * (contentWidth / CGFloat(numberOfColumnsInSection))
        var originY = columns[column].columnHeight
        
        let sectionInset = insetForMosaicCell()
        
        originX += sectionInset.left
        originY += sectionInset.top
        
        cellWidth -= sectionInset.right
        cellHeight -= sectionInset.bottom
        
        return CGRect(x: originX, y: originY, width: cellWidth, height: cellHeight)
    }
    
    /**
     Calculates height for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated height
     */
    func cellContentHeightFor(mosaicCellType cellType: TRMosaicCellType) -> CGFloat {
        let height = delegate?.heightForSmallMosaicCell() ?? 0
        if cellType == .big {
            return height * 2
        }
        return height
    }
    
    /**
     Calculates width for the given cell type
     
     - parameter cellType: Cell type
     
     - returns: Calculated width
     */
    func cellContentWidthFor(mosaicCellType cellType: TRMosaicCellType) -> CGFloat {
        let width = contentWidth / 3
        if cellType == .big {
            return width * 2
        }
        return width
    }
    
    // MARK: Orientation
    
    /**
     Determines if a layout update is needed when the bounds have been changed
     
     - returns: True if layout needs update
     */
    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let currentBounds = collectionView!.bounds
        
        if currentBounds.size == newBounds.size {
            prepare()
            return true
        }
        
        return false
    }
    
    // MARK: Delegate Wrappers
    
    /**
     Returns the cell type for the specified cell at index path
     
     - returns: Cell type
     */
    func mosaicCellType(index indexPath: IndexPath) -> TRMosaicCellType {
        return delegate?.collectionView(collectionView!, mosaicCellSizeTypeAt: indexPath) ?? .big
    }
    
    /**
     - returns: Returns the UIEdgeInsets that will be used for every cell as a border
     */
    func insetForMosaicCell() -> UIEdgeInsets {
        return delegate?.collectionView(collectionView!, layout: self, insetAtSection: 0) ?? .zero
    }
}

extension TRMosaicLayout {
    
    // MARK: Helper Functions
    
    /**
     - returns: The index of the column with the smallest height
     */
    func indexOfShortestColumn() -> Int {
        var index = 0
        for i in 1..<numberOfColumnsInSection {
            if columns[i] < columns[index] {
                index = i
            }
        }
        return index
    }
    
    /**
     Resets the layout cache and the heights array
     */
    func resetLayoutState() {
        columns = TRMosaicColumns()
        cachedCellLayoutAttributes.removeAll()
    }
}
