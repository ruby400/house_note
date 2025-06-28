import 'package:flutter/material.dart';
import 'dart:async';

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
  
  // 사용자 액션 대기를 위한 상태들
  bool _isWaitingForUserAction = false;
  Timer? _validationTimer;

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
    
    // 첫 단계 시작 액션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.steps.isNotEmpty) {
        widget.steps[0].onStepEnter?.call();
        
        // 첫 단계 처리 - 사용자 액션 대기만 처리
        final firstStep = widget.steps[0];
        if (firstStep.waitForUserAction && firstStep.actionValidator != null) {
          _startWaitingForUserAction();
        }
        // autoNext 로직 완전 제거 - 사용자가 직접 "다음" 버튼을 눌러야 함
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _validationTimer?.cancel();
    super.dispose();
  }

  void _nextStep() {
    // 현재 단계 종료 액션 실행
    if (_currentStep < widget.steps.length) {
      widget.steps[_currentStep].onStepExit?.call();
    }

    if (_currentStep < widget.steps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
        
        // 새 단계 시작 액션 실행
        widget.steps[_currentStep].onStepEnter?.call();
        
        // 실제 UI 조작이 필요한 단계인지 확인
        final currentStep = widget.steps[_currentStep];
        if (currentStep.waitForUserAction && currentStep.actionValidator != null) {
          _startWaitingForUserAction();
        }
        // autoNext 로직 완전 제거 - 모든 단계에서 사용자가 직접 "다음" 버튼을 눌러야 함
      });
    } else {
      _animationController.reverse().then((_) {
        widget.onCompleted();
      });
    }
  }

  void _skipGuide() {
    _validationTimer?.cancel();
    _animationController.reverse().then((_) {
      widget.onSkipped?.call();
    });
  }

  void _startWaitingForUserAction() {
    setState(() {
      _isWaitingForUserAction = true;
    });
    
    final currentStep = widget.steps[_currentStep];
    
    // 강제 UI 액션이 있으면 실행 (예: 바텀시트 열기)
    currentStep.forceUIAction?.call();
    
    // 주기적으로 검증 함수 확인
    _validationTimer = Timer.periodic(currentStep.pollInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // 사용자 액션 검증
      if (currentStep.actionValidator?.call() == true) {
        timer.cancel();
        setState(() {
          _isWaitingForUserAction = false;
        });
        
        // 검증 성공 후 다음 단계로
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _nextStep();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) return const SizedBox.shrink();

    final currentGuideStep = widget.steps[_currentStep];

    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _pulseController]),
      builder: (context, child) {
        return IgnorePointer(
          ignoring: false, // 전체적으로는 터치를 허용
          child: Stack(
            children: [
              // 하이라이트 영역과 배경 - 터치 이벤트 완전히 무시
              if (currentGuideStep.targetKey != null)
                IgnorePointer(
                  child: _buildHighlightArea(currentGuideStep),
                ),

              // 가이드 말풍선만 터치 가능
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

      // 타겟 영역 정의 (PopupMenuButton을 위해 더 큰 터치 영역)
      final targetRect = Rect.fromLTWH(
        targetPosition.dx - 10,
        targetPosition.dy - 10,
        targetSize.width + 20,
        targetSize.height + 20,
      );

      return _buildInteractiveHighlight(targetRect, actualPosition, step);
    }

    // 단순한 하이라이트만 표시 (터치 차단 없음)
    return Positioned.fill(
      child: CustomPaint(
        painter: HighlightPainter(
          targetKey: step.targetKey!,
          fadeValue: _fadeAnimation.value,
          pulseValue: _pulseAnimation.value,
          tooltipPosition: actualPosition,
          screenSize: MediaQuery.of(context).size,
          dynamicTargets: step.dynamicTargets, // 동적 타겟들 전달
          shouldHighlightPopup: step.shouldHighlightPopup, // 팝업 하이라이트 여부 전달
        ),
      ),
    );
  }

  // 단순한 하이라이트만 표시 (터치 차단 완전 제거)
  Widget _buildInteractiveHighlight(Rect targetRect, GuideTooltipPosition actualPosition, GuideStep step) {
    return CustomPaint(
      painter: HighlightPainter(
        targetKey: step.targetKey!,
        fadeValue: _fadeAnimation.value,
        pulseValue: _pulseAnimation.value,
        tooltipPosition: actualPosition,
        screenSize: MediaQuery.of(context).size,
        dynamicTargets: step.dynamicTargets, // 동적 타겟들 전달
        shouldHighlightPopup: step.shouldHighlightPopup, // 팝업 하이라이트 여부 전달
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
    
    // 동적 영역(바텀시트, 팝업 등)과의 충돌 감지 및 회피
    if (step.shouldAvoidDynamicArea != null && 
        step.shouldAvoidDynamicArea!() && 
        step.getDynamicArea != null) {
      try {
        final dynamicArea = step.getDynamicArea!();
        final tooltipRect = Rect.fromLTWH(left, top, tooltipWidth, tooltipHeight);
        
        // 디버깅: 동적 영역과 말풍선 위치 출력
        
        // 말풍선과 동적 영역이 겹치는지 확인
        if (tooltipRect.overlaps(dynamicArea)) {
          
          // 1. 위쪽으로 이동 시도
          final newTopPosition = dynamicArea.top - tooltipHeight - 20;
          if (newTopPosition > MediaQuery.of(context).padding.top + margin) {
            top = newTopPosition;
            actualPosition = GuideTooltipPosition.top;
          }
          // 2. 위쪽도 안되면 상단 고정 (가장 확실한 방법)
          else {
            left = 20;
            top = MediaQuery.of(context).padding.top + margin;
            actualPosition = GuideTooltipPosition.top;
          }
        }
      } catch (e) {
        // 위치 계산 실패 시 기본값 유지
      }
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
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 단계 표시만 중앙 정렬 (아이콘 제거)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9866),
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
            ),
          ),

          // 액션 힌트 (사용자 액션 대기 중일 때만 표시)
          if (_isWaitingForUserAction && step.actionHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF9866).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: Color(0xFFFF9866),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.actionHint!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3748),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                      // 현재 단계 종료 액션 실행
                      widget.steps[_currentStep].onStepExit?.call();
                      
                      _animationController.reverse().then((_) {
                        setState(() {
                          _currentStep--;
                        });
                        _animationController.forward();
                        
                        // 이전 단계 시작 액션 실행
                        widget.steps[_currentStep].onStepEnter?.call();
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
                // 사용자 액션 대기 중이면 버튼 비활성화
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWaitingForUserAction 
                        ? Colors.grey.shade300 
                        : const Color(0xFFFF9866),
                    foregroundColor: _isWaitingForUserAction 
                        ? Colors.grey.shade600 
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: const Size(80, 36),
                  ),
                  onPressed: _isWaitingForUserAction ? null : _nextStep,
                  child: _isWaitingForUserAction
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '대기중',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
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
  final VoidCallback? onStepEnter; // 단계 시작할 때 실행할 액션
  final VoidCallback? onStepExit; // 단계 종료할 때 실행할 액션
  final bool autoNext; // 자동으로 다음 단계로 넘어갈지 여부
  final Duration? autoNextDelay; // 자동 넘어가기 딜레이
  
  // 실제 UI 조작을 위한 새로운 필드들
  final bool waitForUserAction; // 사용자 액션을 기다릴지 여부
  final bool Function()? actionValidator; // 사용자 액션 검증 함수
  final VoidCallback? forceUIAction; // UI를 강제로 조작하는 함수 (예: 바텀시트 열기)
  final String? actionHint; // 사용자가 해야 할 액션에 대한 힌트
  final Duration pollInterval; // 검증 함수 호출 간격
  
  // 동적 UI 요소 추적을 위한 새로운 필드들
  final List<GlobalKey> Function()? dynamicTargets; // 동적으로 나타나는 UI 요소들의 GlobalKey 목록
  final List<String> Function()? dynamicSelectors; // CSS 선택자 형태로 동적 요소 추적
  final bool Function()? shouldHighlightPopup; // 팝업 영역을 하이라이트해야 하는지 여부
  final Rect Function()? getDynamicArea; // 동적으로 나타나는 UI 영역 (바텀시트, 팝업 등)
  final bool Function()? shouldAvoidDynamicArea; // 동적 영역을 피해서 말풍선 위치를 조정할지 여부

  GuideStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.icon,
    this.tooltipPosition = GuideTooltipPosition.bottom,
    this.onStepEnter,
    this.onStepExit,
    this.autoNext = false,
    this.autoNextDelay = const Duration(seconds: 2),
    this.waitForUserAction = false,
    this.actionValidator,
    this.forceUIAction,
    this.actionHint,
    this.pollInterval = const Duration(milliseconds: 500),
    this.dynamicTargets,
    this.dynamicSelectors,
    this.shouldHighlightPopup,
    this.getDynamicArea,
    this.shouldAvoidDynamicArea,
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
  final List<GlobalKey> Function()? dynamicTargets; // 동적 타겟들
  final bool Function()? shouldHighlightPopup; // 팝업 하이라이트 여부

  HighlightPainter({
    required this.targetKey,
    required this.fadeValue,
    required this.pulseValue,
    required this.screenSize,
    this.tooltipPosition = GuideTooltipPosition.bottom,
    this.dynamicTargets,
    this.shouldHighlightPopup,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 모든 강조할 영역들 수집
    final List<Rect> highlightRects = [];
    
    // 메인 타겟 영역 추가
    final RenderBox? renderBox =
        targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final targetSize = renderBox.size;
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final targetRect = Rect.fromLTWH(
        targetPosition.dx - 10,
        targetPosition.dy - 10,
        targetSize.width + 20,
        targetSize.height + 20,
      );
      highlightRects.add(targetRect);
    }
    
    // 동적 타겟들 추가 (팝업, 바텀시트, 드롭다운 등)
    if (dynamicTargets != null) {
      try {
        final dynamicKeys = dynamicTargets!();
        for (final key in dynamicKeys) {
          final dynamicRenderBox = key.currentContext?.findRenderObject() as RenderBox?;
          if (dynamicRenderBox != null) {
            final dynamicSize = dynamicRenderBox.size;
            final dynamicPosition = dynamicRenderBox.localToGlobal(Offset.zero);
            final dynamicRect = Rect.fromLTWH(
              dynamicPosition.dx - 5,
              dynamicPosition.dy - 5,
              dynamicSize.width + 10,
              dynamicSize.height + 10,
            );
            highlightRects.add(dynamicRect);
          }
        }
      } catch (e) {
        // 동적 타겟 추가 중 오류 발생시 무시
      }
    }
    
    // 특별한 경우: PopupMenuButton이 열렸을 때 대략적인 팝업 영역 추가
    // (실제 PopupMenu 위젯을 추적하기 어려우므로 추정)
    if (renderBox != null && shouldHighlightPopup != null && shouldHighlightPopup!()) {
      // 메인 타겟 버튼 아래쪽에 팝업이 나타날 것으로 예상되는 영역
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;
      
      // 팝업 메뉴 영역 추정 (타겟 버튼 아래, 약간 오른쪽)
      final estimatedPopupRect = Rect.fromLTWH(
        targetPosition.dx,
        targetPosition.dy + targetSize.height + 48, // offset 고려
        280, // PopupMenuButton의 maxWidth와 비슷
        250, // 대략적인 높이 (더 크게)
      );
      
      // 화면 경계 내에 있는지 확인
      if (estimatedPopupRect.right <= screenSize.width && 
          estimatedPopupRect.bottom <= screenSize.height) {
        highlightRects.add(estimatedPopupRect);
      }
    }

    // 화면 전체에서 모든 강조 영역을 제외한 부분만 어둡게
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));
    
    // 모든 강조 영역에 대해 구멍 뚫기
    for (final rect in highlightRects) {
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    }
    
    path.fillType = PathFillType.evenOdd; // 홀수 규칙으로 구멍 뚫기

    // 구멍이 뚫린 어두운 배경 그리기
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6 * fadeValue);
    canvas.drawPath(path, backgroundPaint);

    // 메인 타겟에만 펄스 효과 적용
    if (renderBox != null) {
      final targetSize = renderBox.size;
      final targetPosition = renderBox.localToGlobal(Offset.zero);
      final targetCenter = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );

      // 펄스 효과 (메인 타겟 주변에만)
      final pulseRadius = 10 + (5 * pulseValue);
      final pulseOpacity = (1.0 - pulseValue) * 0.5 * fadeValue;

      canvas.drawCircle(
        targetCenter,
        pulseRadius,
        Paint()
          ..color = const Color(0xFFFF9866).withValues(alpha: pulseOpacity)
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
      ..color = const Color(0xFFFF9866).withValues(alpha: 0.25)
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
    
    // 화살표 제거됨 - 말풍선만 표시

    // 화살표 제거 - 말풍선만 표시
  }






  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
