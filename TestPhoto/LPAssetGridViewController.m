//
//  LPAssetGridViewController.m
//  TestPhoto
//
//  Created by Jack on 2017/12/1.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import "LPAssetGridViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import "LPAssetGridViewCell.h"
#import "LPAssetViewController.h"

@interface UICollectionView (LPPhoto)

@end

@implementation UICollectionView (LPPhoto)

- (NSArray<NSIndexPath *> *)indexPathForElements:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *attr in allLayoutAttributes) {
        [arr addObject:attr.indexPath];
    }
    return arr;
}

@end

#pragma mark -- GridView

@interface LPAssetGridViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,PHPhotoLibraryChangeObserver,LPASssetGridViewCellDelegate>
{
    CGSize _thumbnailSize;
    PHCachingImageManager *_imageManager;
    CGRect _previousPreheatRect;
}
@property (nonatomic,strong) NSMutableArray *assetSelectedArray;

@property (strong, nonatomic) IBOutlet UICollectionView *cv;


@end

@implementation LPAssetGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (@available(iOS 11.0, *)) {
        self.cv.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    _imageManager = [[PHCachingImageManager alloc] init];
    [self resetCacheAssets];
    if (self.fetchResult == nil) {
        PHFetchOptions *allOptions = [[PHFetchOptions alloc] init];
        allOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        self.fetchResult = [PHAsset fetchAssetsWithOptions:allOptions];
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateItemSize];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self updateItemSize];
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

#pragma mark - Private

- (NSMutableArray *)assetSelectedArray {
    if (!_assetSelectedArray) {
        _assetSelectedArray = [NSMutableArray array];
    }
    return _assetSelectedArray;
}

- (void)updateItemSize {
    
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat desiredItemWidth = 100;
    CGFloat columns = MAX(floor(viewWidth / desiredItemWidth), 4);
    CGFloat padding = 3;
    CGFloat itemWidth = floor((viewWidth - (columns + 1) * padding) / columns);
    CGSize itemSize = CGSizeMake(itemWidth, itemWidth);
    
    id layout = self.cv.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)layout;
        flowLayout.itemSize = itemSize;
        flowLayout.minimumLineSpacing = padding;
        flowLayout.minimumInteritemSpacing = padding;
        flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    _thumbnailSize = CGSizeMake(itemWidth * scale, itemWidth * scale);
}

- (void)resetCacheAssets {
    [_imageManager stopCachingImagesForAllAssets];
    _previousPreheatRect = CGRectZero;
}

- (NSArray *)mapIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:indexPaths.count];
    
    for (NSIndexPath *indexPath in indexPaths) {
        [arr addObject:[self.fetchResult objectAtIndex:indexPath.item]];
    }
    
    return arr;
}

- (NSArray *)flatMap:(NSArray *)rects {
    
    NSMutableArray *arr = [NSMutableArray array];
    for (NSValue *rectValue in rects) {
        NSArray *indexPaths = [self.cv indexPathForElements:rectValue.CGRectValue];
        [arr addObjectsFromArray:indexPaths];
    }
    return  arr;
    
}

- (void)updateCacheAssets {
    if (self.isViewLoaded && self.view.window != nil) {
        
        CGRect visibleRect = (CGRect){self.cv.contentOffset,self.cv.bounds.size};
        CGRect preheatRect = CGRectInset(visibleRect, 0, -0.5 * visibleRect.size.height);
        
        CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(_previousPreheatRect));
        if (delta < self.cv.bounds.size.height / 3) {
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

#pragma mark - Data Soure

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fetchResult.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LPAssetGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Asset_Grid_Cell" forIndexPath:indexPath];
    
    PHAsset *asset = [self.fetchResult objectAtIndex:indexPath.item];
    
    if (@available(iOS 9.1, *)) {
        if ((asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) == PHAssetMediaSubtypePhotoLive) {
            cell.livePhotoBadgeImage = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent]; // PhotoUI
        }
    } else {
        // Fallback on earlier versions
    }
    
    cell.presentedAssetIdentifier = asset.localIdentifier;
    [_imageManager requestImageForAsset:asset targetSize:_thumbnailSize contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if ([cell.presentedAssetIdentifier isEqualToString:asset.localIdentifier] && result != nil) {
            cell.thumbnailImage = result;
        }
    }];
    
    cell.delegate = self;
    if ([self.assetSelectedArray containsObject:asset]) {
        [cell showSelectedAtIndex:[self.assetSelectedArray indexOfObject:asset] + 1];
    }
    
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateCacheAssets];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *identifier = @"LPAssetViewController_old";
    if (@available(iOS 9.1,*)) {
        identifier = @"LPAssetViewController";
    }
    
    LPAssetViewController *destination = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
    destination.asset = [_fetchResult objectAtIndex:indexPath.item];
    destination.assetCollection = _assetColleciton;
    
    [self.navigationController pushViewController:destination animated:YES];
}

