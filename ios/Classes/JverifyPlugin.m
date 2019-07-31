#import "JverifyPlugin.h"
#import "JVERIFICATIONService.h"
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
/// 默认超时时间
static long j_default_timeout = 5000;

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
    }else if([methodName isEqualToString:@"preLogin"]){
        [self preLogin:call result:result];
    }else if([methodName isEqualToString:@"dismissLoginAuthView"]){
        [self dismissLoginController:call result:result];
    }else if([methodName isEqualToString:@"setCustomUI"]){
//        [self setCustomUIWithConfig:call result:result];
    }else if ([methodName isEqualToString:@"setCustomAuthViewAllWidgets"]) {
        [self setCustomAuthViewAllWidgets:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - 设置日志 debug 模式
-(void)setDebugMode:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setDebugMode::");
    
    NSDictionary *arguments = call.arguments;
    NSNumber *debug = arguments[@"debug"];
    [JVERIFICATIONService setDebug:[debug boolValue]];
}

#pragma mark - 初始化 SDK
- (void)setup:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - setup::");
    NSDictionary *arguments = [call arguments];
    NSString *appKey = arguments[@"appKey"];
    NSString *channel = arguments[@"channel"];
    NSNumber *useIDFA = arguments[@"useIDFA"];
    
    JVAuthConfig *config = [[JVAuthConfig alloc] init];
    if (![appKey isKindOfClass:[NSNull class]]) {
        config.appKey = appKey;
    }
    config.appKey =appKey;
    if (![channel isKindOfClass:[NSNull class]]) {
        config.channel = channel;
    }
    NSString *idfaStr = NULL;
    if(![useIDFA isKindOfClass:[NSNull class]]){
        if([useIDFA boolValue]){
            idfaStr = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
            config.advertisingId = idfaStr;
        }
    }
    [JVERIFICATIONService setupWithConfig:config];
}

#pragma mark - 获取初始化状态
-(BOOL)isSetupClient:(FlutterResult)result {
    JVLog(@"Action - isSetupClient:");
    BOOL isSetup = [JVERIFICATIONService isSetupClient];
    if (!isSetup) {
        JVLog(@"初始化未完成!");
    }
    result(@{j_result_key:[NSNumber numberWithBool:isSetup]});
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
    result(@{j_result_key:[NSNumber numberWithBool:isEnable]});
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

    NSDictionary *arguments=  [call arguments];
    NSString *phone = arguments[@"phone"];
    NSString *token = arguments[@"token"];
    
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
                               j_msg_key :res[@"message"] ? res[@"message"] : @""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}
#pragma mark - SDK 请求授权一键登录
-(void)loginAuth:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - loginAuth::%@",call.arguments);

    NSDictionary *arguments = [call arguments];
    NSNumber *hide = arguments[@"autoDismiss"];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    /*
     参数说明:
     vc 当前控制器
     hide 完成后是否自动隐藏授权页，默认YES。若此字段设置为NO，请在收到一键登录回调后调用SDK提供的关闭授权页面方法。
     completion 登录结果
        result 字典
            获取到时， token 时 key 有 code、operator、loginToken字段，
            获取不到时，token 是 key 为 code 和 content 字段
     */
    [JVERIFICATIONService getAuthorizationWithController:vc hide:[hide boolValue] completion:^(NSDictionary *res) {
        JVLog(@"loginAuth result = %@",res);
        
        NSString *content = @"";
        if(res[@"loginToken"]){
            content =res[@"loginToken"];
        }else if(res[@"content"]){
            content = res[@"content"];
        }
        
        NSDictionary *dict = @{
                               j_code_key:res[@"code"],
                               j_msg_key :content,
                               j_opr_key :res[@"operator"]?:@""
                               };
        dispatch_async(dispatch_get_main_queue(), ^{
            result(dict);
        });
    }];
}
#pragma mark - SDK关闭授权页面
-(void)dismissLoginController:(FlutterMethodCall*) call result:(FlutterResult)result{
    JVLog(@"Action - dismissLoginController::");
    [JVERIFICATIONService dismissLoginController];
}

