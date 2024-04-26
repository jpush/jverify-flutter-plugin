#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"
#import "JGInforCollectionAuth.h"
// 如果需要使用 idfa 功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
#define UIColorFromRGB(rgbValue)  ([UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0])


#define JVLog(fmt, ...) NSLog((@"| JVER | iOS | " fmt), ##__VA_ARGS__)

/// 统一 key
static NSString *const j_result_key = @"result";
/// 错误码
static NSString *const j_code_key = @"code";
/// 回调的提示信息，统一返回 flutter 为 message
static NSString *const j_msg_key = @"message";
/// 运营商信息
static NSString *const j_opr_key = @"operator";
/// 手机号
static NSString *const j_phone_key = @"phone";
/// 默认超时时间
static long j_default_timeout = 5000;
static BOOL needStartAnim = FALSE;
static BOOL needCloseAnim = FALSE;

@interface JverifyPlugin ()
@property (nonatomic, copy) void(^hidAgreementAlertView)(void);
@end

@implementation JverifyPlugin

NSObject<FlutterPluginRegistrar>* _jv_registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel methodChannelWithName:@"jverify"
                                                                binaryMessenger:[registrar messenger]];
    _jv_registrar = registrar;
    JverifyPlugin* instance = [[JverifyPlugin alloc] init];
    instance.channel = channel;
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - handleMethodCall: %@",call.method);
    
    NSString *methodName = call.method;
    if ([methodName isEqualToString:@"setup"]) {
        [self setup:call result:result];
    }else if([methodName isEqualToString:@"setDebugMode"]){
        [self setDebugMode:call result:result];
    }else if([methodName isEqualToString:@"setCollectionAuth"]){
        [self setCollectionAuth:call result:result];
    }else if([methodName isEqualToString:@"isInitSuccess"]) {
        [self isSetupClient:result];
    }else if([methodName isEqualToString:@"checkVerifyEnable"]){
        [self checkVerifyEnable:call result:result];
    }else if([methodName isEqualToString:@"getToken"]){
        [self getToken:call result:result];
    }else if([methodName isEqualToString:@"verifyNumber"]){
        [self verifyNumber:call result:result];
    }else if([methodName isEqualToString:@"loginAuth"]){
        [self loginAuth:call result:result];
    }else if ([methodName isEqualToString:@"loginAuthSyncApi"]){
        [self loginAuthSyncApi:call result:result];
    } else if([methodName isEqualToString:@"preLogin"]){
        [self preLogin:call result:result];
    }else if([methodName isEqualToString:@"dismissLoginAuthView"]){
        [self dismissLoginController:call result:result];
    }else if([methodName isEqualToString:@"setCustomUI"]){
        //        [self setCustomUIWithConfig:call result:result];
    }else if ([methodName isEqualToString:@"setCustomAuthViewAllWidgets"]) {
        [self setCustomAuthViewAllWidgets:call result:result];
    }else if ([methodName isEqualToString:@"clearPreLoginCache"]) {
        [self clearPreLoginCache:call result:result];
    }else if ([methodName isEqualToString:@"setCustomAuthorizationView"]) {
        [self setCustomAuthorizationView:call result:result];
    }else if ([methodName isEqualToString:@"getSMSCode"]){
        [self getSMSCode:call result:result];
    }else if ([methodName isEqualToString:@"setGetCodeInternal"]){
        [self setGetCodeInternal:call result:result];
    }else if ([methodName isEqualToString:@"smsAuth"]) {
        [self smsAuth:call result:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}
#pragma mark -SMS
- (void)getSMSCode:(FlutterMethodCall*) call result:(FlutterResult)resultDict{
    NSDictionary *arguments = call.arguments;
    JVLog(@"Action - getSMSCode:%@",arguments);
    NSString *phoneNumber = arguments[@"phoneNumber"];
    NSString *singId = arguments[@"signId"];
    NSString *tempId = arguments[@"tempId"];
    [JVERIFICATIONService getSMSCode:phoneNumber templateID:tempId signID:singId completionHandler:^(NSDictionary * _Nonnull result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSNumber *code = [result objectForKey:@"code"];
            NSString *msg = [result objectForKey:@"msg"];
            NSString *uuid =  [result objectForKey:@"uuid"];
            if ([code intValue] == 3000) {
                NSDictionary*dict = @{@"code":code,@"message":msg,@"result":uuid};
                resultDict(dict);
            }else{
                NSDictionary*dict = @{@"code":code,@"message":msg};
                resultDict(dict);
            }
        });
    }];
}
- (void)setGetCodeInternal:(FlutterMethodCall*) call result:(FlutterResult)resultDict{
    JVLog(@"Action - setGetCodeInternal::");
    NSDictionary *arguments = call.arguments;
    NSNumber *time = arguments[@"timeInterval"];
    [JVERIFICATIONService setGetCodeInternal:[time intValue]];
}

- (void)smsAuth:(FlutterMethodCall*) call result:(FlutterResult)resultDict{
    NSDictionary *arguments = call.arguments;
    NSNumber *autoDismiss = arguments[@"autoDismiss"];
    NSTimeInterval timeout = [arguments[@"timeout"] longLongValue];
    NSInteger smsAuthIndex = [arguments[@"smsAuthIndex"] longLongValue];
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    __weak typeof(self) weakself = self;
    [JVERIFICATIONService getSMSAuthorizationWithController:vc hide:[autoDismiss boolValue] animated:needStartAnim timeout:timeout completion:^(NSDictionary * _Nonnull res) {
       
        JVLog(@"getSMSAuthorizationWithController result = %@",res);
        
        NSString *msg;
        NSString *phoneNumber;
        if([res[@"content"] isKindOfClass:[NSString class]]){
            msg = res[@"content"];
        }else if ([res[@"content"] isKindOfClass:[NSDictionary class]]) {
            phoneNumber = [res[@"content"] objectForKey:@"number"];
            if ([[res[@"content"] objectForKey:@"tokenReponse"] isKindOfClass:[NSDictionary class]]) {
                msg = [res[@"content"][@"tokenReponse"] objectForKey:@"resultMsg"];
            }
        }
        NSDictionary *dict = @{
            j_code_key:res[@"code"],
            j_msg_key :msg?:@"",
            j_phone_key: phoneNumber?:@"",
            @"smsAuthIndex": @(smsAuthIndex)
        };
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            //通过 channel 返回
            [strongself.channel invokeMethod:@"onReceiveSMSAuthCallBackEvent" arguments:dict];
        });
        
    } actionBlock:^(NSInteger type, NSString * _Nonnull content) {
        
    }];
}

#pragma mark - 设置日志 debug 模式
-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setDebugMode::");
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

#pragma mark - 设置合规/采集授权 
-(void)setCollectionAuth:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setCollectionAuth::");
    
    NSDictionary *arguments = call.arguments;
    __block  NSNumber *auth = arguments[@"auth"];
    
    [JGInforCollectionAuth  JCollectionAuth:^(JGInforCollectionAuthItems * _Nonnull authInfo) {
        authInfo.isAuth = [auth boolValue];
    }];
}

#pragma mark - 初始化 SDK
- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setup::");
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *useIDFA = arguments[@"useIDFA"];
    NSNumber *timeout = arguments[@"timeout"];
    
    JVAuthConfig *config = [[JVAuthConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    if ([timeout isKindOfClass:[NSNull class]]) {
        timeout = @(10000);
    }
    config.timeout = [timeout longLongValue];
    
    NSString *idfaStr = NULL;
    if(![useIDFA isKindOfClass:[NSNull class]]){
        if([useIDFA boolValue]){
            idfaStr = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            config.advertisingId = idfaStr;
        }
    }
    
    __weak typeof(self) weakself = self;
    config.authBlock = ^(NSDictionary *result) {
        JVLog(@"初始化结果 result:%@", result);
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = result[@"content"];
            NSString *code = result[@"code"];
            NSDictionary *dic = @{
                j_code_key:(code?@([code intValue]):@(0)),
                j_msg_key:(message?message:@"")
            };
            //通过 channel 返回
            [strongself.channel invokeMethod:@"onReceiveSDKSetupCallBackEvent" arguments:dic];
        });
    };
    [JVERIFICATIONService setupWithConfig:config];
}

#pragma mark - 获取初始化状态
-(BOOL)isSetupClient:(FlutterResult)result {
    JVLog(@"Action - isSetupClient:");
    BOOL isSetup = [JVERIFICATIONService isSetupClient];
    if (!isSetup) {
        JVLog(@"初始化未完成!");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        result(@{j_result_key:[NSNumber numberWithBool:isSetup]});
    });
    
    // 初始换成功
    //···
    return isSetup;
}

#pragma mark - 判断网络环境是否支持
-(BOOL)checkVerifyEnable:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - checkVerifyEnable::");
    BOOL isEnable = [JVERIFICATIONService checkVerifyEnable];
    if(!isEnable) {
        JVLog(@"当前网络环境不支持认证！");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        result(@{j_result_key:[NSNumber numberWithBool:isEnable]});
    });
    
    //继续获取token操作
    //...
    return isEnable;
}

#pragma mark - 获取号码认证token
-(void)getToken:(FlutterMethodCall*)call result:(FlutterResult)result{
    JVLog(@"Action - getToken::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明
     timeout 超时时间。单位ms，合法范围3000~10000。
     completion 参数是字典 返回token 、错误码等相关信息，token有效期1分钟, 一次认证后失效
     res 字典
     获取到token时，key 有 code、token、operator 字段，
     获取不到token时，key 为 code 、content 字段
     
     */
    [JVERIFICATIONService getToken:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk getToken completion : %@",res);
        
        NSString *content = @"";
        if(res[@"token"]){
            content =res[@"token"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        NSDictionary *dict = @{
            j_code_key: res[@"code"],
            j_msg_key : content,
            j_opr_key : res[@"operator"] ? res[@"operator"] : @""
        };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}

#pragma mark - SDK 发起号码认证
-(void)verifyNumber:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - verifyNumber::%@",call.arguments);
    
    /* 2.4.3版本开始，此接口已移除
     NSDictionary *arguments=  [call arguments];
     NSString *phone = arguments[@"phone"];
     NSString *token = arguments[@"token"];
     
     [JVERIFICATIONService ]
     JVAuthEntity *entity = [[JVAuthEntity alloc] init];
     entity.number = phone;
     if (![token isKindOfClass:[NSNull class]]) {
     if (token && token.length) {
     entity.token = token;
     }
     }
     
     [JVERIFICATIONService verifyNumber:entity result:^(NSDictionary *res) {
     JVLog(@"sdk verifyNumber completion : %@",res);
     
     NSDictionary *dict = @{
     j_code_key:res[@"code"],
     j_msg_key :res[@"content"] ? res[@"content"] : @""
     };
     dispatch_async(dispatch_get_main_queue(), ^{
     result(dict);
     });
     }];
     */
}
#pragma mark - SDK 登录预取号
- (void)preLogin:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - preLogin::%@",call.arguments);
    
    NSDictionary *arguments=  [call arguments];
    NSNumber *timeoutNum = arguments[@"timeout"];
    NSTimeInterval timeout = [timeoutNum longLongValue];
    if (timeout <= 0) {
        timeout = j_default_timeout;
    }
    
    /*
     参数说明:
     completion 预取号结果
     result 字典 key为code和message两个字段
     timeout 超时时间。单位ms，合法范围3000~10000。
     */
    [JVERIFICATIONService preLogin:timeout completion:^(NSDictionary *res) {
        JVLog(@"sdk preLogin completion :%@",res);
        
        NSDictionary *dict = @{
            j_code_key:res[@"code"],
            j_msg_key :res[@"content"] ? res[@"content"] : @""
        };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}

#pragma mark - SDK清除预取号缓存
- (void)clearPreLoginCache:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - clearPreLoginCache::");
    [JVERIFICATIONService clearPreLoginCache];
}
#pragma mark - SDK 请求授权一键登录
-(void)loginAuth:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - loginAuth::%@",call.arguments);
    [self loginAuthSync:NO call:call result:result];
}
-(void)loginAuthSyncApi:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - loginAuthSyncApi::%@",call.arguments);
    [self loginAuthSync:YES call:call result:result];
}
-(void)loginAuthSync:(BOOL)isSync call:(FlutterMethodCall*)call result:(FlutterResult)result {
    JVLog(@"Action - loginAuthSync::%@",call.arguments);
    
    NSDictionary *arguments = [call arguments];
    NSNumber *hide = arguments[@"autoDismiss"];
    NSTimeInterval timeout = [arguments[@"timeout"] longLongValue];
    NSInteger loginAuthIndex = [arguments[@"loginAuthIndex"] longLongValue];
    NSNumber *enableSms = arguments[@"enableSms"];

    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    __weak typeof(self) weakself = self;
    [JVERIFICATIONService getAuthorizationWithController:vc enableSms:[enableSms boolValue] hide:[hide boolValue] animated:needStartAnim timeout:timeout completion:^(NSDictionary *res) {
        JVLog(@"getAuthorizationWithController result = %@",res);
        
        NSString *content = @"";
        if(res[@"loginToken"]){
            content =res[@"loginToken"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        NSDictionary *dict = @{
            j_code_key:res[@"code"],
            j_msg_key :content,
            j_opr_key :res[@"operator"]?:@"",
            @"loginAuthIndex": @(loginAuthIndex)
        };
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isSync) {
                //通过 channel 返回
                [strongself.channel invokeMethod:@"onReceiveLoginAuthCallBackEvent" arguments:dict];
            }else{
                // 通过回调返回
                result(dict);
            }
        });
    } actionBlock:^(NSInteger type, NSString *content) {
        JVLog("Authorization actionBlock: type = %ld", (long)type);
        /// 事件
        NSDictionary *jsonMap = @{
            j_code_key:@(type),
            j_msg_key:content?content:@"",
            @"loginAuthIndex": @(loginAuthIndex)
        };
        __strong typeof(weakself) strongself = weakself;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongself.channel invokeMethod:@"onReceiveAuthPageEvent" arguments:jsonMap];
        });
    }];
}
#pragma mark - SDK关闭授权页面
-(void)dismissLoginController:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - dismissLoginController::");
    [JVERIFICATIONService dismissLoginControllerAnimated:needCloseAnim completion:^{
        
    }];
}

