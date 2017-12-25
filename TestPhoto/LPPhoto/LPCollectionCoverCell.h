//
//  LPCollectionGridCell.h
//  TestPhoto
//
//  Created by Jack on 2017/12/5.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPCollectionCoverCell : UITableViewCell

@property (nonatomic,strong) UIImage *cover;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *presentedCollectionIdentifier;
@end
