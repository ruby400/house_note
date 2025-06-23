import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveGuideOverlay extends StatefulWidget {
  final List<GuideStep> steps;
  final VoidCallback onCompleted;
  final VoidCallback? onSkipped;

  const InteractiveGuideOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    this.onSkipped,
  });

  @override
  State<InteractiveGuideOverlay> createState() =>
      _InteractiveGuideOverlayState();
}

class _InteractiveGuideOverlayState extends State<InteractiveGuideOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _animationController.reverse().then((_) {
        widget.onCompleted();
      });
    }
  }

  void _skipGuide() {
    _animationController.reverse().then((_) {
      widget.onSkipped?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) return const SizedBox.shrink();

    final currentGuideStep = widget.steps[_currentStep];

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _pulseController]),
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 전체 배경 터치 감지
              Positioned.fill(
                child: GestureDetector(
                  onTap: _nextStep,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // 하이라이트 영역 (화살표) - 말풍선 아래에 그려짐
              if (currentGuideStep.targetKey != null)
                _buildHighlightArea(currentGuideStep),

              // 가이드 말풍선 - 화살표 위에 그려져서 버튼이 눌리도록
              _buildGuideTooltip(currentGuideStep),

              // 상단 컨트롤
              _buildTopControls(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightArea(GuideStep step) {
    // 실제 말풍선 위치를 계산
    GuideTooltipPosition actualPosition = step.tooltipPosition;
    final RenderBox? renderBox =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;
      final screenSize = MediaQuery.of(context).size;
      const tooltipWidth = 320.0;
      const totalMargin =
          19.0 + 60.0 + 7.6; // targetMargin + arrowLength + balloonMargin

      // 실제 배치 위치 계산 (말풍선 배치 로직과 동일)
      switch (step.tooltipPosition) {
        case GuideTooltipPosition.left:
          if (targetPosition.dx - tooltipWidth - totalMargin < 20) {
            if (targetPosition.dx +
                    targetSize.width +
                    totalMargin +
                    tooltipWidth >
                screenSize.width - 20) {
              actualPosition = GuideTooltipPosition.bottom;
            } else {
              actualPosition = GuideTooltipPosition.right;
            }
          }
          break;
        case GuideTooltipPosition.right:
          if (targetPosition.dx +
                  targetSize.width +
                  totalMargin +
                  tooltipWidth >
              screenSize.width - 20) {
            if (targetPosition.dx - tooltipWidth - totalMargin < 20) {
              actualPosition = GuideTooltipPosition.bottom;
            } else {
              actualPosition = GuideTooltipPosition.left;
            }
          }
          break;
        case GuideTooltipPosition.top:
          if (targetPosition.dy - 200.0 - totalMargin <
              MediaQuery.of(context).padding.top + 20) {
            actualPosition = GuideTooltipPosition.bottom;
          }
          break;
        case GuideTooltipPosition.bottom:
          if (targetPosition.dy + targetSize.height + 200.0 + totalMargin >
              screenSize.height - 80) {
            actualPosition = GuideTooltipPosition.top;
          }
          break;
      }
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: HighlightPainter(
          targetKey: step.targetKey!,
          fadeValue: _fadeAnimation.value,
          pulseValue: _pulseAnimation.value,
          tooltipPosition: actualPosition,
          screenSize: MediaQuery.of(context).size,
        ),
      ),
    );
  }

  Widget _buildGuideTooltip(GuideStep step) {
    return _buildPositionedTooltip(step);
  }

  Widget _buildPositionedTooltip(GuideStep step) {
    // 타곋 위치 가져오기
    final RenderBox? renderBox =
        step.targetKey?.currentContext?.findRenderObject() as RenderBox?;

    // 타곋이 없으면 기본 위치에 말풍선 표시
    if (renderBox == null) {
      return _buildDefaultTooltip(step);
    }

    final targetSize = renderBox.size;
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // 말풍선 사이즈 (알약 모양 - 가로가 훨씬 긴 형태)
    const tooltipWidth = 360.0;
    const tooltipHeight = 190.0;
    const balloonMargin = 7.6; // 화살표에서 0.2cm 떨어진 거리 (0.2cm = 약 7.6px)
    const arrowLength = 60.0; // 화살표 길이
    const targetMargin = 19.0; // 타겟에서 0.5cm 떨어진 거리

    // 전체 거리 = 타겟에서 화살표까지 + 화살표 길이 + 화살표에서 말풍선까지
    final totalMargin = targetMargin + arrowLength + balloonMargin;

    // 말풍선 위치 계산
    late double left, top;
    late GuideTooltipPosition actualPosition;

    // 우선 지정된 위치로 배치 시도
    switch (step.tooltipPosition) {
      case GuideTooltipPosition.top:
        left = targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
        top = targetPosition.dy - tooltipHeight - totalMargin;
        actualPosition = GuideTooltipPosition.top;

        // 화면 밖으로 나가는지 검사
        if (top < MediaQuery.of(context).padding.top + 20) {
          // 아래쪽으로 변경
          top = targetPosition.dy + targetSize.height + totalMargin;
          actualPosition = GuideTooltipPosition.bottom;
        }
        break;

      case GuideTooltipPosition.bottom:
        left = targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
        top = targetPosition.dy + targetSize.height + totalMargin;
        actualPosition = GuideTooltipPosition.bottom;

        // 화면 밖으로 나가는지 검사
        if (top + tooltipHeight > screenSize.height - 80) {
          // 위쪽으로 변경
          top = targetPosition.dy - tooltipHeight - totalMargin;
          actualPosition = GuideTooltipPosition.top;
        }
        break;

      case GuideTooltipPosition.left:
        left = targetPosition.dx - tooltipWidth - totalMargin;
        top = targetPosition.dy + (targetSize.height / 2) - (tooltipHeight / 2);
        actualPosition = GuideTooltipPosition.left;

        // 화면 밖으로 나가는지 검사하고, 공간이 부족하면 아래로 배치
        if (left < 20) {
          // 오른쪽 시도
          if (targetPosition.dx +
                  targetSize.width +
                  totalMargin +
                  tooltipWidth >
              screenSize.width - 20) {
            // 오른쪽도 공간이 부족하면 아래로 배치
            left =
                targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
            top = targetPosition.dy + targetSize.height + totalMargin;
            actualPosition = GuideTooltipPosition.bottom;
          } else {
            // 오른쪽으로 변경
            left = targetPosition.dx + targetSize.width + totalMargin;
            actualPosition = GuideTooltipPosition.right;
          }
        }
        break;

      case GuideTooltipPosition.right:
        left = targetPosition.dx + targetSize.width + totalMargin;
        top = targetPosition.dy + (targetSize.height / 2) - (tooltipHeight / 2);
        actualPosition = GuideTooltipPosition.right;

        // 화면 밖으로 나가는지 검사하고, 공간이 부족하면 아래로 배치
        if (left + tooltipWidth > screenSize.width - 20) {
          // 왼쪽 시도
          if (targetPosition.dx - tooltipWidth - totalMargin < 20) {
            // 왼쪽도 공간이 부족하면 아래로 배치
            left =
                targetPosition.dx + (targetSize.width / 2) - (tooltipWidth / 2);
            top = targetPosition.dy + targetSize.height + totalMargin;
            actualPosition = GuideTooltipPosition.bottom;
          } else {
            // 왼쪽으로 변경
            left = targetPosition.dx - tooltipWidth - totalMargin;
            actualPosition = GuideTooltipPosition.left;
          }
        }
        break;
    }

    // 좌우 방향 마진 조정
    const margin = 20.0;
    if (left < margin) {
      left = margin;
    } else if (left + tooltipWidth > screenSize.width - margin) {
      left = screenSize.width - tooltipWidth - margin;
    }

    // 상하 방향 마진 조정
    if (top < MediaQuery.of(context).padding.top + margin) {
      top = MediaQuery.of(context).padding.top + margin;
    } else if (top + tooltipHeight > screenSize.height - 80) {
      top = screenSize.height - tooltipHeight - 80;
    }

    return Positioned(
      left: left,
      top: top,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: _buildTooltipContent(
              step, actualPosition, targetPosition, targetSize),
        ),
      ),
    );
  }

  Widget _buildDefaultTooltip(GuideStep step) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 180, // 화살표와 더 떨어지도록 위치 조정
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Opacity(
          opacity: _fadeAnimation.value,
          child: _buildTooltipContent(
              step, GuideTooltipPosition.bottom, Offset.zero, Size.zero),
        ),
      ),
    );
  }

  Widget _buildTooltipContent(
      GuideStep step,
      GuideTooltipPosition actualPosition,
      Offset targetPosition,
      Size targetSize) {
    return CustomPaint(
      painter: TooltipPainter(
        position: actualPosition,
        targetPosition: targetPosition,
        targetSize: targetSize,
        targetKey: step.targetKey, // GlobalKey를 직접 전달
      ),
      child: Container(
        width: 360,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        child: _buildTooltipContentInner(step),
      ),
    );
  }

  Widget _buildTooltipContentInner(GuideStep step) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 단계 표시만 중앙 정렬 (아이콘 제거)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentStep + 1}/${widget.steps.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 제목
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),

          const SizedBox(height: 8),

          // 설명
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A5568),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // 액션 버튼들 (타원형 안에 맞게 조정)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentStep > 0) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: const Size(60, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () {
                      _animationController.reverse().then((_) {
                        setState(() {
                          _currentStep--;
                        });
                        _animationController.forward();
                      });
                    },
                    child: const Text(
                      '이전',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12), // 버튼 사이 간격을 좁힘
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18), // 더 둥글게
                    ),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: const Size(80, 36),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == widget.steps.length - 1 ? '완료' : '다음',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Opacity(
        opacity: _fadeAnimation.value,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 건너뛰기 버튼만 표시 (진행률 표시 제거)
            if (widget.onSkipped != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _skipGuide,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GuideStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final IconData? icon;
  final GuideTooltipPosition tooltipPosition;

  GuideStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.icon,
    this.tooltipPosition = GuideTooltipPosition.bottom,
  });
}

