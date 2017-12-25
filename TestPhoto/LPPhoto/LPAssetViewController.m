//
//  LPAssetViewController.m
//  TestPhoto
//
//  Created by Jack on 2017/12/11.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPAssetViewController.h"
#import "LPAnimatedImageView.h"
#import "LPAnimateImage.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

@interface LPAssetViewController ()
@property (strong, nonatomic) IBOutlet LPAnimatedImageView *animatedImageView;
@property (strong, nonatomic) IBOutlet PHLivePhotoView *livePhotoView NS_AVAILABLE_IOS(9_1);
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic,assign) CGSize targetSize;
@property (nonatomic,assign) BOOL isPlayingHint;

@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) AVPlayerLooper *playerLooper NS_AVAILABLE_IOS(10_0);

@end

@implementation LPAssetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateContent];
}

- (CGSize)targetSize {
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(_animatedImageView.bounds.size.width * scale, _animatedImageView.bounds.size.height * scale);
}

- (void)updateContent {
    if (@available(iOS 11.0, *)) {
        switch (_asset.playbackStyle) {
            case PHAssetPlaybackStyleLivePhoto: {
                [self updateLivePhoto:NO];
            }
                break;
            case PHAssetPlaybackStyleImageAnimated: {
                [self updateAnimatedImage:NO];
            }
                break;
            case PHAssetPlaybackStyleImage: {
                [self updateStillImage:NO];
            }
                break;
            case PHAssetPlaybackStyleUnsupported: {
                
            }
                break;
            case PHAssetPlaybackStyleVideo: {
                [self updateStillImage:NO]; // as a placeholder until play is tapped
            }
                break;
            case PHAssetPlaybackStyleVideoLooping: {
                [self play:self];
            }
                break;
                
            default:
                break;
        }
    } else {
        // Fallback on earlier versions
        
        switch (_asset.mediaType) {
            case PHAssetMediaTypeImage: {
                [self updateStillImage:NO];
            }
                break;
            case PHAssetMediaTypeVideo: {
                [self updateStillImage:NO];
            }
                break;
                
            default:
                break;
        }
        
    }
}

- (void)updateAnimatedImage:(BOOL)network {
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.version = PHImageRequestOptionsVersionOriginal;
    options.networkAccessAllowed = network;
    
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
      
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%f",progress);
        });
        
    };
    
    __weak typeof(self) weakSelf = self;
    [[PHImageManager defaultManager] requestImageDataForAsset:_asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        if (imageData == nil) {
            
            BOOL isInClound = [[info objectForKey:PHImageResultIsInCloudKey] boolValue];
            if (isInClound && network == NO) {
                [weakSelf updateAnimatedImage:YES];
            }
            
            return ;
        }
        
        LPAnimateImage *animatedImage = [[LPAnimateImage alloc] initWithData:imageData];
        _animatedImageView.animatedImage = animatedImage;
        _animatedImageView.isPlaying = true;
        
    }];
    
}

- (void)updateLivePhoto:(BOOL)network {
    
    if (@available(iOS 9.1, *)) {
        PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.version = PHImageRequestOptionsVersionOriginal;
        options.networkAccessAllowed = network;
        
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%f",progress);
            });
            
        };
        
        __weak typeof(self) weakSelf = self;
    
        [[PHImageManager defaultManager] requestLivePhotoForAsset:_asset targetSize:self.targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            
            if (livePhoto == nil) {
                BOOL isInClound = [[info objectForKey:PHImageResultIsInCloudKey] boolValue];
                if (isInClound && network == NO) {
                    [weakSelf updateLivePhoto:YES];
                }
                return ;
            }
            
            _livePhotoView.livePhoto = livePhoto;
            if (!weakSelf.isPlayingHint) {
                weakSelf.isPlayingHint = YES;
                [weakSelf.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
            }
            
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (void)updateStillImage:(BOOL)network {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.version = PHImageRequestOptionsVersionOriginal;
    options.networkAccessAllowed = network;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%f",progress);
        });
    };
    
    __weak typeof(self) weakSelf = self;
    [[PHImageManager defaultManager] requestImageForAsset:_asset targetSize:self.targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        if (result == nil) {
            BOOL isInClound = [[info objectForKey:PHImageResultIsInCloudKey] boolValue];
            if (isInClound && network == NO) {
                [weakSelf updateStillImage:YES];
            }
            return ;
        }
        
        weakSelf.imageView.image = result;
        
    }];
    
}

- (void)play:(id) sender {
    
}


@end
