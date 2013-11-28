//
//  TopViewController.m
//  Omikuji2
//
//  Created by MotohiroNAKAMURA on 2013/10/25.
//  Copyright (c) 2013年 com.self.planningdev. All rights reserved.
//

#import "TopViewController.h"
#import "ViewController.h"
#import "LaunchViewController.h"
#import "ManagementViewController.h"

AppDelegate *delegate;

@interface TopViewController ()

@end

@implementation TopViewController



int counter;

float totalBytes;
float loadedBytes;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    
    delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
 
    NSLog(@"numloop: %d", delegate.numLoop);
    if (delegate.numLoop >= NUM_LOOP) {
        exit(0);
        return ;
    }
    
    if (delegate.qrErrorMsg != nil) {
        NSString *error = delegate.qrErrorMsg;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"QR読み込みエラー" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        delegate.qrErrorMsg = nil;
    }
    
    //TOP画面のwebページを表示
    self.webView.delegate = self;
    
    NSURL * url = [NSURL URLWithString:delegate.topURL];
    [self.webView setBackgroundColor:[UIColor clearColor]];
    [self.webView setOpaque:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    //QRコード読み込みページに遷移する関数を定義する
    [self.webView stringByEvaluatingJavaScriptFromString:
     @"var qrScanOpen = function(dest) { dest = dest.replace(\"http://\", \"\");window.location = \"omikuji://\"+dest; };"
     ];
    
    //定期更新確認を設定
    //[NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL target:self selector:@selector(checkUpdate:) userInfo:nil repeats:YES];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.webView setDelegate:nil];
    [self.webView stopLoading];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL] absoluteString];
    if ([url hasPrefix:@"omikuji://"]) {
        //QR画面に遷移
        url = [url stringByReplacingOccurrencesOfString:@"omikuji://" withString:@""];
        delegate.qrURL = [NSString stringWithFormat:@"http://t.bemss.jp/appsdev01/html/%@", url];
        
        ViewController *qrView = [self.storyboard instantiateViewControllerWithIdentifier:@"QRView"];
        [self presentViewController:qrView animated:YES completion:nil];
    }
    return YES;
}

- (void)longTouchDetected:(id)sender
{
    //10秒長押ししたら管理画面に遷移する
    ManagementViewController *managementView = [self.storyboard instantiateViewControllerWithIdentifier:@"ManageNavi"];
    [self presentViewController:managementView animated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (IBAction)touchupInside:(id)sender {
    NSLog(@"touchupinside");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longTouchDetected:) object:sender];
}

- (IBAction)touchDown:(id)sender {
    NSLog(@"touchdown");
    [self performSelector:@selector(longTouchDetected:) withObject:sender afterDelay:TIME_TO_LONG_TAP];
}

