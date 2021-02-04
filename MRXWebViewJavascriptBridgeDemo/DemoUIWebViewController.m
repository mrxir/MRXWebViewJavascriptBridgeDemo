//
//  DemoUIWebViewController.m
//  MRXWebViewJavascriptBridgeDemo
//
//  Created by tangxi on 2021/2/4.
//

#import "DemoUIWebViewController.h"
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>

@interface DemoUIWebViewController ()
@property (nonatomic, strong) UIWebView *webView;
@property WebViewJavascriptBridge* bridge;
@property (nonatomic, strong) NSDictionary *userInfoMap;
@end

@implementation DemoUIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 模拟两个用户信息
    self.userInfoMap = @{@"liming@email.com": @{@"username": @"liming",
                                                @"age": @(18),
                                                @"nickname": @"Jack Li"},
                         @"vanessa@email.com": @{@"username": @"娜娜",
                                                 @"age":@(22),
                                                 @"nickname": @"honey nana"}
    };
    
    self.webView = (UIWebView *)self.view;
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView];
    [_bridge setWebViewDelegate:self];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY年M月d日 HH:mm:ss";
    
    // 直接调用 JS 中注册的 updateTime 交互方法进行 HTML 页面内容更新时间
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSDate *date = [NSDate date];
        [self.bridge callHandler:@"updateTime" data:[dateFormatter stringFromDate:date] responseCallback:^(id responseData) {
            NSLog(@"responseData: %@", responseData);
        }];
    }];
    
    
    // 注册一个名为 getUserInfo 的方法，供 js 调用
    // 本方法使用规则如下
    // 入参1 data：{"userId": "欲查询的用户id，例如'vanessa@email.com'"}
    // 入参2 responseCallback：js 的回调函数，回调函数的传参是在 js 调用处设定的
    [_bridge registerHandler:@"getUserInfo" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        // 这里模拟了一次耗时操作，1.5秒后将查询结果回调给js
        NSLog(@"查询中，请稍候...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 这里的 data 就是 DemoWebApp.html 第 53 行和第 63 行的参数
            NSDictionary *userInfo = [self.userInfoMap objectForKey:[data valueForKey:@"userId"]];
            
            if (userInfo) {
                responseCallback(@{@"userInfo": userInfo});
            } else {
                responseCallback([NSString stringWithFormat:@"错误 - 用户不存在 '%@'", [data valueForKey:@"userId"]]);
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:NULL];
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"错误 - 用户不存在 '%@'", [data valueForKey:@"userId"]] preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:cancel];
                [self presentViewController:ac animated:YES completion:NULL];
                
            }
            
            
        });
        
    }];
    
    [self loadExamplePage:_webView];
    
}

- (void)loadExamplePage:(UIWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"DemoWebApp" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

@end
