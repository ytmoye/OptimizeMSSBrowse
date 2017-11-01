//
//  MSSBrowseBaseViewController.m
//  MSSBrowse
//
//  Created by 于威 on 16/4/26.
//  Copyright © 2016年 于威. All rights reserved.
//

#import "MSSBrowseBaseViewController.h"
#import "UIImageView+WebCache.h"
#import "SDImageCache.h"
#import "UIImage+MSSScale.h"
#import "MSSBrowseRemindView.h"
#import "MSSBrowseActionSheet.h"
#import "MSSBrowseDefine.h"
#import "UIImage+MSSExtend.h"

CGSize MSS_ScreenSize() {
    static CGSize size;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size = [UIScreen mainScreen].bounds.size;
        if (size.height < size.width) {
            CGFloat tmp = size.height;
            size.height = size.width;
            size.width = tmp;
        }
    });
    return size;
}

#define MSS_DEVICE_WIDTH   (MSS_ScreenSize().width)
#define MSS_DEVICE_HEIGHT  (MSS_ScreenSize().height)

@interface MSSBrowseBaseViewController ()

@property (nonatomic,strong)NSArray *browseItemArray;
@property (nonatomic,assign)NSInteger firstIndex;
@property (nonatomic,assign)NSInteger currentIndex;
@property (nonatomic,assign)BOOL isRotate;// 判断是否正在切换横竖屏
@property (nonatomic,strong)UILabel *countLabel;// 当前图片位置
@property (nonatomic,strong)NSMutableArray *originalRectArray;
@property (nonatomic,strong)NSMutableArray *verticalBigRectArray;
@property (nonatomic,strong)NSMutableArray *horizontalBigRectArray;
@property (nonatomic,strong)UIImage *screenShotImage;
@property (nonatomic,strong)UIImageView *screenShotImageView;
@property (nonatomic,strong)UIView *bgView;
@property (nonatomic,assign)UIDeviceOrientation currentOrientation;
@property (nonatomic,strong)MSSBrowseActionSheet *browseActionSheet;
@property (nonatomic,strong)MSSBrowseRemindView *browseRemindView;

@property (nonatomic, assign)BOOL didLayoutSubviews;

@property (nonatomic, assign)BOOL statusBarHidden;
@end

@implementation MSSBrowseBaseViewController

#pragma mark - Life Cycle

