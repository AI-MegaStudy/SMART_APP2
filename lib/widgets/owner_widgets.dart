import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_app/util/app_colors.dart';

void showOwnerSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

Future<void> showConfirmAction({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '확인',
  bool destructive = false,
  required VoidCallback onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: destructive
                      ? FilledButton.styleFrom(backgroundColor: Colors.red)
                      : null,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    onConfirm();
  }
}

Future<void> showInfoAction({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = '확인',
  VoidCallback? onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(confirmLabel),
            ),
          ),
        ],
      );
    },
  );
  onConfirm?.call();
}

String objectParticle(String text) {
  if (text.isEmpty) return '을';
  final code = text.characters.last.runes.first;
  if (code < 0xAC00 || code > 0xD7A3) return '를';
  return (code - 0xAC00) % 28 == 0 ? '를' : '을';
}

String subjectParticle(String text) {
  if (text.isEmpty) return '이';
  final code = text.characters.last.runes.first;
  if (code < 0xAC00 || code > 0xD7A3) return '가';
  return (code - 0xAC00) % 28 == 0 ? '가' : '이';
}

String requiredMessage(String label) => '$label${objectParticle(label)} 입력하세요.';

String invalidMessage(String label) =>
    '올바른 $label${subjectParticle(label)} 아닙니다.';

String? requiredValidator(String label, String? value) {
  if ((value ?? '').trim().isEmpty) return requiredMessage(label);
  return null;
}

String? regexValidator({
  required String label,
  required String? value,
  required RegExp pattern,
  String? invalidText,
}) {
  final required = requiredValidator(label, value);
  if (required != null) return required;
  return pattern.hasMatch(value!.trim())
      ? null
      : invalidText ?? invalidMessage(label);
}

String? nameValidator(String? value) => regexValidator(
  label: '이름',
  value: value,
  pattern: RegExp(r'^[가-힣a-zA-Z\s]{2,20}$'),
);

String? emailValidator(String? value) => regexValidator(
  label: '이메일',
  value: value,
  pattern: RegExp(r'^[\w.\-]+@[\w\-]+(\.[\w\-]+)+$'),
);

String? passwordValidator(String? value) => regexValidator(
  label: '비밀번호',
  value: value,
  pattern: RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,20}$'),
  invalidText: '비밀번호는 영문과 숫자를 포함해 8~20자로 입력하세요.',
);

String? phoneValidator(String? value) =>
    regexValidator(label: '전화번호', value: value, pattern: RegExp(r'^\d{9,11}$'));

String? businessValidator(String? value) =>
    regexValidator(label: '사업자번호', value: value, pattern: RegExp(r'^\d{10}$'));

String? invoiceValidator(String? value) =>
    regexValidator(label: '송장번호', value: value, pattern: RegExp(r'^\d{8,20}$'));

String? numberValidator(String label, String? value) {
  final required = requiredValidator(label, value);
  if (required != null) return required;
  return RegExp(r'^\d+$').hasMatch(value!.trim())
      ? null
      : invalidMessage(label);
}

String? numericValidator(String? value) {
  if ((value ?? '').trim().isEmpty) return '값을 입력하세요.';
  return RegExp(r'^\d+$').hasMatch(value!.trim()) ? null : '숫자만 입력하세요.';
}

String? phoneNumberValidator(String? value) => phoneValidator(value);

String? businessNumberValidator(String? value) => businessValidator(value);

String? invoiceNumberValidator(String? value) => invoiceValidator(value);

class AppScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;

  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing ?? const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            SliverList.separated(
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: children[index],
              ),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: children.length,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData icon;
  final bool compact;

  const HeroPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            bottom: -10,
            child: Icon(
              icon,
              size: compact ? 112 : 132,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                eyebrow,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 26,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GridCards extends StatelessWidget {
  final List<Widget> children;

  const GridCards({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 520 ? 4 : 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.22,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.text, size: 24),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;
  final Color iconBackground;
  final Color iconColor;
  final TextStyle? subtitleStyle;
  final bool showChevron;

  const DataTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    this.onTap,
    this.iconBackground = AppColors.mint,
    this.iconColor = AppColors.green,
    this.subtitleStyle,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ).merge(subtitleStyle),
                    ),
                  ],
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 10),
                StatusBadge(text: badge, color: badgeColor),
              ],
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: iconColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const SectionHeader({super.key, required this.title, this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (actionText != null)
          Text(
            actionText!,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class LabeledField extends StatefulWidget {
  final String label;
  final String value;
  final String? hintText;
  final String? helperText;
  final String? regexHint;
  final bool enabled;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? suffixText;
  final int maxLength;
  final bool obscureText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  const LabeledField({
    super.key,
    required this.label,
    required this.value,
    this.hintText,
    this.helperText,
    this.regexHint,
    this.enabled = true,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.suffixText,
    this.maxLength = 20,
    this.obscureText = false,
    this.readOnly = false,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late final FocusNode focusNode;
  late final bool ownsFocusNode;
  late final VoidCallback focusListener;

  @override
  void initState() {
    super.initState();
    ownsFocusNode = widget.focusNode == null;
    focusNode = widget.focusNode ?? FocusNode();
    focusListener = () => setState(() {});
    focusNode.addListener(focusListener);
  }

  @override
  void dispose() {
    focusNode.removeListener(focusListener);
    if (ownsFocusNode) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = !widget.enabled
        ? AppColors.muted
        : widget.readOnly
        ? AppColors.muted.withValues(alpha: 0.55)
        : AppColors.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.label),
        const SizedBox(height: 7),
        TextFormField(
          focusNode: focusNode,
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.value : null,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          style: TextStyle(color: textColor),
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator:
              widget.validator ??
              (widget.enabled
                  ? (text) => requiredValidator(widget.label, text)
                  : null),
          decoration: InputDecoration(
            hintText: widget.hintText ?? widget.label,
            hintStyle: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.55),
            ),
            helperText: focusNode.hasFocus
                ? widget.helperText ?? widget.regexHint
                : null,
            errorText: widget.errorText,
            suffix: widget.suffixText == null ? null : Text(widget.suffixText!),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

class LabeledNumberField extends StatelessWidget {
  final String label;
  final String value;
  final String suffixText;
  final String? hintText;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;

  const LabeledNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.suffixText,
    this.hintText,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      value: value,
      controller: controller,
      hintText: hintText ?? label,
      regexHint: '숫자만 입력',
      keyboardType: TextInputType.number,
      inputFormatters: const [DigitsOnlyInputFormatter()],
      validator:
          validator ??
          (text) {
            final base = numericValidator(text);
            return base == null ? null : requiredMessage(label);
          },
      suffixText: suffixText,
    );
  }
}

class LabeledBox extends StatelessWidget {
  final String label;
  final String value;
  final String? hintText;
  final bool enabled;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool required;
  final int maxLength;
  final bool showCounter;

  const LabeledBox({
    super.key,
    required this.label,
    required this.value,
    this.hintText,
    this.enabled = true,
    this.controller,
    this.validator,
    this.required = true,
    this.maxLength = 300,
    this.showCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          enabled: enabled,
          minLines: 3,
          maxLines: 4,
          maxLength: maxLength,
          style: TextStyle(color: enabled ? AppColors.text : AppColors.muted),
          validator:
              validator ??
              (required && enabled
                  ? (text) => requiredValidator(label, text)
                  : null),
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: TextStyle(
              color: AppColors.muted.withValues(alpha: 0.55),
            ),
            counterText: showCounter ? null : '',
          ),
        ),
      ],
    );
  }
}

class LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hintText;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: value.isEmpty ? '' : value,
          isExpanded: true,
          alignment: AlignmentDirectional.centerStart,
          menuMaxHeight: kMinInteractiveDimension * 5,
          items: [
            const DropdownMenuItem(
              value: '',
              alignment: Alignment.centerLeft,
              child: Text('선택하세요.'),
            ),
            for (final item in items)
              DropdownMenuItem(
                value: item,
                alignment: Alignment.centerLeft,
                child: Text(item),
              ),
          ],
          onChanged: onChanged,
          validator: (text) =>
              (text ?? '').trim().isEmpty ? requiredMessage(label) : null,
          decoration: InputDecoration(hintText: hintText ?? label),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class NoticeBox extends StatelessWidget {
  final Color color;
  final String text;

  const NoticeBox({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

class FilterTabs extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onChanged;

  const FilterTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final label in labels) ...[
            ChoiceChip(
              selected: selected == label,
              label: Text(label),
              showCheckmark: true,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.green,
              labelStyle: TextStyle(
                color: selected == label ? Colors.white : AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
              onSelected: (_) => onChanged(label),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class ActionChipIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const ActionChipIcon({super.key, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: AppColors.mint,
        foregroundColor: AppColors.green,
      ),
      onPressed: onPressed ?? () {},
      icon: Icon(icon),
    );
  }
}

class DualActionBar extends StatelessWidget {
  final String left;
  final String right;
  final VoidCallback? onLeftPressed;
  final VoidCallback? onRightPressed;

  const DualActionBar({
    super.key,
    required this.left,
    required this.right,
    this.onLeftPressed,
    this.onRightPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: onLeftPressed ?? () {},
              child: Text(left),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: onRightPressed ?? () {},
              child: Text(right),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;

  const PrimaryAction({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FilledButton(
        style: backgroundColor == null
            ? null
            : FilledButton.styleFrom(backgroundColor: backgroundColor),
        onPressed: onPressed ?? () {},
        child: Text(label),
      ),
    );
  }
}

class YieldChart extends StatelessWidget {
  const YieldChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        height: 1,
                        color: AppColors.line.withValues(alpha: 0.7),
                      ),
                  ],
                ),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Bar(height: 54),
                    _Bar(height: 78),
                    _Bar(height: 104),
                    _Bar(height: 92),
                    _Bar(height: 68),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ChartLabel('10.12'),
              _ChartLabel('10.13'),
              _ChartLabel('10.14'),
              _ChartLabel('10.15'),
              _ChartLabel('10.16'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;

  const _Bar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String label;

  const _ChartLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CameraPreviewCard extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool hasImage;
  final Uint8List? imageBytes;
  final Offset inspectionAnchor;
  final ValueChanged<Offset>? onInspectionAnchorChanged;

  const CameraPreviewCard({
    super.key,
    this.icon = Icons.local_florist,
    this.label,
    this.hasImage = false,
    this.imageBytes,
    this.inspectionAnchor = const Offset(0.5, 0.72),
    this.onInspectionAnchorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: hasImage
              ? const [Color(0xff9F2F25), Color(0xffE57352), Color(0xffF6B38D)]
              : const [Color(0xffF4F7F1), Color(0xffDCECE4)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (imageBytes != null)
            Positioned.fill(
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else
            Center(
              child: Icon(
                icon,
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.84)
                    : AppColors.green.withValues(alpha: 0.28),
                size: hasImage ? 118 : 82,
              ),
            ),
          if (label != null)
            Positioned(
              left: 16,
              top: 16,
              child: StatusBadge(text: label!, color: Colors.white),
            ),
          if (hasImage)
            _InspectionOverlayTool(
              anchor: inspectionAnchor,
              onChanged: onInspectionAnchorChanged,
            ),
          if (!hasImage)
            const Center(
              child: Text(
                '갤러리에서 이미지를 선택하세요',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InspectionOverlayTool extends StatelessWidget {
  final Offset anchor;
  final ValueChanged<Offset>? onChanged;

  const _InspectionOverlayTool({required this.anchor, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left = (anchor.dx * constraints.maxWidth).clamp(
          16.0,
          constraints.maxWidth - 42.0,
        );
        final top = (anchor.dy * constraints.maxHeight).clamp(
          16.0,
          constraints.maxHeight - 42.0,
        );
        return Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            onPanUpdate: (details) {
              final next = Offset(
                ((left + details.delta.dx) / constraints.maxWidth).clamp(
                  0.0,
                  1.0,
                ),
                ((top + details.delta.dy) / constraints.maxHeight).clamp(
                  0.0,
                  1.0,
                ),
              );
              onChanged?.call(next);
            },
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DashTextInputFormatter extends TextInputFormatter {
  final List<int> groups;

  const DashTextInputFormatter(this.groups);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    var offset = 0;
    for (final size in groups) {
      if (offset >= digits.length) break;
      final end = (offset + size).clamp(0, digits.length);
      if (buffer.isNotEmpty) buffer.write('-');
      buffer.write(digits.substring(offset, end));
      offset = end;
    }
    if (offset < digits.length) {
      if (buffer.isNotEmpty) buffer.write('-');
      buffer.write(digits.substring(offset));
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class DigitsOnlyInputFormatter extends TextInputFormatter {
  const DigitsOnlyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
