//
//  ViewController.m
//  TestPhoto
//
//  Created by Jack on 2017/11/30.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPMasterViewController.h"
#import <Photos/Photos.h>
#import "LPAssetGridViewController.h"
#import "LPCollectionCoverCell.h"

@interface LPMasterViewController ()<UITableViewDelegate,UITableViewDataSource,PHPhotoLibraryChangeObserver>
{
    PHFetchResult<PHAsset *> *_allPhotos;
    PHFetchResult<PHAssetCollection *> *_smartAlbums;
    PHFetchResult<PHCollection *> *_userAlbums;
    
    PHCachingImageManager *_imageManager;
    CGRect _previousPreheatRect;
    CGSize _thumbnailSize;
}
@property (strong, nonatomic) IBOutlet UITableView *tb;

@end

@implementation LPMasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (@available(iOS 11.0, *)) {
        self.tb.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    _imageManager = [[PHCachingImageManager alloc] init];
    [self resetCacheAssets];
    
    [self lp_loadAlbums];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    _thumbnailSize = CGSizeMake(60 * scale, 60 * scale);
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)lp_loadAlbums {
    PHFetchOptions *allOptions = [[PHFetchOptions alloc] init];
    allOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    _allPhotos = [PHAsset fetchAssetsWithOptions:allOptions];
    _smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    _userAlbums = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateCacheAssets];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - Cache

- (void)resetCacheAssets {
    [_imageManager stopCachingImagesForAllAssets];
    _previousPreheatRect = CGRectZero;
}

- (NSArray *)mapIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:indexPaths.count];
    
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = [self assetAtIndexPath:indexPath];
        if (asset && (asset.pixelWidth > 0 && asset.pixelHeight > 0)) {
            [arr addObject:asset];
        }
    }
    
    return arr;
}

- (NSArray *)flatMap:(NSArray *)rects {
    
    NSMutableArray *arr = [NSMutableArray array];
    for (NSValue *rectValue in rects) {
        NSArray *indexPaths = [self.tb indexPathsForRowsInRect:rectValue.CGRectValue];
        [arr addObjectsFromArray:indexPaths];
    }
    return  arr;
    
}

- (void)updateCacheAssets {
    if (self.isViewLoaded && self.view.window != nil) {
        
        CGRect visibleRect = (CGRect){self.tb.contentOffset,self.tb.bounds.size};
        CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
        
        CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(_previousPreheatRect));
        if (delta < self.tb.bounds.size.height / 3) {
            return;
        }
        NSArray *arr = [self differencesBetweenOldRect:_previousPreheatRect newRect:preheatRect];
        NSArray *addedRects = [arr objectAtIndex:0];
        NSArray *removedRects = [arr objectAtIndex:1];
        
        NSArray *addedAssets = [self mapIndexPaths:[self flatMap:addedRects]];
        NSArray *removedAssets = [self mapIndexPaths:[self flatMap:removedRects]];
        
        [_imageManager startCachingImagesForAssets:addedAssets targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
        [_imageManager startCachingImagesForAssets:removedAssets targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil];
        
        _previousPreheatRect = preheatRect;
    }
    return;
}

- (NSArray *)differencesBetweenOldRect:(CGRect)old newRect:(CGRect)new {
    if (CGRectIntersectsRect(old, new)) {
        CGFloat oldMaxY = CGRectGetMaxY(old);
        CGFloat oldMinY = CGRectGetMinY(old);
        CGFloat newMaxY = CGRectGetMaxY(new);
        CGFloat newMinY = CGRectGetMinY(new);
        
        
        NSMutableArray *added = [NSMutableArray array];
        if (CGRectGetMaxY(new) > CGRectGetMaxY(old)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMaxY(old), new.size.width, CGRectGetMaxY(new) - CGRectGetMaxY(old));
            [added addObject:[NSValue valueWithCGRect:rect]];
        }
        if (CGRectGetMinY(old) > CGRectGetMinY(new)) {
            CGRect rect = CGRectMake(new.origin.x, CGRectGetMinY(new),CGRectGetWidth(new),CGRectGetMinY(old) - CGRectGetMinY(new));
            [added addObject:[NSValue valueWithCGRect:rect]];
        }
        
        NSMutableArray *removed = [NSMutableArray array];
        if (newMaxY < oldMaxY) {
            CGRect rect = CGRectMake(new.origin.x, newMaxY, CGRectGetWidth(new), oldMaxY - newMaxY);
            [removed addObject:[NSValue valueWithCGRect:rect]];
        }
        if (oldMinY < newMinY) {
            CGRect rect = CGRectMake(new.origin.x, oldMinY, CGRectGetWidth(new), newMinY - oldMinY);
            [removed addObject:[NSValue valueWithCGRect:rect]];
        }
        
        return @[added,removed];
    } else {
        return @[@[[NSValue valueWithCGRect:new]],@[[NSValue valueWithCGRect:old]]];
    }
}

