//
//  GridViewCell.m
//  TestPhoto
//
//  Created by Jack on 2017/12/4.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPAssetGridViewCell.h"

@interface LPAssetGridViewCell ()
@property (strong, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (strong, nonatomic) IBOutlet UIImageView *livePhotoBadgeImageView;
@property (strong, nonatomic) IBOutlet UIButton *selectBtn;

@end

@implementation LPAssetGridViewCell

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    
    self.thumbnailImageView.image = _thumbnailImage;
}

- (void)setLivePhotoBadgeImage:(UIImage *)livePhotoBadgeImage {
    _livePhotoBadgeImage = livePhotoBadgeImage;
    self.livePhotoBadgeImageView.image = _livePhotoBadgeImage;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.thumbnailImage = nil;
    self.livePhotoBadgeImage = nil;
    
    self.selectBtn.selected = NO;
    [self.selectBtn setTitle:nil forState:UIControlStateNormal];
}

- (void)showSelectedAtIndex:(NSInteger)index {
    self.selectBtn.selected = YES;
    [self.selectBtn setTitle:[NSString stringWithFormat:@"%ld",(long)index] forState:UIControlStateSelected];
}

- (IBAction)selectBtnClick:(UIButton *)sender {
    
    sender.selected = !sender.isSelected;
    if (sender.isSelected) {
        if (self.delegate) {
            NSInteger count = [self.delegate numberOfSelectedAsset];
            [sender setTitle:[NSString stringWithFormat:@"%ld",(long)count+1] forState:UIControlStateSelected];
        }
    } else {
        [sender setTitle:nil forState:UIControlStateNormal];
    }
    
    
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        
        sender.transform = CGAffineTransformScale(sender.transform, 1.2, 1.2);
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
            
            sender.transform = CGAffineTransformIdentity;
            
        } completion:^(BOOL finished) {
            
            // 消除Reload时，Animated Button不在当前IndexPath。
            if (self.delegate) {
                [self.delegate assetGridViewCell:self didSelect:sender.isSelected];
            }
            
            
        }];
    }];
}

@end
