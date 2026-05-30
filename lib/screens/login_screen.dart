import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/florashop_logo.dart';
import 'main_navigation.dart';

void _showSoftKeyboard() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  });
}

const String _passwordMaskChar = '•';

String _passwordMask(int length) =>
    List.filled(length, _passwordMaskChar).join();

class _NoPeekPasswordFormatter extends TextInputFormatter {
  final TextEditingController rawController;

  _NoPeekPasswordFormatter(this.rawController);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = rawController.text;
    final oldMask = oldValue.text;
    final incoming = newValue.text;

    if (incoming == oldMask) {
      final cursor =
          newValue.selection.baseOffset.clamp(0, rawText.length).toInt();
      return TextEditingValue(
        text: _passwordMask(rawText.length),
        selection: TextSelection.collapsed(offset: cursor),
      );
    }

    var prefix = 0;
    while (prefix < oldMask.length &&
        prefix < incoming.length &&
        oldMask.codeUnitAt(prefix) == incoming.codeUnitAt(prefix)) {
      prefix++;
    }

    var oldSuffix = oldMask.length;
    var incomingSuffix = incoming.length;
    while (oldSuffix > prefix &&
        incomingSuffix > prefix &&
        oldMask.codeUnitAt(oldSuffix - 1) ==
            incoming.codeUnitAt(incomingSuffix - 1)) {
      oldSuffix--;
      incomingSuffix--;
    }

    final removedCount = oldSuffix - prefix;
    final insertedText = incoming
        .substring(prefix, incomingSuffix)
        .replaceAll(_passwordMaskChar, '');
    final replaceStart = math.min(prefix, rawText.length);
    final replaceEnd = math.min(replaceStart + removedCount, rawText.length);
    final nextRawText = rawText.replaceRange(
      replaceStart,
      replaceEnd,
      insertedText,
    );
    final cursor = math.min(
      nextRawText.length,
      replaceStart + insertedText.length,
    );

    rawController.value = TextEditingValue(
      text: nextRawText,
      selection: TextSelection.collapsed(offset: cursor),
    );

    return TextEditingValue(
      text: _passwordMask(nextRawText.length),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}

class _NoPeekPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isObscured;
  final VoidCallback onToggleVisibility;
  final String label;
  final String hint;
  final IconData prefix;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _NoPeekPasswordField({
    required this.controller,
    required this.isObscured,
    required this.onToggleVisibility,
    required this.label,
    required this.hint,
    required this.prefix,
    required this.textInputAction,
    this.focusNode,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<_NoPeekPasswordField> createState() => _NoPeekPasswordFieldState();
}

class _NoPeekPasswordFieldState extends State<_NoPeekPasswordField> {
  late final TextEditingController _maskController;
  late final _NoPeekPasswordFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _maskController = TextEditingController(
      text: _passwordMask(widget.controller.text.length),
    );
    _formatter = _NoPeekPasswordFormatter(widget.controller);
  }

  @override
  void didUpdateWidget(covariant _NoPeekPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _formatter.rawController.value = widget.controller.value;
    }

    if (widget.isObscured) {
      _syncMaskController();
    }
  }

  @override
  void dispose() {
    _maskController.dispose();
    super.dispose();
  }

