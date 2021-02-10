import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'context_menu.dart';
import 'tooltip.dart';
import 'icons.dart';
import 'theme.dart';
import 'theme_color.dart';
import 'theme_text.dart';
import 'desktop.dart';

class DropDownButton<T> extends StatefulWidget {
  const DropDownButton({
    Key? key,
    required this.itemBuilder,
    this.value,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.isField = false,
    this.enabled = true,
  }) : super(key: key);

  final ContextMenuItemBuilder<T> itemBuilder;

  final T? value;

  final ContextMenuItemSelected<T>? onSelected;

  final ContextMenuCanceled? onCanceled;

  final String? tooltip;

  final bool isField;

  final bool enabled;

  @override
  _DropDownButtonState<T> createState() => _DropDownButtonState<T>();
}

class _DropDownButtonState<T> extends State<DropDownButton<T>>
    with ComponentStateMixin {
  void showButtonMenu() async {
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context)!.context.findRenderObject()! as RenderBox;

    final Rect position = Rect.fromPoints(
      button.localToGlobal(
        Offset.zero,
        ancestor: overlay,
      ),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    );

    final List<ContextMenuEntry<T>> items = widget.itemBuilder(context);

    assert(items.isNotEmpty);

    setState(() => waiting = true);

    await showMenu<T>(
      context: context,
      items: items,
      initialValue: widget.value,
      position: position,
      width: button.size.width,
      settings: RouteSettings(),
    ).then<void>((T? newValue) {
      if (!mounted) return null;

      if (newValue == null) {
        if (widget.onCanceled != null) widget.onCanceled!();
        return null;
      }

      if (widget.onSelected != null) widget.onSelected!(newValue);
    });

    setState(() => waiting = false);
  }

  void _handleHoverEntered() {
    if (!hovered) setState(() => hovered = true);
  }

  void _handleHoverExited() {
    if (hovered) setState(() => hovered = false);
  }

  void _handleTapDown(TapDownDetails event) {
    if (!pressed) setState(() => pressed = true);
  }

  void _handleTapUp(TapUpDetails event) {
    if (pressed) setState(() => pressed = false);
  }

  void _handleTapCancel() {
    if (pressed) setState(() => pressed = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final TextStyle textStyle = textTheme.body1.copyWith(fontSize: 14.0);
    final enabled = widget.enabled;

    Widget child;
    HSLColor? inactiveBackground;

    if (widget.value != null) {
      child = widget
          .itemBuilder(context)
          .firstWhere((value) => value.represents(widget.value!));
      inactiveBackground = colorScheme.background;
    } else {
      child = Container();
    }

    final waitingBackground = colorScheme.background3;

    Border border;

    final borderColor = waiting
        ? waitingBackground
        : hovered
            ? colorScheme.background2
            : colorScheme.background1;

    border = Border.all(color: borderColor.toColor(), width: 1.0);

    final background = waiting ? waitingBackground : inactiveBackground;

    final foreground = textTheme.textMedium;

    Widget result = DefaultTextStyle(
      style: textStyle,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinMenuHeight,
          minWidth: kMinMenuWidth,
          maxHeight: kMaxMenuHeight,
          maxWidth: kMaxMenuWidth,
        ),
        decoration: BoxDecoration(
          color: background?.toColor(),
          border: border,
        ),
        //constraints: constraints,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IgnorePointer(
              ignoring: true,
              child: child,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.expand_more,
                size: 18.0,
                color: foreground.toColor(),
              ),
            ),
          ],
        ),
      ),
    );

    if (enabled) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _handleHoverEntered(),
        onExit: (_) => _handleHoverExited(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: showButtonMenu,
          child: result,
        ),
      );
    }

    result = Semantics(
      button: true,
      child: result,
    );

    if (widget.tooltip != null) {
      result = Tooltip(
        message: widget.tooltip!, // FIXME
        child: result,
      );
    }

    return result;
  }
}