import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _minInputHeight = 70.0;
const _buttonSize = 70.0;
const _maxInputHeight = 200.0;

class BottomBarCardContent extends StatefulWidget {
  final VoidCallback? onSubmit;
  final VoidCallback? onVoice;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  const BottomBarCardContent({
    super.key,
    this.onSubmit,
    this.onVoice,
    this.onChanged,
    this.hintText,
  });

  @override
  State<BottomBarCardContent> createState() => _BottomBarCardContentState();
}

class _BottomBarCardContentState extends State<BottomBarCardContent> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 32 + keyboardInset,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final buttonWidth = _buttonSize;
            final textFieldWidth = maxWidth - buttonWidth - 16;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: textFieldWidth,
                  child: _GlassTextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    hintText: widget.hintText ?? 'Type a message...',
                    minHeight: _minInputHeight,
                    maxHeight: _maxInputHeight,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: buttonWidth,
                  height: _buttonSize,
                  child: _ActionButton(
                    hasText: _hasText,
                    onSubmit: () {
                      if (_hasText) {
                        widget.onSubmit?.call();
                        _textController.clear();
                      } else {
                        widget.onVoice?.call();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final double minHeight;
  final double maxHeight;

  const _GlassTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  double _contentHeight = 70.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeMeasurer();
    super.dispose();
  }

  void _removeMeasurer() {}

  void _onTextChanged() {
    _measureTextHeight();
  }

  void _measureTextHeight() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      if (_contentHeight != widget.minHeight) {
        setState(() {
          _contentHeight = widget.minHeight;
        });
      }
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width * 0.6);

    final lineCount = textPainter.height / (16 * 1.4);
    final newHeight = (widget.minHeight + ((lineCount - 1) * 22.0)).clamp(
      widget.minHeight,
      widget.maxHeight,
    );

    if (newHeight != _contentHeight) {
      setState(() {
        _contentHeight = newHeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.focusNode.requestFocus(),
      child: RepaintBoundary(
        child: AdaptiveGlass(
          shape: const LiquidRoundedSuperellipse(borderRadius: 36),
          settings: InheritedLiquidGlass.ofOrDefault(context),
          quality: GlassQuality.standard,
          useOwnLayer: true,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: _contentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: const TextSelectionThemeData(
                            cursorColor: Colors.white,
                            selectionColor: Colors.white30,
                            selectionHandleColor: Colors.white,
                          ),
                          colorScheme: Theme.of(
                            context,
                          ).colorScheme.copyWith(primary: Colors.white),
                        ),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          maxLines: null,
                          minLines: 1,
                          textAlignVertical: TextAlignVertical.center,
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            hintText: widget.hintText,
                            hintStyle: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool hasText;
  final VoidCallback? onSubmit;

  const _ActionButton({required this.hasText, this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return GlassButton.custom(
      width: _buttonSize,
      height: _buttonSize,
      shape: const LiquidRoundedSuperellipse(borderRadius: 36),
      label: hasText ? 'Send' : 'Voice',
      onTap: onSubmit ?? () {},
      useOwnLayer: true,
      quality: GlassQuality.standard,
      glowRadius: 1.1,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            hasText ? Icons.send : Icons.mic,
            key: ValueKey(hasText),
            size: 31,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