#pragma mark - 自定义授权页面所有的 UI （包括：原有的、新加的）
-(void)setCustomAuthViewAllWidgets:(FlutterMethodCall*) call result:(FlutterResult)result {
    JVLog(@"Action - setCustomAuthViewAllWidgets:%@",call.arguments);
    
    NSDictionary *uiconfig = call.arguments[@"uiconfig"];
    NSArray *widgets = call.arguments[@"widgets"];
    
    /*移动*/
    JVMobileUIConfig *mobileUIConfig = [[JVMobileUIConfig alloc] init];
    /*联通*/
    JVUnicomUIConfig *unicomUIConfig = [[JVUnicomUIConfig alloc] init];
    /*电信*/
    JVTelecomUIConfig *telecomUIConfig = [[JVTelecomUIConfig alloc] init];
    
    [self setCustomUIWithConfigWithMobile:mobileUIConfig unicom:unicomUIConfig telecom:telecomUIConfig configArguments:uiconfig];
    
    [JVERIFICATIONService customUIWithConfig:mobileUIConfig customViews:^(UIView *customAreaView) {
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
    [JVERIFICATIONService customUIWithConfig:unicomUIConfig customViews:^(UIView *customAreaView) {
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
    [JVERIFICATIONService customUIWithConfig:telecomUIConfig customViews:^(UIView *customAreaView) {
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

/**
 自定义授权页面原有的 UI 控件

 @param mobileUIConfig 移动
 @param unicomUIConfig 联通
 @param telecomUIConfig 电信
 @param config 自定义配置
 */
- (void)setCustomUIWithConfigWithMobile:(JVUIConfig *)mobileUIConfig
                                 unicom:(JVUIConfig *)unicomUIConfig
                                telecom:(JVUIConfig *)telecomUIConfig
                        configArguments:(NSDictionary *)config {
    JVLog(@"Action - setCustomUIWithConfigWithMobile:::");
    
    mobileUIConfig.barStyle = 0;
    unicomUIConfig.barStyle = 0;
    telecomUIConfig.barStyle = 0;

    NSNumber *navColor = [self getValue:config key:@"navColor"];
    if (navColor) {
        mobileUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        unicomUIConfig.navColor  = UIColorFromRGB([navColor intValue]);
        telecomUIConfig.navColor = UIColorFromRGB([navColor intValue]);
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
    mobileUIConfig.navText = attr;
    unicomUIConfig.navText = attr;
    telecomUIConfig.navText = attr;
    
    NSString *imageName =[self getValue:config key:@"navReturnImgPath"];
    if(imageName){
        mobileUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        unicomUIConfig.navReturnImg  = [UIImage imageNamed:imageName];
        telecomUIConfig.navReturnImg = [UIImage imageNamed:imageName];
    }
    
    NSString *logoImgPath =[self getValue:config key:@"logoImgPath"];
    if(logoImgPath){
        mobileUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        unicomUIConfig.logoImg  = [UIImage imageNamed:logoImgPath];
        telecomUIConfig.logoImg = [UIImage imageNamed:logoImgPath];
    }
    
    NSNumber *logoHidden = [self getValue:config key:@"logoHidden"];
    if(logoHidden){
        mobileUIConfig.logoHidden  = [logoHidden boolValue];
        unicomUIConfig.logoHidden  = [logoHidden boolValue];
        telecomUIConfig.logoHidden = [logoHidden boolValue];
    }
    
    NSNumber *logoWidth = [self getValue:config key:@"logoWidth"];
    if(logoWidth){
        mobileUIConfig.logoWidth  = [logoWidth intValue];
        unicomUIConfig.logoWidth  = [logoWidth intValue];
        telecomUIConfig.logoWidth = [logoWidth intValue];
    }
    
    NSNumber *logoHeight = [self getValue:config key:@"logoHeight"];
    if(logoHeight){
        mobileUIConfig.logoHeight  = [logoHeight intValue];
        unicomUIConfig.logoHeight  = [logoHeight intValue];
        telecomUIConfig.logoHeight = [logoHeight intValue];
    }
    
    NSNumber *logoOffsetY = [self getValue:config key:@"logoOffsetY"];
    if(logoOffsetY){
        mobileUIConfig.logoOffsetY  = [logoOffsetY integerValue];
        unicomUIConfig.logoOffsetY  = [logoOffsetY integerValue];
        telecomUIConfig.logoOffsetY = [logoOffsetY integerValue];
    }
    
    NSNumber *numberColor = [self getValue:config key:@"numberColor"];
    if(numberColor){
        mobileUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        unicomUIConfig.numberColor  = UIColorFromRGB([numberColor intValue]);
        telecomUIConfig.numberColor = UIColorFromRGB([numberColor intValue]);
    }
    
    NSNumber *numFieldOffsetY = [self getValue:config key:@"numFieldOffsetY"];
    if(numFieldOffsetY){
        mobileUIConfig.numFieldOffsetY  = [numFieldOffsetY integerValue];
        unicomUIConfig.numFieldOffsetY  = [numFieldOffsetY integerValue];
        telecomUIConfig.numFieldOffsetY = [numFieldOffsetY integerValue];
    }
    
    NSString *logBtnText = [self getValue:config key:@"logBtnText"];
    if(logBtnText){
        mobileUIConfig.logBtnText  = logBtnText;
        unicomUIConfig.logBtnText  = logBtnText;
        telecomUIConfig.logBtnText = logBtnText;
    }
    
    NSNumber *logBtnTextColor = [self getValue:config key:@"logBtnTextColor"];
    if(logBtnTextColor){
        mobileUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        unicomUIConfig.logBtnTextColor  = UIColorFromRGB([logBtnTextColor integerValue]);
        telecomUIConfig.logBtnTextColor = UIColorFromRGB([logBtnTextColor integerValue]);
    }
    
    NSNumber *logBtnOffsetY = [self getValue:config key:@"logBtnOffsetY"];
    if(logBtnOffsetY){
        mobileUIConfig.logBtnOffsetY  = [logBtnOffsetY integerValue];
        unicomUIConfig.logBtnOffsetY  = [logBtnOffsetY integerValue];
        telecomUIConfig.logBtnOffsetY = [logBtnOffsetY integerValue];
    }
    NSString *loginBtnNormalImage =[self getValue:config key:@"loginBtnNormalImage"];
    loginBtnNormalImage = loginBtnNormalImage?:nil;
    NSString *loginBtnPressedImage =[self getValue:config key:@"loginBtnPressedImage"];
    loginBtnPressedImage = loginBtnPressedImage?:nil;
    NSString *loginBtnUnableImage =[self getValue:config key:@"loginBtnUnableImage"];
    loginBtnUnableImage = loginBtnUnableImage?:nil;
    NSArray * images =[[NSArray alloc]initWithObjects:[UIImage imageNamed:loginBtnNormalImage],[UIImage imageNamed:loginBtnPressedImage],[UIImage imageNamed:loginBtnUnableImage],nil];
    mobileUIConfig.logBtnImgs = images;
    unicomUIConfig.logBtnImgs = images;
    telecomUIConfig.logBtnImgs = images;
    
    NSString *uncheckedImgPath =[self getValue:config key:@"uncheckedImgPath"];
    if (uncheckedImgPath) {
        mobileUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        unicomUIConfig.uncheckedImg  = [UIImage imageNamed:uncheckedImgPath];
        telecomUIConfig.uncheckedImg = [UIImage imageNamed:uncheckedImgPath];
    }
    
    NSString *checkedImgPath =[self getValue:config key:@"checkedImgPath"];
    if (checkedImgPath) {
        mobileUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        unicomUIConfig.checkedImg  = [UIImage imageNamed:checkedImgPath];
        telecomUIConfig.checkedImg = [UIImage imageNamed:checkedImgPath];
    }

    NSNumber *privacyOffsetY = [self getValue:config key:@"privacyOffsetY"];
    if(privacyOffsetY){
        mobileUIConfig.privacyOffsetY  = [privacyOffsetY integerValue];
        unicomUIConfig.privacyOffsetY  = [privacyOffsetY integerValue];
        telecomUIConfig.privacyOffsetY = [privacyOffsetY integerValue];
    }
    
    NSString *clauseName = [self getValue:config key:@"clauseName"];
    NSString *clauseUrl = [self getValue:config key:@"clauseUrl"];
    if (clauseName && clauseUrl) {
        mobileUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        unicomUIConfig.appPrivacyOne  = @[clauseName,clauseUrl];
        telecomUIConfig.appPrivacyOne = @[clauseName,clauseUrl];
    }
    
    NSString *clauseNameTwo = [self getValue:config key:@"clauseNameTwo"];
    NSString *clauseUrlTwo = [self getValue:config key:@"clauseUrlTwo"];
    if (clauseNameTwo && clauseUrlTwo) {
        mobileUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        unicomUIConfig.appPrivacyTwo  = @[clauseNameTwo,clauseUrlTwo];
        telecomUIConfig.appPrivacyTwo = @[clauseNameTwo,clauseUrlTwo];
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
    mobileUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    unicomUIConfig.appPrivacyColor  = @[privacyBasicColor,privacyColor];
    telecomUIConfig.appPrivacyColor = @[privacyBasicColor,privacyColor];
    
    NSNumber *sloganTextColor = [self getValue:config key:@"sloganTextColor"];
    if(sloganTextColor){
        mobileUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        unicomUIConfig.sloganTextColor  = UIColorFromRGB([sloganTextColor integerValue]);
        telecomUIConfig.sloganTextColor = UIColorFromRGB([sloganTextColor integerValue]);
    }
    
    NSNumber *sloganOffsetY = [self getValue:config key:@"sloganOffsetY"];
    if(sloganOffsetY){
        mobileUIConfig.sloganOffsetY  = [sloganOffsetY integerValue];
        unicomUIConfig.sloganOffsetY  = [sloganOffsetY integerValue];
        telecomUIConfig.sloganOffsetY = [sloganOffsetY integerValue];
    }
    
    NSNumber *privacyState = [self getValue:config key:@"privacyState"];
    mobileUIConfig.privacyState = [privacyState boolValue];
    unicomUIConfig.privacyState = [privacyState boolValue];
    telecomUIConfig.privacyState = [privacyState boolValue];
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
        NSString *tag = @"1001";
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
    /*
    NSNumber *isSingleLine = [self getValue:widgetDic key:@"isSingleLine"];
    if (![isSingleLine boolValue]) {
        label.numberOfLines = 0;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:20],};
        CGSize textSize = [label.text boundingRectWithSize:CGSizeMake(width, height) options:NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
        height = textSize.height;
    }
    
     NSNumber *lines = [self getValue:widgetDic key:@"lines"];
     if (lines) {
     label.numberOfLines = [lines integerValue];
     }
     NSNumber *maxLines = [self getValue:widgetDic key:@"maxLines"];
     if (maxLines) {
     }
     */
    
    
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
    NSString *tag = @"1002";
    button.tag = [tag integerValue];
    
    NSString *widgetId = [self getValue:widgetDic key:@"widgetId"];
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
        [_channel invokeMethod:@"onReceiveClickWidgetEvent" arguments:@{@"widgetId":widgetId}];
    }
}

#pragma mark - 其他
- (id)getValue:(NSDictionary *)arguments key:(NSString*) key{
    if (arguments && ![arguments[key] isKindOfClass:[NSNull class]]) {
        return arguments[key]?:0;
    }else{
        return 0;
    }
}

//- (id)object:(FlutterMethodCall*)caller forKey:(NSString *)key {
//    if (caller && ![caller.arguments[key] isKindOfClass:[NSNull class]]) {
//        return caller.arguments[key]?:nil;
//    }
//    return nil;
//}
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
