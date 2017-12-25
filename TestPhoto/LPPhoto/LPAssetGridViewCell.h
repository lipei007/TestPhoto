//
//  GridViewCell.h
//  TestPhoto
//
//  Created by Jack on 2017/12/4.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LPAssetGridViewCell;
@protocol LPASssetGridViewCellDelegate <NSObject>

- (NSInteger)numberOfSelectedAsset;
- (void)assetGridViewCell:(LPAssetGridViewCell *)cell didSelect:(BOOL)selected;

@end

@interface LPAssetGridViewCell : UICollectionViewCell

@property (nonatomic,weak) id<LPASssetGridViewCellDelegate> delegate;
@property (nonatomic,copy) NSString *presentedAssetIdentifier;
@property (nonatomic,strong) UIImage *thumbnailImage;
@property (nonatomic,strong) UIImage *livePhotoBadgeImage;

- (void)showSelectedAtIndex:(NSInteger)index;

@end
