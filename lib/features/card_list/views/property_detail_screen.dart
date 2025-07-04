import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/features/onboarding/views/interactive_guide_overlay.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  static const routeName = 'property-detail';
  static const routePath = '/property-detail';

  final PropertyData propertyData;

  const PropertyDetailScreen({
    super.key,
    required this.propertyData,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  // 튜토리얼 관련 GlobalKey들
  final GlobalKey _headerKey = GlobalKey();
  final GlobalKey _imageGalleryKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _editableFieldKey = GlobalKey();

  // 카테고리별 항목 정의
  final Map<String, List<Map<String, dynamic>>> categories = {
    '필수 정보': [
      {'key': 'rent', 'label': '월세', 'type': 'text'},
      {'key': 'deposit', 'label': '보증금', 'type': 'text'},
      {
        'key': 'housing_type',
        'label': '주거 형태',
        'type': 'select',
        'options': ['빌라', '오피스텔', '아파트', '근린생활시설']
      },
      {'key': 'building_use', 'label': '건축물용도', 'type': 'text'},
      {
        'key': 'lease_registration',
        'label': '임차권등기명령 이력',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'mortgage',
        'label': '근저당권',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'seizure_history',
        'label': '가압류, 압류, 경매 이력',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {'key': 'contract_conditions', 'label': '계약 조건', 'type': 'text'},
      {'key': 'property_register', 'label': '등기부등본(말소사항 포함으로)', 'type': 'text'},
      {'key': 'move_in_date', 'label': '입주 가능일', 'type': 'text'},
      {
        'key': 'resident_registration',
        'label': '전입신고',
        'type': 'select',
        'options': ['가능', '불가능']
      },
      {'key': 'maintenance_fee', 'label': '관리비', 'type': 'text'},
      {
        'key': 'housing_insurance',
        'label': '주택보증보험',
        'type': 'select',
        'options': ['가능', '불가능']
      },
      {'key': 'special_terms', 'label': '특약', 'type': 'text'},
      {'key': 'special_notes', 'label': '특이사항', 'type': 'text'},
    ],
    '기본 정보': [
      {'key': 'area', 'label': '평수', 'type': 'text'},
      {'key': 'room_count', 'label': '방개수', 'type': 'text'},
      {
        'key': 'room_structure',
        'label': '방구조',
        'type': 'select',
        'options': ['원룸', '1.5룸', '다각형방', '복도형']
      },
      {
        'key': 'window_view',
        'label': '창문 뷰',
        'type': 'select',
        'options': ['뻥뷰', '막힘', '옆건물 가까움', '마주보는 건물', '벽뷰']
      },
      {
        'key': 'direction',
        'label': '방향(나침반)',
        'type': 'select',
        'options': ['정남향', '정동향', '정서향', '정북향', '남서향', '남동향', '동남향', '동북향', '북동향', '북서향']
      },
      {'key': 'lighting', 'label': '채광', 'type': 'text'},
      {'key': 'floor', 'label': '층수', 'type': 'text'},
      {
        'key': 'elevator',
        'label': '엘리베이터',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'air_conditioning',
        'label': '에어컨 방식',
        'type': 'select',
        'options': ['천장형', '벽걸이', '중앙냉방']
      },
      {
        'key': 'heating',
        'label': '난방방식',
        'type': 'select',
        'options': ['보일러', '심야전기', '중앙난중']
      },
      {
        'key': 'veranda',
        'label': '베란다',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'balcony',
        'label': '발코니',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'parking',
        'label': '주차장',
        'type': 'select',
        'options': ['기계식', '지하주차장', '지상주차장']
      },
      {
        'key': 'bathroom',
        'label': '화장실',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'gas_type',
        'label': '가스',
        'type': 'select',
        'options': ['도시가스', 'lpg가스']
      },
    ],
    '치안': [
      {
        'key': 'location_type',
        'label': '위치',
        'type': 'select',
        'options': ['차도', '대로변', '골목길']
      },
      {
        'key': 'cctv',
        'label': 'cctv 여부',
        'type': 'select',
        'options': ['1층만', '각층', '없음']
      },
      {
        'key': 'window_condition',
        'label': '창문 상태',
        'type': 'select',
        'options': ['철제창', '나무창']
      },
      {
        'key': 'door_condition',
        'label': '문 상태',
        'type': 'select',
        'options': ['삐그덕댐', '잘안닫침', '잘닫침']
      },
      {
        'key': 'landlord_environment',
        'label': '집주인 성격',
        'type': 'select',
        'options': ['이상함', '별로', '좋은것같음']
      },
      {
        'key': 'landlord_residence',
        'label': '집주인 거주',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'nearby_bars',
        'label': '집근처 술집',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'security_bars',
        'label': '저층 방범창',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'day_atmosphere',
        'label': '집주변 낮분위기',
        'type': 'select',
        'options': ['을씨년스러움', '사람들 많이다님', '사람들 안다님', '평범함', '분위기 좋음', '따뜻함']
      },
      {
        'key': 'night_atmosphere',
        'label': '집주변 밤분위기',
        'type': 'select',
        'options': ['을씨년스러움', '무서움', '스산함', '평범함', '사람들 많이다님', '사람들 안다님']
      },
      {
        'key': 'double_lock',
        'label': '2중 잠금장치',
        'type': 'select',
        'options': ['있음', '없음', '설치해준다함']
      },
    ],
    '소음 • 외풍 • 미세먼지': [
      {
        'key': 'noise_source',
        'label': '집 근처 소음원',
        'type': 'select',
        'options': ['공장', '공사장', '폐기장', '고물상', '큰 도로', '없음']
      },
      {
        'key': 'indoor_noise',
        'label': '실내소음',
        'type': 'select',
        'options': ['가벽']
      },
      {
        'key': 'double_window',
        'label': '이중창(소음, 외풍)',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'window_seal',
        'label': '창문 밀폐(미세먼지)',
        'type': 'select',
        'options': ['있음', '없음']
      },
    ],
    '청결': [
      {
        'key': 'water_pressure',
        'label': '수압',
        'type': 'select',
        'options': ['약함', '보통', '강함']
      },
      {
        'key': 'water_leak',
        'label': '누수',
        'type': 'select',
        'options': ['없음', '있음']
      },
      {
        'key': 'ac_mold',
        'label': '에어컨 내부 곰팡이',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'ac_smell',
        'label': '에어컨 냄새',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'ventilation',
        'label': '환기(공기순환)',
        'type': 'select',
        'options': ['됨', '안됨']
      },
      {
        'key': 'mold',
        'label': '곰팡이(벽,화장실,베란다)',
        'type': 'select',
        'options': ['있음', '없음']
      },
      {
        'key': 'smell',
        'label': '냄새',
        'type': 'select',
        'options': ['이상함', '퀘퀘함', '담배냄새']
      },
      {
        'key': 'insects',
        'label': '벌레(바퀴똥)',
        'type': 'select',
        'options': ['서랍', '씽크대 하부장 모서리', '씽크대 상부장']
      },
    ],
    '🚌 교통, 편의시설': [
      {
        'key': 'subway_distance',
        'label': '지하철 거리',
        'type': 'select',
        'options': ['5분거리', '10분거리', '15분거리', '20분거리']
      },
      {
        'key': 'bus_distance',
        'label': '버스 정류장',
        'type': 'select',
        'options': ['5분거리', '10분거리', '15분거리', '20분거리']
      },
      {
        'key': 'convenience_store',
        'label': '편의점 거리',
        'type': 'select',
        'options': ['5분거리', '10분거리', '15분거리', '20분거리']
      },
    ],
    '미관': [
      {
        'key': 'molding',
        'label': '몰딩',
        'type': 'select',
        'options': ['체리몰딩', '화이트몰딩', '없음', '나무']
      },
      {
        'key': 'window_film',
        'label': '창문',
        'type': 'select',
        'options': ['난초그림시트', '격자무늬 시트지', '네모패턴시트지', '없음']
      },
    ],
    '기타사항': [
      {'key': 'related_links', 'label': '관련 링크', 'type': 'text'},
      {'key': 'real_estate_info', 'label': '부동산 정보', 'type': 'text'},
      {'key': 'landlord_info', 'label': '집주인 정보', 'type': 'text'},
      {'key': 'agent_check', 'label': '계약시 중개보조인인지 중개사인지 체크', 'type': 'text'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('목록 상세 보기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: _headerKey,
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showInteractiveGuide,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 갤러리 (3개 사진)
            Container(
              key: _imageGalleryKey,
              height: 150,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildImagePlaceholder()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildImagePlaceholder()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildImagePlaceholder()),
                ],
              ),
            ),

            // 부동산 제목과 별점
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '집 이름 : ',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.propertyData.name.isNotEmpty
                              ? widget.propertyData.name
                              : '부동산 정보',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                            5,
                            (index) => Icon(
                                  index < widget.propertyData.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                )),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.propertyData.rating}/5',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF8A65),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getPropertyValue('location'),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 주요 정보 요약
                  Row(
                    children: [
                      _buildSummaryItem('보증금', widget.propertyData.deposit),
                      const SizedBox(width: 16),
                      _buildSummaryItem('월세', widget.propertyData.rent),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 카테고리별 정보 섹션들
            ...categories.entries.map((entry) => _buildInfoSection(
                  entry.key,
                  entry.value,
                  _getCategoryColor(entry.key),
                )).toList().asMap().entries.map((entry) {
              final widget = entry.value;
              final index = entry.key;
              if (index == 0) {
                return Container(
                  key: _categoryKey,
                  child: widget,
                );
              }
              return widget;
            }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            '사진',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      String title, List<Map<String, dynamic>> items, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A9E9E9E),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // 섹션 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items
                  .map((item) => _buildInfoRow(
                        item['label'],
                        _getPropertyValue(item['key']),
                        item,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, Map<String, dynamic> itemConfig) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditDialog(label, value, itemConfig),
              child: Container(
                key: label == '월세' ? _editableFieldKey : null,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.isNotEmpty ? value : '입력하세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: value.isNotEmpty
                              ? Colors.black87
                              : Colors.grey[500],
                          fontWeight: value.isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPropertyValue(String key) {
    switch (key) {
      case 'rent':
        return widget.propertyData.rent;
      case 'deposit':
        return widget.propertyData.deposit;
      case 'direction':
        return widget.propertyData.direction;
      case 'landlord_environment':
        return widget.propertyData.landlordEnvironment;
      case 'location':
        return widget.propertyData.additionalData['location'] ?? '송파구동';
      default:
        // additionalData에서 값 찾기
        return widget.propertyData.additionalData[key] ?? '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '필수 정보':
        return const Color(0xFFFFCDD2);
      case '기본 정보':
        return const Color(0xFFFFF9C4);
      case '치안':
        return const Color(0xFFE8F5E8);
      case '소음 • 외풍 • 미세먼지':
        return const Color(0xFFE1F5FE);
      case '청결':
        return const Color(0xFFE3F2FD);
      case '🚌 교통, 편의시설':
        return const Color(0xFFFFF3E0);
      case '미관':
        return const Color(0xFFF3E5F5);
      case '기타사항':
        return const Color(0xFFE8EAF6);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  void _showEditDialog(
      String label, String currentValue, Map<String, dynamic> itemConfig) {
    if (itemConfig['type'] == 'select') {
      _showSelectDialog(label, currentValue, itemConfig);
    } else {
      _showTextEditDialog(label, currentValue, itemConfig);
    }
  }

  void _showSelectDialog(
      String label, String currentValue, Map<String, dynamic> itemConfig) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...itemConfig['options'].map<Widget>((option) => ListTile(
                  title: Text(option),
                  trailing: currentValue == option
                      ? const Icon(Icons.check, color: Color(0xFFFF8A65))
                      : null,
                  onTap: () {
                    // TODO: 값 업데이트 로직 구현
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showTextEditDialog(
      String label, String currentValue, Map<String, dynamic> itemConfig) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '값을 입력하세요',
          ),
          maxLines: itemConfig['key'] == 'special_terms' ||
                  itemConfig['key'] == 'special_notes'
              ? 3
              : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 값 업데이트 로직 구현
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showInteractiveGuide() {
    final steps = [
      GuideStep(
        title: '부동산 상세 정보',
        description: '이 화면에서는 선택한 부동산의 상세 정보를 확인하고 편집할 수 있습니다.',
        targetKey: _headerKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        icon: Icons.info_outline,
      ),
      GuideStep(
        title: '사진 갤러리',
        description: '부동산 사진을 3개까지 추가할 수 있습니다. 사진을 탭하여 추가해보세요.',
        targetKey: _imageGalleryKey,
        tooltipPosition: GuideTooltipPosition.bottom,
        icon: Icons.photo_camera,
      ),
      GuideStep(
        title: '정보 카테고리',
        description: '필수 정보, 기본 정보, 치안 등 카테고리별로 정보가 구분되어 있습니다.',
        targetKey: _categoryKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.category,
      ),
      GuideStep(
        title: '정보 편집',
        description: '각 항목을 탭하여 정보를 입력하거나 수정할 수 있습니다.',
        targetKey: _editableFieldKey,
        tooltipPosition: GuideTooltipPosition.top,
        icon: Icons.edit,
      ),
    ];

    InteractiveGuideManager.showGuide(
      context,
      steps: steps,
      onCompleted: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('튜토리얼을 완료했습니다!'),
            backgroundColor: Color(0xFFFF8A65),
          ),
        );
      },
      onSkipped: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('튜토리얼을 건너뛰었습니다.')),
        );
      },
    );
  }
}
