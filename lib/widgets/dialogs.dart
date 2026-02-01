import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    required this.title,
    required this.message,
    super.key,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: YaruDialogTitleBar(
        title: Text(title),
        leading: isDestructive
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(YaruIcons.warning, color: theme.colorScheme.error),
              )
            : null,
      ),
      content: Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        if (isDestructive)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(confirmLabel),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
      ],
    );
  }
}

class InfoDialog extends StatelessWidget {
  const InfoDialog({
    required this.title,
    required this.content,
    super.key,
    this.closeLabel = 'Close',
  });

  final String title;
  final Widget content;
  final String closeLabel;

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget content,
    String closeLabel = 'Close',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) =>
          InfoDialog(title: title, content: content, closeLabel: closeLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: YaruDialogTitleBar(title: Text(title)),
      content: content,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(closeLabel),
        ),
      ],
    );
  }
}

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({required this.message, super.key});

  final String message;

  static Future<T?> showWhile<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() operation,
  }) async {
    final dialogCompleter = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProgressDialog(message: message),
    );

    try {
      final result = await operation();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      await dialogCompleter;
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: YaruDialogTitleBar(
        title: Text(message),
        leading: const Center(
          child: SizedBox.square(
            dimension: 25,
            child: YaruCircularProgressIndicator(strokeWidth: 3),
          ),
        ),
        isClosable: false,
      ),
    );
  }
}