  void _syncMaskController() {
    final rawLength = widget.controller.text.length;
    final mask = _passwordMask(rawLength);
    final cursor =
        _maskController.selection.baseOffset.clamp(0, rawLength).toInt();

    if (_maskController.text != mask) {
      _maskController.value = TextEditingValue(
        text: mask,
        selection: TextSelection.collapsed(offset: cursor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isObscured) {
      _syncMaskController();
    }

    return TextFormField(
      controller: widget.isObscured ? _maskController : widget.controller,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      enableSuggestions: false,
      autocorrect: false,
      enableIMEPersonalizedLearning: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.isObscured ? [_formatter] : const [],
      onTap: _showSoftKeyboard,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppTheme.textPrimary,
        letterSpacing: 0,
      ),
      decoration: _inputDeco(
        label: widget.label,
        hint: widget.hint,
        prefix: widget.prefix,
        suffix: IconButton(
          tooltip: widget.isObscured
              ? 'Tampilkan kata sandi'
              : 'Sembunyikan kata sandi',
          icon: Icon(
            widget.isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFFD94D83),
            size: 20,
          ),
          onPressed: widget.onToggleVisibility,
        ),
      ),
      validator: (_) => widget.validator?.call(widget.controller.text),
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}

class _ReliableEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const _ReliableEmailField({
    required this.controller,
    required this.focusNode,
    required this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
  });

  void _focusAndShowKeyboard() {
    focusNode.requestFocus();
    _showSoftKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _focusAndShowKeyboard(),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: textInputAction,
        enableSuggestions: false,
        autocorrect: false,
        enableIMEPersonalizedLearning: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        textCapitalization: TextCapitalization.none,
        onTap: _focusAndShowKeyboard,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: AppTheme.textPrimary,
          letterSpacing: 0,
        ),
        decoration: _inputDeco(
          label: 'Email',
          hint: 'nama@email.com',
          prefix: Icons.mail_outline_rounded,
        ),
        validator: validator,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }
}

const String _connectionErrorText =
    'Tidak bisa terhubung ke server. Pastikan internet aktif atau hubungi admin.';

String _firstValidationMessage(Map<String, dynamic>? errors, String field) {
  final value = errors?[field];

  if (value is List && value.isNotEmpty) {
    return value.first.toString();
  }

  if (value is String && value.isNotEmpty) {
    return value;
  }

  return '';
}

bool _isConnectionError(Object error) {
  return error is ApiException &&
      (error.statusCode == 0 ||
          error.statusCode == 408 ||
          error.statusCode >= 500);
}

String _friendlyErrorMessage(Object error, {String? preferredField}) {
  if (error is UnauthorizedException) {
    return 'Email atau kata sandi belum sesuai.';
  }

  if (error is ValidationException) {
    final fieldMessage = preferredField == null
        ? ''
        : _firstValidationMessage(error.errors, preferredField);

    if (fieldMessage.isNotEmpty) return fieldMessage;

    return error.message;
  }

  if (_isConnectionError(error)) {
    return _connectionErrorText;
  }

  if (error is ApiException) {
    return error.message;
  }

  return 'Permintaan belum berhasil. Silakan coba lagi.';
}

class _FieldHelperText extends StatelessWidget {
  final String text;

  const _FieldHelperText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: Color(0xFFA84C75),
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  final String text;