- (instancetype)initWithBrowseItemArray:(NSArray *)browseItemArray currentIndex:(NSInteger)currentIndex
{
    self = [super init];
    if(self)
    {
        _browseItemArray = browseItemArray;
        _firstIndex = currentIndex;
        _currentIndex = currentIndex;
        _isEqualRatio = YES;
        _isFirstOpen = YES;
        _screenWidth = MSS_SCREEN_WIDTH;
        _screenHeight = MSS_SCREEN_HEIGHT;
        _currentOrientation = UIDeviceOrientationPortrait;
        _verticalBigRectArray = [[NSMutableArray alloc]init];
        _horizontalBigRectArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initData];
    [self createBrowseView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _statusBarHidden = YES;
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _didLayoutSubviews = YES;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Public

- (void)showBrowseViewController:(__kindof UIViewController *)presentingViewController
{
    [self prepareForBrowse];
    [presentingViewController presentViewController:self animated:NO completion:nil];
}

// 当大图frame为空时，需要大图加载完成后重新计算坐标
- (CGRect)getBigImageRectIfIsEmptyRect:(CGRect)rect bigImage:(UIImage *)bigImage
{
    if(CGRectIsEmpty(rect))
    {
        return [bigImage mss_getBigImageRectSizeWithScreenWidth:self.screenWidth screenHeight:self.screenHeight];
    }
    return rect;
}

// 获取指定视图在window中的位置
- (CGRect)getFrameInWindow:(UIView *)view
{
    // 改用[UIApplication sharedApplication].keyWindow.rootViewController.view，防止present新viewController坐标转换不准问题
    return [view.superview convertRect:view.frame toView:GETAPPWINDOW];
}

// 子类重写此方法
- (void)loadBrowseImageWithBrowseItem:(MSSBrowseModel *)browseItem Cell:(id)cell bigImageRect:(CGRect)bigImageRect
{
    
}

#pragma mark - Private
- (void)prepareForBrowse
{
    self.screenShotImage = [UIImage screenshot];
    /** 记录小图相对整个屏幕的原始坐标 */
    if (self.recordOriginalRect) {
        for (MSSBrowseModel *browseItem in _browseItemArray)
        {
            CGRect originalRect = CGRectZero;
            if(browseItem.smallImageView)
            {
                originalRect = [self getFrameInWindow:browseItem.smallImageView];
            }
            NSValue *originalValue = [NSValue valueWithCGRect:originalRect];
            [self.originalRectArray addObject:originalValue];
        }
    }
}

- (void)initData
{
    for (MSSBrowseModel *browseItem in _browseItemArray)
    {
        CGRect verticalRect = CGRectZero;
        CGRect horizontalRect = CGRectZero;
        // 等比可根据小图宽高计算大图宽高
        if(_isEqualRatio)
        {
            if(browseItem.smallImageView)
            {
                verticalRect = [browseItem.smallImageView.image mss_getBigImageRectSizeWithScreenWidth:MSS_SCREEN_WIDTH screenHeight:MSS_SCREEN_HEIGHT];
                horizontalRect = [browseItem.smallImageView.image mss_getBigImageRectSizeWithScreenWidth:MSS_SCREEN_HEIGHT screenHeight:MSS_SCREEN_WIDTH];
            }
        }
        NSValue *verticalValue = [NSValue valueWithCGRect:verticalRect];
        [_verticalBigRectArray addObject:verticalValue];
        NSValue *horizontalValue = [NSValue valueWithCGRect:horizontalRect];
        [_horizontalBigRectArray addObject:horizontalValue];
    }
}

- (void)createBrowseView
{
    if (self.screenShotImage) {
        self.screenShotImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.screenShotImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        self.screenShotImageView.image = self.screenShotImage;
        [self.view addSubview:self.screenShotImageView];
        self.screenShotImageView.hidden = YES;
    }
    self.view.backgroundColor = [UIColor blackColor];

    _bgView = [[UIView alloc]initWithFrame:self.view.bounds];
    _bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _bgView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_bgView];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.minimumLineSpacing = 0;
    // 布局方式改为从上至下，默认从左到右
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    // Section Inset就是某个section中cell的边界范围
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
    // 每行内部cell item的间距
    flowLayout.minimumInteritemSpacing = 0;
    // 每行的间距
    flowLayout.minimumLineSpacing = 0;
    
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(0, 0, _screenWidth + kBrowseSpace, _screenHeight) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.bounces = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.backgroundColor = [UIColor blackColor];
    [_collectionView registerClass:[MSSBrowseCollectionViewCell class] forCellWithReuseIdentifier:@"MSSBrowserCell"];

    _collectionView.contentOffset = CGPointMake(_currentIndex * (_screenWidth + kBrowseSpace), 0);
    [_bgView addSubview:_collectionView];
    
    _countLabel = [[UILabel alloc] init];
    _countLabel.textColor = [UIColor whiteColor];
    _countLabel.text = _browseItemArray.count > 1 ? [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex + 1,(long)_browseItemArray.count] : @"";
    _countLabel.textAlignment = NSTextAlignmentCenter;
    [_bgView addSubview:_countLabel];
    _countLabel.frame = CGRectMake((MSS_DEVICE_WIDTH - 200.0) / 2.0, 25.0, 200.0, 16.0);
    _countLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    _browseRemindView = [[MSSBrowseRemindView alloc]initWithFrame:_bgView.bounds];
    _browseRemindView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_bgView addSubview:_browseRemindView];
}

#pragma mark - UIColectionViewDataSource
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MSSBrowseModel *browseItem = [_browseItemArray objectAtIndex:indexPath.row];
    MSSBrowseCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MSSBrowserCell" forIndexPath:indexPath];
    // 还原初始缩放比例
    cell.zoomScrollView.frame = CGRectMake(0, 0, _screenWidth, _screenHeight);
    cell.zoomScrollView.zoomScale = 1.0f;
    // 将scrollview的contentSize还原成缩放前
    cell.zoomScrollView.contentSize = CGSizeMake(_screenWidth, _screenHeight);
    cell.zoomScrollView.zoomImageView.contentMode = browseItem.smallImageView.contentMode;
    cell.zoomScrollView.zoomImageView.clipsToBounds = browseItem.smallImageView.clipsToBounds;
    [cell.loadingView mss_setFrameInSuperViewCenterWithSize:CGSizeMake(30, 30)];
    CGRect bigImageRect = [_verticalBigRectArray[indexPath.row] CGRectValue];
    if(_currentOrientation != UIDeviceOrientationPortrait)
    {
        bigImageRect = [_horizontalBigRectArray[indexPath.row] CGRectValue];
    }
    [self loadBrowseImageWithBrowseItem:browseItem Cell:cell bigImageRect:bigImageRect];
    
    __weak __typeof(self)weakSelf = self;
    [cell tapClick:^(MSSBrowseCollectionViewCell *browseCell) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf tap:browseCell];
    }];
    [cell longPress:^(MSSBrowseCollectionViewCell *browseCell) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:browseItem.bigImageUrl completion:^(BOOL isInCache) {
            if (isInCache) {
                [strongSelf longPress:browseCell];
            }
        }];
    }];
    return cell;
    
    return nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _browseItemArray.count;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(_screenWidth + kBrowseSpace, _screenHeight);
}

