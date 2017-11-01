//
//  ViewController.m
//  OptimizeMSSBrowse
//
//  Created by yutao on 31/10/2017.
//  Copyright © 2017 yutao. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"
#import "MSSBrowseNetworkViewController.h"

@interface TestCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView *imageView;

- (void)setContentWithImageURL:(NSString *)imageURL;

@end

@implementation TestCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
        return self;
    }
    return nil;
}

- (void)commonInit
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.frame = self.bounds;
    imageView.clipsToBounds = YES;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:imageView];
    _imageView = imageView;
}

- (void)setContentWithImageURL:(NSString *)imageURL
{
    [_imageView sd_setImageWithURL:[NSURL URLWithString:imageURL]];
}

@end

static NSString *cellIdentifier = @"TestCell";

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSArray<NSString *> *_smallImageURLs;
    NSArray<NSString *> *_bigImageURLs;
}
@end

@implementation ViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //有导航控制器才会显示
    self.title = self.navigationController ? @"有导航栏" : @"没有导航栏";
    
    [self prepareDataSource];
    [self createCollectionView];
}

#pragma mark - Private

- (void)prepareDataSource
{
    _smallImageURLs = @[@"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_112885.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_112281.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_111838.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_111393.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_110974.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_110458.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_19962.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_19517.jpg!128x96",
                        @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_18577.jpg!128x96"];
    
    _bigImageURLs = @[@"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_112885.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_112281.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_111838.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_111393.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_110974.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_110458.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_19962.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_19517.jpg!400",
                      @"http://ures.kktv8.com/kktv/picture/20171101/9/118755805_18577.jpg!400"];
}

- (void)createCollectionView
{
    //大图和小图的比例最好是一样的
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat imageWidth = (screenWidth - 4 * 10.0) / 3.0;
    CGFloat imageHeight = imageWidth / 128.0 * 96.0;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
    flowLayout.minimumInteritemSpacing = 10;
    flowLayout.minimumLineSpacing = 10;
    flowLayout.itemSize = CGSizeMake(imageWidth, imageHeight);
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds
                                                          collectionViewLayout:flowLayout];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.backgroundColor = UIColor.whiteColor;
    [collectionView registerClass:[TestCollectionViewCell class]
       forCellWithReuseIdentifier:cellIdentifier];
    [self.view addSubview:collectionView];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _smallImageURLs.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TestCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setContentWithImageURL:_smallImageURLs[indexPath.item]];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *itemsArray = [NSMutableArray arrayWithCapacity:_bigImageURLs.count];
    
    for (NSInteger i = 0; i < _bigImageURLs.count; i++)
    {
        MSSBrowseModel *browseItem = [[MSSBrowseModel alloc]init];
        browseItem.bigImageUrl = _bigImageURLs[i]; //加载网络图片大图地址
        
        //这里是为了所有smallImageView都填上去，如果某个没传，那么浏览到那张图片退出的时候就没有缩小动画
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        TestCollectionViewCell *cell = (TestCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        browseItem.smallImageView = cell.imageView;
        
        [itemsArray addObject:browseItem];
    }
    
    MSSBrowseNetworkViewController *browseVC = [[MSSBrowseNetworkViewController alloc] initWithBrowseItemArray:itemsArray currentIndex:indexPath.row];
    browseVC.recordOriginalRect = self.navigationController ? YES : NO;
    browseVC.isEqualRatio = NO;
    [browseVC showBrowseViewController:self];
}

@end