#pragma mark - Add Image Asset

- (void)addImage:(UIImage *)img atAssetCollection:(PHAssetCollection *)assetCollection {
    if (img == nil) {
        return;
//        if (@available(iOS 10.0, *)) {
//            img = [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(300, 400)] imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
//                UIColor *color = [UIColor colorWithHue:(arc4random_uniform(100) / 100) saturation:1 brightness:1 alpha:1];
//                [color setFill];
//                [rendererContext fillRect:rendererContext.format.bounds];
//            }];
//        } else {
//            // Fallback on earlier versions
//            return;
//        }
    }
    
    if ([assetCollection canPerformEditOperation:PHCollectionEditOperationAddContent]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetChangeRequest *creationRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:img];
            PHAssetCollectionChangeRequest *addAssetRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.assetColleciton];
            [addAssetRequest addAssets:@[creationRequest.placeholderForCreatedAsset]];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (!success) {
                NSLog(@"add photo error: %@",error);
            }
        }];
    } else {
        NSLog(@"you can not add asset for this collection");
    }
    
    
}

#pragma mark - Photo Library Change

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if (!changes) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.fetchResult = [changes fetchResultAfterChanges];
        if (changes.hasIncrementalChanges) {
            [self.cv performBatchUpdates:^{
                
                NSIndexSet *removed = changes.removedIndexes;
                if (removed.count > 0) {
                    NSMutableArray<NSIndexPath *> *arr = [NSMutableArray array];
                    [removed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                        [arr addObject:indexPath];
                    }];
                    [self.cv deleteItemsAtIndexPaths:arr];
                }
                
                NSIndexSet *insert = changes.insertedIndexes;
                if (insert.count > 0) {
                    NSMutableArray<NSIndexPath *> *arr = [NSMutableArray array];
                    [insert enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                        [arr addObject:indexPath];
                    }];
                    [self.cv insertItemsAtIndexPaths:arr];
                }
                
                NSIndexSet *changed = changes.changedIndexes;
                if (changed.count > 0) {
                    NSMutableArray<NSIndexPath *> *arr = [NSMutableArray array];
                    [changed enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:0];
                        [arr addObject:indexPath];
                    }];
                    [self.cv insertItemsAtIndexPaths:arr];
                }
                
                [changes enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    [self.cv moveItemAtIndexPath:[NSIndexPath indexPathForItem:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForItem:toIndex inSection:0]];
                }];
                
            } completion:^(BOOL finished) {
                
            }];
        } else {
            [self.cv reloadData];
        }
        [self resetCacheAssets];
    });
    
}

#pragma mark - Grid Cell Delegate

- (NSInteger)numberOfSelectedAsset {
    return self.assetSelectedArray.count;
}

- (void)assetGridViewCell:(LPAssetGridViewCell *)cell didSelect:(BOOL)selected {
    NSIndexPath *indexPath = [self.cv indexPathForCell:cell];
    PHAsset *asset = [self.fetchResult objectAtIndex:indexPath.item];
    
    if (selected) {
        [self.assetSelectedArray addObject:asset];
    } else {
        NSInteger deleteIndex = [self.assetSelectedArray indexOfObject:asset];
        [self.assetSelectedArray removeObject:asset];
        if (deleteIndex != self.assetSelectedArray.count) {
            [self.cv reloadData];
        }
    }
}

@end
