import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../dialogs/context_menu.dart';

import 'button.dart';

/// Button that shows a context menu when pressed.
class ContextMenuButton<T> extends StatefulWidget {
  ///
  const ContextMenuButton(
    this.child, {
    required this.itemBuilder,
    this.value,
    this.color,
    this.onSelected,
    this.onCanceled,
    this.padding,
    this.tooltip,
    this.enabled = true,
    Key? key,
  }) : super(key: key);

  /// The body of the button.
  final Widget child;

  /// The color of the button.
  final HSLColor? color;

  /// The list of [ContextMenuItem] used for the context menu.
  final ContextMenuItemBuilder<T> itemBuilder;

  /// The current value in the context menu.
  final T? value;

  /// Called when the context menu selection changes.
  final ContextMenuItemSelected<T>? onSelected;

  /// Called when the user cancels the context menu selection.
  final ContextMenuCanceled? onCanceled;

  /// The button tooltip;
  final String? tooltip;

  /// If this button is enabled.
  final bool enabled;

  /// The button padding.
  final EdgeInsets? padding;

  @override
  _ContextMenuButtonState<T> createState() => _ContextMenuButtonState<T>();
}

class _ContextMenuButtonState<T> extends State<ContextMenuButton<T>> {
  Future<void> showButtonMenu(BuildContext context) async {
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

    await showMenu<T>(
      context: context,
      items: items,
      initialValue: widget.value,
      position: position,
      settings: const RouteSettings(),
    ).then<void>((T? newValue) {
      if (!mounted) {
        return null;
      }

      if (newValue == null) {
        if (widget.onCanceled != null) {
          widget.onCanceled!();
        }
        return null;
      }

      if (widget.onSelected != null) {
        widget.onSelected!(newValue);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      padding: widget.padding,
      bodyPadding: widget.padding != null ? EdgeInsets.zero : null,
      body: widget.child,
      onPressed: widget.enabled ? () => showButtonMenu(context) : null,
      tooltip: widget.tooltip,
    );
  }
}
