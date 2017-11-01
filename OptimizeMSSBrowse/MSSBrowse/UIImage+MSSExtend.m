//
//  UIImage+MSSExtend.m
//  OptimizeMSSBrowse
//
//  Created by yutao on 31/10/2017.
//  Copyright © 2017 yutao. All rights reserved.
//

#import "UIImage+MSSExtend.h"

@implementation UIImage (MSSExtend)

#pragma mark - Image Orientation

- (UIImage *)imageRotateToOrientation:(UIImageOrientation)imageOrientation
{
    if (self.imageOrientation == imageOrientation) {
        return self;
    }
    
    UIImage *newImage = [UIImage imageWithCGImage:[self CGImage]
                                            scale:[self scale]
                                      orientation:imageOrientation];
    return newImage;
}

#pragma mark - Screenshot

+ (UIImage *)screenshot
{
    return [self screenshotWithStatusBar:YES];
}

+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar
{
    CGRect screenShotRect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(o))
    {
        CGFloat oldWidth = screenShotRect.size.width;
        screenShotRect.size.width = screenShotRect.size.height;
        screenShotRect.size.height = oldWidth;
    }
    return [self screenshotWithStatusBar:withStatusBar rect:screenShotRect];
}

+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect
{
    UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
    return [self screenshotWithStatusBar:withStatusBar rect:rect orientation:o];
}

