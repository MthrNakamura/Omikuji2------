//
//  VideoViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"

@interface VideoViewController : UIViewController <UIWebViewDelegate> {
    MPMoviePlayerViewController *moviePlayer;
}
@property (strong, nonatomic) AppDelegate *delegate;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIWindow *offScreenWindow;

- (void)MPMoviePlayerPlaybackDidFinishNotification;
- (void)playMovie;

- (NSString *)convertPrintInfo2Receipt:(NSString *)printInfo;
- (UIImage *)createQRBarcode:(NSString *)qrString;
- (void)downloadImage:(NSString *)urlString;
- (void)saveImage:(NSData *)imageData;
@end