#pragma mark - 自定义授权页面所有的 UI （包括：原有的、新加的）
-(void)setCustomAuthViewAllWidgets:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomAuthViewAllWidgets:%@",call.arguments);
    
    NSDictionary *uiconfig = call.arguments[@"uiconfig"];
    NSArray *widgets = call.arguments[@"widgets"];
    [self layoutUIConfig:uiconfig widgets:widgets isAutorotate:NO];
}
- (void)setCustomAuthorizationView:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomAuthorizationView:%@",call.arguments);
    
    BOOL isAutorotate = [call.arguments[@"isAutorotate"] boolValue];
    NSDictionary *portraitConfig = call.arguments[@"portraitConfig"];
    NSArray *widgets = call.arguments[@"widgets"];
    [self layoutUIConfig:portraitConfig widgets:widgets isAutorotate:isAutorotate];
}

- (void)layoutUIConfig:(NSDictionary *)uiconfigPara widgets:(NSArray *)widgets isAutorotate:(BOOL)isAutorotate {
    
    JVUIConfig *config = [[JVUIConfig alloc] init];
    config.autoLayout = YES;
    config.shouldAutorotate = isAutorotate;
    [self setCustomUIWithUIConfig:config configArguments:uiconfigPara];
    
    [JVERIFICATIONService customUIWithConfig:config customViews:^(UIView *customAreaView) {
        for (NSDictionary *widgetDic in widgets) {
            NSString *type = [self getValue:widgetDic key:@"type"];
            if ([type isEqualToString:@"textView"]) {
                [customAreaView addSubview:[self addCustomTextWidget:widgetDic]];
            }else if ([type isEqualToString:@"button"]){
                [customAreaView addSubview:[self addCustomButtonWidget:widgetDic]];
            }else{
                
            }
        }
    }];
}
#pragma mark - 自定义授权页面原有的 UI 控件

JVLayoutConstraint *JVLayoutTop(CGFloat top,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:top];
}
JVLayoutConstraint *JVLayoutBottom(CGFloat bottom,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:bottom];
}
JVLayoutConstraint *JVLayoutLeft(CGFloat left,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:left];
}
JVLayoutConstraint *JVLayoutRight(CGFloat right,JVLayoutItem toItem,NSLayoutAttribute attr2) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:toItem attribute:attr2 multiplier:1 constant:right];
}
JVLayoutConstraint *JVLayoutCenterX(CGFloat centerX) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterX multiplier:1 constant:centerX];
}
JVLayoutConstraint *JVLayoutCenterY(CGFloat centerY,JVLayoutItem toItem) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:toItem attribute:NSLayoutAttributeCenterY multiplier:1 constant:centerY];
}
JVLayoutConstraint *JVLayoutWidth(CGFloat widht) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:widht];
}
JVLayoutConstraint *JVLayoutHeight(CGFloat height) {
    return [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:height];
}

- (void)cancelAgreementAlertView {
    if (self.hidAgreementAlertView) {
        self.hidAgreementAlertView();
    }
}