#pragma mark - Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:{
            return 1;
        }
        case 1: {
            return _smartAlbums.count;
        }
        case 2: {
            return _userAlbums.count;
        }
        default: {
            return 0;
        }
    };
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSString *title = nil;
    PHAsset *asset = [self assetAtIndexPath:indexPath];
    switch (indexPath.section) {
        case 0:{
            title = @"所有图片";
        }
            break;
        case 1: {
            title = [self ChineseTitleForCollection:[_smartAlbums objectAtIndex:indexPath.row]];
        }
            break;
        case 2: {
            title = [self ChineseTitleForCollection:[_userAlbums objectAtIndex:indexPath.row]];
        }
            break;
    }
    
    LPCollectionCoverCell *coverCell = [tableView dequeueReusableCellWithIdentifier:@"Collection_Cover_Cell" forIndexPath:indexPath];
    
    coverCell.title = title;
    coverCell.presentedCollectionIdentifier = asset.localIdentifier;
    if (asset && (asset.pixelWidth > 0 && asset.pixelHeight > 0)) {
        [_imageManager requestImageForAsset:asset targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if ([coverCell.presentedCollectionIdentifier isEqualToString:asset.localIdentifier] && result != nil) {
                coverCell.cover = result;
            }
        }];
    }
    
    return coverCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LPAssetGridViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LPAssetGridViewController"];
    PHCollection *collection;
    switch (indexPath.section) {
        case 0:{
            vc.fetchResult = _allPhotos;
        }
            break;
        case 1: {
            collection = [_smartAlbums objectAtIndex:indexPath.row];
        }
            break;
        case 2: {
            collection = [_userAlbums objectAtIndex:indexPath.row];
        }
            break;
        
    };
    
    if (indexPath.section != 0) {
        vc.fetchResult = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)collection options:nil];
        vc.assetColleciton = (PHAssetCollection *)collection;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCacheAssets];
}

#pragma mark - Private

- (NSString *)ChineseTitleForCollection:(PHCollection *)collection {
    
    NSDictionary *convertDic = @{
                                 @"All Photos"      :   @"所有图片",
                                 @"Time-lapse"      :   @"延时摄影",
                                 @"Bursts"          :   @"连拍快照",
                                 @"Panoramas"       :   @"全景照",
                                 @"Favorites"       :   @"个人收藏",
                                 @"Selfies"         :   @"自拍",
                                 @"Screenshots"     :   @"屏幕快照",
                                 @"Slo-mo"          :   @"慢动作",
                                 @"Recently Added"  :   @"最近添加",
                                 @"Videos"          :   @"视频",
                                 @"Portrait"        :   @"人像",
                                 @"Live Photos"     :   @"Live Photo",
                                 @"Animated"        :   @"动图",
                                 @"Long Exposure"   :   @"长曝光"
                                 };
    
    if ([convertDic.allKeys containsObject:collection.localizedTitle]) {
        return [convertDic objectForKey:collection.localizedTitle];
    } else {
        return collection.localizedTitle;
    }
}

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = nil;
    switch (indexPath.section) {
        case 0:{
            if (_allPhotos.count > 0) {
                asset = [_allPhotos objectAtIndex:0];
            }
        }
            break;
        case 1: {
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)[_smartAlbums objectAtIndex:indexPath.row] options:nil];
            if (result.count > 0) {
                asset = [result objectAtIndex:0];
            }
        }
            break;
        case 2: {
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:(PHAssetCollection *)[_userAlbums objectAtIndex:indexPath.row] options:nil];
            if (result.count > 0) {
                asset = [result objectAtIndex:0];
            }
        }
            break;
    }
    
    if (!asset) {
        asset = [[PHAsset alloc] init];
    }
    
    return asset;
}


#pragma mark - Action

- (IBAction)clickAddAlbum:(UIBarButtonItem *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"New Album" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Album Name";
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        NSString *title = textField.text;
        if (title != nil && title.length > 0) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                if (!success) {
                    NSLog(@"error creating album: %@",error);
                }
            }];
        }
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mrak - PhotoLibrary Change

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *changeDetails = nil;
        
        changeDetails = [changeInstance changeDetailsForFetchResult:_allPhotos];
        if (changeDetails) {
            _allPhotos = [changeDetails fetchResultAfterChanges];
        }
        
        changeDetails = [changeInstance changeDetailsForFetchResult:_smartAlbums];
        if (changeDetails) {
            _smartAlbums = [changeDetails fetchResultAfterChanges];
            [self.tb reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        changeDetails = [changeInstance changeDetailsForFetchResult:_userAlbums];
        if (changeDetails) {
            _userAlbums = [changeDetails fetchResultAfterChanges];
            [self.tb reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        
    });
}


@end
