import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../extensions.dart';
import '../../features/ms_store/ms_store_page.dart';
import '../../features/ms_store/ms_store_product_page.dart';
import '../../features/tweaks/performance/performance_page.dart';
import '../../features/tweaks/personalization/personalization_page.dart';
import '../../features/tweaks/security/security_page.dart';
import '../../features/tweaks/updates/updates_page.dart';
import '../../features/tweaks/utilities/utilities_page.dart';
import '../../main.dart';
import '../services/win_registry_service.dart';
import '../settings/settings_page.dart';
import '../widgets/unsupported_widget.dart';
import 'app_routes.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialRoute ?? RouteMeta.tweaksSecurity.path,
    redirect: (context, state) {
      if (!WinRegistryService.isSupported) {
        return AppRoutes.unsupported;
      }
      return null; // Allow navigation
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(shellContext: context, child: child);
        },
        routes: [
          // 5 个调整页提升为顶级路由,与 msstore/settings 同级,
          // 通过左栏直接切换(行为与其它顶级项一致)。
          GoRoute(
            path: RouteMeta.tweaksSecurity.path,
            name: 'security',
            builder: (context, state) => const SecurityPage(),
          ),
          GoRoute(
            path: RouteMeta.tweaksPerformance.path,
            name: 'performance',
            builder: (context, state) => const PerformancePage(),
          ),
          GoRoute(
            path: RouteMeta.tweaksPersonalization.path,
            name: 'personalization',
            builder: (context, state) => const PersonalizationPage(),
          ),
          GoRoute(
            path: RouteMeta.tweaksUtilities.path,
            name: 'utilities',
            builder: (context, state) => const UtilitiesPage(),
          ),
          GoRoute(
            path: RouteMeta.tweaksUpdates.path,
            name: 'updates',
            builder: (context, state) => const UpdatesPage(),
          ),
          GoRoute(
            path: RouteMeta.msStore.path,
            name: 'msstore',
            builder: (context, state) => const MSStorePage(),
            routes: [
              GoRoute(
                path: 'product/:productId',
                name: 'msstore-product',
                pageBuilder: (context, state) {
                  // final SearchProduct? product = state.extra is SearchProduct
                  //     ? state.extra! as SearchProduct
                  //     : null;
                  final String productId = state.pathParameters['productId']!;

                  return AppRoutes.buildPageWithHorizontalTransition(
                    barrierColor: context.theme.scaffoldBackgroundColor,
                    state: state,
                    child: MSStoreProductPage(productId: productId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteMeta.settings.path,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.unsupported,
        builder: (context, state) => const UnsupportedWidget(),
      ),
    ],
  );

  return router;
}