//自定义授权页面原有的 UI 控件
- (void)setCustomUIWithUIConfig:(JVUIConfig *)uiconfig configArguments:(NSDictionary *)config {
    JVLog(@"Action - setCustomUIWithUIConfig::");
    NSString *authStatusBarStyle = [config objectForKey:@"authStatusBarStyle"];
    NSString *privacyStatusBarStyle = [config objectForKey:@"privacyStatusBarStyle"];
    uiconfig.preferredStatusBarStyle = [self getStatusBarStyle:authStatusBarStyle];
    uiconfig.agreementPreferredStatusBarStyle = [self getStatusBarStyle:privacyStatusBarStyle];
    uiconfig.dismissAnimationFlag = needCloseAnim;
    if ([[config allKeys] containsObject:@"authBGVideoPath"] && [[config allKeys] containsObject:@"authBGVideoImgPath"]) {
        [uiconfig setVideoBackgroudResource:[config objectForKey:@"authBGVideoPath"] placeHolder:[config objectForKey:@"authBGVideoImgPath"]];
    }
    if ([[config allKeys] containsObject:@"authBGGifPath"]) {
        NSString *gitPath = [[NSBundle mainBundle] pathForResource:[config objectForKey:@"authBGGifPath"] ofType:@"gif"];
        if (gitPath) {
            uiconfig.authPageGifImagePath = gitPath;
        }
    }
    /************** 弹出方式 ***************/
    UIModalTransitionStyle transitionStyle = [self getTransitionStyle:[self getValue:config key:@"modelTransitionStyle"]];
    uiconfig.modalTransitionStyle = transitionStyle;
    
    /************** 背景 ***************/
    NSString *authBackgroundImage = [config objectForKey:@"authBackgroundImage"];
    authBackgroundImage = authBackgroundImage?:nil;
    if (authBackgroundImage) {
        uiconfig.authPageBackgroundImage = [UIImage imageNamed:authBackgroundImage];
    }
    
    needStartAnim = [[self getValue:config key:@"needStartAnim"] boolValue];
    needCloseAnim = [[self getValue:config key:@"needCloseAnim"] boolValue];
    
    JVLog(@"Action - setCustomAuthorizationView:needStartAnim %d",needStartAnim);
    JVLog(@"Action - setCustomAuthorizationView:needStartAnim %d",needCloseAnim);
    
    /************** 导航栏 ***************/
    NSNumber *navHidden = [self getValue:config key:@"navHidden"];
    if (navHidden) {
        uiconfig.navCustom = [navHidden boolValue];
    }
    NSNumber *navReturnBtnHidden = [self getValue:config key:@"navReturnBtnHidden"];
    if (navReturnBtnHidden) {
        uiconfig.navReturnHidden = [navReturnBtnHidden boolValue];
    }
    
    NSNumber *navColor = [self getValue:config key:@"navColor"];
    if (navColor) {
        uiconfig.navColor  = UIColorFromRGB([navColor intValue]);
    }
    
    NSString *navText = [self getValue:config key:@"navText"];
    if (!navText) {
        navText = @"登录";
    }
    UIColor *navTextColor = UIColorFromRGB(-1);
    if ([self getValue:config key:@"navTextColor"]) {
        navTextColor = UIColorFromRGB([[self getValue:config key:@"navTextColor"] intValue]);
    }
    NSDictionary *navTextAttr = @{NSForegroundColorAttributeName:navTextColor};
    NSAttributedString *attr = [[NSAttributedString alloc]initWithString:navText attributes:navTextAttr];
    uiconfig.navText = attr;
    
    NSString *imageName =[self getValue:config key:@"navReturnImgPath"];
    if(imageName){
        uiconfig.navReturnImg  = [UIImage imageNamed:imageName];
    }
    NSNumber *navTransparent = [self getValue:config key:@"navTransparent"];
    if (navTransparent) {
        uiconfig.navTransparent = [navTransparent boolValue];
    }

    /************** logo ***************/
    JVLayoutItem logoLayoutItem = [self getLayotItem:[self getValue:config key:@"logoVerticalLayoutItem"]];
    NSNumber *logoWidth = [self getNumberValue:config key:@"logoWidth"];
    NSNumber *logoHeight = [self getNumberValue:config key:@"logoHeight"];
    NSNumber *logoOffsetX = [self getNumberValue:config key:@"logoOffsetX"];
    NSNumber *logoOffsetY = [self getNumberValue:config key:@"logoOffsetY"];
    if (logoLayoutItem == JVLayoutItemNone) {
        uiconfig.logoWidth = [logoWidth floatValue];
        uiconfig.logoHeight = [logoHeight floatValue];
        uiconfig.logoOffsetY = [logoOffsetY floatValue];
    }else{
        
        JVLayoutConstraint *logo_cons_x = JVLayoutCenterX([logoOffsetX floatValue]);
        JVLayoutConstraint *logo_cons_y = JVLayoutTop([logoOffsetY floatValue],logoLayoutItem,NSLayoutAttributeTop);
        JVLayoutConstraint *logo_cons_w = JVLayoutWidth([logoWidth floatValue]);
        JVLayoutConstraint *logo_cons_h = JVLayoutHeight([logoHeight floatValue]);
        
        uiconfig.logoConstraints = @[logo_cons_x,logo_cons_y,logo_cons_w,logo_cons_h];
        uiconfig.logoHorizontalConstraints = uiconfig.logoConstraints;
    }
    
    NSString *logoImgPath =[self getValue:config key:@"logoImgPath"];
    if(logoImgPath){
        uiconfig.logoImg  = [UIImage imageNamed:logoImgPath];
    }
    
    NSNumber *logoHidden = [self getValue:config key:@"logoHidden"];
    if(logoHidden){
        uiconfig.logoHidden  = [logoHidden boolValue];
    }
    
    /************** num ***************/
    JVLayoutItem numberLayoutItem = [self getLayotItem:[self getValue:config key:@"numberVerticalLayoutItem"]];
    NSNumber *numFieldOffsetX = [self getNumberValue:config key:@"numFieldOffsetX"];
    NSNumber *numFieldOffsetY = [self getNumberValue:config key:@"numFieldOffsetY"];
    NSNumber *numberFieldWidth = [self getNumberValue:config key:@"numberFieldWidth"];
    NSNumber *numberFieldHeight = [self getNumberValue:config key:@"numberFieldHeight"];
    if (numberLayoutItem == JVLayoutItemNone) {
        uiconfig.numFieldOffsetY = [numFieldOffsetY floatValue];
    }else{
        JVLayoutConstraint *num_cons_x = JVLayoutCenterX([numFieldOffsetX floatValue]);
        JVLayoutConstraint *num_cons_y = JVLayoutTop([numFieldOffsetY floatValue],numberLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *num_cons_w = JVLayoutWidth([numberFieldWidth floatValue]);
        JVLayoutConstraint *num_cons_h = JVLayoutHeight([numberFieldHeight floatValue]);
        
        uiconfig.numberConstraints = @[num_cons_x,num_cons_y,num_cons_w,num_cons_h];
        uiconfig.numberHorizontalConstraints = uiconfig.numberConstraints;
    }
    
    NSNumber *numberColor = [self getValue:config key:@"numberColor"];
    if(numberColor){
        uiconfig.numberColor  = UIColorFromRGB([numberColor intValue]);
    }
    
    NSNumber *numberSize = [self getValue:config key:@"numberSize"];
    if (numberSize) {
        uiconfig.numberFont = [UIFont systemFontOfSize:[numberSize floatValue]];
    }
    
    /************** slogan ***************/
    JVLayoutItem sloganLayoutItem = [self getLayotItem:[self getValue:config key:@"sloganVerticalLayoutItem"]];
    NSNumber *sloganOffsetX = [self getNumberValue:config key:@"sloganOffsetX"];
    NSNumber *sloganOffsetY = [self getNumberValue:config key:@"sloganOffsetY"];
    NSNumber *sloganWidth = [self getNumberValue:config key:@"sloganWidth"];
    NSNumber *sloganHeight = [self getNumberValue:config key:@"sloganHeight"];
    
    if (sloganLayoutItem == JVLayoutItemNone) {
        uiconfig.sloganOffsetY = [sloganOffsetY floatValue];
    }else{
        JVLayoutConstraint *slogan_cons_top = JVLayoutTop([sloganOffsetY floatValue], sloganLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *slogan_cons_centerx = JVLayoutCenterX([sloganOffsetX floatValue]);
        CGFloat sloganH = [sloganHeight floatValue]>0?:20;
        CGFloat sloganW = [sloganWidth floatValue]>0?:200;
        JVLayoutConstraint *slogan_cons_width = JVLayoutWidth(sloganW);
        JVLayoutConstraint *slogan_cons_height = JVLayoutHeight(sloganH);
        uiconfig.sloganConstraints = @[slogan_cons_top,slogan_cons_centerx,slogan_cons_width,slogan_cons_height];
        uiconfig.sloganHorizontalConstraints = uiconfig.sloganConstraints;
    }
    
    NSNumber *sloganTextColor = [self getValue:config key:@"sloganTextColor"];
    if(sloganTextColor){
        uiconfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
    }
    
    NSNumber *sloganTextSize = [self getValue:config key:@"sloganTextSize"];
    if (sloganTextSize) {
        uiconfig.sloganFont = [UIFont systemFontOfSize:[sloganTextSize floatValue]];
    }
    
    /************** login btn ***************/
    JVLayoutItem logBtnLayoutItem = [self getLayotItem:[self getValue:config key:@"logBtnVerticalLayoutItem"]];
    NSNumber *logBtnOffsetX = [self getNumberValue:config key:@"logBtnOffsetX"];
    NSNumber *logBtnOffsetY = [self getNumberValue:config key:@"logBtnOffsetY"];
    NSNumber *logBtnWidth   = [self getNumberValue:config key:@"logBtnWidth"];
    NSNumber *logBtnHeight  = [self getNumberValue:config key:@"logBtnHeight"];
    if (logBtnLayoutItem == JVLayoutItemNone) {
        uiconfig.logBtnOffsetY = [logBtnOffsetY floatValue];
    }else{
        JVLayoutConstraint *logoBtn_cons_x = JVLayoutCenterX([logBtnOffsetX floatValue]);
        JVLayoutConstraint *logoBtn_cons_y = JVLayoutTop([logBtnOffsetY floatValue], logBtnLayoutItem,NSLayoutAttributeBottom);
        JVLayoutConstraint *logoBtn_cons_w = JVLayoutWidth([logBtnWidth floatValue]);
        JVLayoutConstraint *logoBtn_cons_h = JVLayoutHeight([logBtnHeight floatValue]);
        
        uiconfig.logBtnConstraints  = @[logoBtn_cons_x,logoBtn_cons_y,logoBtn_cons_w,logoBtn_cons_h];
        uiconfig.logBtnHorizontalConstraints  = uiconfig.logBtnConstraints;
    }
    
    NSString *logBtnText = [self getValue:config key:@"logBtnText"];
    if(logBtnText){
        uiconfig.logBtnText  = logBtnText;
    }
    NSNumber *logBtnTextSize = [self getValue:config key:@"logBtnTextSize"];
    if (logBtnTextSize) {
        uiconfig.logBtnFont = [UIFont systemFontOfSize:[logBtnTextSize floatValue]];
    }
    NSNumber *logBtnTextColor = [self getValue:config key:@"logBtnTextColor"];
    if(logBtnTextColor){
        uiconfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
    }
    
    NSString *loginBtnNormalImage = [config objectForKey:@"loginBtnNormalImage"];
    loginBtnNormalImage = loginBtnNormalImage?:nil;
    NSString *loginBtnPressedImage = [config objectForKey:@"loginBtnPressedImage"];
    loginBtnPressedImage = loginBtnPressedImage?:nil;
    NSString *loginBtnUnableImage = [config objectForKey:@"loginBtnUnableImage"];
    loginBtnUnableImage = loginBtnUnableImage?:nil;
    NSArray * images =[[NSArray alloc]initWithObjects:[UIImage imageNamed:loginBtnNormalImage],[UIImage imageNamed:loginBtnPressedImage],[UIImage imageNamed:loginBtnUnableImage],nil];
    uiconfig.logBtnImgs = images;
    
    /************** chck box ***************/
    NSNumber *privacyOffsetY = [self getNumberValue:config key:@"privacyOffsetY"];
    NSNumber *privacyOffsetX = [self getValue:config key:@"privacyOffsetX"];
    
    CGFloat privacyCheckboxSize = [[self getNumberValue:config key:@"privacyCheckboxSize"] floatValue];
    if (privacyCheckboxSize == 0) {
        privacyCheckboxSize = 20.0;
    }
    BOOL privacyCheckboxInCenter = [[self getValue:config key:@"privacyCheckboxInCenter"] boolValue];
    
    BOOL privacyCheckboxHidden = [[self getValue:config key:@"privacyCheckboxHidden"] boolValue];
    uiconfig.checkViewHidden = privacyCheckboxHidden;
    CGFloat privacyLeftSpace = 0;
    
    if (privacyOffsetX == nil) {
        uiconfig.privacyTextAlignment = NSTextAlignmentCenter;
        privacyOffsetX =  @(15);
        
    }
    privacyLeftSpace = privacyCheckboxHidden ? [privacyOffsetX floatValue] : ([privacyOffsetX floatValue]+privacyCheckboxSize+5+5);//算上CheckBox的左右间隙;
    CGFloat privacyRightSpace = [privacyOffsetX floatValue] ;
    
    
    //checkbox
    JVLayoutConstraint *box_cons_x = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeLeft multiplier:1 constant:-5];
    JVLayoutConstraint *box_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeTop multiplier:1 constant:3];
    if (privacyCheckboxInCenter) {
        box_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemPrivacy attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    }
    JVLayoutConstraint *box_cons_w = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:privacyCheckboxSize];
    JVLayoutConstraint *box_cons_h = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:privacyCheckboxSize];
    
    uiconfig.checkViewConstraints = @[box_cons_x,box_cons_y,box_cons_w,box_cons_h];
    uiconfig.checkViewHorizontalConstraints = uiconfig.checkViewConstraints;
    
    NSNumber *privacyState = [self getValue:config key:@"privacyState"];
    uiconfig.privacyState = [privacyState boolValue];
    
    NSString *uncheckedImgPath = [config objectForKey:@"uncheckedImgPath"];
    if (uncheckedImgPath) {
        uiconfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
    }
    NSString *checkedImgPath = [config objectForKey:@"checkedImgPath"];
    if (checkedImgPath) {
        uiconfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
    }
    
    /************** privacy ***************/
    //隐私弹窗
    BOOL isAlertPrivacyVc = [[self getValue:config key:@"isAlertPrivacyVc"] boolValue];
    uiconfig.isAlertPrivacyVC = isAlertPrivacyVc;
    uiconfig.agreementAlertViewShowWindow = YES;
    
    //自定义协议
    NSString *tempSting = @"";
    BOOL privacyWithBookTitleMark = [[self getValue:config key:@"privacyWithBookTitleMark"] boolValue];
    
    NSMutableArray *appPrivacyss = [NSMutableArray array];
    if([[config allKeys] containsObject:@"privacyText"] && [[config objectForKey:@"privacyText"] isKindOfClass:[NSArray class]])
    {
        if ([[config objectForKey:@"privacyText"] count]>=1) {
            [appPrivacyss addObject:[[config objectForKey:@"privacyText"] objectAtIndex:0]];
            tempSting = [tempSting stringByAppendingString:[[config objectForKey:@"privacyText"] objectAtIndex:0]];
        }
        
    }
    if([[config allKeys] containsObject:@"privacyItem"] && [[config objectForKey:@"privacyItem"] isKindOfClass:[NSString class]]){
        NSString *privacyJson = [config objectForKey:@"privacyItem"];
        NSData *privacyData = [privacyJson  dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *privacys= [NSJSONSerialization JSONObjectWithData:privacyData options:0 error:nil];
        for (NSInteger i = 0; i<privacys.count; i++) {
            NSMutableArray *item = [NSMutableArray array];
            
            NSDictionary *obj = [privacys objectAtIndex:i];
            
            //加入协议之间的分隔符
            if ([[obj allKeys] containsObject:@"separator"] ) {
                [item addObject:[obj objectForKey:@"separator"]];
                tempSting = [tempSting stringByAppendingString:[obj objectForKey:@"separator"]];
            }
            //加入name
            if ([[obj allKeys] containsObject:@"name"] ) {
                [item addObject:[NSString stringWithFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),[obj objectForKey:@"name"],(privacyWithBookTitleMark?@"》":@"")]];
                tempSting = [tempSting stringByAppendingFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),[obj objectForKey:@"name"],(privacyWithBookTitleMark?@"》":@"")];
                
            }
            //加入url
            if ([[obj allKeys] containsObject:@"url"] ) {
                [item addObject:[obj objectForKey:@"url"]];
            }
            //加入协议详细页面的导航栏文字 可以是NSAttributedString类型 自定义  这里是直接拿name进行展示
            if ([[obj allKeys] containsObject:@"name"] ) {
                UIColor *privacyNavTitleTextColor = UIColorFromRGB(-1);
                if ([self getValue:config key:@"privacyNavTitleTextColor"]) {
                    privacyNavTitleTextColor = UIColorFromRGB([[self getValue:config key:@"privacyNavTitleTextColor"] intValue]);
                }
                NSNumber *privacyNavTitleTextSize = [self getValue:config key:@"privacyNavTitleTextSize"];
                if (!privacyNavTitleTextSize) {
                    privacyNavTitleTextSize = @(16);
                }
                NSDictionary *privayNavTextAttr = @{NSForegroundColorAttributeName:privacyNavTitleTextColor,
                                                    NSFontAttributeName:[UIFont systemFontOfSize:[privacyNavTitleTextSize floatValue]]};
                NSAttributedString *privayAttr = [[NSAttributedString alloc]initWithString:[obj objectForKey:@"name"] attributes:privayNavTextAttr];
                if(privayAttr){
                    [item addObject:privayAttr];
                }
            }
            //添加一条协议appPrivacyss中
            [appPrivacyss addObject:item];
            
        }
    }
    //设置尾部
    if([[config allKeys] containsObject:@"privacyText"] && [[config objectForKey:@"privacyText"] isKindOfClass:[NSArray class]])
    {
        if ([[config objectForKey:@"privacyText"] count]>=2) {
            [appPrivacyss addObject:[[config objectForKey:@"privacyText"] objectAtIndex:1]];
            tempSting = [tempSting stringByAppendingString:[[config objectForKey:@"privacyText"] objectAtIndex:1]];
        }
        
    }
    
    //设置
    if (appPrivacyss.count>1) {
        uiconfig.appPrivacys = appPrivacyss;
    }
    
    BOOL privacyHintToast = [[self getValue:config key:@"privacyHintToast"] boolValue];
    if(privacyHintToast){
        uiconfig.customPrivacyAlertViewBlock = ^(UIViewController *vc , NSArray *appPrivacys,void(^loginAction)(void)) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请点击同意协议" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil] ];
            [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:nil] ];
            [vc presentViewController:alert animated:true completion:nil];
            
        };
    }
    
    // 二次弹窗自定义视图
    __weak __typeof(self)weakSelf = self;
    NSArray *agreementAlertViewWidgets = [self getValue:config key:@"agreementAlertViewWidgets"];
    uiconfig.customAgreementAlertView = ^(UIView * _Nonnull superView, void (^ _Nonnull hidAlertView)(void)) {
        weakSelf.hidAgreementAlertView = hidAlertView;
        for (NSDictionary *widgetDic in agreementAlertViewWidgets) {
            NSString *type = [self getValue:widgetDic key:@"type"];
            if ([type isEqualToString:@"textView"]) {
                [superView addSubview:[self addCustomTextWidget:widgetDic]];
            }else if ([type isEqualToString:@"button"]){
                UIButton *cancle = [self addCustomButtonWidget:widgetDic];
                [superView addSubview:cancle];
                [cancle addTarget:weakSelf action:@selector(cancelAgreementAlertView) forControlEvents:UIControlEventTouchUpInside];
            }else{
                
            }
        }
    };
    
    NSDictionary *agreementAlertViewUIFrames = [self getValue:config key:@"agreementAlertViewUIFrames"];
    
    uiconfig.resetAgreementAlertViewFrameBlock = ^(NSValue * _Nullable __autoreleasing * _Nullable superViewFrame, NSValue * _Nullable __autoreleasing * _Nullable alertViewFrame, NSValue * _Nullable __autoreleasing * _Nullable titleFrame, NSValue * _Nullable __autoreleasing * _Nullable contentFrame, NSValue * _Nullable __autoreleasing * _Nullable buttonFrame) {
        NSArray *superView = [agreementAlertViewUIFrames valueForKey:@"superViewFrame"];
        if (superView && superView.count >= 4) {
            *superViewFrame = [NSValue valueWithCGRect:CGRectMake([superView[0] intValue], [superView[1] intValue], [superView[2] intValue], [superView[3] intValue])];
        }
        NSArray *alertView = [agreementAlertViewUIFrames valueForKey:@"alertViewFrame"];
        if (alertView && alertView.count >= 4) {
            *alertViewFrame = [NSValue valueWithCGRect:CGRectMake([alertView[0] intValue], [alertView[1] intValue], [alertView[2] intValue], [alertView[3] intValue])];
        }
        NSArray *title = [agreementAlertViewUIFrames valueForKey:@"titleFrame"];
        if (title && title.count >= 4) {
            *titleFrame = [NSValue valueWithCGRect:CGRectMake([title[0] intValue], [title[1] intValue], [title[2] intValue], [title[3] intValue])];
        }
        NSArray *content = [agreementAlertViewUIFrames valueForKey:@"contentFrame"];
        if (content && content.count >= 4) {
            *contentFrame = [NSValue valueWithCGRect:CGRectMake([content[0] intValue], [content[1] intValue], [content[2] intValue], [content[3] intValue])];
        }
        NSArray *button = [agreementAlertViewUIFrames valueForKey:@"buttonFrame"];
        if (button && button.count >= 4) {
            *buttonFrame = [NSValue valueWithCGRect:CGRectMake([button[0] intValue], [button[1] intValue], [button[2] intValue], [button[3] intValue])];
        }
    };
    
    
    BOOL isCenter = [[self getValue:config key:@"privacyTextCenterGravity"] boolValue];
    NSTextAlignment alignmet = isCenter?NSTextAlignmentCenter:NSTextAlignmentLeft;
    uiconfig.privacyTextAlignment = alignmet;
    
    uiconfig.privacyShowBookSymbol = privacyWithBookTitleMark;
    
    NSString *clauseName = [self getValue:config key:@"clauseName"];
    NSString *clauseUrl = [self getValue:config key:@"clauseUrl"];
    if (![[config allKeys] containsObject:@"privacyItem"]  && clauseName && clauseUrl) {
        uiconfig.appPrivacyOne  = @[clauseName,clauseUrl];
        tempSting = [tempSting stringByAppendingFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),clauseName,(privacyWithBookTitleMark?@"》":@"")];
    }
    
    NSString *clauseNameTwo = [self getValue:config key:@"clauseNameTwo"];
    NSString *clauseUrlTwo = [self getValue:config key:@"clauseUrlTwo"];
    if (![[config allKeys] containsObject:@"privacyItem"]  && clauseNameTwo && clauseUrlTwo) {
        uiconfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        tempSting = [tempSting stringByAppendingFormat:@"%@%@%@",(privacyWithBookTitleMark?@"《":@""),clauseNameTwo,(privacyWithBookTitleMark?@"》":@"")];
    }
    
    NSArray *privacyComponents = [self getValue:config key:@"privacyText"];
    if (![[config allKeys] containsObject:@"privacyItem"]  && privacyComponents.count) {
        uiconfig.privacyComponents = privacyComponents;
        tempSting = [tempSting stringByAppendingString:[privacyComponents componentsJoinedByString:@"、"]];
    }
    
    NSNumber *privacyTextSize = [self getValue:config key:@"privacyTextSize"];
    if (privacyTextSize) {
        uiconfig.privacyTextFontSize = [privacyTextSize floatValue];
    }
    
    JVLayoutItem privacyLayoutItem = [self getLayotItem:[self getValue:config key:@"privacyVerticalLayoutItem"]];
    
    int widthScreen =  [UIScreen mainScreen].bounds.size.width;
    NSDictionary *popViewConfig = [self getValue:config key:@"popViewConfig"];
    if (popViewConfig) {
        widthScreen = [[self getValue:popViewConfig key:@"width"] intValue];
    }
    tempSting = [tempSting stringByAppendingString:@"《中国移动统一认证服务条款》"];
    CGFloat lableWidht  = widthScreen - (privacyLeftSpace + privacyRightSpace);
    CGSize lablesize = [tempSting boundingRectWithSize:CGSizeMake(lableWidht, CGFLOAT_MAX)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[privacyTextSize floatValue]]}
                                               context:nil].size;
    
    JVLayoutConstraint *privacy_cons_x = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeLeft multiplier:1 constant:privacyLeftSpace];
    JVLayoutConstraint *privacy_cons_y = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeBottom multiplier:1 constant:-[privacyOffsetY floatValue]];
    JVLayoutConstraint *privacy_cons_w = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:lableWidht];
    JVLayoutConstraint *privacy_cons_h = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:lablesize.height];
    if (privacyLayoutItem == JVLayoutItemNone) {
        uiconfig.privacyOffsetY = [privacyOffsetY floatValue];
    }else{
        uiconfig.privacyConstraints = @[privacy_cons_x,privacy_cons_y,privacy_cons_w,privacy_cons_h];
        uiconfig.privacyHorizontalConstraints = uiconfig.privacyConstraints;
    }
    //隐私条款垂直对齐方式
    if ([[config allKeys] containsObject:@"textVerAlignment"]) {
        uiconfig.textVerAlignment = [[config objectForKey:@"textVerAlignment"] intValue];
    }else{
        uiconfig.textVerAlignment = JVVerAlignmentMiddle;
    }
    
    NSNumber *clauseBaseColor = [self getValue:config key:@"clauseBaseColor"];
    UIColor *privacyBasicColor =[UIColor grayColor];
    if(clauseBaseColor){
        privacyBasicColor =  UIColorFromRGB([clauseBaseColor integerValue]);
    }
    NSNumber *clauseColor = [self getValue:config key:@"clauseColor"];
    UIColor *privacyColor = UIColorFromRGB(-16007674);
    if(clauseColor){
        privacyColor =UIColorFromRGB([clauseColor integerValue]);
    }
    uiconfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    
    /************** 协议 web 页面 ***************/
    NSNumber *privacyNavColor = [self getValue:config key:@"privacyNavColor"];
    if (privacyNavColor) {
        uiconfig.agreementNavBackgroundColor  = UIColorFromRGB([privacyNavColor intValue]);
    }
    
    NSString *privacyNavText = [self getValue:config key:@"privacyNavTitleTitle"];
    if (!privacyNavText) {
        privacyNavText =  @"运营商服务条款";
    }
    
    UIColor *privacyNavTitleTextColor = UIColorFromRGB(-1);
    if ([self getValue:config key:@"privacyNavTitleTextColor"]) {
        privacyNavTitleTextColor = UIColorFromRGB([[self getValue:config key:@"privacyNavTitleTextColor"] intValue]);
    }
    NSNumber *privacyNavTitleTextSize = [self getValue:config key:@"privacyNavTitleTextSize"];
    if (!privacyNavTitleTextSize) {
        privacyNavTitleTextSize = @(16);
    }
    NSDictionary *privayNavTextAttr = @{NSForegroundColorAttributeName:privacyNavTitleTextColor,
                                        NSFontAttributeName:[UIFont systemFontOfSize:[privacyNavTitleTextSize floatValue]]};
    NSAttributedString *privayAttr = [[NSAttributedString alloc]initWithString:privacyNavText attributes:privayNavTextAttr];
    uiconfig.agreementNavText = privayAttr;
    uiconfig.agreementNavTextColor = privacyNavTitleTextColor;
    
    NSString *privacyNavReturnBtnImage =[self getValue:config key:@"privacyNavReturnBtnImage"];
    if(privacyNavReturnBtnImage){
        uiconfig.agreementNavReturnImage  = [UIImage imageNamed:privacyNavReturnBtnImage];
    }
    
    // 自定义协议 1
    NSString *privacyNavTitleTitle1 = [self getValue:config key:@"privacyNavTitleTitle1"];
    if (!privacyNavTitleTitle1) {
        privacyNavTitleTitle1 =  @"服务条款";
    }
    NSDictionary *privayNavTextAttr1 = @{NSForegroundColorAttributeName:privacyNavTitleTextColor,
                                         NSFontAttributeName:[UIFont systemFontOfSize:[privacyNavTitleTextSize floatValue]]};
    NSAttributedString *privayAttr1 = [[NSAttributedString alloc]initWithString:privacyNavTitleTitle1 attributes:privayNavTextAttr1];
    uiconfig.firstPrivacyAgreementNavText = privayAttr1;
    
    // 自定义协议 2
    NSString *privacyNavTitleTitle2 = [self getValue:config key:@"privacyNavTitleTitle2"];
    if (!privacyNavTitleTitle2) {
        privacyNavTitleTitle2 =  @"服务条款";
    }
    NSDictionary *privayNavTextAttr2 = @{NSForegroundColorAttributeName:privacyNavTitleTextColor,
                                         NSFontAttributeName:[UIFont systemFontOfSize:[privacyNavTitleTextSize floatValue]]};
    NSAttributedString *privayAttr2 = [[NSAttributedString alloc]initWithString:privacyNavTitleTitle2 attributes:privayNavTextAttr2];
    uiconfig.secondPrivacyAgreementNavText = privayAttr2;
    
    /************** loading 框 ***************/
    JVLayoutConstraint *loadingConstraintX = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    JVLayoutConstraint *loadingConstraintY = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    JVLayoutConstraint *loadingConstraintW = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:30];
    JVLayoutConstraint *loadingConstraintH = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:30];
    
    uiconfig.loadingConstraints = @[loadingConstraintX,loadingConstraintY,loadingConstraintW,loadingConstraintH];
    uiconfig.loadingHorizontalConstraints = uiconfig.loadingConstraints;
    
    /************** 协议二次弹窗样式***************/
    
    NSInteger agreementAlertViewTitleTexSize = [[self getValue:config key:@"agreementAlertViewTitleTexSize"] integerValue];
    uiconfig.agreementAlertViewTitleTexFont = [UIFont systemFontOfSize:agreementAlertViewTitleTexSize];
    
    NSNumber *agreementAlertViewTitleTextColorInt = [self getValue:config key:@"agreementAlertViewTitleTextColor"];
    if (agreementAlertViewTitleTextColorInt) {
        UIColor *agreementAlertViewTitleTextColor = UIColorFromRGB([agreementAlertViewTitleTextColorInt integerValue]);
        uiconfig.agreementAlertViewTitleTextColor = agreementAlertViewTitleTextColor;
    }
    
    NSTextAlignment agreementAlertViewContentTextAlignment = [[self getValue:config key:@"agreementAlertViewContentTextAlignment"] integerValue];
    uiconfig.agreementAlertViewContentTextAlignment = NSTextAlignmentLeft;
    
    NSInteger agreementAlertViewContentTextFontSize = [[self getValue:config key:@"agreementAlertViewContentTextFontSize"] integerValue];
    uiconfig.agreementAlertViewContentTextFontSize = agreementAlertViewContentTextFontSize;
    
    
    UIImage *agreementAlertViewLoginBtnNormalImage = [UIImage imageNamed:[config objectForKey:@"agreementAlertViewLoginBtnNormalImagePath"]] ? : [UIImage imageNamed:@"login_btn_normal"];
    UIImage *agreementAlertViewLoginBtnPressedImage = [UIImage imageNamed:[config objectForKey:@"agreementAlertViewLoginBtnPressedImagePath"]] ? : [UIImage imageNamed:@"login_btn_press"];
    UIImage *agreementAlertViewLoginBtnUnableImage = [UIImage imageNamed:[config objectForKey:@"agreementAlertViewLoginBtnUnableImagePath"]] ? : [UIImage imageNamed:@"login_btn_unable"];
    if(agreementAlertViewLoginBtnNormalImage && agreementAlertViewLoginBtnPressedImage && agreementAlertViewLoginBtnUnableImage){
        NSArray * agreementAlertViewLogBtnImgs =[[NSArray alloc]initWithObjects:agreementAlertViewLoginBtnNormalImage,agreementAlertViewLoginBtnPressedImage,agreementAlertViewLoginBtnUnableImage,nil];
            uiconfig.agreementAlertViewLogBtnImgs = agreementAlertViewLogBtnImgs;
    }
    
 
    NSNumber *agreementAlertViewLogBtnTextColorInt = [self getValue:config key:@"agreementAlertViewLogBtnTextColor"];
    if (agreementAlertViewLogBtnTextColorInt) {
        UIColor *agreementAlertViewLogBtnTextColor = UIColorFromRGB([agreementAlertViewLogBtnTextColorInt integerValue]);
        uiconfig.agreementAlertViewLogBtnTextColor = agreementAlertViewLogBtnTextColor;
    }
    
    /************** 窗口模式样式设置 ***************/
    if (popViewConfig) {
        NSNumber *isPopViewTheme = [self getValue:popViewConfig key:@""];
        NSNumber *width = [self getValue:popViewConfig key:@"width"];
        NSNumber *height = [self getValue:popViewConfig key:@"height"];
        NSNumber *offsetCenterX = [self getValue:popViewConfig key:@"offsetCenterX"];
        NSNumber *offsetCenterY = [self getValue:popViewConfig key:@"offsetCenterY"];
        
        NSNumber *popViewCornerRadius = [self getValue:popViewConfig key:@"popViewCornerRadius"];
        NSNumber *backgroundAlpha = [self getValue:popViewConfig key:@"backgroundAlpha"];
        if ([isPopViewTheme boolValue]) {
            return;
        }
        
        uiconfig.showWindow = YES;
        uiconfig.navCustom = YES;
        uiconfig.windowCornerRadius = [popViewCornerRadius floatValue];
        uiconfig.windowBackgroundAlpha = [backgroundAlpha floatValue];
        
        // 弹窗模式背景图
        if (authBackgroundImage) {
            uiconfig.windowBackgroundImage = [UIImage imageNamed:authBackgroundImage];
        }
        
        CGFloat windowW = [width floatValue];
        CGFloat windowH = [height floatValue];
        CGFloat windowX = [offsetCenterX floatValue];
        CGFloat windowY = [offsetCenterY floatValue];
        JVLayoutConstraint *windowConstraintX = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterX multiplier:1 constant:windowX];
        JVLayoutConstraint *windowConstraintY = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemSuper attribute:NSLayoutAttributeCenterY multiplier:1 constant:windowY];
        JVLayoutConstraint *windowConstraintW = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeWidth multiplier:1 constant:windowW];
        JVLayoutConstraint *windowConstraintH = [JVLayoutConstraint constraintWithAttribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:JVLayoutItemNone attribute:NSLayoutAttributeHeight multiplier:1 constant:windowH];
        uiconfig.windowConstraints = @[windowConstraintX,windowConstraintY,windowConstraintW,windowConstraintH];
        uiconfig.windowHorizontalConstraints = uiconfig.windowConstraints;
    }
    
    NSDictionary *smsUIConfig = [config valueForKey:@"smsUIConfig"];
    if (smsUIConfig && [smsUIConfig isKindOfClass:[NSDictionary class]]) {
        [self setCustomSmsUIConfig:uiconfig smsUIConfigArguments:smsUIConfig];
    }
}