+ (UIImage *)screenshotWithStatusBar:(BOOL)withStatusBar rect:(CGRect)rect orientation:(UIInterfaceOrientation)o
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = CGRectGetWidth(screenRect);
    CGFloat screenHeight = CGRectGetHeight(screenRect);
    CGAffineTransform preTransform = CGAffineTransformIdentity;
    switch (o)
    {
        case UIInterfaceOrientationPortrait:
            //move screenshot rect origin to down left
            //rotate screenshot rect to meet portrait
            //move screenshot rect origin to up left
            //....yes, with a single line..
            preTransform = CGAffineTransformTranslate(preTransform, -rect.origin.x, -rect.origin.y);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            //move screenshot rect origin to down left
            preTransform = CGAffineTransformTranslate(preTransform, screenWidth - rect.origin.x, -rect.origin.y);
            //rotate screenshot rect to meet portrait
            preTransform = CGAffineTransformRotate(preTransform, M_PI);
            //move screenshot rect origin to up left
            preTransform = CGAffineTransformTranslate(preTransform, 0, -screenHeight);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            //move screenshot rect origin to down left
            preTransform = CGAffineTransformTranslate(preTransform, -rect.origin.x, -rect.origin.y);
            //rotate screenshot rect to meet portrait
            preTransform = CGAffineTransformRotate(preTransform, M_PI_2);
            //move screenshot rect origin to up left
            preTransform = CGAffineTransformTranslate(preTransform, 0, -screenHeight);
            break;
        case UIInterfaceOrientationLandscapeRight:
            //move screenshot rect origin to down left
            preTransform = CGAffineTransformTranslate(preTransform, screenHeight - rect.origin.x, screenWidth - rect.origin.y);
            //rotate screenshot rect to meet portrait
            preTransform = CGAffineTransformRotate(preTransform, - M_PI_2);
            //move screenshot rect origin to up left
            preTransform = CGAffineTransformTranslate(preTransform, 0, -screenHeight);
            break;
        default:
            break;
    }
    
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    //    if (NULL != UIGraphicsBeginImageContextWithOptions)
    //    {
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    //    }
    //    else
    //    {
    //        UIGraphicsBeginImageContext(rect.size);
    //    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    BOOL hasTakenStatusBarScreenshot = NO;
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            
            // Apply pre tranform to context.
            // to convert all interface orientation situation to portrait situation.
            CGContextConcatCTM(context, preTransform);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            
            // Render the layer hierarchy to the current context
            if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
                //速度比 renderInContext: 快很多  afterScreenUpdates:YES会引起其他动画延迟
                [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO];
            } else {
                [window.layer renderInContext:context];
            }
            
            // Restore the context
            CGContextRestoreGState(context);
        }
        
        // Screenshot status bar if next window's window level > status bar window level
        NSArray *windows = [[UIApplication sharedApplication] windows];
        NSUInteger currentWindowIndex = [windows indexOfObject:window];
        if (windows.count > currentWindowIndex + 1)
        {
            UIWindow *nextWindow = [windows objectAtIndex:currentWindowIndex + 1];
            if (withStatusBar && nextWindow.windowLevel > UIWindowLevelStatusBar && !hasTakenStatusBarScreenshot)
            {
                [self mergeStatusBarToContext:context rect:rect screenshotOrientation:o];
                hasTakenStatusBarScreenshot = YES;
            }
        }
        else
        {
            if (withStatusBar && !hasTakenStatusBarScreenshot)
            {
                [self mergeStatusBarToContext:context rect:rect screenshotOrientation:o];
                hasTakenStatusBarScreenshot = YES;
            }
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)mergeStatusBarToContext:(CGContextRef)context
                           rect:(CGRect)rect
          screenshotOrientation:(UIInterfaceOrientation)o
{
    UIView *statusBarView = [[UIApplication sharedApplication] valueForKey:@"statusBar"];
    if (!statusBarView || ![statusBarView isKindOfClass:[UIView class]]) {
        return;
    }
    
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGAffineTransform preTransform = CGAffineTransformIdentity;
    if (o == statusBarOrientation)
    {
        preTransform = CGAffineTransformTranslate(preTransform, -rect.origin.x, -rect.origin.y);
    }
    //Handle status bar orientation in portrait and portrait upside down screen shot
    else if((o == UIInterfaceOrientationPortrait && statusBarOrientation == UIInterfaceOrientationLandscapeLeft) ||
            (o == UIInterfaceOrientationPortraitUpsideDown && statusBarOrientation == UIInterfaceOrientationLandscapeRight))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, - M_PI_2);
        preTransform = CGAffineTransformTranslate(preTransform, CGRectGetMaxY(rect) - screenHeight, -rect.origin.x);
    }
    else if((o == UIInterfaceOrientationPortrait && statusBarOrientation == UIInterfaceOrientationLandscapeRight) ||
            (o == UIInterfaceOrientationPortraitUpsideDown && statusBarOrientation == UIInterfaceOrientationLandscapeLeft))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, M_PI_2);
        preTransform = CGAffineTransformTranslate(preTransform, -CGRectGetMaxY(rect), rect.origin.x - screenWidth);
    }
    else if((o == UIInterfaceOrientationPortrait && statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (o == UIInterfaceOrientationPortraitUpsideDown && statusBarOrientation == UIInterfaceOrientationPortrait))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, - M_PI);
        preTransform = CGAffineTransformTranslate(preTransform, rect.origin.x - screenWidth, CGRectGetMaxY(rect) - screenHeight);
    }
    //Handle status bar orientation in landscape left and landscape right screen shot
    else if((o == UIInterfaceOrientationLandscapeLeft && statusBarOrientation == UIInterfaceOrientationPortrait) ||
            (o == UIInterfaceOrientationLandscapeRight && statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, M_PI_2);
        preTransform = CGAffineTransformTranslate(preTransform, -CGRectGetMaxY(rect), rect.origin.x - screenHeight);
    }
    else if((o == UIInterfaceOrientationLandscapeLeft && statusBarOrientation == UIInterfaceOrientationLandscapeRight) ||
            (o == UIInterfaceOrientationLandscapeRight && statusBarOrientation == UIInterfaceOrientationLandscapeLeft))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, M_PI);
        preTransform = CGAffineTransformTranslate(preTransform, rect.origin.x - screenHeight, CGRectGetMaxY(rect) - screenWidth);
    }
    else if((o == UIInterfaceOrientationLandscapeLeft && statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) ||
            (o == UIInterfaceOrientationLandscapeRight && statusBarOrientation == UIInterfaceOrientationPortrait))
    {
        preTransform = CGAffineTransformTranslate(preTransform, 0, rect.size.height);
        preTransform = CGAffineTransformRotate(preTransform, - M_PI_2);
        preTransform = CGAffineTransformTranslate(preTransform, CGRectGetMaxY(rect) - screenWidth, -rect.origin.x);
    }
    
    // -renderInContext: renders in the coordinate space of the layer,
    // so we must first apply the layer's geometry to the graphics context
    CGContextSaveGState(context);
    // Apply pre transform
    CGContextConcatCTM(context, preTransform);
    // Center the context around the window's anchor point
    CGContextTranslateCTM(context, [statusBarView center].x, [statusBarView center].y);
    // Apply the view transform about the anchor point
    CGContextConcatCTM(context, [statusBarView transform]);
    // Offset by the portion of the bounds left of and above the anchor point
    CGContextTranslateCTM(context,
                          -[statusBarView bounds].size.width * [[statusBarView layer] anchorPoint].x,
                          -[statusBarView bounds].size.height * [[statusBarView layer] anchorPoint].y);
    
    // Render the layer hierarchy to the current context
    if ([statusBarView respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        //速度比 renderInContext: 快很多  afterScreenUpdates:YES会引起其他动画延迟
        [statusBarView drawViewHierarchyInRect:statusBarView.bounds afterScreenUpdates:NO];
    } else {
        [statusBarView.layer renderInContext:context];
    }
    
    // Restore the context
    CGContextRestoreGState(context);
}

@end
