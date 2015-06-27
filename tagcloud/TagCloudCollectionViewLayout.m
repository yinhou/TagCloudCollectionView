//
//  TagCloudCollectionViewLayout.m
//  tagcloud
//
//  Created by Yin Hou on 6/25/15.
//  Copyright (c) 2015 Yin Hou. All rights reserved.
//

#import "TagCloudCollectionViewLayout.h"

static const CGFloat MARGIN = 10.f;
static const CGFloat SCROLLING_SLOW_DOWN_RATE = 1/4.f;

@interface TagCloudCollectionViewLayout ()

@property (nonatomic, strong) NSMutableArray *layoutAttributes;
@property (nonatomic, strong) NSMutableArray *rightEdges, *leftEdges;
@property (nonatomic, assign) CGFloat maxXRight, maxXLeft;

@end

@implementation TagCloudCollectionViewLayout

- (void)prepareLayout {
    self.layoutAttributes = @[].mutableCopy;
    [self setUpInitialEdges];

    for (NSInteger i = 0; i < [self.collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i
                                                    inSection:0];
        CGSize itemSize = [self.dataSource collectionViewLayout:self
                                           itemSizeForIndexPath:indexPath];
        CGRect itemFrame = CGRectMake(i % 2 ? -INFINITY : INFINITY, .0f, itemSize.width, itemSize.height);
        NSMutableArray *edges = i % 2 ? self.leftEdges : self.rightEdges;
        
        [self updateItemCellFrame:&itemFrame fittingEdges:edges];
        [self updateEdges:edges withNewItemFrame:itemFrame];
        [self addLayoutAttributesWithIndexPath:indexPath itemFrame:itemFrame];
    }
    [self moveAllLayoutAttributeFramesIntoCanvas];
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.maxXRight + fabs(self.maxXLeft), self.collectionView.bounds.size.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return self.layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.layoutAttributes[indexPath.item];
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    CGPoint current = self.collectionView.contentOffset;
    CGFloat distance = fabs(fabs(proposedContentOffset.x) - fabs(current.x));
    distance = distance * SCROLLING_SLOW_DOWN_RATE;
    
    if (proposedContentOffset.x < current.x) {
        current.x -= distance;
    } else {
        current.x += distance;
    }
    return current;
}

#pragma mark -
#pragma mark Helpers

- (void)setUpInitialEdges {
    int height = (int)ceil(self.collectionView.bounds.size.height);
    self.rightEdges = @[].mutableCopy;
    for (int i = 0; i < height; i++) {
        [self.rightEdges addObject:@(0)];
        
    }
    self.leftEdges = @[].mutableCopy;
    for (int i = 0; i < height; i++) {
        [self.leftEdges addObject:@(0)];
    }
    self.maxXRight = .0f;;
}

- (CGFloat)maxEdgeXInItemRangeWithItemSize:(CGSize)itemSize startingY:(int)startingY edges:(NSArray *)edges{
    CGFloat maxEdgeXInItemRange = .0f;
    for (int movingYInItemRange = startingY; movingYInItemRange < (startingY + itemSize.height + 2 * MARGIN); movingYInItemRange++) {
        CGFloat edgeX = [edges[movingYInItemRange] floatValue];
        if (fabs(edgeX) > fabs(maxEdgeXInItemRange)) {
            maxEdgeXInItemRange = edgeX;
        }
    }
    return maxEdgeXInItemRange;
}

- (void)updateItemCellFrame:(CGRect *)framePointer fittingEdges:(NSArray *)edges{
    CGFloat maxY = self.collectionView.bounds.size.height - framePointer->size.height - 2 * MARGIN;
    for (int y = 0; y < maxY; y++) {
        CGFloat maxEdgeXInItemRange = [self maxEdgeXInItemRangeWithItemSize:framePointer->size startingY:y edges:edges];
        if (framePointer->origin.x < .0f) { //left side
            if (fabs(maxEdgeXInItemRange) < fabs([self maxXForItemFrame:*framePointer])) {
                framePointer->origin.x = maxEdgeXInItemRange - MARGIN - framePointer->size.width;
                framePointer->origin.y = y + MARGIN;
            }
        } else {
            if (maxEdgeXInItemRange < framePointer->origin.x) {
                framePointer->origin.x = maxEdgeXInItemRange + MARGIN;
                framePointer->origin.y = y + MARGIN;
            }
        }
        
    }
}

- (void)updateEdges:(NSMutableArray *)mutableEdges withNewItemFrame:(CGRect)frame {
    CGFloat newX = [self maxXForItemFrame:frame];
    for (int movingYInItemRange = 0; movingYInItemRange < frame.size.height; movingYInItemRange++) {
        mutableEdges[(int)ceil(frame.origin.y) + movingYInItemRange] = @(newX);
    }
    [self updateMaxEdgesWithItemFrame:frame];
}

- (CGFloat)maxXForItemFrame:(CGRect)frame {
    CGFloat maxX;
    if (frame.origin.x < .0f) {
        maxX = frame.origin.x;
    } else {
        maxX = frame.origin.x + frame.size.width;
    }
    return maxX;
}

- (void)updateMaxEdgesWithItemFrame:(CGRect)itemFrame {
    CGFloat newX = [self maxXForItemFrame:itemFrame];
    if (newX < .0f) {
        if (newX < self.maxXLeft) {
            self.maxXLeft = newX;
        }
    } else {
        if (newX > self.maxXRight) {
            self.maxXRight = newX;
        }
    }
}

- (void)addLayoutAttributesWithIndexPath:(NSIndexPath *)indexPath itemFrame:(CGRect)itemFrame {
    UICollectionViewLayoutAttributes *layoutAttribute = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    layoutAttribute.frame = itemFrame;
    [self.layoutAttributes addObject:layoutAttribute];
}

- (void)moveAllLayoutAttributeFramesIntoCanvas {
    for (UICollectionViewLayoutAttributes *attributesItem in self.layoutAttributes) {
        CGRect frame = attributesItem.frame;
        frame.origin.x = frame.origin.x + fabs(self.maxXLeft);
        attributesItem.frame = frame;
    }
}

@end
