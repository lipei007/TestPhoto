//
//  LPCollectionGridCell.m
//  TestPhoto
//
//  Created by Jack on 2017/12/5.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPCollectionCoverCell.h"

@interface LPCollectionCoverCell ()

@property (nonatomic,strong) IBOutlet UIImageView *coverView;
@property (nonatomic,strong) IBOutlet UILabel *titleLabel;

@end

@implementation LPCollectionCoverCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCover:(UIImage *)cover {
    _cover = cover;
    self.coverView.image = _cover;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = _title;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.cover = nil;
    self.title = nil;
}

@end