//- (void)checkUpdate:(NSTimer *)timer
//{
//    NSLog(@"start auto-update");
//    
//    //前回までのコンテンツリストを読み込む
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *contentsDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:
//                                        [defaults dataForKey:CONTENTSLIST_KEY]];
//    if (contentsDictionary == nil) {
//        //前回までのデータが無ければすべてダウンロード
//        //コンテンツをひとつずつ確認
//        NSMutableDictionary *jsonDictionary = [[NSMutableDictionary alloc]init];
//        NSDictionary *aNewContentValue;
//        NSArray *contents = [delegate.contentsList objectForKey:CONTENTSLIST_KEY];
//        for (NSDictionary *content in contents) {
//            switch ([[content objectForKey:@"type"] intValue]) {
//                case CONTENTS_TOPURL: //待受画面のURL情報
//                    delegate.topURL = [content objectForKey:@"url"];
//                    
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_QR_RAYER: //QRスキャン画面にレイヤする画面のURL情報
//                    //リソースのURLを取得
//                    delegate.qrURL = [content objectForKey:@"url"];
//                    
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_MOVIE: //抽選動画
//                    //動画をダウンロード
//                    if (![self downloadMovieSynchronously:[content objectForKey:@"id"]])
//                        return ;
//                    
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type",  [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_SOUND: //音声ファイル
//                    if (![self downloadMovieSynchronously:[content objectForKey:@"id"]])
//                        return ;
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type",  [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_DRAWEROPENED: //印刷エラー(カバーが開いている)
//                    delegate.drawerOpenURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_FAILEDTOCUT: //紙のカットに失敗
//                    delegate.failedCutURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_HEADERTEMP: //ヘッダーの温度が異常
//                    delegate.headerTempURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPEREMPTY: //紙切れ
//                    delegate.paperEmptyURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPERJAMMED: //紙詰まり
//                    delegate.paperJammedURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_POWERERROR: //電源異常
//                    delegate.powerErrorURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_UNUSUALDATA: //異常な量のデータを受け取った
//                    delegate.unusualDataURL = [content objectForKey:@"url"];
//                    //このコンテンツのjsonを作成
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[content objectForKey:@"type"], @"type", [content objectForKey:@"url"], @"url", [content objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                default:
//                    break;
//            }
//            [jsonDictionary setObject:aNewContentValue forKey:[content objectForKey:@"id"]];
//        }
//        //コンテンツリストを保存
//        NSData *dicData = [NSKeyedArchiver archivedDataWithRootObject:jsonDictionary];
//        [defaults setObject:dicData forKey:CONTENTSLIST_KEY];
//        
//        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"コンテンツ更新" message:@"すべてのコンテンツは最新の状態です" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
//        
////        [jsonDictionary release];
////        [aNewContentValue release];
//        return ;
//    }
//    
//    
//    //前回までのデータと更新日時を比較して、既存のコンテンツよりも更新日時が新しければダウンロード
//    NSMutableDictionary *jsonData = [[NSMutableDictionary alloc]init];
//    BOOL shouldBeUpdateList = NO;
//    NSArray *newContents = [delegate.contentsList objectForKey:@"contents"];
//    for (NSDictionary *newContent in newContents) {
//        NSDictionary *aNewContentValue;
//        BOOL existSameId = NO;
//        //新しいコンテンツと同じIDのコンテンツが既存のリストに存在するか
//        NSString *newId = [newContent objectForKey:@"id"];
//        for (NSString *key in [contentsDictionary keyEnumerator]) {
//            if ([key isEqualToString:newId]) {
//                existSameId = YES;
//                break;
//            }
//        }
//        BOOL shouldBeDownloaded = NO;
//        
//        NSDictionary *prevContent;
//        //存在すれば、更新日時を比較
//        if (existSameId) {
//            prevContent = [contentsDictionary objectForKey:newId];
//            long prevUpdDatetime = (long)[prevContent objectForKey:@"finalUpdDatetime"];
//            long newUpdDatetime = (long)[[newContent objectForKey:newId]objectForKey:@"finalUpdDatetime"];
//            if (prevUpdDatetime < newUpdDatetime) {
//                shouldBeDownloaded = YES;
//                shouldBeUpdateList = YES;
//            }
//        }
//        else {
//            shouldBeDownloaded = YES;
//            shouldBeUpdateList = YES;
//        }
//        
//        //既存のデータを読み込む
//        if (existSameId && !shouldBeDownloaded) {
//            switch ([[prevContent objectForKey:@"type"] intValue]) {
//                case CONTENTS_TOPURL: //待受画面のURL情報
//                    delegate.topURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_QR_RAYER: //QRスキャン画面にレイヤする画面のURL情報
//                    //リソースのURLを取得
//                    delegate.qrURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_MOVIE: //抽選動画
//                    //動画をダウンロード
//                    if (![self downloadMovieSynchronously:[prevContent objectForKey:@"id"]])
//                        return ;
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type",  [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_SOUND: //音声ファイル
//                    if (![self downloadMovieSynchronously:[prevContent objectForKey:@"id"]])
//                        return ;
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type",  [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_DRAWEROPENED: //印刷エラー(カバーが開いている)
//                    delegate.drawerOpenURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_FAILEDTOCUT: //紙のカットに失敗
//                    delegate.failedCutURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_HEADERTEMP: //ヘッダーの温度が異常
//                    delegate.headerTempURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPEREMPTY: //紙切れ
//                    delegate.paperEmptyURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPERJAMMED: //紙詰まり
//                    delegate.paperJammedURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_POWERERROR: //電源異常
//                    delegate.powerErrorURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_UNUSUALDATA: //異常な量のデータを受け取った
//                    delegate.unusualDataURL = [prevContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[prevContent objectForKey:@"type"], @"type", [prevContent objectForKey:@"url"], @"url", [prevContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//            }
//            //JSONデータを追加
//            [jsonData setObject:aNewContentValue forKey:[prevContent objectForKey:@"id"]];
//        }
//        //ダウンロード
//        else if (shouldBeDownloaded) {
//            switch ([[newContent objectForKey:@"type"] intValue]) {
//                case CONTENTS_TOPURL: //待受画面のURL情報
//                    delegate.topURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_QR_RAYER: //QRスキャン画面にレイヤする画面のURL情報
//                    //リソースのURLを取得
//                    delegate.qrURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_MOVIE: //抽選動画
//                    //動画をダウンロード
//                    if (![self downloadMovieSynchronously:[newContent objectForKey:@"id"]])
//                        return ;
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case CONTENTS_SOUND: //音声ファイル
//                    if (![self downloadMovieSynchronously:[newContent objectForKey:@"id"]])
//                        return ;
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_DRAWEROPENED: //印刷エラー(カバーが開いている)
//                    delegate.drawerOpenURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_FAILEDTOCUT: //紙のカットに失敗
//                    delegate.failedCutURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_HEADERTEMP: //ヘッダーの温度が異常
//                    delegate.headerTempURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPEREMPTY: //紙切れ
//                    delegate.paperEmptyURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_PAPERJAMMED: //紙詰まり
//                    delegate.paperJammedURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_POWERERROR: //電源異常
//                    delegate.powerErrorURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//                case ERROR_UNUSUALDATA: //異常な量のデータを受け取った
//                    delegate.unusualDataURL = [newContent objectForKey:@"url"];
//                    aNewContentValue = [[NSDictionary alloc]initWithObjectsAndKeys:[newContent objectForKey:@"type"], @"type", [newContent objectForKey:@"url"], @"url", [newContent objectForKey:@"finalUpdDatetime"], @"finalUpdDatetime", nil];
//                    break;
//            }
//            //JSONデータを追加
//            [jsonData setObject:aNewContentValue forKey:[newContent objectForKey:@"id"]];
//        }
//    }
//    //コンテンツリストを保存
//    NSLog(@"すべてのコンテンツは最新です");
//}

- (NSMutableURLRequest *)createDownloadMovieRequest:(NSString *)contentId
{
    //リクエストURLを設定
    NSString *urlStr = [[NSString alloc]initWithFormat:@"%@?id=%@", DOWNLOAD_API, contentId];
    NSURL *url = [[NSURL alloc]initWithString:urlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
//    [url release];
//    [urlStr release];
    
    //ヘッダーを設定
    [request setValue:APP_ID forHTTPHeaderField:@"ApplicationId"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:delegate.accessToken forHTTPHeaderField:@"Authorization"];
    
    //GETに設定
    [request setHTTPMethod:@"GET"];
    
    return request;
}

- (BOOL)prefersStatusBarHidden {return YES;}

- (BOOL)downloadMovieSynchronously:(NSString *)contentId
{
    //同期通信で動画をダウンロード
    NSMutableURLRequest *request = [self createDownloadMovieRequest:contentId];
    NSError *error;
    NSURLResponse *response;
    NSData *responseData =  [NSURLConnection sendSynchronousRequest:request
                                                  returningResponse:&response error:&error];
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (![self checkDownloadStatus:httpResponse])
        return NO;
    
    
    //動画を保存
    NSString *moviePath = [[NSString alloc]initWithFormat:@"%@.mp4", contentId];
    NSString *storePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:moviePath];
    //[moviePath release];
    if (responseData) {
        NSError *error;
        [responseData writeToFile:storePath options:NSDataWritingAtomic error:&error];
        if (error != nil) {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"ダウンロード失敗" message:@"ダウンロードに失敗しました" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return NO;
        }
    }
    return YES;
}

- (BOOL)checkDownloadStatus:(NSHTTPURLResponse *)httpResponse
{
    switch (httpResponse.statusCode) {
        case 200:
            NSLog(@"動画のダウンロードに成功");
            return YES;
        case 401:
            NSLog(@"認証エラー: コンテンツリストの取得に失敗しました");
            break;
        case 404:
            NSLog(@"コンテンツが見つかりません");
            break;
        case 500:
            NSLog(@"内部エラー: コンテンツリストの取得中にシステムエラーが発生しました");
            break;
        default:
            NSLog(@"未知のエラー: コンテンツリストの取得中に未知のエラーが発生しました");
            break;
    }

    return NO;
}
@end
