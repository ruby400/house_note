import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/core/utils/logger.dart';
import 'package:house_note/core/widgets/guest_mode_banner.dart';
import 'package:house_note/core/widgets/login_prompt_dialog.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';
import 'package:house_note/debug/chart_debug_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';

class ChartScreen extends ConsumerStatefulWidget {
  static const routeName = 'charts';
  static const routePath = '/charts';

  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _checkedItems = {};
  final List<String> _sortOptions = ['최신순', '거리순', '월세순'];
  String _selectedSort = '최신순';
  String _searchQuery = ''; // 검색어
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // 가이드용 GlobalKey들
  final GlobalKey _addChartKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _sortKey = GlobalKey();
  final GlobalKey _chartItemKey = GlobalKey();
  final GlobalKey _checkboxKey = GlobalKey();
  final GlobalKey _sortAddKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog() {
    if (_checkedItems.isEmpty || !_checkedItems.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('삭제할 차트를 먼저 선택해주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final selectedCount = _checkedItems.values.where((v) => v).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFFF8A65)),
            SizedBox(width: 8),
            Text('차트 삭제'),
          ],
        ),
        content:
            Text('선택한 $selectedCount개의 차트를 삭제하시겠습니까?\n삭제된 차트는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedCharts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }




  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: Color(0xFFFF8A65)),
            SizedBox(width: 8),
            Text('차트 디버그'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('90차트 및 모든 차트의 현재 상태를 확인합니다.'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search, color: Color(0xFFFF8A65)),
              title: const Text('90차트 상태 분석'),
              subtitle: const Text('90차트의 PropertyData와 ColumnOptions 확인'),
              onTap: () {
                Navigator.pop(context);
                ChartDebugUtils.analyzeChart90Status(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('90차트 분석 완료. 로그를 확인하세요.'),
                    backgroundColor: Color(0xFFFF8A65),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cleaning_services, color: Colors.green),
              title: const Text('90차트 데이터 정리'),
              subtitle: const Text('잘못된 데이터 제거 및 정리'),
              onTap: () {
                Navigator.pop(context);
                ChartDebugUtils.cleanupChart90Data(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('90차트 데이터 정리 완료.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.blue),
              title: const Text('모든 차트 목록'),
              subtitle: const Text('현재 로드된 모든 차트 확인'),
              onTap: () {
                Navigator.pop(context);
                final chartList = ref.read(propertyChartListProvider);
                AppLogger.info('=== 현재 차트 목록 ===');
                for (int i = 0; i < chartList.length; i++) {
                  final chart = chartList[i];
                  AppLogger.info('차트 $i: ID="${chart.id}", Title="${chart.title}", Properties=${chart.properties.length}개');
                }
                AppLogger.info('총 ${chartList.length}개 차트');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('총 ${chartList.length}개 차트 확인 완료. 로그를 확인하세요.'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.purple),
              title: const Text('90차트 테스트 생성'),
              subtitle: const Text('테스트용 90차트를 생성합니다'),
              onTap: () {
                Navigator.pop(context);
                _createTest90Chart();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('90차트 테스트 생성 완료.'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showInteractiveGuide() {
    final steps = [
      GuideStep(
        title: '차트 생성',
        description: '드롭다운 메뉴에서 새로운 차트를 추가할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _addChartKey,
        icon: Icons.add_chart,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '차트 선택',
        description: '체크박스로 여러 차트를 선택할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _checkboxKey,
        icon: Icons.check_box,
        tooltipPosition: GuideTooltipPosition.right,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '차트 상세보기',
        description: '차트를 탭해서 상세 비교표를 확인할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _chartItemKey,
        icon: Icons.table_chart,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '차트 검색',
        description: '차트 제목으로 실시간 검색할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _searchKey,
        icon: Icons.search,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '차트 정렬',
        description: '최신순, 거리순, 월세순으로 정렬할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _sortKey,
        icon: Icons.sort,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '정렬 추가',
        description: '사용자 정의 정렬 방식을 추가할 수 있습니다. 다음 버튼을 눌러 계속하세요.',
        targetKey: _sortAddKey,
        icon: Icons.add_box,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: '차트 선택하기 ✅',
        description: '내보낼 차트를 체크박스로 선택하세요.',
        targetKey: _checkboxKey,
        icon: Icons.check_box,
        tooltipPosition: GuideTooltipPosition.right,
        waitForUserAction: false,
        autoNext: true,
        onStepEnter: () {
          // 첫 번째 차트 자동 선택
          final chartList = ref.read(propertyChartListProvider);
          if (chartList.isNotEmpty) {
            setState(() {
              _checkedItems[chartList.first.id] = true;
            });
          }
        },
      ),
      GuideStep(
        title: '메뉴 열기 📱',
        description: '화살표 버튼을 눌러 내보내기 메뉴를 열어보세요.',
        targetKey: _addChartKey,
        icon: Icons.more_vert,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: 'PDF 내보내기 📄',
        description: 'PDF로 내보내면 문서로 저장됩니다.',
        targetKey: _addChartKey,
        icon: Icons.picture_as_pdf,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
      GuideStep(
        title: 'PNG 내보내기 📸',
        description: '이미지로 내보내면 갤러리에 저장됩니다.',
        targetKey: _addChartKey,
        icon: Icons.image,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
        onStepExit: () {
          // 선택 해제
          setState(() {
            _checkedItems.clear();
          });
        },
      ),
      GuideStep(
        title: '차트 삭제 🗑️',
        description: '불필요한 차트는 선택 후 삭제할 수 있습니다.',
        targetKey: _addChartKey,
        icon: Icons.delete,
        tooltipPosition: GuideTooltipPosition.bottom,
        waitForUserAction: false,
        autoNext: true,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('차트 가이드가 완료되었습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가이드를 건너뛰었습니다.'),
          ),
        );
      },
    );
  }

  void _deleteSelectedCharts() {
    final selectedIds = _checkedItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    for (String chartId in selectedIds) {
      ref.read(propertyChartListProvider.notifier).deleteChart(chartId);
    }

    setState(() {
      _checkedItems.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedIds.length}개의 차트가 삭제되었습니다.'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _exportToPDF() async {
    final selectedCharts = _getSelectedCharts();
    if (selectedCharts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내보낼 차트를 먼저 선택해주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedCharts.length}개의 차트를 PDF로 내보내는 중...'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );

    try {
      // 저장 권한 확인 및 요청
      final hasPermission = await _checkAndRequestStoragePermission();
      if (!hasPermission) {
        return; // 권한이 없으면 함수 종료
      }

      final pdf = pw.Document();
      final now = DateTime.now();

      // 한글 폰트 로드
      final font = await PdfGoogleFonts.nanumGothicRegular();
      final fontBold = await PdfGoogleFonts.nanumGothicBold();

      for (final chart in selectedCharts) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(
                    level: 0,
                    child: pw.Text(
                      chart.title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        font: fontBold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '생성일: ${chart.date.year}-${chart.date.month.toString().padLeft(2, '0')}-${chart.date.day.toString().padLeft(2, '0')}',
                    style: pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey, font: font),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '총 ${chart.properties.length}개의 부동산 항목',
                    style: pw.TextStyle(fontSize: 14, font: font),
                  ),
                  pw.SizedBox(height: 20),
                  _buildPdfTable(chart, font, fontBold),
                ],
              );
            },
          ),
        );
      }

      // PDF를 다운로드 폴더에 저장
      Directory? saveDir;
      String locationMessage;

      if (Platform.isAndroid) {
        // Android에서 다운로드 폴더 사용
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          // 다운로드 폴더가 없으면 외부 저장소 사용
          saveDir = await getExternalStorageDirectory();
          if (saveDir != null) {
            final downloadDir = Directory('${saveDir.path}/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            saveDir = downloadDir;
          } else {
            saveDir = await getApplicationDocumentsDirectory();
          }
        }
        locationMessage = '다운로드 폴더';
      } else {
        // iOS에서는 Documents 디렉토리 사용 (다운로드 폴더 접근 제한)
        saveDir = await getApplicationDocumentsDirectory();
        locationMessage = '문서 폴더';
      }

      final fileName = 'house_charts_${now.millisecondsSinceEpoch}.pdf';
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF가 $locationMessage에 저장되었습니다: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '공유',
              onPressed: () async => await Printing.sharePdf(
                  bytes: await pdf.save(), filename: '부동산차트.pdf'),
            ),
          ),
        );
        setState(() {
          _checkedItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 내보내기 실패: $e'),
            backgroundColor: const Color(0xFFFF8A65),
          ),
        );
      }
    }
  }

  void _exportToPNG() async {
    final selectedCharts = _getSelectedCharts();
    if (selectedCharts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내보낼 차트를 먼저 선택해주세요.'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedCharts.length}개의 차트를 PNG로 내보내는 중...'),
        backgroundColor: const Color(0xFFFF8A65),
        duration: const Duration(milliseconds: 800),
      ),
    );

    try {
      // 저장 권한 확인 및 요청
      final hasPermission = await _checkAndRequestGalleryPermission();
      if (!hasPermission) {
        return; // 권한이 없으면 함수 종료
      }

      final now = DateTime.now();
      List<String> savedFiles = [];

      for (int i = 0; i < selectedCharts.length; i++) {
        final chart = selectedCharts[i];

        // 차트를 이미지로 변환
        final imageBytes = await _createChartImage(chart);

        // 갤러리에 저장
        final fileName =
            'chart_${chart.title}_${now.millisecondsSinceEpoch}_$i.png';
        await Gal.putImageBytes(imageBytes, name: fileName);
        savedFiles.add(fileName);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${savedFiles.length}개의 이미지가 갤러리에 저장되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 800),
          ),
        );
        setState(() {
          _checkedItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PNG 내보내기 실패: $e'),
            backgroundColor: const Color(0xFFFF8A65),
          ),
        );
      }
    }
  }

  List<PropertyChartModel> _getSelectedCharts() {
    final chartList = ref.read(propertyChartListProvider);
    return chartList.where((chart) => _checkedItems[chart.id] == true).toList();
  }

  pw.Widget _buildPdfTable(
      PropertyChartModel chart, pw.Font font, pw.Font fontBold) {
    final headers = ['집 이름', '보증금', '월세', '재계/방향', '집주인 환경', '별점'];

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        // 헤더 행
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map(
                (header) => pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, font: fontBold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        // 데이터 행들
        ...chart.properties.map(
          (property) => pw.TableRow(
            children: [
              _buildPdfCell(property.name, font),
              _buildPdfCell(property.deposit, font),
              _buildPdfCell(property.rent, font),
              _buildPdfCell(property.direction, font),
              _buildPdfCell(property.landlordEnvironment, font),
              _buildPdfCell(property.rating.toString(), font),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text.isEmpty ? '-' : text,
        style: pw.TextStyle(fontSize: 10, font: font),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<Uint8List> _createChartImage(PropertyChartModel chart) async {
    // MediaQuery와 올바른 위젯 트리를 가진 임시 위젯 생성
    final widget = MediaQuery(
      data: const MediaQueryData(
        size: Size(800, 600),
        devicePixelRatio: 2.0,
        textScaler: TextScaler.linear(1.0),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          color: Colors.white,
          child: Container(
            width: 800,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chart.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8A65),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '생성일: ${chart.date.year}-${chart.date.month.toString().padLeft(2, '0')}-${chart.date.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '총 ${chart.properties.length}개의 부동산 항목',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _buildImageTable(chart),
              ],
            ),
          ),
        ),
      ),
    );

    return await _screenshotController.captureFromWidget(
      widget,
      pixelRatio: 2.0,
    );
  }

  Widget _buildImageTable(PropertyChartModel chart) {
    final headers = ['집 이름', '보증금', '월세', '재계/방향', '집주인 환경', '별점'];

    return Table(
      border: TableBorder.all(
        color: Colors.grey[400]!,
        width: 1.0,
      ),
      children: [
        // 헤더 행
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFFFF8A65),
          ),
          children: headers
              .map(
                (header) => Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    header,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        // 데이터 행들
        ...chart.properties.asMap().entries.map((entry) {
          final index = entry.key;
          final property = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: index % 2 == 0 ? Colors.white : Colors.grey[50],
            ),
            children: [
              _buildImageCell(property.name),
              _buildImageCell(property.deposit),
              _buildImageCell(property.rent),
              _buildImageCell(property.direction),
              _buildImageCell(property.landlordEnvironment),
              _buildImageCell(property.rating.toString()),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildImageCell(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Text(
        text.isEmpty ? '-' : text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _navigateToChart(String chartId) {
    AppLogger.d('차트 네비게이션 시작 - chartId: $chartId');

    // 입력값 검증 강화
    if (chartId.isEmpty || chartId.trim().isEmpty) {
      AppLogger.warning('차트 ID가 비어있어 네비게이션을 중단합니다.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('유효하지 않은 차트입니다.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // mounted 상태 확인
    if (!mounted) {
      AppLogger.warning('위젯이 마운트되지 않아 네비게이션을 중단합니다.');
      return;
    }

    try {
      // 안전한 chartId로 정제
      final safeChartId = chartId.trim();

      // goNamed 사용 (라우터에 정의된 이름으로)
      context.goNamed(
        'filtering-chart',
        pathParameters: {'chartId': safeChartId},
      );

      AppLogger.d('차트 네비게이션 성공 - chartId: $safeChartId');
    } catch (e, stackTrace) {
      AppLogger.error('네비게이션 실패', error: e, stackTrace: stackTrace);

      // 에러 발생시 사용자에게 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차트를 열 수 없습니다: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF8A65),
            action: SnackBarAction(
              label: '다시 시도',
              textColor: Colors.white,
              onPressed: () => _navigateToChart(chartId),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('차트 목록',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // 디버그 버튼 (90차트 상태 확인용)
          IconButton(
            icon: const Icon(
              Icons.bug_report,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _showDebugDialog(),
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _showInteractiveGuide(),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF9575), // 좋은 중간조 주황색 (왼쪽 위)
                Color(0xFFFF8A65), // 메인 주황색 (중간)
                Color(0xFFFF8064), // 따뜻한 주황색 (오른쪽 아래)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // 게스트 모드 배너 (로그인하지 않은 사용자에게만 표시)
          Consumer(
            builder: (context, ref, child) {
              final isAuthenticated = ref.watch(authStateChangesProvider).value != null;
              if (!isAuthenticated) {
                return const GuestModeBanner();
              }
              return const SizedBox.shrink();
            },
          ),
          _buildSearchAndFilterSection(),
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final chartList = ref.watch(propertyChartListProvider);

                // 검색어로 필터링
                List<PropertyChartModel> filteredChartList = chartList;
                if (_searchQuery.isNotEmpty) {
                  filteredChartList = chartList.where((chart) {
                    final title = chart.title.toLowerCase();
                    return title.contains(_searchQuery);
                  }).toList();
                }

                return _buildChartList(filteredChartList);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  key: _searchKey,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '차트 제목으로 검색...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                key: _addChartKey,
                icon: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: Colors.white, size: 24),
                ),
                offset: const Offset(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                surfaceTintColor: Colors.white,
                constraints: const BoxConstraints(
                  minWidth: 280,
                  maxWidth: 320,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'add_chart',
                    height: 64,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_chart,
                                color: Color(0xFF66BB6A), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '차트목록 추가',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '새로운 부동산 차트를 생성합니다',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 16,
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[300]!,
                            Colors.transparent
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export_pdf',
                    height: 64,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A65)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                color: Color(0xFFFF8A65), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('PDF로 내보내기',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF2D3748))),
                                Text('선택한 차트들을 PDF 파일로 저장',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'export_png',
                    height: 64,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF42A5F5)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.image,
                                color: Color(0xFF42A5F5), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('PNG로 내보내기',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF2D3748))),
                                Text('선택한 차트들을 이미지 파일로 저장',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    enabled: false,
                    height: 16,
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.grey[300]!,
                            Colors.transparent
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete_all',
                    height: 64,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 248, 248, 248),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 243, 243, 243),
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('선택한 차트 삭제',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color:
                                            Color.fromARGB(255, 74, 74, 74))),
                                Text('삭제된 차트는 복구할 수 없습니다',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF718096))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                onSelected: (String value) {
                  switch (value) {
                    case 'add_chart':
                      // 로그인 상태 확인
                      final isAuthenticated = ref.read(authStateChangesProvider).value != null;
                      
                      if (!isAuthenticated) {
                        // 게스트 사용자는 로그인 프롬프트 표시
                        LoginPromptDialog.show(
                          context,
                          title: '차트 생성',
                          message: '현재 둘러보기 모드입니다.\n데이터를 저장하려면 로그인이 필요합니다.\n\n지금 로그인하시겠습니까?',
                          icon: Icons.add_chart,
                        );
                        return;
                      }
                      
                      _showAddChartDialog();
                      break;
                    case 'export_pdf':
                      _exportToPDF();
                      break;
                    case 'export_png':
                      _exportToPNG();
                      break;
                    case 'delete_all':
                      _showDeleteDialog();
                      break;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._sortOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      key: index == 0 ? _sortKey : null,
                      child: _buildFilterChip(option, _selectedSort == option),
                    ),
                  );
                }),
                _buildAddFilterButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSort = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8A65) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAddFilterButton() {
    return GestureDetector(
      key: _sortAddKey,
      onTap: _showAddSortDialog,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.grey, size: 20),
      ),
    );
  }

  void _showAddSortDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        elevation: 8,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        title: null,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sort, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '정렬항목추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // 내용
              Padding(
                padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '새로운 정렬 항목을 추가하여 차트를 정렬할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '정렬 이름',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '예: 가격순, 평점순, 인기순',
                  hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                  prefixIcon: const Icon(Icons.label, color: Color(0xFFFF8A65)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF8F5),
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        // 하단 버튼들
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('취소',
                      style: TextStyle(
                          color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() => _sortOptions.add(controller.text.trim()));
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '"${controller.text.trim()}" 정렬항목이 추가되었습니다.',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFFFF8A65),
                            duration: const Duration(milliseconds: 1000),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            margin: const EdgeInsets.all(16),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('추가',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
              ],
            ),
          ),
      ),
    );
  }

  void _showAddChartDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 8,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_chart,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '새 차트 추가',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
                // 내용 부분
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '새로운 부동산 차트를 생성합니다.',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: '차트 제목',
                          labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                          hintText: '예: 강남구 부동산 차트',
                          hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                          prefixIcon:
                              const Icon(Icons.title, color: Color(0xFFFF8A65)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF8A65), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFF8F5),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFFFF8A65),
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Color(0xFF2D3748),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCCBC)),
                            color: const Color(0xFFFFF8F5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFFFF8A65), size: 18),
                              const SizedBox(width: 12),
                              Text(
                                '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF424242),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down,
                                  color: Color(0xFFFF8A65), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 버튼 부분
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('취소',
                            style: TextStyle(
                                color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8A65).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty) {
                              _addNewChart(titleController.text.trim(), selectedDate);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '"${titleController.text.trim()}" 차트가 생성되었습니다.',
                                      style:
                                          const TextStyle(fontWeight: FontWeight.w600)),
                                  backgroundColor: const Color(0xFFFF8A65),
                                  duration: const Duration(milliseconds: 1000),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  margin: const EdgeInsets.all(16),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('생성',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addNewChart(String title, DateTime date) {
    final newChart = PropertyChartModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
    );
    ref.read(propertyChartListProvider.notifier).addChart(newChart);
  }

  void _createTest90Chart() {
    AppLogger.info('90차트 테스트 생성 시작');
    
    final test90Chart = PropertyChartModel(
      id: '90',
      title: '90차트 테스트',
      date: DateTime.now(),
      properties: [
        PropertyData(
          id: '90_property_1',
          name: '90차트 테스트 부동산 1',
          address: '서울시 테스트구 90번지',
          deposit: '1000',
          rent: '50',
          direction: '남향',
          landlordEnvironment: '좋음',
          rating: 4,
          additionalData: {
            'col_7': '테스트 데이터 1',
            'col_8': '테스트 데이터 2',
            'col_9': '테스트 데이터 3',
            '주거 형태': '오피스텔',
            '평수': '20평대',
          },
        ),
        PropertyData(
          id: '90_property_2',
          name: '90차트 테스트 부동산 2',
          address: '서울시 테스트구 91번지',
          deposit: '1500',
          rent: '70',
          direction: '동향',
          landlordEnvironment: '보통',
          rating: 3,
          additionalData: {
            'col_7': '테스트 데이터 A',
            'col_8': '테스트 데이터 B',
            'col_9': '테스트 데이터 C',
            '주거 형태': '빌라',
            '평수': '15평대',
          },
        ),
      ],
      columnOptions: {
        '재계/방향': ['동향', '서향', '남향', '북향'],
        '집주인 환경': ['좋음', '보통', '나쁨'],
        '집 이름': ['90차트 테스트 부동산 1', '90차트 테스트 부동산 2'],
        '보증금': ['1000', '1500', '2000'],
        '월세': ['50', '70', '90'],
        '주거 형태': ['오피스텔', '빌라', '아파트'],
        '평수': ['15평대', '20평대', '25평대'],
        '테스트 컬럼1': ['옵션1', '옵션2', '옵션3'],
        '테스트 컬럼2': ['A', 'B', 'C'],
        '테스트 컬럼3': ['데이터1', '데이터2', '데이터3'],
      },
      columnVisibility: {
        '집 이름': true,
        '보증금': true,
        '월세': true,
        '재계/방향': true,
        '집주인 환경': false,
        '주소': false,
        '주거 형태': true,
        '평수': true,
        '테스트 컬럼1': false,
        '테스트 컬럼2': false,
        '테스트 컬럼3': false,
      },
    );
    
    ref.read(propertyChartListProvider.notifier).addChart(test90Chart);
    AppLogger.info('90차트 테스트 생성 완료: ID=${test90Chart.id}, Properties=${test90Chart.properties.length}개');
  }

  Widget _buildChartList(List<PropertyChartModel> chartList) {
    // 빈 리스트 처리
    if (chartList.isEmpty) {
      return _searchQuery.isNotEmpty
          ? _buildNoSearchResults()
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('차트가 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('새 차트를 추가해보세요',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
    }

    return _buildChartListView(chartList);
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('\'$_searchQuery\'에 대한 검색 결과가 없습니다.',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('다른 검색어를 시도해보세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartListView(List<PropertyChartModel> chartList) {
    return ListView.builder(
      itemCount: chartList.length,
      itemBuilder: (context, index) {
        try {
          // null 체크 및 안전한 차트 데이터 접근
          if (index >= chartList.length) {
            AppLogger.warning(
                '차트 리스트 인덱스 범위 초과: $index >= ${chartList.length}');
            return const SizedBox.shrink();
          }

          final chart = chartList[index];
          if (chart.id.isEmpty) {
            AppLogger.warning('차트 ID가 비어있음: index=$index');
            return const SizedBox.shrink();
          }

          final isChecked = _checkedItems[chart.id] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: index % 2 == 0
                  ? const Color.fromARGB(255, 244, 244, 244)
                  : const Color.fromARGB(255, 255, 255, 255),
              border: const Border(
                  bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
            ),
            child: ListTile(
              key: index == 0 ? _chartItemKey : null, // 첫 번째 차트 항목에만 키 적용
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              leading: Checkbox(
                key: index == 0 ? _checkboxKey : null, // 첫 번째 체크박스에만 키 적용
                value: isChecked,
                side: const BorderSide(
                    width: 2, color: Color.fromARGB(255, 195, 195, 195)),
                onChanged: (bool? value) {
                  try {
                    setState(() {
                      _checkedItems[chart.id] = value ?? false;
                    });
                  } catch (e) {
                    AppLogger.error('체크박스 상태 업데이트 실패', error: e);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                activeColor: const Color(0xFFFF8A65),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chart.title.isNotEmpty ? chart.title : '제목 없음',
                    style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 57, 57, 57),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(chart.date),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
              onTap: () {
                // 차트 네비게이션 (체크박스는 별도로 처리)
                try {
                  AppLogger.d(
                      '차트 리스트 아이템 클릭 - ID: ${chart.id}, Title: ${chart.title}');
                  _navigateToChart(chart.id);
                } catch (e, stackTrace) {
                  AppLogger.error('차트 리스트 아이템 클릭 실패',
                      error: e, stackTrace: stackTrace);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('차트를 열 수 없습니다: ${e.toString()}'),
                        backgroundColor: const Color(0xFFFF8A65),
                      ),
                    );
                  }
                }
              },
            ),
          );
        } catch (e, stackTrace) {
          AppLogger.error('차트 리스트 아이템 빌드 실패', error: e, stackTrace: stackTrace);
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFCDD2), width: 0.5),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.error, color: Color(0xFFFF8A65)),
                SizedBox(width: 8),
                Text('차트 로드 오류', style: TextStyle(color: Color(0xFFFF8A65))),
              ],
            ),
          );
        }
      },
    );
  }

  // 안전한 날짜 포맷팅 헬퍼 메서드
  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 없음';

    try {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      AppLogger.error('날짜 포맷팅 실패', error: e);
      return '날짜 오류';
    }
  }

  // 갤러리 저장 권한 확인 및 요청
  Future<bool> _checkAndRequestGalleryPermission() async {
    try {
      // gal 패키지를 위한 권한 확인
      if (Platform.isAndroid) {
        // Android에서 gal 패키지는 자동으로 적절한 권한을 처리
        // 하지만 명시적으로 photos 권한 확인
        final status = await Permission.photos.status;

        if (status.isGranted) {
          return true;
        }

        // 권한 요청
        final requestResult = await Permission.photos.request();

        if (requestResult.isGranted) {
          return true;
        }

        // 권한이 영구적으로 거부되었는지 확인
        if (requestResult.isPermanentlyDenied) {
          await _showPermissionDialog(Permission.photos,
              isPermanentlyDenied: true);
        } else {
          await _showPermissionDialog(Permission.photos,
              isPermanentlyDenied: false);
        }

        return false;
      } else {
        // iOS에서는 photos 권한만 확인
        final status = await Permission.photos.status;

        if (status.isGranted) {
          return true;
        }

        final requestResult = await Permission.photos.request();

        if (requestResult.isGranted) {
          return true;
        }

        await _showPermissionDialog(Permission.photos,
            isPermanentlyDenied: requestResult.isPermanentlyDenied);
        return false;
      }
    } catch (e) {
      AppLogger.error('권한 확인 중 오류 발생', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한 확인 중 오류가 발생했습니다.'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      }
      return false;
    }
  }

  // 권한 거부 시 설정 페이지 이동 다이얼로그
  Future<void> _showPermissionDialog(Permission permission,
      {required bool isPermanentlyDenied}) async {
    if (!mounted) return;

    final String permissionName =
        permission == Permission.photos ? '사진' : '저장소';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                  isPermanentlyDenied
                      ? Icons.block
                      : Icons.warning_amber_rounded,
                  color: isPermanentlyDenied ? Colors.red : Colors.orange),
              const SizedBox(width: 8),
              Text(isPermanentlyDenied ? '권한 차단됨' : '권한 필요'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPermanentlyDenied) ...[
                Text('$permissionName 접근 권한이 차단되어 있습니다.'),
                const SizedBox(height: 12),
                const Text(
                  '이미지를 갤러리에 저장하려면 설정에서 권한을 허용해주세요.',
                  style: TextStyle(fontSize: 14),
                ),
              ] else ...[
                Text('이미지를 갤러리에 저장하기 위해 $permissionName 접근 권한이 필요합니다.'),
                const SizedBox(height: 12),
                const Text(
                  '권한을 허용하시겠습니까?',
                  style: TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '설정 > 개인정보 보호 및 보안 > 권한에서 설정할 수 있습니다.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A65),
                foregroundColor: Colors.white,
              ),
              child: const Text('설정으로 이동'),
              onPressed: () async {
                Navigator.of(context).pop();

                // 앱 설정 페이지로 이동
                final opened = await openAppSettings();

                if (!opened) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('설정 페이지를 열 수 없습니다. 수동으로 설정해주세요.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // PDF 저장을 위한 저장소 권한 확인 및 요청
  Future<bool> _checkAndRequestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 11+ (API 30+)에서는 스코프드 스토리지 사용
        // Downloads 폴더에 직접 저장할 수 있으므로 권한이 필요하지 않음
        return true;
      } else {
        // iOS에서는 Documents 디렉토리에 저장하므로 권한 불필요
        return true;
      }
    } catch (e) {
      AppLogger.error('저장소 권한 확인 중 오류 발생', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한 확인 중 오류가 발생했습니다.'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      }
      return false;
    }
  }

  // 저장소 권한 거부 시 설정 페이지 이동 다이얼로그
}
