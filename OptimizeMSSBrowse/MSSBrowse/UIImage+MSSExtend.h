//
//  UIImage+MSSExtend.h
//  OptimizeMSSBrowse
//
//  Created by yutao on 31/10/2017.
//  Copyright © 2017 yutao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (MSSExtend)

#pragma mark - Image Orientation

- (UIImage *)imageRotateToOrientation:(UIImageOrientation)imageOrientation;

#pragma mark - Screenshot

//Get the screenshot, image rotate to status bar's current interface orientation. With status bar.
+ (UIImage *)screenshot;

//Get the screenshot, image rotate to status bar's current interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar;

//Get the screenshot with rect, image rotate to status bar's current interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect;

//Get the screenshot with rect, you can specific a interface orientation.
+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect orientation:(UIInterfaceOrientation)o;

@end
