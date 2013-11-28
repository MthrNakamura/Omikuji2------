//
//  TopViewController.h
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"


@interface TopViewController : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate> {
    NSURLConnection *connection;
    //NSMutableData *asyncData;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;


- (IBAction)touchupInside:(id)sender;
- (IBAction)touchDown:(id)sender;

- (void)longTouchDetected:(id)sender;


- (void)checkUpdate:(NSTimer *)timer;
- (BOOL)downloadMovieSynchronously:(NSString *)contentId;
- (NSMutableURLRequest *)createDownloadMovieRequest:(NSString *)contentId;
- (BOOL)checkDownloadStatus:(NSHTTPURLResponse *)httpResponse;
@end
