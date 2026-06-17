import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart' as msicons;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/card_highlight.dart';
import '../../../../i18n/generated/strings.g.dart';
import '../performance_service.dart';

class PowerplanSection extends ConsumerWidget {
  const PowerplanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PowerPlanMode mode = ref.watch(powerPlanModeStatusProvider);
    final bool masterOn = mode != PowerPlanMode.off;
    final service = ref.read(performanceServiceProvider);

    // 应用某个模式并刷新相关状态(切换会建一个、删另一个)
    Future<void> applyMode(PowerPlanMode target) async {
      await service.setPowerPlanMode(target);
      ref.invalidate(powerPlanModeStatusProvider);
      ref.invalidate(reviPowerPlanC6StatesStatusProvider);
    }

    return CardHighlight(
      icon: msicons.FluentIcons.rocket_20_regular,
      label: t.tweaksPerformancePowerPlan,
      description: t.tweaksPerformancePowerPlanDescription,
      // 受控展开:主开关 ON 自动展开露出方案选择,OFF 收起
      expanded: masterOn,
      action: CardToggleSwitch(
        value: masterOn,
        onChanged: (value) async {
          // ON → 默认启用"标准";OFF → 停用全部,系统回落 Balanced
          await applyMode(value ? PowerPlanMode.standard : PowerPlanMode.off);
        },
      ),
      children: [
        // 标准(= 现有 Revision 调校)
        CardListTile(
          title: t.tweaksPerformancePowerPlanStandard,
          description: t.tweaksPerformancePowerPlanStandardDescription,
          trailing: CardToggleSwitch(
            value: mode == PowerPlanMode.standard,
            onChanged: (value) async {
              // 恰好选一个:仅"开"有效;点已选中的(value=false)无操作
              if (value) await applyMode(PowerPlanMode.standard);
            },
          ),
        ),

        // C-States 仅在"标准"选中时出现(Revision 方案专属子选项)
        if (mode == PowerPlanMode.standard)
          CardListTile(
            title: t.tweaksPerformanceCStates,
            description: t.tweaksPerformanceCStatesDescription,
            trailing: CardToggleSwitch(
              value: ref.watch(reviPowerPlanC6StatesStatusProvider),
              onChanged: (value) async {
                value
                    ? await service.disableReviPowerPlanC6States()
                    : await service.enableReviPowerPlanC6States();
                ref.invalidate(reviPowerPlanC6StatesStatusProvider);
              },
            ),
          ),

        // 极限(= AMD 调校)
        CardListTile(
          title: t.tweaksPerformancePowerPlanExtreme,
          description: t.tweaksPerformancePowerPlanExtremeDescription,
          trailing: CardToggleSwitch(
            value: mode == PowerPlanMode.extreme,
            onChanged: (value) async {
              if (value) await applyMode(PowerPlanMode.extreme);
            },
          ),
        ),
      ],
    );
  }
}
