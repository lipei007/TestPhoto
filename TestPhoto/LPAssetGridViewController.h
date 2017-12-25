//
//  LPAssetGridViewController.h
//  TestPhoto
//
//  Created by Jack on 2017/12/1.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@interface LPAssetGridViewController : UIViewController

@property (nonatomic,strong) PHFetchResult<PHAsset *> *fetchResult;
@property (nonatomic,strong) PHAssetCollection *assetColleciton;

@end