#pragma mark - UIScrollViewDeletate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(!_isRotate)
    {
        _currentIndex = scrollView.contentOffset.x / (_screenWidth + kBrowseSpace);
        _countLabel.text = [NSString stringWithFormat:@"%ld/%ld",(long)_currentIndex + 1,(long)_browseItemArray.count];
    }
    _isRotate = NO;
}

#pragma mark - Tap Method
- (void)tap:(MSSBrowseCollectionViewCell *)browseCell
{
    // 集合视图背景色设置为透明
    _collectionView.backgroundColor = [UIColor clearColor];
    //显示背景
    self.screenShotImageView.hidden = NO;
    // 动画结束前不可点击透明背景后的内容
    _collectionView.userInteractionEnabled = NO;
    
    // 停止加载
    NSArray *cellArray = _collectionView.visibleCells;
    for (MSSBrowseCollectionViewCell *cell in cellArray)
    {
        [cell.loadingView stopAnimation];
    }
    [_countLabel removeFromSuperview];
    _countLabel = nil;
    
    NSIndexPath *indexPath = [_collectionView indexPathForCell:browseCell];
    browseCell.zoomScrollView.zoomScale = 1.0f;
    MSSBrowseModel *browseItem = _browseItemArray[indexPath.row];
    /*
     建议小图列表的collectionView尽量不要复用，因为当小图的列表collectionview复用时，传进来的BrowseItem数组只有当前显示cell的smallImageView，在当前屏幕外的cell上的小图由于复用关系实际是没有的，所以只能有简单的渐变动画
     */
    if(browseItem.smallImageView)
    {
        CGRect rect;
        if (_originalRectArray.count > indexPath.row) {
            rect = [_originalRectArray[indexPath.row] CGRectValue];
        } else {
            rect = [self getFrameInWindow:browseItem.smallImageView];
        }
        CGAffineTransform transform = CGAffineTransformMakeRotation(0);
        if(_currentOrientation == UIDeviceOrientationLandscapeLeft)
        {
            transform = CGAffineTransformMakeRotation(- M_PI / 2);
            rect = CGRectMake(rect.origin.y, MSS_DEVICE_WIDTH - rect.size.width - rect.origin.x, rect.size.height, rect.size.width);
        }
        else if(_currentOrientation == UIDeviceOrientationLandscapeRight)
        {
            transform = CGAffineTransformMakeRotation(M_PI / 2);
            rect = CGRectMake(MSS_DEVICE_HEIGHT - rect.size.height - rect.origin.y, rect.origin.x, rect.size.height, rect.size.width);
        }
        
        [UIView animateWithDuration:MSS_ANIMATION_DURATION animations:^{
            browseCell.zoomScrollView.zoomImageView.transform = transform;
            browseCell.zoomScrollView.zoomImageView.frame = rect;
        } completion:^(BOOL finished) {
            __weak __typeof(&*self) weakSelf = self;
            [self dismissViewControllerAnimated:NO completion:^{
                weakSelf.screenShotImageView.hidden = YES;
            }];
        }];
    }
    else
    {
        [UIView animateWithDuration:MSS_ANIMATION_DURATION animations:^{
            _collectionView.alpha = 0.0;
        } completion:^(BOOL finished) {
            __weak __typeof(&*self) weakSelf = self;
            [self dismissViewControllerAnimated:NO completion:^{
                weakSelf.screenShotImageView.hidden = YES;
            }];
        }];
    }
}

- (void)longPress:(MSSBrowseCollectionViewCell *)browseCell
{
    [_browseActionSheet removeFromSuperview];
    _browseActionSheet = nil;
    __weak __typeof(self)weakSelf = self;
    _browseActionSheet = [[MSSBrowseActionSheet alloc]initWithTitleArray:@[@"保存图片",@"复制图片地址"] cancelButtonTitle:@"取消" didSelectedBlock:^(NSInteger index) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf browseActionSheetDidSelectedAtIndex:index currentCell:browseCell];
    }];
    [_browseActionSheet showInView:_bgView];
}

