//
//  MSSBrowseCollectionViewCell.m
//  MSSBrowse
//
//  Created by 于威 on 15/12/5.
//  Copyright © 2015年 于威. All rights reserved.
//

#import "MSSBrowseCollectionViewCell.h"
#import "MSSBrowseDefine.h"

@interface MSSBrowseCollectionViewCell ()

@property (nonatomic,copy)MSSBrowseCollectionViewCellTapBlock tapBlock;
@property (nonatomic,copy)MSSBrowseCollectionViewCellLongPressBlock longPressBlock;

@end

@implementation MSSBrowseCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self createCell];
    }
    return self;
}

- (void)createCell
{
    _zoomScrollView = [[MSSBrowseZoomScrollView alloc]init];
    __weak __typeof(self)weakSelf = self;
    [_zoomScrollView tapClick:^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.tapBlock(strongSelf);
    }];
    [self.contentView addSubview:_zoomScrollView];
    
    _loadingView = [[MSSBrowseLoadingImageView alloc]init];
    [_zoomScrollView addSubview:_loadingView];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressGesture:)];
    [self.contentView addGestureRecognizer:longPressGesture];
}

- (void)tapClick:(MSSBrowseCollectionViewCellTapBlock)tapBlock
{
    _tapBlock = tapBlock;
}

- (void)longPress:(MSSBrowseCollectionViewCellLongPressBlock)longPressBlock
{
    _longPressBlock = longPressBlock;
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)gesture
{
    if(_longPressBlock)
    {
        if(gesture.state == UIGestureRecognizerStateBegan)
        {
            _longPressBlock(self);
        }
    }
}

- (UIView *)containerView
{
    return _zoomScrollView;
}

- (UIImage *)image
{
    return _zoomScrollView.zoomImageView.image;
}

- (void)resizeContainerViewWithNewBounds:(CGRect)newBounds
                            imageBigRect:(CGRect)imageBigRect
{
    _zoomScrollView.zoomScale = 1.0;
    _zoomScrollView.frame = newBounds;
    _zoomScrollView.zoomImageView.frame = imageBigRect;
    _loadingView.frame = CGRectMake((newBounds.size.width - 30) / 2, (newBounds.size.width - 30) / 2, 30, 30);
}
@end
