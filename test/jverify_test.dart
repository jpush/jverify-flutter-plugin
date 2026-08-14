import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jverify/jverify.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('jverify_test');
  late List<MethodCall> calls;
  late Jverify jverify;
  Future<dynamic> Function(MethodCall call)? respond;

  Future<void> invokeNative(MethodCall call) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(call),
      null,
    );
  }

  setUp(() async {
    calls = <MethodCall>[];
    jverify = Jverify.private(channel);
    respond = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return respond?.call(call);
    });
    jverify.setup(appKey: 'register-native-handler');
    await Future<void>.delayed(Duration.zero);
    calls.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  test('HarmonyOS-only UI properties are serialized for the native adapter',
      () async {
    final JVUIConfig config = JVUIConfig()
      ..harmonyAuthPageFontFollowSystem = false
      ..harmonyTopSafeAreaHeight = 24
      ..harmonyBottomSafeAreaHeight = 12
      ..harmonyStackLayout = true
      ..harmonyReturnBtnWidth = 30
      ..harmonyReturnBtnHeight = 31
      ..harmonyLogBtnBackgroundColor = 0xFF0099FF
      ..harmonyLogBtnBorderRadius = 20
      ..harmonyPrivacyHintToastText = '请勾选隐私协议'
      ..harmonyPrivacyClauseStart = '登录即同意'
      ..harmonyPrivacyClauseEnd = '并使用本机号码登录';

    jverify.setCustomAuthorizationView(false, config);
    await Future<void>.delayed(Duration.zero);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setCustomAuthorizationView');
    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> portraitConfig =
        arguments['portraitConfig'] as Map<dynamic, dynamic>;
    expect(portraitConfig['harmonyAuthPageFontFollowSystem'], isFalse);
    expect(portraitConfig['harmonyTopSafeAreaHeight'], 24);
    expect(portraitConfig['harmonyBottomSafeAreaHeight'], 12);
    expect(portraitConfig['harmonyStackLayout'], isTrue);
    expect(portraitConfig['harmonyReturnBtnWidth'], 30);
    expect(portraitConfig['harmonyReturnBtnHeight'], 31);
    expect(portraitConfig['harmonyLogBtnBackgroundColor'], 0xFF0099FF);
    expect(portraitConfig['harmonyLogBtnBorderRadius'], 20);
    expect(portraitConfig['harmonyPrivacyHintToastText'], '请勾选隐私协议');
    expect(portraitConfig['harmonyPrivacyClauseStart'], '登录即同意');
    expect(portraitConfig['harmonyPrivacyClauseEnd'], '并使用本机号码登录');
  });

  test('China Mobile HarmonyOS UI model keeps typed nested values', () async {
    final JVUIConfig config = JVUIConfig()
      ..harmonyCmUIConfig = (JVHarmonyCMUIConfig()
        ..authPageGrayScale = 0.8
        ..numberMargin = JVHarmonyMargin(left: 12, top: 24)
        ..numberAlignRule = (JVHarmonyAlignRule()
          ..middle = JVHarmonyHorizontalRule(
              '__container__', JVHarmonyHorizontalAlign.center))
        ..numberWidth = 140
        ..numberHeight = 36
        ..loginBtnBorderColor = 0xFF112233
        ..loginBtnBorderWidth = 1.5
        ..checkBoxSize = const JVHarmonySize(18, 20)
        ..checkBoxAlignRule = (JVHarmonyAlignRule()
          ..left = JVHarmonyHorizontalRule(
              '__container__', JVHarmonyHorizontalAlign.start)
          ..bottom = JVHarmonyVerticalRule(
              '__container__', JVHarmonyVerticalAlign.bottom))
        ..checkBoxLocation = 1
        ..checkBoxShape = JVHarmonyCheckBoxShape.circle
        ..clauseTextAlign = JVHarmonyTextAlign.center
        ..clauseMargin = JVHarmonyMargin(left: 10, bottom: 24)
        ..clauseAlignRule = (JVHarmonyAlignRule()
          ..middle = JVHarmonyHorizontalRule(
              '__container__', JVHarmonyHorizontalAlign.center)
          ..center = JVHarmonyVerticalRule(
              'clause_checkBox', JVHarmonyVerticalAlign.center))
        ..privacyMarginRight = 16
        ..privacyOffsetY = 30
        ..privacyOffsetYB = 36
        ..activityIn = 'page_in'
        ..activityOut = 'page_out'
        ..windowWidth = 320
        ..windowHeight = 480
        ..windowX = 12
        ..windowY = 18
        ..windowBottom = 24
        ..themeId = 2
        ..fitsSystemWindows = true
        ..useDefaultLoginButtonImage = true
        ..webCloseImgWidth = 30
        ..webCloseImgHeight = 30
        ..webCloseImgMargin = JVHarmonyMargin(left: 16, top: 52)
        ..webCloseImgAlignRule = (JVHarmonyAlignRule()
          ..left = JVHarmonyHorizontalRule(
              '__container__', JVHarmonyHorizontalAlign.start)
          ..top = JVHarmonyVerticalRule(
              '__container__', JVHarmonyVerticalAlign.top))
        ..clauses = <JVHarmonyCMClause>[
          JVHarmonyCMClause(text: '登录即同意'),
          JVHarmonyCMClause(
            text: '《用户协议》',
            url: 'https://example.com/privacy',
            isProtocol: true,
          ),
        ]
        ..loginPage = JVHarmonyCMLoginPageConfig(
          showTitle: true,
          title: '移动登录',
          backgroundColor: 0x00000000,
          backgroundImage: 'cm_background',
          widgets: <JVHarmonyCMLoginPageWidget>[
            JVHarmonyCMLoginPageWidget(
              id: 'cm_close',
              type: JVCustomWidgetType.button,
              image: JVHarmonyImageConfig(
                name: 'cm_close_image',
                fit: JVHarmonyImageFit.cover,
              ),
              action: JVHarmonyCustomWidgetAction.dismissLoginAuth,
              toastText: '关闭移动授权页',
            ),
            JVHarmonyCMLoginPageWidget(
              id: 'cm_passive_image',
              anchor: 'cm_close',
              type: JVCustomWidgetType.image,
              image: JVHarmonyImageConfig(
                source: 'data:image/png;base64,AAAA',
              ),
              action: JVHarmonyCustomWidgetAction.none,
            ),
          ],
        )
        ..loginConfirmDialog = JVHarmonyCMLoginConfirmDialogConfig(
          message: '确认登录？',
        )
        ..windowMode = JVHarmonyWindowConfig(
          widthPercent: '80%',
          heightPercent: '50%',
          alignment: JVHarmonyDialogAlignment.bottom,
        ));

    jverify.setCustomAuthorizationView(false, config);
    await Future<void>.delayed(Duration.zero);

    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> portraitConfig =
        arguments['portraitConfig'] as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> cmConfig =
        portraitConfig['harmonyCmUIConfig'] as Map<dynamic, dynamic>;
    expect(cmConfig['authPageGrayScale'], 0.8);
    expect(
        cmConfig['numberMargin'], <String, dynamic>{'left': 12.0, 'top': 24.0});
    expect(
      cmConfig['numberAlignRule'],
      <String, dynamic>{
        'middle': <String, dynamic>{
          'anchor': '__container__',
          'align': 'center',
        },
      },
    );
    expect(cmConfig['numberWidth'], 140.0);
    expect(cmConfig['numberHeight'], 36.0);
    expect(cmConfig['loginBtnBorderColor'], 0xFF112233);
    expect(cmConfig['loginBtnBorderWidth'], 1.5);
    expect(cmConfig['checkBoxSize'], <String, dynamic>{
      'width': 18.0,
      'height': 20.0,
    });
    expect(
      cmConfig['checkBoxAlignRule'],
      <String, dynamic>{
        'left': <String, dynamic>{
          'anchor': '__container__',
          'align': 'start',
        },
        'bottom': <String, dynamic>{
          'anchor': '__container__',
          'align': 'bottom',
        },
      },
    );
    expect(cmConfig['checkBoxLocation'], 1);
    expect(cmConfig['checkBoxShape'], 'circle');
    expect(cmConfig['clauseTextAlign'], 'center');
    expect(cmConfig['clauseMargin'], <String, dynamic>{
      'left': 10.0,
      'bottom': 24.0,
    });
    expect(
      cmConfig['clauseAlignRule'],
      <String, dynamic>{
        'middle': <String, dynamic>{
          'anchor': '__container__',
          'align': 'center',
        },
        'center': <String, dynamic>{
          'anchor': 'clause_checkBox',
          'align': 'center',
        },
      },
    );
    expect(cmConfig['privacyMarginRight'], 16.0);
    expect(cmConfig['privacyOffsetY'], 30.0);
    expect(cmConfig['privacyOffsetYB'], 36.0);
    expect(cmConfig['activityIn'], 'page_in');
    expect(cmConfig['activityOut'], 'page_out');
    expect(cmConfig['windowWidth'], 320.0);
    expect(cmConfig['windowHeight'], 480.0);
    expect(cmConfig['windowX'], 12.0);
    expect(cmConfig['windowY'], 18.0);
    expect(cmConfig['windowBottom'], 24.0);
    expect(cmConfig['themeId'], 2);
    expect(cmConfig['fitsSystemWindows'], isTrue);
    expect(cmConfig['useDefaultLoginButtonImage'], isTrue);
    expect(cmConfig['webCloseImgWidth'], 30.0);
    expect(cmConfig['webCloseImgHeight'], 30.0);
    expect(cmConfig['webCloseImgMargin'], <String, dynamic>{
      'left': 16.0,
      'top': 52.0,
    });
    expect(
      cmConfig['webCloseImgAlignRule'],
      <String, dynamic>{
        'left': <String, dynamic>{
          'anchor': '__container__',
          'align': 'start',
        },
        'top': <String, dynamic>{
          'anchor': '__container__',
          'align': 'top',
        },
      },
    );
    expect(cmConfig['clauses'], hasLength(2));
    expect(cmConfig['loginPage'], containsPair('title', '移动登录'));
    expect(cmConfig['loginPage'], containsPair('backgroundColor', 0));
    expect(
      (cmConfig['loginPage'] as Map<dynamic, dynamic>)['widgets'],
      contains(containsPair('action', 'dismissLoginAuth')),
    );
    final List<dynamic> cmWidgets = (cmConfig['loginPage']
        as Map<dynamic, dynamic>)['widgets'] as List<dynamic>;
    expect(cmWidgets, hasLength(2));
    expect(cmWidgets, contains(containsPair('action', 'none')));
    expect(cmWidgets, contains(containsPair('anchor', 'cm_close')));
    final Map<dynamic, dynamic> cmWidget =
        cmWidgets.first as Map<dynamic, dynamic>;
    expect(cmWidget['image'], <String, dynamic>{
      'name': 'cm_close_image',
      'fit': 'cover',
    });
    expect(cmWidget['toastText'], '关闭移动授权页');
    expect(cmConfig['loginConfirmDialog'], containsPair('message', '确认登录？'));
    expect(
      cmConfig['windowMode'],
      containsPair('alignment', 'bottom'),
    );
    expect(cmConfig['windowMode'], containsPair('width', '80%'));
    expect(cmConfig['windowMode'], containsPair('height', '50%'));
  });

  test('HarmonyOS custom widgets keep controlled actions', () async {
    final JVCustomWidget authWidget =
        JVCustomWidget('auth_help', JVCustomWidgetType.textView)
          ..title = '帮助'
          ..isClickEnable = true
          ..harmonyBorderRadius = 6
          ..harmonyAction = JVHarmonyCustomWidgetAction.callback;
    final JVCustomWidget dialogWidget =
        JVCustomWidget('dialog_close', JVCustomWidgetType.button)
          ..title = '取消'
          ..harmonyAction = JVHarmonyCustomWidgetAction.closeCheckDialog;
    final JVUIConfig config = JVUIConfig()
      ..privacyCheckDialogConfig = (JVPrivacyCheckDialogConfig()
        ..widgets = <JVCustomWidget>[dialogWidget]);

    jverify.setCustomAuthorizationView(false, config,
        widgets: <JVCustomWidget>[authWidget]);
    await Future<void>.delayed(Duration.zero);

    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    expect(
      (arguments['widgets'] as List<dynamic>).single,
      containsPair('harmonyAction', 'callback'),
    );
    final Map<dynamic, dynamic> portrait =
        arguments['portraitConfig'] as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> dialog =
        portrait['privacyCheckDialogConfig'] as Map<dynamic, dynamic>;
    expect(
      (dialog['widgets'] as List<dynamic>).single,
      containsPair('harmonyAction', 'closeCheckDialog'),
    );
  });

  test('HarmonyOS clickable image widgets keep typed image sources', () async {
    final JVCustomWidget authImage =
        JVCustomWidget('auth_image', JVCustomWidgetType.image)
          ..harmonyImage = JVHarmonyImageConfig(
            source: 'data:image/png;base64,AAAA',
            fit: JVHarmonyImageFit.contain,
          )
          ..harmonyAction = JVHarmonyCustomWidgetAction.callback
          ..harmonyToastText = '图片已点击';
    final JVCustomWidget dialogImageButton =
        JVCustomWidget('dialog_image', JVCustomWidgetType.button)
          ..btnNormalImageName = 'dialog_close'
          ..harmonyImage = JVHarmonyImageConfig(
            name: 'dialog_close',
            fit: JVHarmonyImageFit.fill,
          )
          ..harmonyAction = JVHarmonyCustomWidgetAction.closeCheckDialog;
    final JVUIConfig config = JVUIConfig()
      ..privacyCheckDialogConfig = (JVPrivacyCheckDialogConfig()
        ..widgets = <JVCustomWidget>[dialogImageButton]);

    jverify.setCustomAuthorizationView(false, config,
        widgets: <JVCustomWidget>[authImage]);
    await Future<void>.delayed(Duration.zero);

    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> auth =
        (arguments['widgets'] as List<dynamic>).single as Map<dynamic, dynamic>;
    expect(auth['type'], 'image');
    expect(auth['isClickEnable'], isTrue);
    expect(auth['harmonyToastText'], '图片已点击');
    expect(auth['harmonyImage'], <String, dynamic>{
      'source': 'data:image/png;base64,AAAA',
      'fit': 'contain',
    });
    final Map<dynamic, dynamic> portrait =
        arguments['portraitConfig'] as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> dialog =
        portrait['privacyCheckDialogConfig'] as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> dialogButton =
        (dialog['widgets'] as List<dynamic>).single as Map<dynamic, dynamic>;
    expect(dialogButton['type'], 'button');
    expect(dialogButton['harmonyImage'], <String, dynamic>{
      'name': 'dialog_close',
      'fit': 'fill',
    });
  });

  test('China Mobile login page is a transparent overlay by default', () {
    final JVHarmonyCMLoginPageConfig page = JVHarmonyCMLoginPageConfig(
      widgets: <JVHarmonyCMLoginPageWidget>[
        JVHarmonyCMLoginPageWidget(id: 'overlay_button'),
      ],
    );

    expect(page.toJsonMap()['backgroundColor'], 0x00000000);
    expect(page.toJsonMap()['widgets'], hasLength(1));
  });

  test('setup forwards the existing public contract unchanged', () async {
    jverify.setup(
      appKey: 'test-app-key',
      channel: 'developer-default',
      useIDFA: false,
      timeout: 9000,
      setControlWifiSwitch: false,
    );
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.method, 'setup');
    expect(calls.single.arguments, <String, dynamic>{
      'appKey': 'test-app-key',
      'channel': 'developer-default',
      'useIDFA': false,
      'timeout': 9000,
      'setControlWifiSwitch': false,
    });
  });

  test('simple capability methods preserve their channel names', () async {
    respond = (MethodCall call) async {
      if (call.method == 'isInitSuccess' ||
          call.method == 'checkVerifyEnable' ||
          call.method == 'validPreloginCache') {
        return <String, dynamic>{'result': true};
      }
      return null;
    };

    jverify.setDebugMode(true);
    jverify.setCollectionAuth(true);
    expect(await jverify.isInitSuccess(), containsPair('result', true));
    expect(await jverify.checkVerifyEnable(), containsPair('result', true));
    expect(await jverify.validPreloginCache(), containsPair('result', true));
    jverify.clearPreLoginCache();
    jverify.dismissLoginAuthView();
    await Future<void>.delayed(Duration.zero);

    expect(
      calls.map((MethodCall call) => call.method),
      containsAllInOrder(<String>[
        'setDebugMode',
        'setCollectionAuth',
        'isInitSuccess',
        'checkVerifyEnable',
        'validPreloginCache',
        'clearPreLoginCache',
        'dismissLoginAuthView',
      ]),
    );
  });

  test('getSMSCode preserves named arguments and unsupported response',
      () async {
    respond = (MethodCall call) async => <String, dynamic>{
          'code': -2,
          'message': 'getSMSCode is not supported on HarmonyOS',
        };

    final Map<dynamic, dynamic> result = await jverify.getSMSCode(
      phoneNum: '13800138000',
      signId: 'sign',
      tempId: 'template',
    );

    expect(calls.single.method, 'getSMSCode');
    expect(calls.single.arguments, <String, String>{
      'phoneNumber': '13800138000',
      'signId': 'sign',
      'tempId': 'template',
    });
    expect(result['code'], -2);
  });

  test('loginAuth future preserves timeout and completion map', () async {
    respond = (MethodCall call) async => <String, dynamic>{
          'code': 6000,
          'message': 'login-token',
          'operator': 'CM',
        };

    final Map<dynamic, dynamic> result = await jverify.loginAuth(
      true,
      timeout: 8000,
    );

    expect(calls.single.method, 'loginAuth');
    expect(calls.single.arguments, <String, dynamic>{
      'autoDismiss': true,
      'timeout': 8000,
    });
    expect(result['message'], 'login-token');
  });

  test('sync login callback and page event are routed by request index',
      () async {
    JVListenerEvent? loginEvent;
    JVAuthPageEvent? pageEvent;
    jverify.loginAuthSyncApi2(
      autoDismiss: false,
      timeout: 9000,
      loginAuthcallback: (JVListenerEvent event) => loginEvent = event,
      pageEventCallback: (JVAuthPageEvent event) => pageEvent = event,
    );
    await Future<void>.delayed(Duration.zero);
    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    final int index = arguments['loginAuthIndex'] as int;

    await invokeNative(MethodCall(
      'onReceiveAuthPageEvent',
      <String, dynamic>{
        'code': 1,
        'message': 'page shown',
        'loginAuthIndex': index,
      },
    ));
    await invokeNative(MethodCall(
      'onReceiveLoginAuthCallBackEvent',
      <String, dynamic>{
        'code': 6000,
        'message': 'login-token',
        'operator': 'CM',
        'loginAuthIndex': index,
      },
    ));
    await invokeNative(MethodCall(
      'onReceiveAuthPageEvent',
      <String, dynamic>{
        'code': 2,
        'message': 'late page event',
        'loginAuthIndex': index,
      },
    ));

    expect(calls.single.method, 'loginAuthSyncApi');
    expect(pageEvent?.message, 'page shown');
    expect(loginEvent?.message, 'login-token');
  });

  test('setup and custom widget events reach registered listeners', () async {
    JVSDKSetupEvent? setupEvent;
    String? widgetId;
    jverify.addSDKSetupCallBackListener(
      (JVSDKSetupEvent event) => setupEvent = event,
    );
    jverify.addClikWidgetEventListener(
      'harmony_widget',
      (String eventId) => widgetId = eventId,
    );

    await invokeNative(const MethodCall(
      'onReceiveSDKSetupCallBackEvent',
      <String, dynamic>{'code': 8000, 'message': 'initialized'},
    ));
    await invokeNative(const MethodCall(
      'onReceiveClickWidgetEvent',
      <String, dynamic>{'widgetId': 'harmony_widget'},
    ));

    expect(setupEvent?.code, 8000);
    expect(widgetId, 'harmony_widget');
  });

  test('continuous listeners can be removed without affecting others',
      () async {
    int firstAuthEvents = 0;
    int secondAuthEvents = 0;
    int widgetEvents = 0;
    void firstAuthListener(JVAuthPageEvent event) => firstAuthEvents++;
    void secondAuthListener(JVAuthPageEvent event) => secondAuthEvents++;

    jverify.addAuthPageEventListener(firstAuthListener);
    jverify.addAuthPageEventListener(secondAuthListener);
    jverify.addClikWidgetEventListener(
      'removable_widget',
      (String id) => widgetEvents++,
    );
    expect(jverify.removeAuthPageEventListener(firstAuthListener), isTrue);
    expect(jverify.removeClikWidgetEventListener('removable_widget'), isTrue);

    await invokeNative(const MethodCall(
      'onReceiveAuthPageEvent',
      <String, dynamic>{'code': 1, 'message': 'shown'},
    ));
    await invokeNative(const MethodCall(
      'onReceiveClickWidgetEvent',
      <String, dynamic>{'widgetId': 'removable_widget'},
    ));
    expect(firstAuthEvents, 0);
    expect(secondAuthEvents, 1);
    expect(widgetEvents, 0);

    jverify.offAuthPageEvent();
    jverify.removeCustomViewsClickCallback();
  });

  test('deprecated verifyNumber remains a completed compatibility result',
      () async {
    final Map<dynamic, dynamic> result =
        await jverify.verifyNumber('13800138000', token: 'unused');

    expect(result, containsPair('error', 'This interface is deprecated'));
    expect(calls, isEmpty);
  });

  test('legacy custom UI method keeps uiconfig and widgets contract', () async {
    final JVUIConfig config = JVUIConfig()..logBtnText = '登录';
    final JVCustomWidget widget =
        JVCustomWidget('widget', JVCustomWidgetType.textView)..title = '说明';

    jverify
        .setCustomAuthViewAllWidgets(config, widgets: <JVCustomWidget>[widget]);
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.method, 'setCustomAuthViewAllWidgets');
    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    expect(arguments['uiconfig'], containsPair('logBtnText', '登录'));
    expect(arguments['widgets'], hasLength(1));
  });

  test('getToken rejects a repeated request until the first future completes',
      () async {
    final Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();
    respond = (MethodCall call) {
      if (call.method == 'getToken') {
        return completer.future;
      }
      return Future<dynamic>.value(null);
    };

    final Future<Map<dynamic, dynamic>> first = jverify.getToken();
    final Map<dynamic, dynamic> repeated = await jverify.getToken();
    expect(repeated['code'], Jverify.j_flutter_error_code_repeat);
    expect(calls.where((MethodCall call) => call.method == 'getToken'),
        hasLength(1));

    completer.complete(<String, dynamic>{
      'code': 2000,
      'message': 'complete-token',
      'operator': 'CM',
    });
    expect(await first, containsPair('message', 'complete-token'));
  });

  test('preLogin omits an invalid timeout and keeps enableSms', () async {
    respond = (MethodCall call) async => <String, dynamic>{
          'code': 7000,
          'message': 'ok',
          'operator': 'CM',
        };

    await jverify.preLogin(timeOut: 2999, enableSms: true);

    expect(calls.single.method, 'preLogin');
    expect(calls.single.arguments, <String, dynamic>{'enableSms': true});
  });

  test('HarmonyOS SMS callback can route the native not-supported result',
      () async {
    JVSMSEvent? received;
    int pageEvents = 0;
    jverify.smsAuth(
      autoDismiss: true,
      smsCallback: (JVSMSEvent event) => received = event,
      pageEventCallback: (JVAuthPageEvent event) => pageEvents++,
    );
    await Future<void>.delayed(Duration.zero);
    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;

    await invokeNative(MethodCall(
      'onReceiveSMSAuthCallBackEvent',
      <String, dynamic>{
        'code': -2,
        'message': 'smsAuth is not supported on HarmonyOS',
        'smsAuthIndex': arguments['smsAuthIndex'],
      },
    ));
    await invokeNative(MethodCall(
      'onReceiveSMSAuthPageEvent',
      <String, dynamic>{
        'code': 1,
        'message': 'late page event',
        'smsAuthIndex': arguments['smsAuthIndex'],
      },
    ));

    expect(received?.code, -2);
    expect(received?.message, contains('not supported'));
    expect(pageEvents, 0);
  });

  test('authorization back event reaches the configured Dart listener',
      () async {
    int pressed = 0;
    final JVUIConfig config = JVUIConfig()
      ..authPageBackPressedListener = () => pressed++;
    jverify.setCustomAuthorizationView(false, config);
    await Future<void>.delayed(Duration.zero);

    await invokeNative(
      const MethodCall('onReceiveAuthPageBackPressedEvent'),
    );

    expect(pressed, 1);
  });

  test('legacy login callbacks are dispatched once without mutating iteration',
      () async {
    final List<int?> codes = <int?>[];
    jverify.addLoginAuthCallBackListener(
      (JVListenerEvent event) => codes.add(event.code),
    );
    jverify.addLoginAuthCallBackListener(
      (JVListenerEvent event) => codes.add(event.code),
    );

    await invokeNative(const MethodCall(
      'onReceiveLoginAuthCallBackEvent',
      <String, dynamic>{'code': 6000, 'message': 'token', 'operator': 'CM'},
    ));
    await invokeNative(const MethodCall(
      'onReceiveLoginAuthCallBackEvent',
      <String, dynamic>{'code': 6001, 'message': 'failed', 'operator': 'CM'},
    ));

    expect(codes, <int?>[6000, 6000]);
  });

  test('SMS compatibility API keeps the existing channel contract', () async {
    jverify.setGetCodeInternal(30000);
    await Future<void>.delayed(Duration.zero);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'setGetCodeInternal');
    expect(calls.single.arguments, <String, int>{'timeInterval': 30000});
  });

  test('privacy compatibility fields are serialized for HarmonyOS', () async {
    final JVUIConfig config = JVUIConfig()
      ..privacyItem = <JVPrivacy>[
        JVPrivacy('用户协议', 'https://example.com/privacy', separator: '、'),
      ]
      ..isAlertPrivacyVc = true
      ..privacyCheckDialogConfig =
          (JVPrivacyCheckDialogConfig()..enablePrivacyCheckDialog = false);

    jverify.setCustomAuthorizationView(false, config);
    await Future<void>.delayed(Duration.zero);

    final Map<dynamic, dynamic> arguments =
        calls.single.arguments as Map<dynamic, dynamic>;
    final Map<dynamic, dynamic> portraitConfig =
        arguments['portraitConfig'] as Map<dynamic, dynamic>;
    final List<dynamic> privacyItems =
        jsonDecode(portraitConfig['privacyItem'] as String) as List<dynamic>;
    expect(privacyItems, <Map<String, dynamic>>[
      <String, dynamic>{
        'name': '用户协议',
        'url': 'https://example.com/privacy',
        'separator': '、',
      },
    ]);
    expect(portraitConfig['isAlertPrivacyVc'], isTrue);
    expect(
      portraitConfig['privacyCheckDialogConfig'],
      containsPair('enablePrivacyCheckDialog', false),
    );
  });
}