  const _FieldErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppTheme.error,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ServerStatusNotice extends StatelessWidget {
  final String text;

  const _ServerStatusNotice(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBCFA4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 17,
            color: Color(0xFFC2410C),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A3412),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowerBackground extends StatelessWidget {
  final Widget child;

  const _FlowerBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF7FB),
              Color(0xFFFFD9EA),
              Color(0xFFF7E8FF),
            ],
            stops: [0, 0.56, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FlowerPainter()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minHeight = math.max(
                    0.0,
                    constraints.maxHeight - 48 - bottomInset,
                  );

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      isKeyboardOpen ? 12 : 24,
                      20,
                      24 + bottomInset,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      constraints: BoxConstraints(minHeight: minHeight),
                      alignment: isKeyboardOpen
                          ? Alignment.topCenter
                          : Alignment.center,
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const flowers = <_Bloom>[
      _Bloom(0.09, 0.08, 40, Color(0xFFF49AC1), -0.2),
      _Bloom(0.52, 0.05, 30, Color(0xFFFFC4DC), 0.4),
      _Bloom(0.78, 0.14, 44, Color(0xFFF3A4C9), 0.1),
      _Bloom(0.93, 0.08, 34, Color(0xFFEFA0C3), -0.5),
      _Bloom(0.06, 0.44, 34, Color(0xFFFFD2E3), 0.6),
      _Bloom(0.96, 0.42, 40, Color(0xFFF4A2C4), -0.2),
      _Bloom(0.15, 0.73, 42, Color(0xFFEFA0C3), 0.3),
      _Bloom(0.86, 0.78, 38, Color(0xFFFFD9EA), -0.6),
      _Bloom(0.27, 0.89, 26, Color(0xFFFFE0EF), 0.2),
      _Bloom(0.77, 0.91, 34, Color(0xFFF19AC0), 0.5),
      _Bloom(0.52, 0.98, 30, Color(0xFFEFA0C3), 0.2),
    ];

    for (final flower in flowers) {
      _drawBloom(
        canvas,
        Offset(flower.x * size.width, flower.y * size.height),
        flower.radius,
        flower.color,
        flower.rotation,
      );
    }

    const leaves = <_Leaf>[
      _Leaf(0.23, 0.14, -0.65, 34),
      _Leaf(0.62, 0.18, 0.38, 32),
      _Leaf(0.08, 0.52, -0.55, 38),
      _Leaf(0.92, 0.56, 0.55, 36),
      _Leaf(0.32, 0.81, -0.35, 34),
      _Leaf(0.71, 0.84, 0.35, 36),
    ];

    final leafPaint = Paint()
      ..color = const Color(0xFF7DBE89).withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;

    for (final leaf in leaves) {
      canvas.save();
      canvas.translate(leaf.x * size.width, leaf.y * size.height);
      canvas.rotate(leaf.rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: leaf.width,
          height: leaf.width * 0.38,
        ),
        leafPaint,
      );
      canvas.restore();
    }

    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.56)
      ..style = PaintingStyle.fill;
    for (final sparkle in const [
      Offset(0.18, 0.28),
      Offset(0.84, 0.25),
      Offset(0.12, 0.62),
      Offset(0.64, 0.68),
    ]) {
      _drawSparkle(
        canvas,
        Offset(sparkle.dx * size.width, sparkle.dy * size.height),
        7,
        sparklePaint,
      );
    }
  }

  void _drawBloom(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double rotation,
  ) {
    final petalPaint = Paint()..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final petalCenter = Offset(
        math.cos(angle) * radius * 0.58,
        math.sin(angle) * radius * 0.58,
      );
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);
      petalPaint.color = i.isEven
          ? color.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: radius * 0.82,
            height: radius * 0.54,
          ),
          Radius.circular(radius),
        ),
        petalPaint,
      );
      canvas.restore();
    }

    petalPaint.color = const Color(0xFFFFF0B8).withValues(alpha: 0.92);
    canvas.drawCircle(Offset.zero, radius * 0.3, petalPaint);
    petalPaint.color = const Color(0xFFE0A822).withValues(alpha: 0.74);
    canvas.drawCircle(
        Offset(-radius * 0.06, -radius * 0.04), radius * 0.07, petalPaint);
    canvas.drawCircle(
        Offset(radius * 0.08, radius * 0.04), radius * 0.06, petalPaint);
    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.28, center.dy - radius * 0.28)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.28, center.dy + radius * 0.28)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.28, center.dy + radius * 0.28)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.28, center.dy - radius * 0.28)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Bloom {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double rotation;

  const _Bloom(this.x, this.y, this.radius, this.color, this.rotation);
}

class _Leaf {
  final double x;
  final double y;
  final double rotation;
  final double width;

  const _Leaf(this.x, this.y, this.rotation, this.width);
}

class _AuthCard extends StatelessWidget {
  final List<Widget> children;

