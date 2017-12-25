//
//  LPAssetViewController.h
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PHAsset,PHAssetCollection;
@interface LPAssetViewController : UIViewController

@property (nonatomic,strong) PHAsset *asset;
@property (nonatomic,strong) PHAssetCollection *assetCollection;

@end
