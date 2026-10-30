import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/util/native/tray_helper.dart';
import 'package:localsend_app/widget/watcher/window_watcher.dart';
import 'package:mockito/mockito.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window_manager');
  final calls = <String>[];
  bool minimized = false;
  bool failHide = false;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    calls.clear();
    minimized = false;
    failHide = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isMinimized') return minimized;
      if (call.method == 'hide' && failHide) throw PlatformException(code: 'hide_failed');
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<RefenaContainer> mountWatcher(WidgetTester tester, {required bool trayEnabled}) async {
    final persistence = MockPersistenceService();
    when(persistence.isMinimizeToTray()).thenReturn(trayEnabled);
    final container = RefenaContainer(overrides: [persistenceProvider.overrideWithValue(persistence)]);
    await tester.pumpWidget(RefenaScope(
      container: container,
      child: const WindowWatcher(child: SizedBox()),
    ));
    await tester.pump();
    calls.clear();
    return container;
  }

  testWidgets('Windows minimize hides the window when tray mode is enabled', (tester) async {
    final container = await mountWatcher(tester, trayEnabled: true);
    final listener = tester.state(find.byType(WindowWatcher)) as WindowListener;
    listener.onWindowMinimize();
    await tester.pump();
    expect(calls, contains('hide'));
    expect(container.read(sleepProvider), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Windows minimize keeps normal taskbar behavior when tray mode is disabled', (tester) async {
    final container = await mountWatcher(tester, trayEnabled: false);
    final listener = tester.state(find.byType(WindowWatcher)) as WindowListener;
    listener.onWindowMinimize();
    await tester.pump();
    expect(calls, isNot(contains('hide')));
    expect(container.read(sleepProvider), isTrue);
  });

  testWidgets('Linux minimize behavior is unchanged', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await mountWatcher(tester, trayEnabled: true);
    final listener = tester.state(find.byType(WindowWatcher)) as WindowListener;
    listener.onWindowMinimize();
    await tester.pump();
    expect(calls, isNot(contains('hide')));
  });

  testWidgets('A native hide failure does not crash the app', (tester) async {
    await mountWatcher(tester, trayEnabled: true);
    failHide = true;
    final listener = tester.state(find.byType(WindowWatcher)) as WindowListener;
    listener.onWindowMinimize();
    await tester.pump();
    expect(calls, contains('hide'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Opening a minimized tray window restores it before showing and focusing', (tester) async {
    await mountWatcher(tester, trayEnabled: true);
    minimized = true;
    await showFromTray();
    expect(calls, ['isMinimized', 'restore', 'show', 'focus']);
  });

  testWidgets('Opening a hidden but not minimized window does not restore it', (tester) async {
    await mountWatcher(tester, trayEnabled: true);
    await showFromTray();
    expect(calls, ['isMinimized', 'show', 'focus']);
  });

  testWidgets('Linux tray opening does not invoke Windows restoration', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await mountWatcher(tester, trayEnabled: true);
    await showFromTray();
    expect(calls, ['show', 'focus']);
  });
}