enum GuideTooltipPosition {
  top,
  bottom,
  left,
  right,
}

class HighlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final double fadeValue;
  final double pulseValue;
  final GuideTooltipPosition tooltipPosition;
  final Size screenSize;

  HighlightPainter({
    required this.targetKey,
    required this.fadeValue,
    required this.pulseValue,
    required this.screenSize,
    this.tooltipPosition = GuideTooltipPosition.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 타겟 위젯의 위치와 크기 가져오기
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final targetSize = renderBox.size;
      final targetPosition = renderBox.localToGlobal(Offset.zero);

      // 타겟 영역 정의 (약간의 패딩 포함)
      final targetRect = Rect.fromLTWH(
        targetPosition.dx - 8,
        targetPosition.dy - 8,
        targetSize.width + 16,
        targetSize.height + 16,
      );

      // Path로 화면 전체에서 타겟 영역을 제외한 부분만 어둡게
      final path = Path()
        ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height))
        ..addRRect(RRect.fromRectAndRadius(targetRect, const Radius.circular(8)))
        ..fillType = PathFillType.evenOdd; // 홀수 규칙으로 구멍 뚫기

      // 구멍이 뚫린 어두운 배경 그리기
      final backgroundPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6 * fadeValue);
      canvas.drawPath(path, backgroundPaint);

      // 타겟 영역 외곽선 그리기
      final borderPaint = Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.8 * fadeValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(8)),
        borderPaint,
      );

      // 타겟의 중심점
      final targetCenter = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );

      // 펄스 효과 (타겟 주변에 작은 원)
      final pulseRadius = 10 + (5 * pulseValue);
      final pulseOpacity = (1.0 - pulseValue) * 0.5 * fadeValue;

      canvas.drawCircle(
        targetCenter,
        pulseRadius,
        Paint()
          ..color = const Color(0xFFFFC107).withValues(alpha: pulseOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 가이드 매니저 클래스
class InteractiveGuideManager {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void showGuide(
    BuildContext context, {
    required List<GuideStep> steps,
    VoidCallback? onCompleted,
    VoidCallback? onSkipped,
  }) {
    if (_isShowing) return;

    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => InteractiveGuideOverlay(
        steps: steps,
        onCompleted: () {
          hideGuide();
          onCompleted?.call();
        },
        onSkipped: () {
          hideGuide();
          onSkipped?.call();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hideGuide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  static bool get isShowing => _isShowing;
}

// 말풍선 화살표를 그리는 CustomPainter
class TooltipPainter extends CustomPainter {
  final GuideTooltipPosition position;
  final Offset targetPosition;
  final Size targetSize;
  final GlobalKey? targetKey;

  TooltipPainter({
    required this.position,
    required this.targetPosition,
    required this.targetSize,
    this.targetKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFC107).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final borderPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 타원형 말풍선을 위한 타원 (패딩을 줄여서 타원이 더 크게)
    const padding = 4.0;
    final balloonRect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // 덜 둥근 모양을 위한 반지름 (높이의 1/4로 줄임)
    final cornerRadius = balloonRect.height / 4;

    // 노란색 후광 효과 그리기 (가장 바깥쪽, 크기 줄임)
    final glowRect = balloonRect.inflate(8);
    final glowRRect = RRect.fromRectAndRadius(
      glowRect,
      Radius.circular(glowRect.height / 4),
    );
    canvas.drawRRect(glowRRect, glowPaint);

    // 말풍선 배경 그리기 (덜 둥근 모양)
    final balloonRRect = RRect.fromRectAndRadius(
      balloonRect,
      Radius.circular(cornerRadius),
    );
    canvas.drawRRect(balloonRRect, paint);

    // 말풍선 테두리 그리기 (덜 둥근 모양)
    canvas.drawRRect(balloonRRect, borderPaint);

    // 말풍선에서 나오는 선 화살표 그리기
    _drawArrowFromBalloon(canvas, balloonRect);
  }

  void _drawArrowFromBalloon(Canvas canvas, Rect balloonRect) {
    // 복잡한 좌표 변환 대신 간단하고 확실한 방법 사용
    // position 정보만 사용해서 올바른 방향으로 화살표 그리기
    
    Offset targetDirection;
    
    // 말풍선 position에 따라 타겟이 있는 방향 결정
    switch (position) {
      case GuideTooltipPosition.top:
        // 말풍선이 타겟 위에 있으므로 화살표는 아래로
        targetDirection = const Offset(0, 1);
        break;
      case GuideTooltipPosition.bottom:
        // 말풍선이 타겟 아래에 있으므로 화살표는 위로
        targetDirection = const Offset(0, -1);
        break;
      case GuideTooltipPosition.left:
        // 말풍선이 타겟 왼쪽에 있으므로 화살표는 오른쪽으로
        targetDirection = const Offset(1, 0);
        break;
      case GuideTooltipPosition.right:
        // 말풍선이 타겟 오른쪽에 있으므로 화살표는 왼쪽으로
        targetDirection = const Offset(-1, 0);
        break;
    }
    
    // 말풍선 중심에서 타겟 방향으로 화살표 그리기
    final balloonCenter = balloonRect.center;
    final targetCenter = balloonCenter + (targetDirection * 70);

    // 화살표 제거 - 말풍선만 표시
  }


  void _drawCurlyArrowToTarget(Canvas canvas, Rect balloonRect, Offset targetCenter) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 말풍선 중심에서 타겟으로의 방향
    final balloonCenter = balloonRect.center;
    final direction = targetCenter - balloonCenter;
    final distance = math.sqrt(direction.dx * direction.dx + direction.dy * direction.dy);

    if (distance < 20) return; // 너무 가까우면 그리지 않음

    // 정규화된 방향
    final normalizedDirection = Offset(direction.dx / distance, direction.dy / distance);

    // 말풍선 가장자리에서 시작 (안전한 여백 포함)
    final balloonRadius = balloonRect.height / 2;
    const margin = 15.0;

    final arrowStart = Offset(
      balloonCenter.dx + normalizedDirection.dx * (balloonRadius + margin),
      balloonCenter.dy + normalizedDirection.dy * (balloonRadius + margin),
    );

    // 돼지꼬리 곡선을 위한 제어점들
    const curveLength = 45.0;
    final midPoint = Offset(
      arrowStart.dx + normalizedDirection.dx * (curveLength * 0.6),
      arrowStart.dy + normalizedDirection.dy * (curveLength * 0.6),
    );

    // 수직 방향 벡터 (돼지꼬리 곡선을 위해)
    final perpendicular = Offset(-normalizedDirection.dy, normalizedDirection.dx);
    
    // 첫 번째 곡선 (시계방향)
    final curve1Control = Offset(
      midPoint.dx + perpendicular.dx * 15,
      midPoint.dy + perpendicular.dy * 15,
    );
    
    // 두 번째 곡선 (반시계방향)
    final curve2Start = Offset(
      midPoint.dx + normalizedDirection.dx * 15,
      midPoint.dy + normalizedDirection.dy * 15,
    );
    
    final curve2Control = Offset(
      curve2Start.dx - perpendicular.dx * 12,
      curve2Start.dy - perpendicular.dy * 12,
    );
    
    final arrowEnd = Offset(
      curve2Start.dx + normalizedDirection.dx * 15,
      curve2Start.dy + normalizedDirection.dy * 15,
    );

    // 돼지꼬리 Path 그리기
    final path = Path();
    path.moveTo(arrowStart.dx, arrowStart.dy);
    
    // 첫 번째 곡선
    path.quadraticBezierTo(
      curve1Control.dx, curve1Control.dy,
      midPoint.dx, midPoint.dy,
    );
    
    // 두 번째 곡선
    path.quadraticBezierTo(
      curve2Control.dx, curve2Control.dy,
      arrowEnd.dx, arrowEnd.dy,
    );

    canvas.drawPath(path, arrowPaint);

    // 화살표 머리 그리기 (끝점에서)
    const arrowHeadLength = 12.0;
    final arrowHead1 = arrowEnd - (normalizedDirection * arrowHeadLength) + (perpendicular * arrowHeadLength * 0.5);
    final arrowHead2 = arrowEnd - (normalizedDirection * arrowHeadLength) - (perpendicular * arrowHeadLength * 0.5);

    canvas.drawLine(arrowEnd, arrowHead1, arrowPaint);
    canvas.drawLine(arrowEnd, arrowHead2, arrowPaint);
  }




  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