#pragma mark - StatusBar Method
- (BOOL)prefersStatusBarHidden
{
    return _statusBarHidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.presentingViewController.preferredStatusBarStyle;
}

#pragma mark - Orientation Method
- (BOOL)shouldAutorotate
{
    return self.didLayoutSubviews;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.didLayoutSubviews) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UICollectionViewCell *currentCell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:_currentIndex inSection:0]];
    if (currentCell) {
        MSSBrowseCollectionViewCell *cell = (MSSBrowseCollectionViewCell *)currentCell;
        UIView *containerView = [cell containerView];
        [containerView removeFromSuperview];
        containerView.frame = _bgView.bounds;
        [_bgView insertSubview:containerView aboveSubview:_collectionView];
        _collectionView.hidden = YES;
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            _isRotate = YES;
            _currentOrientation = [UIDevice currentDevice].orientation;
            CGRect bigImageRect = CGRectZero;
            _screenWidth = size.width;
            _screenHeight = size.height;
            if(_currentOrientation == UIDeviceOrientationPortrait)
            {
                bigImageRect = [_verticalBigRectArray[_currentIndex] CGRectValue];
            }
            else
            {
                bigImageRect = [_horizontalBigRectArray[_currentIndex] CGRectValue];
            }
            
            CGRect bigRect = [self getBigImageRectIfIsEmptyRect:bigImageRect bigImage:[cell image]];
            
            [cell resizeContainerViewWithNewBounds:CGRectMake(0, 0, size.width, size.height) imageBigRect:bigRect];
            
            if(_browseActionSheet)
            {
                [_browseActionSheet updateFrame];
            }
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [_collectionView.collectionViewLayout invalidateLayout];
            _collectionView.frame = CGRectMake(0, 0, size.width + kBrowseSpace, size.height);
            _collectionView.contentOffset = CGPointMake((size.width + kBrowseSpace) * _currentIndex, 0);
            [_collectionView reloadData];
            [containerView removeFromSuperview];
            [cell.contentView addSubview:containerView];
            _collectionView.hidden = NO;
            [self setNewScreenShotImageWithCurrentDeviceOrientation:_currentOrientation];
        }];
    }
}

- (void)setNewScreenShotImageWithCurrentDeviceOrientation:(UIDeviceOrientation)currentDeviceOrientation
{
    switch (currentDeviceOrientation) {
        case UIDeviceOrientationPortrait:
            self.screenShotImage = [self.screenShotImage imageRotateToOrientation:UIImageOrientationUp];
            break;
        case UIDeviceOrientationLandscapeLeft:
            self.screenShotImage = [self.screenShotImage imageRotateToOrientation:UIImageOrientationLeft];
            break;
        case UIDeviceOrientationLandscapeRight:
            self.screenShotImage = [self.screenShotImage imageRotateToOrientation:UIImageOrientationRight];
            break;
        default:
            break;
    }
    
    self.screenShotImageView.image = self.screenShotImage;
}

#pragma mark - MSSActionSheetClick
- (void)browseActionSheetDidSelectedAtIndex:(NSInteger)index currentCell:(MSSBrowseCollectionViewCell *)currentCell
{    // 保存图片
    if(index == 0)
    {
        UIImageWriteToSavedPhotosAlbum(currentCell.zoomScrollView.zoomImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
    // 复制图片地址
    else if(index == 1)
    {
        MSSBrowseModel *currentBwowseItem = _browseItemArray[_currentIndex];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = currentBwowseItem.bigImageUrl;
        [self showBrowseRemindViewWithText:@"复制图片地址成功"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *text = nil;
    if(error)
    {
        text = @"保存图片失败";
    }
    else
    {
        text = @"保存图片成功";
    }
    [self showBrowseRemindViewWithText:text];
}

#pragma mark - RemindView Method
- (void)showBrowseRemindViewWithText:(NSString *)text
{
    [_browseRemindView showRemindViewWithText:text];
    _bgView.userInteractionEnabled = NO;
    [self performSelector:@selector(hideRemindView) withObject:nil afterDelay:0.7];
}

- (void)hideRemindView
{
    [NSObject  cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideRemindView) object:nil];
    [_browseRemindView hideRemindView];
    _bgView.userInteractionEnabled = YES;
}

#pragma mark - getter

- (NSMutableArray *)originalRectArray
{
    if (!_originalRectArray) {
        _originalRectArray = [NSMutableArray array];
    }
    return _originalRectArray;
}

@end