- (void)setCustomSmsUIConfig:(JVUIConfig *)uiConfig smsUIConfigArguments:(NSDictionary *)smsUIConfig {
    
    NSString *smsAuthPageBackgroundImagePath = [self getValue:smsUIConfig key:@"smsAuthPageBackgroundImagePath"];
    if (smsAuthPageBackgroundImagePath) {
        uiConfig.smsAuthPageBackgroundImage = [UIImage imageNamed:smsAuthPageBackgroundImagePath];
    }
    
    NSString *smsNavText = [self getValue:smsUIConfig key:@"smsNavText"];
    NSNumber *smsNavTextSize = [self getValue:smsUIConfig key:@"smsNavTextSize"];
    NSNumber *smsNavTextColor = [self getValue:smsUIConfig key:@"smsNavTextColor"];
    NSNumber *smsNavTextBold = [self getValue:smsUIConfig key:@"smsNavTextBold"];
    NSMutableDictionary *smsNavTextAttris = [NSMutableDictionary dictionary];
    if (smsNavTextColor) {
        [smsNavTextAttris setValue:UIColorFromRGB([smsNavTextColor integerValue]) forKey:NSForegroundColorAttributeName];
    }
    if (smsNavTextSize) {
        if (smsNavTextBold) {
            [smsNavTextAttris setValue:[UIFont boldSystemFontOfSize:[smsNavTextSize floatValue]] forKey:NSFontAttributeName];
        }else {
            [smsNavTextAttris setValue:[UIFont systemFontOfSize:[smsNavTextSize floatValue]] forKey:NSFontAttributeName];
        }
       
    }
    if (smsNavText) {
        uiConfig.smsNavText = [[NSAttributedString alloc]initWithString:smsNavText attributes:nil];;
    }
    
    // logo
    NSNumber *smsLogoWidth = [self getValue:smsUIConfig key:@"smsLogoWidth"];
    NSNumber *smsLogoHeight = [self getValue:smsUIConfig key:@"smsLogoHeight"];
    NSNumber *smsLogoOffsetX = [self getValue:smsUIConfig key:@"smsLogoOffsetX"];
    NSNumber *smsLogoOffsetY = [self getValue:smsUIConfig key:@"smsLogoOffsetY"];
    NSNumber *smsLogoOffsetBottomY = [self getValue:smsUIConfig key:@"smsLogoOffsetBottomY"];
    NSNumber *isSmsLogoHidden = [self getValue:smsUIConfig key:@"isSmsLogoHidden"];
    NSString *smsLogoResName =[self getValue:smsUIConfig key:@"smsLogoResName"];
    if (isSmsLogoHidden) {
        uiConfig.smsLogoHidden = [isSmsLogoHidden boolValue];
    }
    if(smsLogoResName){
        uiConfig.smsLogoImg  = [UIImage imageNamed:smsLogoResName];
    }
    NSMutableArray *smsLogoAttris = [NSMutableArray array];
    if (smsLogoWidth){
        JVLayoutConstraint *sms_logo_cons_w = JVLayoutWidth([smsLogoWidth floatValue]);
        [smsLogoAttris addObject:sms_logo_cons_w];
    }
    if (smsLogoHeight) {
        JVLayoutConstraint *sms_logo_cons_h = JVLayoutHeight([smsLogoHeight floatValue]);
        [smsLogoAttris addObject:sms_logo_cons_h];
    }
    if (smsLogoOffsetX) {
        JVLayoutConstraint *sms_logo_cons_x = JVLayoutLeft([smsLogoOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsLogoAttris addObject:sms_logo_cons_x];
    }
    if (smsLogoOffsetY) {
        JVLayoutConstraint *sms_logo_cons_y = JVLayoutTop([smsLogoOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsLogoAttris addObject:sms_logo_cons_y];
    }
    if (smsLogoOffsetBottomY) {
        JVLayoutConstraint *sms_logo_cons_b = JVLayoutBottom([smsLogoOffsetBottomY floatValue], JVLayoutItemSuper, NSLayoutAttributeBottom);
        [smsLogoAttris addObject:sms_logo_cons_b];
    }
  
    uiConfig.smsLogoConstraints = smsLogoAttris;
    uiConfig.smsLogoHorizontalConstraints = uiConfig.smsLogoConstraints;
    
    // slogan
    NSNumber *smsSloganTextSize = [self getValue:smsUIConfig key:@"smsSloganTextSize"];
    NSNumber *smsSloganTextColor = [self getValue:smsUIConfig key:@"smsSloganTextColor"];
    NSNumber *smsSloganOffsetX = [self getValue:smsUIConfig key:@"smsSloganOffsetX"];
    NSNumber *smsSloganOffsetY = [self getValue:smsUIConfig key:@"smsSloganOffsetY"];
    NSNumber *smsSloganOffsetBottomY = [self getValue:smsUIConfig key:@"smsSloganOffsetBottomY"];
    NSNumber *smsSloganHeight = [self getValue:smsUIConfig key:@"smsSloganHeight"];
    NSNumber *smsSloganWidth = [self getValue:smsUIConfig key:@"smsSloganWidth"];
    if (smsSloganTextSize) {
        uiConfig.smsSloganFont = [UIFont systemFontOfSize:[smsSloganTextSize floatValue]];
    }
    if (smsSloganTextColor) {
        uiConfig.smsSloganTextColor = UIColorFromRGB([smsSloganTextColor integerValue]);
    }
    NSMutableArray *smsSloganAttris = [NSMutableArray array];
    if (smsSloganOffsetX) {
        JVLayoutConstraint *sms_slogan_cons_x = JVLayoutLeft([smsSloganOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsSloganAttris addObject:sms_slogan_cons_x];
    }
    if (smsSloganOffsetY) {
        JVLayoutConstraint *sms_slogan_cons_y = JVLayoutTop([smsSloganOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsSloganAttris addObject:sms_slogan_cons_y];
    }
    if (smsSloganOffsetBottomY) {
        JVLayoutConstraint *sms_slogan_cons_b = JVLayoutBottom([smsSloganOffsetBottomY floatValue], JVLayoutItemSuper, NSLayoutAttributeBottom);
        [smsSloganAttris addObject:sms_slogan_cons_b];
    }
    if (smsSloganWidth) {
        JVLayoutConstraint *sms_slogan_cons_w = JVLayoutWidth([smsSloganWidth floatValue]);
        [smsSloganAttris addObject:sms_slogan_cons_w];
    }
    if (smsSloganHeight) {
        JVLayoutConstraint *sms_slogan_cons_h = JVLayoutHeight([smsSloganHeight floatValue]);
        [smsSloganAttris addObject:sms_slogan_cons_h];
    }
    uiConfig.smsSloganConstraints = smsSloganAttris;
    uiConfig.smsSloganHorizontalConstraints = uiConfig.smsSloganConstraints;
  
    
    // SMS号码输入框设置
    NSNumber *smsPhoneInputViewOffsetX = [self getValue:smsUIConfig key:@"smsPhoneInputViewOffsetX"];
    NSNumber *smsPhoneInputViewOffsetY = [self getValue:smsUIConfig key:@"smsPhoneInputViewOffsetY"];
    NSNumber *smsPhoneInputViewWidth = [self getValue:smsUIConfig key:@"smsPhoneInputViewWidth"];
    NSNumber *smsPhoneInputViewHeight = [self getValue:smsUIConfig key:@"smsPhoneInputViewHeight"];
    NSNumber *smsPhoneInputViewTextColor = [self getValue:smsUIConfig key:@"smsPhoneInputViewTextColor"];
    NSNumber *smsPhoneInputViewTextSize = [self getValue:smsUIConfig key:@"smsPhoneInputViewTextSize"];
    NSString *smsPhoneInputViewPlaceholderText = [self getValue:smsUIConfig key:@"smsPhoneInputViewPlaceholderText"];
    NSString *smsPhoneInputViewBorderStyle = [self getValue:smsUIConfig key:@"smsPhoneInputViewBorderStyle"];
    if (smsPhoneInputViewTextColor) {
        uiConfig.smsNumberTFColor = UIColorFromRGB([smsPhoneInputViewTextColor integerValue]);
    }
    if (smsPhoneInputViewTextSize) {
        uiConfig.smsNumberTFFont = [UIFont systemFontOfSize:[smsPhoneInputViewTextSize floatValue]];
    }
    if (smsPhoneInputViewPlaceholderText) {
        uiConfig.smsNumberTFPlaceholder = smsPhoneInputViewPlaceholderText;
    }
    if (smsPhoneInputViewBorderStyle) {
        uiConfig.smsNumberTFBorderStyle = [self getTFBorderStyleStyle:smsPhoneInputViewBorderStyle];
    }
    NSMutableArray *smsPhoneInputViewAttris = [NSMutableArray array];
    if (smsPhoneInputViewOffsetX) {
        JVLayoutConstraint *sms_phoneInputView_cons_x = JVLayoutLeft([smsPhoneInputViewOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsPhoneInputViewAttris addObject:sms_phoneInputView_cons_x];
    }
    if (smsPhoneInputViewOffsetY) {
        JVLayoutConstraint *sms_phoneInputView_cons_y = JVLayoutTop([smsPhoneInputViewOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsPhoneInputViewAttris addObject:sms_phoneInputView_cons_y];
    }
    if (smsPhoneInputViewWidth) {
        JVLayoutConstraint *sms_phoneInputView_cons_w = JVLayoutWidth([smsPhoneInputViewWidth floatValue]);
        [smsPhoneInputViewAttris addObject:sms_phoneInputView_cons_w];
    }
    if (smsPhoneInputViewHeight) {
        JVLayoutConstraint *sms_phoneInputView_cons_h = JVLayoutHeight([smsPhoneInputViewHeight floatValue]);
        [smsPhoneInputViewAttris addObject:sms_phoneInputView_cons_h];
    }
    
    uiConfig.smsNumberTFConstraints = smsPhoneInputViewAttris;
    uiConfig.smsNumberTFHorizontalConstraints = uiConfig.smsNumberTFConstraints;
    
    
    // SMS验证码输入框设置
    NSNumber *smsVerifyCodeEditTextViewOffsetX = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewOffsetX"];
    NSNumber *smsVerifyCodeEditTextViewOffsetY = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewOffsetY"];
    NSNumber *smsVerifyCodeEditTextViewOffsetR = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewOffsetR"];
    NSNumber *smsVerifyCodeEditTextViewWidth = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewWidth"];
    NSNumber *smsVerifyCodeEditTextViewHeight = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewHeight"];
    NSNumber *smsVerifyCodeEditTextViewTextColor = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewTextColor"];
    NSNumber *smsVerifyCodeEditTextViewTextSize = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewTextSize"];
    NSString *smsVerifyCodeEditTextViewPlaceholderText = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewPlaceholderText"];
    NSString *smsVerifyCodeEditTextViewBorderStyle = [self getValue:smsUIConfig key:@"smsVerifyCodeEditTextViewBorderStyle"];
    if (smsVerifyCodeEditTextViewTextColor) {
        uiConfig.smsCodeTFColor = UIColorFromRGB([smsVerifyCodeEditTextViewTextColor integerValue]);
    }
    if (smsVerifyCodeEditTextViewTextSize) {
        uiConfig.smsCodeTFFont = [UIFont systemFontOfSize:[smsVerifyCodeEditTextViewTextSize floatValue]];
    }
    if (smsVerifyCodeEditTextViewPlaceholderText) {
        uiConfig.smsCodeTFPlaceholder = smsVerifyCodeEditTextViewPlaceholderText;
    }
    if (smsVerifyCodeEditTextViewBorderStyle) {
        uiConfig.smsCodeTFBorderStyle = [self getTFBorderStyleStyle:smsVerifyCodeEditTextViewBorderStyle];
    }
    NSMutableArray *smsVerifyCodeEditTextViewAttris = [NSMutableArray array];
    if (smsVerifyCodeEditTextViewOffsetX) {
        JVLayoutConstraint *sms_verifyCodeEditTextView_cons_x = JVLayoutLeft([smsVerifyCodeEditTextViewOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsVerifyCodeEditTextViewAttris addObject:sms_verifyCodeEditTextView_cons_x];
    }
    if (smsVerifyCodeEditTextViewOffsetY) {
        JVLayoutConstraint *sms_verifyCodeEditTextView_cons_y = JVLayoutTop([smsVerifyCodeEditTextViewOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsVerifyCodeEditTextViewAttris addObject:sms_verifyCodeEditTextView_cons_y];
    }
    if (smsVerifyCodeEditTextViewOffsetR) {
        JVLayoutConstraint *sms_verifyCodeEditTextView_cons_R = JVLayoutRight([smsVerifyCodeEditTextViewOffsetR floatValue],JVLayoutItemSuper,NSLayoutAttributeRight);
        [smsVerifyCodeEditTextViewAttris addObject:sms_verifyCodeEditTextView_cons_R];
    }
    if (smsVerifyCodeEditTextViewWidth) {
        JVLayoutConstraint *w = JVLayoutWidth([smsVerifyCodeEditTextViewWidth floatValue]);
        [smsVerifyCodeEditTextViewAttris addObject:w];
    }
    if (smsVerifyCodeEditTextViewHeight) {
        JVLayoutConstraint *h = JVLayoutHeight([smsVerifyCodeEditTextViewHeight floatValue]);
        [smsVerifyCodeEditTextViewAttris addObject:h];
    }
    uiConfig.smsCodeTFConstraints = smsVerifyCodeEditTextViewAttris;
    uiConfig.smsCodeTFHorizontalConstraints = uiConfig.smsCodeTFConstraints;
    
    //  SMS获取验证码按钮
    NSNumber *smsGetVerifyCodeTextViewOffsetX = [self getValue:smsUIConfig key:@"smsGetVerifyCodeTextViewOffsetX"];
    NSNumber *smsGetVerifyCodeTextViewOffsetY = [self getValue:smsUIConfig key:@"smsGetVerifyCodeTextViewOffsetY"];
    NSNumber *smsGetVerifyCodeTextViewOffsetR = [self getValue:smsUIConfig key:@"smsGetVerifyCodeTextViewOffsetR"];
    NSNumber *smsGetVerifyCodeBtnWidth = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnWidth"];
    NSNumber *smsGetVerifyCodeBtnHeight = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnHeight"];
    NSNumber *smsGetVerifyCodeTextViewTextColor = [self getValue:smsUIConfig key:@"smsGetVerifyCodeTextViewTextColor"];
    NSNumber *smsGetVerifyCodeTextViewTextSize = [self getValue:smsUIConfig key:@"smsGetVerifyCodeTextViewTextSize"];
    NSString *smsGetVerifyCodeBtnText = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnText"];
    NSString *smsGetVerifyCodeBtnBackgroundPath = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnBackgroundPaths"];
    NSArray *smsGetVerifyCodeBtnBackgroundPaths = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnBackgroundPaths"];
    NSNumber *smsGetVerifyCodeBtnCornerRadius = [self getValue:smsUIConfig key:@"smsGetVerifyCodeBtnCornerRadius"];
    if (smsGetVerifyCodeBtnText) {
        NSMutableDictionary *smsGetVerifyCodeTextViewAttr = [NSMutableDictionary dictionary];
        if (smsGetVerifyCodeTextViewTextColor) {
            [smsGetVerifyCodeTextViewAttr setValue:UIColorFromRGB([smsGetVerifyCodeTextViewTextColor integerValue]) forKey:NSForegroundColorAttributeName];
        }
        if (smsGetVerifyCodeTextViewTextSize) {
            [smsGetVerifyCodeTextViewAttr setValue:[UIFont systemFontOfSize:[smsGetVerifyCodeTextViewTextSize floatValue]] forKey:NSFontAttributeName];
        }
        uiConfig.smsGetCodeBtnAttributedString = [[NSAttributedString alloc] initWithString:smsGetVerifyCodeBtnText attributes:smsGetVerifyCodeTextViewAttr];
    }
    if (smsGetVerifyCodeBtnBackgroundPaths) {
        UIImage *img = [UIImage imageNamed:smsGetVerifyCodeBtnBackgroundPaths[0]];
        UIImage *img1 = [UIImage imageNamed:smsGetVerifyCodeBtnBackgroundPaths[1]];
        UIImage *img2 = [UIImage imageNamed:smsGetVerifyCodeBtnBackgroundPaths[2]];
        uiConfig.smsGetCodeBtnImgs = @[img, img1, img2];
    }else if (smsGetVerifyCodeBtnBackgroundPath) {
        UIImage *img = [UIImage imageNamed:smsGetVerifyCodeBtnBackgroundPath];
        uiConfig.smsGetCodeBtnImgs = @[img,img,img];
    }
    if (smsGetVerifyCodeBtnCornerRadius) {
        uiConfig.smsGetCodeBtnCornerRadius = [smsGetVerifyCodeBtnCornerRadius floatValue];
    }
    NSMutableArray *smsGetVerifyCodeBtnAttris = [NSMutableArray array];
    if (smsGetVerifyCodeTextViewOffsetX) {
        JVLayoutConstraint *sms_getVerifyCodeBtn_cons_x = JVLayoutLeft([smsGetVerifyCodeTextViewOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsGetVerifyCodeBtnAttris addObject:sms_getVerifyCodeBtn_cons_x];
    }
    if (smsGetVerifyCodeTextViewOffsetY) {
        JVLayoutConstraint *sms_getVerifyCodeBtn_cons_y = JVLayoutTop([smsGetVerifyCodeTextViewOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsGetVerifyCodeBtnAttris addObject:sms_getVerifyCodeBtn_cons_y];
    }
    if (smsGetVerifyCodeTextViewOffsetR) {
        JVLayoutConstraint *sms_getVerifyCodeBtn_cons_R = JVLayoutRight([smsGetVerifyCodeTextViewOffsetR floatValue],JVLayoutItemSuper,NSLayoutAttributeRight);
        [smsGetVerifyCodeBtnAttris addObject:sms_getVerifyCodeBtn_cons_R];
    }
    if (smsGetVerifyCodeBtnWidth) {
        JVLayoutConstraint *sms_getVerifyCodeBtn_cons_W = JVLayoutWidth([smsGetVerifyCodeBtnWidth floatValue]);
        [smsGetVerifyCodeBtnAttris addObject:sms_getVerifyCodeBtn_cons_W];
    }
    if (smsGetVerifyCodeBtnHeight) {
        JVLayoutConstraint *sms_getVerifyCodeBtn_cons_H = JVLayoutHeight([smsGetVerifyCodeBtnHeight floatValue]);
        [smsGetVerifyCodeBtnAttris addObject:sms_getVerifyCodeBtn_cons_H];
    }
    uiConfig.smsGetCodeBtnConstraints = smsGetVerifyCodeBtnAttris;
    uiConfig.smsGetCodeBtnHorizontalConstraints = uiConfig.smsCodeTFConstraints;
    
    
    //  SMS登录按钮
    NSNumber *smsLogBtnOffsetX = [self getValue:smsUIConfig key:@"smsLogBtnOffsetX"];
    NSNumber *smsLogBtnOffsetY = [self getValue:smsUIConfig key:@"smsLogBtnOffsetY"];
    NSNumber *smsLogBtnBottomOffsetY = [self getValue:smsUIConfig key:@"smsLogBtnBottomOffsetY"];
    NSNumber *smsLogBtnWidth = [self getValue:smsUIConfig key:@"smsLogBtnWidth"];
    NSNumber *smsLogBtnHeight = [self getValue:smsUIConfig key:@"smsLogBtnHeight"];
    NSNumber *smsLogBtnTextColor = [self getValue:smsUIConfig key:@"smsLogBtnTextColor"];
    NSNumber *smsLogBtnTextSize = [self getValue:smsUIConfig key:@"smsLogBtnTextSize"];
    NSString *smsLogBtnText = [self getValue:smsUIConfig key:@"smsLogBtnText"];
    NSNumber *isSmsLogBtnTextBold = [self getValue:smsUIConfig key:@"isSmsLogBtnTextBold"];
    NSString *smsLogBtnBackgroundPath = [self getValue:smsUIConfig key:@"smsLogBtnBackgroundPath"];
    NSArray *smsLogBtnBackgroundPaths = [self getValue:smsUIConfig key:@"smsLogBtnBackgroundPaths"];
    if (smsLogBtnText) {
        NSMutableDictionary *smsLogBtnAttr = [NSMutableDictionary dictionary];
        if (smsLogBtnTextColor) {
            [smsLogBtnAttr setValue:UIColorFromRGB([smsLogBtnTextColor integerValue]) forKey:NSForegroundColorAttributeName];
        }
        if (smsLogBtnTextSize) {
            UIFont *font;
            if (!isSmsLogBtnTextBold || (isSmsLogBtnTextBold && [isSmsLogBtnTextBold boolValue] == NO)) {
                font = [UIFont systemFontOfSize:[smsLogBtnTextSize floatValue]];
            }else {
                font = [UIFont boldSystemFontOfSize:[smsLogBtnTextSize floatValue]];
            }
            [smsLogBtnAttr setValue:font forKey:NSFontAttributeName];
        }
        uiConfig.smsLogBtnAttributedString = [[NSAttributedString alloc] initWithString:smsLogBtnText attributes:smsLogBtnAttr];
    }
    if (smsLogBtnBackgroundPaths) {
        UIImage *img = [UIImage imageNamed:smsLogBtnBackgroundPaths[0]];
        UIImage *img1 = [UIImage imageNamed:smsLogBtnBackgroundPaths[1]];
        UIImage *img2 = [UIImage imageNamed:smsLogBtnBackgroundPaths[2]];
        uiConfig.smsLogBtnImgs = @[img, img1, img2];
    }else if (smsLogBtnBackgroundPath) {
        UIImage *img = [UIImage imageNamed:smsLogBtnBackgroundPath];
        uiConfig.smsLogBtnImgs = @[img,img,img];
    }

    NSMutableArray *smsLogBtnConstraints = [NSMutableArray array];
    if (smsLogBtnOffsetX) {
        JVLayoutConstraint *sms_logBtn_cons_x = JVLayoutLeft([smsLogBtnOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsLogBtnConstraints addObject:sms_logBtn_cons_x];
    }
    if (smsLogBtnOffsetY) {
        JVLayoutConstraint *sms_logBtn_cons_y = JVLayoutTop([smsLogBtnOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeTop);
        [smsLogBtnConstraints addObject:sms_logBtn_cons_y];
    }
    if (smsLogBtnBottomOffsetY) {
        JVLayoutConstraint *sms_logBtn_cons_B = JVLayoutBottom([smsLogBtnBottomOffsetY floatValue],JVLayoutItemSuper,NSLayoutAttributeBottom);
        [smsLogBtnConstraints addObject:sms_logBtn_cons_B];
    }
    if (smsLogBtnWidth) {
        JVLayoutConstraint *sms_logBtn_cons_W = JVLayoutWidth([smsLogBtnWidth floatValue]);
        [smsLogBtnConstraints addObject:sms_logBtn_cons_W];
    }
    if (smsLogBtnWidth) {
        JVLayoutConstraint *sms_logBtn_cons_H = JVLayoutHeight([smsLogBtnHeight floatValue]);
        [smsLogBtnConstraints addObject:sms_logBtn_cons_H];
    }
    uiConfig.smsLogBtnConstraints = smsLogBtnConstraints;
    uiConfig.smsLogBtnHorizontalConstraints = uiConfig.smsCodeTFConstraints;
   
    
    // SMS隐私条款
    NSArray *smsPrivacyColor = [self getValue:smsUIConfig key:@"smsPrivacyColor"];
    NSNumber *smsPrivacyTextVerAlignment = [self getValue:smsUIConfig key:@"smsPrivacyTextVerAlignment"];
    NSNumber *isSmsPrivacyTextGravityCenter = [self getValue:smsUIConfig key:@"isSmsPrivacyTextGravityCenter"];
    NSString *smsPrivacyCheckboxCheckedImgPath = [self getValue:smsUIConfig key:@"smsPrivacyCheckboxCheckedImgPath"];
    NSString *smsPrivacyCheckboxUncheckedImgPath = [self getValue:smsUIConfig key:@"smsPrivacyCheckboxUncheckedImgPath"];
    NSNumber *smsPrivacyCheckboxState = [self getValue:smsUIConfig key:@"smsPrivacyCheckboxState"];
    NSNumber *smsPrivacyCheckboxSize = [self getValue:smsUIConfig key:@"smsPrivacyCheckboxSize"];
    NSNumber *isSmsPrivacyCheckboxInCenter = [self getValue:smsUIConfig key:@"isSmsPrivacyCheckboxInCenter"];
    NSNumber *smsPrivacyCheckboxOffsetX = [self getValue:smsUIConfig key:@"smsPrivacyCheckboxOffsetX"];
    NSNumber *smsPrivacyOffsetX = [self getValue:smsUIConfig key:@"smsPrivacyOffsetX"];
    NSNumber *smsPrivacyOffsetY = [self getValue:smsUIConfig key:@"smsPrivacyOffsetY"];
    NSNumber *smsPrivacyTopOffsetY = [self getValue:smsUIConfig key:@"smsPrivacyTopOffsetY"];
    NSNumber *smsPrivacyWidth = [self getValue:smsUIConfig key:@"smsPrivacyWidth"];
    NSNumber *smsPrivacyHeight = [self getValue:smsUIConfig key:@"smsPrivacyHeight"];
    if (smsPrivacyColor) {
        uiConfig.smsAppPrivacyColor = @[UIColorFromRGB([smsPrivacyColor[0] integerValue]), UIColorFromRGB([smsPrivacyColor[1] integerValue])];
    }
    if (smsPrivacyTextVerAlignment) {
        uiConfig.smsTextVerAlignment = [smsPrivacyTextVerAlignment integerValue];
    }
    if (smsPrivacyCheckboxCheckedImgPath) {
        uiConfig.smsCheckedImg = [UIImage imageNamed:smsPrivacyCheckboxCheckedImgPath];
    }
    if (smsPrivacyCheckboxUncheckedImgPath) {
        uiConfig.smsUncheckedImg = [UIImage imageNamed:smsPrivacyCheckboxUncheckedImgPath];
    }
    if (smsPrivacyCheckboxState) {
        uiConfig.smsPrivacyState = [smsPrivacyCheckboxState boolValue];
    }
    if (isSmsPrivacyTextGravityCenter) {
        uiConfig.smsPrivacyTextAlignment = [isSmsPrivacyTextGravityCenter boolValue]? NSTextAlignmentCenter : NSTextAlignmentLeft;
    }
    NSMutableArray *smsPrivacyConstraints = [NSMutableArray array];
    if (smsPrivacyOffsetX) {
        JVLayoutConstraint *sms_privacy_cons_x = JVLayoutLeft([smsPrivacyOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsPrivacyConstraints addObject:sms_privacy_cons_x];
    }
    if (smsPrivacyOffsetY) {
        JVLayoutConstraint *sms_privacy_cons_b = JVLayoutBottom([smsPrivacyOffsetY floatValue], JVLayoutItemSuper, NSLayoutAttributeBottom);
        [smsPrivacyConstraints addObject:sms_privacy_cons_b];
    }
    if (smsPrivacyTopOffsetY) {
        JVLayoutConstraint *sms_privacy_cons_y = JVLayoutBottom([smsPrivacyTopOffsetY floatValue], JVLayoutItemSuper, NSLayoutAttributeBottom);
        [smsPrivacyConstraints addObject:sms_privacy_cons_y];
    }
    if (smsPrivacyWidth) {
        JVLayoutConstraint *sms_privacy_cons_w = JVLayoutWidth([smsPrivacyWidth floatValue]);
        [smsPrivacyConstraints addObject:sms_privacy_cons_w];
    }
    if (smsPrivacyHeight) {
        JVLayoutConstraint *sms_privacy_cons_h = JVLayoutHeight([smsPrivacyHeight floatValue]);
        [smsPrivacyConstraints addObject:sms_privacy_cons_h];
    }
    uiConfig.smsPrivacyConstraints = smsPrivacyConstraints;
    uiConfig.smsPrivacyHorizontalConstraints = uiConfig.smsPrivacyConstraints;
    

    NSMutableArray *smsPrivacyCheckboxSizeAttris = [NSMutableArray array];
    if (smsPrivacyCheckboxSize) {
        JVLayoutConstraint *w = JVLayoutWidth([smsPrivacyCheckboxSize floatValue]);
        JVLayoutConstraint *h = JVLayoutHeight([smsPrivacyCheckboxSize floatValue]);
        [smsPrivacyCheckboxSizeAttris addObject:w];
        [smsPrivacyCheckboxSizeAttris addObject:h];
    }
    if ([isSmsPrivacyCheckboxInCenter boolValue]) {
        JVLayoutConstraint *centerY = JVLayoutCenterY(0, JVLayoutItemPrivacy);
        [smsPrivacyCheckboxSizeAttris addObject:centerY];
    }else {
        JVLayoutConstraint *top = JVLayoutTop(0, JVLayoutItemPrivacy, NSLayoutAttributeTop);
        [smsPrivacyCheckboxSizeAttris addObject:top];
    }
    if (smsPrivacyCheckboxOffsetX) {
        JVLayoutConstraint *x = JVLayoutLeft([smsPrivacyCheckboxOffsetX floatValue], JVLayoutItemSuper, NSLayoutAttributeLeft);
        [smsPrivacyCheckboxSizeAttris addObject:x];
    }
    
    uiConfig.smsCheckViewConstraints = smsPrivacyCheckboxSizeAttris;
    
    NSMutableArray *smsAppPrivacys = [NSMutableArray array];
    NSString *smsPrivacyClauseStart = [self getValue:smsUIConfig key:@"smsPrivacyClauseStart"];
    [smsAppPrivacys addObject:smsPrivacyClauseStart ?: @""];
    if([[smsUIConfig allKeys] containsObject:@"smsPrivacyBeanList"] && [[smsUIConfig objectForKey:@"smsPrivacyBeanList"] isKindOfClass:[NSString class]]){
        NSString *privacyJson = [smsUIConfig objectForKey:@"smsPrivacyBeanList"];
        NSData *privacyData = [privacyJson  dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *privacys= [NSJSONSerialization JSONObjectWithData:privacyData options:0 error:nil];
        for (NSInteger i = 0; i<privacys.count; i++) {
            NSMutableArray *item = [NSMutableArray array];
            NSDictionary *obj = [privacys objectAtIndex:i];
            //加入协议之间的分隔符
            if ([[obj allKeys] containsObject:@"separator"] ) {
                [item addObject:[obj objectForKey:@"name"]?:@""];
            }
            //加入name
            if ([[obj allKeys] containsObject:@"name"] ) {
                [item addObject:[obj objectForKey:@"name"]];
            }
            //加入url
            if ([[obj allKeys] containsObject:@"url"] ) {
                [item addObject:[obj objectForKey:@"url"]];
            }
            //加入协议详细页面的导航栏文字 可以是NSAttributedString类型 自定义  这里是直接拿name进行展示
            if ([[obj allKeys] containsObject:@"name"] ) {
                [item addObject:[obj objectForKey:@"name"]];
            }
            [smsAppPrivacys addObject:item];
        }
        
        NSString *smsPrivacyClauseEnd = [self getValue:smsUIConfig key:@"smsPrivacyClauseEnd"];
        [smsAppPrivacys addObject:smsPrivacyClauseEnd ?: @""];
        
    }
    uiConfig.smsAppPrivacys = smsAppPrivacys;
    
}

#pragma mark - 添加 label
- (UILabel *)addCustomTextWidget:(NSDictionary *)widgetDic {
    JVLog(@"Action - addCustomTextWidget:");
    UILabel *label = [[UILabel alloc] init];
    
    NSInteger left = [[self getValue:widgetDic key:@"left"] integerValue];
    NSInteger top = [[self getValue:widgetDic key:@"top"] integerValue];
    NSInteger width = [[self getValue:widgetDic key:@"width"] integerValue];
    NSInteger height = [[self getValue:widgetDic key:@"height"] integerValue];
    
    NSString *title = [self getValue:widgetDic key:@"title"];
    if (title) {
        label.text = title;
    }
    NSNumber *titleColor = [self getValue:widgetDic key:@"titleColor"];
    if (titleColor) {
        label.textColor = UIColorFromRGB([titleColor integerValue]);
    }
    NSNumber *backgroundColor = [self getValue:widgetDic key:@"backgroundColor"];
    if (backgroundColor) {
        label.backgroundColor = UIColorFromRGB([backgroundColor integerValue]);
    }
    NSString *textAlignment = [self getValue:widgetDic key:@"textAlignment"];
    if (textAlignment) {
        label.textAlignment = [self getTextAlignment:textAlignment];
    }
    
    NSNumber *font = [self getValue:widgetDic key:@"titleFont"];
    if (font) {
        label.font = [UIFont systemFontOfSize:[font floatValue]];
    }
    
    NSNumber *lines = [self getValue:widgetDic key:@"lines"];
    if (lines) {
        label.numberOfLines = [lines integerValue];
    }
    NSNumber *isSingleLine = [self getValue:widgetDic key:@"isSingleLine"];
    if (![isSingleLine boolValue]) {
        label.numberOfLines = 0;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:20],};
        CGSize textSize = [label.text boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
        height = textSize.height;
    }
    
    NSNumber *isShowUnderline = [self getValue:widgetDic key:@"isShowUnderline"];
    if ([isShowUnderline boolValue]) {
        NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle]};
        NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:title attributes:attribtDic];
        label.attributedText = attribtStr;
    }
    
    NSString *widgetId = [self getValue:widgetDic key:@"widgetId"];
    
    label.frame = CGRectMake(left, top, width, height);
    
    NSNumber *isClickEnable = [self getValue:widgetDic key:@"isClickEnable"];
    if ([isClickEnable boolValue]) {
        NSString *tag = @(left+top+width+height).stringValue;
        label.userInteractionEnabled = YES;
        
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTextWidgetAction:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [label addGestureRecognizer:singleTapGestureRecognizer];
        singleTapGestureRecognizer.view.tag = [tag integerValue];
        
        [self.customWidgetIdDic setObject:widgetId forKey:tag];
    }
    
    return label;
}
- (void)clickTextWidgetAction:(UITapGestureRecognizer *)gestureRecognizer {
    JVLog(@"Action - clickTextWidgetAction:");
    NSString *tag = [NSString stringWithFormat:@"%@",@(gestureRecognizer.view.tag)];
    if (tag) {
        NSString *widgetId = [self.customWidgetIdDic objectForKey:tag];
        [_channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:@{@"widgetId":widgetId}];
    }
}


#pragma mark - 添加 button
- (UIButton *)addCustomButtonWidget:(NSDictionary *)widgetDic {
    JVLog(@"Action - addCustomButtonWidget:");
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    NSInteger left = [[self getValue:widgetDic key:@"left"] integerValue];
    NSInteger top = [[self getValue:widgetDic key:@"top"] integerValue];
    NSInteger width = [[self getValue:widgetDic key:@"width"] integerValue];
    NSInteger height = [[self getValue:widgetDic key:@"height"] integerValue];
    
    NSString *title = [self getValue:widgetDic key:@"title"];
    if (title) {
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitle:title forState:UIControlStateHighlighted];
    }
    NSNumber *titleColor = [self getValue:widgetDic key:@"titleColor"];
    if (titleColor) {
        [button setTitleColor:UIColorFromRGB([titleColor integerValue]) forState:UIControlStateNormal];
    }
    NSNumber *backgroundColor = [self getValue:widgetDic key:@"backgroundColor"];
    if (backgroundColor) {
        [button setBackgroundColor:UIColorFromRGB([backgroundColor integerValue])];
    }
    NSString *textAlignment = [self getValue:widgetDic key:@"textAlignment"];
    if (textAlignment) {
        button.contentHorizontalAlignment = [self getButtonTitleAlignment:textAlignment];
    }
    
    NSNumber *font = [self getValue:widgetDic key:@"titleFont"];
    if (font) {
        button.titleLabel.font = [UIFont systemFontOfSize:[font floatValue]];
    }
    
    
    NSNumber *isShowUnderline = [self getValue:widgetDic key:@"isShowUnderline"];
    if ([isShowUnderline boolValue]) {
        NSDictionary *attribtDic = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle]};
        NSMutableAttributedString *attribtStr = [[NSMutableAttributedString alloc]initWithString:title attributes:attribtDic];
        button.titleLabel.attributedText = attribtStr;
    }
    
    button.frame = CGRectMake(left, top, width, height);
    
    NSNumber *isClickEnable = [self getValue:widgetDic key:@"isClickEnable"];
    button.userInteractionEnabled = [isClickEnable boolValue];
    [button addTarget:self action:@selector(clickCustomWidgetAction:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *widgetId = [self getValue:widgetDic key:@"widgetId"];
    
    NSString *tag = @(left+top+width+height).stringValue;
    button.tag = [tag integerValue];
    
    
    [self.customWidgetIdDic setObject:widgetId forKey:tag];
    
    
    NSString *btnNormalImageName = [self getValue:widgetDic key:@"btnNormalImageName"];
    NSString *btnPressedImageName = [self getValue:widgetDic key:@"btnPressedImageName"];
    if (!btnPressedImageName) {
        btnPressedImageName = btnNormalImageName;
    }
    if (btnNormalImageName) {
        [button setBackgroundImage:[UIImage imageNamed:btnNormalImageName] forState:UIControlStateNormal];
    }
    if (btnPressedImageName) {
        [button setBackgroundImage:[UIImage imageNamed:btnPressedImageName] forState:UIControlStateHighlighted];
        [button setBackgroundImage:[UIImage imageNamed:btnPressedImageName] forState:UIControlStateSelected];
    }
    
    return button;
}

- (void)clickCustomWidgetAction:(UIButton *)button {
    JVLog(@"Action - clickCustomWidgetAction:");
    
    NSString *tag = [NSString stringWithFormat:@"%@",@(button.tag)];
    if (tag) {
        NSString *widgetId = [self.customWidgetIdDic objectForKey:tag];
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakself) strongself = weakself;
            [strongself.channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:@{@"widgetId":widgetId}];
        });
        
    }
}

#pragma mark - 其他
- (id)getValue:(NSDictionary *)arguments key:(NSString*) key{
    if (arguments && ![arguments[key] isKindOfClass:[NSNull class]]) {
        return arguments[key]?:nil;
    }else{
        return nil;
    }
}
- (id)getNumberValue:(NSDictionary *)arguments key:(NSString*) key{
    if (arguments && ![arguments[key] isKindOfClass:[NSNull class]]) {
        return arguments[key]?:@(0);
    }else{
        return @(0);
    }
}


//- (id)object:(FlutterMethodCall*)caller forKey:(NSString *)key {
//    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
//        return caller.arguments[key]?:nil;
//    }
//    return nil;
//}

- (UIModalTransitionStyle)getTransitionStyle:(NSString*)itemStr{
    if ([itemStr isEqualToString:@"FlipHorizontal"]){
        return UIModalTransitionStyleFlipHorizontal;
    }else if ([itemStr isEqualToString:@"CrossDissolve"]){
        return UIModalTransitionStyleCrossDissolve;
    }else if ([itemStr isEqualToString:@"PartialCurl"]){
        return UIModalTransitionStylePartialCurl;
    }
    return UIModalTransitionStyleCoverVertical;
}

- (UIStatusBarStyle)getStatusBarStyle:(NSString*)itemStr{
    if ([itemStr isEqualToString:@"StatusBarStyleDefault"]){
        return UIStatusBarStyleDefault;
    }else if ([itemStr isEqualToString:@"StatusBarStyleLightContent"]){
        return UIStatusBarStyleLightContent;
    }else if ([itemStr isEqualToString:@"StatusBarStyleDarkContent"]){
        if (@available(iOS 13.0, *)) {
            return UIStatusBarStyleDarkContent;
        }
    }
    return UIStatusBarStyleDefault;
}

- (UITextBorderStyle)getTFBorderStyleStyle:(NSString*)itemStr{
    if ([itemStr isEqualToString:@"BorderStyleRoundedRect"]){
        return UITextBorderStyleRoundedRect;
    }else if ([itemStr isEqualToString:@"BorderStyleLine"]){
        return UITextBorderStyleLine;
    }else if ([itemStr isEqualToString:@"BorderStyleBezel"]){
        return UITextBorderStyleBezel;
      
    }
    return UITextBorderStyleNone;
}


- (JVLayoutItem)getLayotItem:(NSString *)itemString {
    JVLayoutItem item = JVLayoutItemNone;
    if (itemString) {
        if ([itemString isEqualToString:@"ItemNone"]) {
            item = JVLayoutItemNone;
        }else if ([itemString isEqualToString:@"ItemLogo"]) {
            item = JVLayoutItemLogo;
        }else if ([itemString isEqualToString:@"ItemNumber"]) {
            item = JVLayoutItemNumber;
        }else if ([itemString isEqualToString:@"ItemSlogan"]) {
            item = JVLayoutItemSlogan;
        }else if ([itemString isEqualToString:@"ItemLogin"]) {
            item = JVLayoutItemLogin;
        }else if ([itemString isEqualToString:@"ItemCheck"]) {
            item = JVLayoutItemCheck;
        }else if ([itemString isEqualToString:@"ItemPrivacy"]) {
            item = JVLayoutItemPrivacy;
        }else if ([itemString isEqualToString:@"ItemSuper"]) {
            item = JVLayoutItemSuper;
        }else{
            item = JVLayoutItemNone;
        }
    }
    return item;
}
- (NSTextAlignment)getTextAlignment:(NSString *)aligement {
    NSTextAlignment model = NSTextAlignmentLeft;
    if (aligement) {
        if ([aligement isEqualToString:@"left"]) {
            model = NSTextAlignmentLeft;
        }else if ([aligement isEqualToString:@"right"]) {
            model = NSTextAlignmentRight;
        }else if ([aligement isEqualToString:@"center"]) {
            model = NSTextAlignmentCenter;
        }else {
            model = NSTextAlignmentLeft;
        }
    }
    return model;
}
- (UIControlContentHorizontalAlignment)getButtonTitleAlignment:(NSString *)aligement {
    UIControlContentHorizontalAlignment model = UIControlContentHorizontalAlignmentCenter;
    if (aligement) {
        if ([aligement isEqualToString:@"left"]) {
            model = UIControlContentHorizontalAlignmentLeft;
        }else if ([aligement isEqualToString:@"right"]) {
            model = UIControlContentHorizontalAlignmentRight;
        }else if ([aligement isEqualToString:@"center"]) {
            model = UIControlContentHorizontalAlignmentCenter;
        }else {
            model = UIControlContentHorizontalAlignmentCenter;
        }
    }
    return model;
}
- (NSMutableDictionary *)customWidgetIdDic {
    if (!_customWidgetIdDic) {
        _customWidgetIdDic  = [NSMutableDictionary dictionary];
    }
    return _customWidgetIdDic;
}

@end
