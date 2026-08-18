import 'package:flutter/material.dart';
import 'package:group_expense_tracker/util/ext/text_util.dart';

/// One entry of [ExpandableFabWidget]'s menu.
class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// The dashboard's single floating action button, which fans out into its
/// actions when tapped.
///
/// One button instead of a stack of them: the dashboard has two ways to create
/// an expense and will likely grow more, and a column of identical circles
/// gives the user no clue which does what. Expanding puts a label next to every
/// icon and turns the plus into a close, so the menu explains itself.
class ExpandableFabWidget extends StatefulWidget {
  /// Listed top to bottom above the main button, in the order given.
  final List<FabAction> actions;

  const ExpandableFabWidget({super.key, required this.actions});

  @override
  State<ExpandableFabWidget> createState() => _ExpandableFabWidgetState();
}

class _ExpandableFabWidgetState extends State<ExpandableFabWidget> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  /// Collapses the menu before running the action, so the screen it opens is
  /// not left sitting behind an expanded FAB when the user comes back.
  void _run(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final action in widget.actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _actionRow(context, action),
          ),
        FloatingActionButton(
          heroTag: "fab_main",
          shape: const CircleBorder(),
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Kept mounted while collapsed but scaled to nothing, so the buttons grow
  /// out of the main FAB rather than popping in at full size.
  Widget _actionRow(BuildContext context, FabAction action) {
    return AnimatedScale(
      scale: _open ? 1 : 0,
      alignment: Alignment.bottomRight,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        opacity: _open ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ignoring pointers while collapsed keeps the invisible buttons
            // from swallowing taps meant for the content underneath.
            IgnorePointer(
              ignoring: !_open,
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(right: 12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    action.label,
                    style: TextUtil(context)
                        .plusJakarta(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_open,
              child: FloatingActionButton.small(
                heroTag: "fab_${action.label}",
                shape: const CircleBorder(),
                onPressed: () => _run(action.onPressed),
                child: Icon(action.icon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