  const _AuthCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB11E5C).withValues(alpha: 0.16),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String headline;
  final String subtitle;

  const _BrandHeader({
    required this.headline,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            FloraShopLogo(size: 54),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLORASHOP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5D1734),
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bunga segar, suasana ceria',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFA84C75),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          headline,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 25,
            height: 1.08,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4B1528),
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9F6079),
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _MoodStrip extends StatelessWidget {
  const _MoodStrip();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MoodChip(icon: Icons.auto_awesome_rounded, label: 'Segar'),
        _MoodChip(icon: Icons.local_florist_rounded, label: 'Mekar'),
        _MoodChip(icon: Icons.favorite_rounded, label: 'Pink lembut'),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MoodChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFC6DC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD94D83)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8C365E),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDeco({
  required String label,
  required String hint,
  required IconData prefix,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF9F6079),
      letterSpacing: 0,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      color: Color(0xFFC793AA),
      letterSpacing: 0,
    ),
    prefixIcon: Icon(prefix, color: const Color(0xFFD94D83), size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.78),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFF4BDD3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFF4BDD3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFD94D83), width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppTheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppTheme.error, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5C9D), Color(0xFFE21666)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFE21666).withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.2,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  Timer? _hidePasswordTimer;

  @override
  void dispose() {
    _hidePasswordTimer?.cancel();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    _hidePasswordTimer?.cancel();

    if (!_obscure) {
      setState(() => _obscure = true);
      return;
    }

    setState(() => _obscure = false);
    _hidePasswordTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _obscure = true);
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context
        .read<AuthProvider>()
        .login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil masuk ke FLORASHOP.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AuthProvider>().errorMessage ?? 'Masuk belum berhasil',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.status == AuthStatus.loading;

    return _FlowerBackground(
      child: _AuthCard(
        children: [
          const _BrandHeader(
            headline: 'Selamat datang kembali',
            subtitle:
                'Masuk dan lanjut kelola toko bunga dengan tampilan yang ceria.',
          ),
          const SizedBox(height: 18),
          const _MoodStrip(),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReliableEmailField(
                  controller: _emailCtrl,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                    _showSoftKeyboard();
                  },
                ),
                const _FieldHelperText(
                  'Gunakan email kasir yang terdaftar di web admin.',
                ),
                const SizedBox(height: 14),
                _NoPeekPasswordField(
                  controller: _passCtrl,
                  focusNode: _passwordFocusNode,
                  isObscured: _obscure,
                  onToggleVisibility: _togglePasswordVisibility,
                  label: 'Kata sandi',
                  hint: 'Minimal 8 karakter',
                  prefix: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!isLoading) _login();
                  },
                ),
                if (authProvider.serverStatusMessage != null) ...[
                  const SizedBox(height: 10),
                  _ServerStatusNotice(authProvider.serverStatusMessage!),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD94D83),
                      padding: const EdgeInsets.fromLTRB(8, 10, 0, 10),
                    ),
                    child: const Text(
                      'Lupa kata sandi?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _PrimaryButton(
                  label: 'Masuk',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _login,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _emailErrorMessage;
  String? _serverStatusMessage;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _emailErrorMessage = null;
      _serverStatusMessage = null;
    });

    try {
      await ApiService.forgotPassword(_emailCtrl.text.trim());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = _friendlyErrorMessage(e, preferredField: 'email');

      setState(() {
        _emailErrorMessage = message.contains('Email kasir') ? message : null;
        _serverStatusMessage =
            _isConnectionError(e) ? 'Server toko belum bisa dijangkau.' : null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _AuthCard(
        children: [
          const _BrandHeader(
            headline: 'Atur ulang kata sandi',
            subtitle:
                'Masukkan email akunmu, lalu cek kode verifikasi dari FLORASHOP.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReliableEmailField(
                  controller: _emailCtrl,
                  focusNode: _emailFocusNode,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _sendEmail();
                  },
                ),
                if (_emailErrorMessage != null)
                  _FieldErrorText(_emailErrorMessage!),
                if (_serverStatusMessage != null) ...[
                  const SizedBox(height: 10),
                  _ServerStatusNotice(_serverStatusMessage!),
                ],
                const SizedBox(height: 18),
                _PrimaryButton(
                  label: 'Kirim kode',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendEmail,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Kembali ke halaman masuk',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD94D83),
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown(notify: false);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _otpCtrls) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _startResendCooldown({bool notify = true}) {
    _resendTimer?.cancel();
    if (notify && mounted) {
      setState(() => _resendSeconds = 60);
    } else {
      _resendSeconds = 60;
    }

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
        return;
      }

      setState(() => _resendSeconds -= 1);
    });
  }

  void _clearOtp() {
    for (final controller in _otpCtrls) {
      controller.clear();
    }

    if (_focusNodes.isNotEmpty) {
      _focusNodes.first.requestFocus();
      _showSoftKeyboard();
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await ApiService.forgotPassword(widget.email);

      if (!mounted) return;

      _clearOtp();
      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru sudah dikirim ke email kasir.'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyErrorMessage(e, preferredField: 'email')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verify() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode OTP.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.verifyOtp(widget.email, _otpCode);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otpCode: _otpCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyErrorMessage(e, preferredField: 'otp')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _AuthCard(
        children: [
          _BrandHeader(
            headline: 'Cek kotak masukmu',
            subtitle:
                'Kode OTP sudah dikirim ke ${widget.email}. Kode berlaku 5 menit.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth =
                  ((constraints.maxWidth - 40) / 6).clamp(38.0, 48.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: boxWidth.toDouble(),
                    height: 54,
                    child: TextFormField(
                      controller: _otpCtrls[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                        color: Color(0xFF5D1734),
                        letterSpacing: 0,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.78),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFF4BDD3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFF4BDD3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFD94D83),
                            width: 1.6,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        } else if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Verifikasi',
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _verify,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                (_resendSeconds == 0 && !_isResending) ? _resendOtp : null,
            child: Text(
              _isResending
                  ? 'Mengirim ulang kode...'
                  : _resendSeconds > 0
                      ? 'Kirim ulang kode dalam $_resendSeconds detik'
                      : 'Kirim ulang kode',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: (_resendSeconds == 0 && !_isResending)
                    ? const Color(0xFFD94D83)
                    : const Color(0xFFB9859B),
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Ganti email',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD94D83),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otpCode;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otpCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  Timer? _hidePassTimer;
  Timer? _hideConfirmTimer;

  @override
  void dispose() {
    _hidePassTimer?.cancel();
    _hideConfirmTimer?.cancel();
    _passFocusNode.dispose();
    _confirmFocusNode.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _toggleNewPasswordVisibility() {
    _hidePassTimer?.cancel();

    if (!_obscurePass) {
      setState(() => _obscurePass = true);
      return;
    }

    setState(() => _obscurePass = false);
    _hidePassTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _obscurePass = true);
    });
  }

  void _toggleConfirmPasswordVisibility() {
    _hideConfirmTimer?.cancel();

    if (!_obscureConfirm) {
      setState(() => _obscureConfirm = true);
      return;
    }

    setState(() => _obscureConfirm = false);
    _hideConfirmTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _obscureConfirm = true);
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.resetPassword(
        widget.email,
        widget.otpCode,
        _passCtrl.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text(
              'Kata sandi berhasil diubah',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B1528),
                letterSpacing: 0,
              ),
            ),
            content: const Text(
              'Silakan masuk dengan kata sandi baru.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF9F6079),
                letterSpacing: 0,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD94D83),
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyErrorMessage(e, preferredField: 'password')),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FlowerBackground(
      child: _AuthCard(
        children: [
          const _BrandHeader(
            headline: 'Kata sandi baru',
            subtitle: 'Buat kata sandi yang aman untuk akun FLORASHOP kamu.',
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NoPeekPasswordField(
                  controller: _passCtrl,
                  focusNode: _passFocusNode,
                  isObscured: _obscurePass,
                  onToggleVisibility: _toggleNewPasswordVisibility,
                  label: 'Kata sandi baru',
                  hint: 'Minimal 8 karakter',
                  prefix: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _confirmFocusNode.requestFocus();
                    _showSoftKeyboard();
                  },
                ),
                const SizedBox(height: 14),
                _NoPeekPasswordField(
                  controller: _confirmCtrl,
                  focusNode: _confirmFocusNode,
                  isObscured: _obscureConfirm,
                  onToggleVisibility: _toggleConfirmPasswordVisibility,
                  label: 'Konfirmasi kata sandi',
                  hint: 'Ulangi kata sandi baru',
                  prefix: Icons.verified_user_outlined,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi wajib diisi';
                    if (v != _passCtrl.text) return 'Kata sandi belum sama';
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _resetPassword();
                  },
                ),
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: 'Simpan kata sandi',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _resetPassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
