import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/property_chart_model.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  static const routeName = 'property-detail';
  static const routePath = '/property-detail';
  
  final PropertyData propertyData;

  const PropertyDetailScreen({
    super.key,
    required this.propertyData,
  });

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  // 카테고리별 항목 정의
  final Map<String, List<Map<String, dynamic>>> categories = {
    '필수 정보': [
      {'key': 'rent', 'label': '월세', 'type': 'text'},
      {'key': 'deposit', 'label': '보증금', 'type': 'text'},
      {'key': 'housing_type', 'label': '주거 형태', 'type': 'select', 'options': ['빌라', '오피스텔', '아파트', '근린생활시설']},
      {'key': 'building_use', 'label': '건축물용도', 'type': 'text'},
      {'key': 'lease_registration', 'label': '임차권등기명령 이력', 'type': 'select', 'options': ['유', '무']},
      {'key': 'mortgage', 'label': '근저당권', 'type': 'select', 'options': ['유', '무']},
      {'key': 'seizure_history', 'label': '가압류, 압류, 경매 이력', 'type': 'select', 'options': ['유', '무']},
      {'key': 'contract_conditions', 'label': '계약 조건', 'type': 'text'},
      {'key': 'property_register', 'label': '등기부등본(말소사항 포함으로)', 'type': 'text'},
      {'key': 'move_in_date', 'label': '입주 가능일', 'type': 'text'},
      {'key': 'resident_registration', 'label': '전입신고', 'type': 'select', 'options': ['가능', '불가능']},
      {'key': 'maintenance_fee', 'label': '관리비', 'type': 'text'},
      {'key': 'housing_insurance', 'label': '주택보증보험', 'type': 'select', 'options': ['가능', '불가능']},
      {'key': 'special_terms', 'label': '특약', 'type': 'text'},
      {'key': 'special_notes', 'label': '특이사항', 'type': 'text'},
    ],
    '기본 정보': [
      {'key': 'area', 'label': '평수', 'type': 'text'},
      {'key': 'room_count', 'label': '방개수', 'type': 'text'},
      {'key': 'room_structure', 'label': '방구조', 'type': 'select', 'options': ['원룸', '1.5룸', '다각형방', '복도형']},
      {'key': 'window_view', 'label': '창문 뷰', 'type': 'select', 'options': ['뻥뷰', '막힘', '옆건물 가까움', '마주보는 건물', '벽뷰']},
      {'key': 'direction', 'label': '방향(나침반)', 'type': 'select', 'options': ['정남', '정동', '정서', '정북', '남서', '남동', '동남', '동북', '북동', '북서']},
      {'key': 'lighting', 'label': '채광', 'type': 'text'},
      {'key': 'floor', 'label': '층수', 'type': 'text'},
      {'key': 'elevator', 'label': '엘리베이터', 'type': 'select', 'options': ['유', '무']},
      {'key': 'air_conditioning', 'label': '에어컨 방식', 'type': 'select', 'options': ['천장형', '벽걸이', '중앙냉방']},
      {'key': 'heating', 'label': '난방방식', 'type': 'select', 'options': ['보일러', '심야전기', '중앙난중']},
      {'key': 'veranda', 'label': '베란다', 'type': 'select', 'options': ['유', '무']},
      {'key': 'balcony', 'label': '발코니', 'type': 'select', 'options': ['유', '무']},
      {'key': 'parking', 'label': '주차장', 'type': 'select', 'options': ['기계식', '지하주차장', '지상주차장']},
      {'key': 'bathroom', 'label': '화장실', 'type': 'select', 'options': ['유', '무']},
      {'key': 'gas_type', 'label': '가스', 'type': 'select', 'options': ['도시가스', 'lpg가스']},
    ],
    '치안': [
      {'key': 'location_type', 'label': '위치', 'type': 'select', 'options': ['차도', '대로변', '골목길']},
      {'key': 'cctv', 'label': 'cctv 여부', 'type': 'select', 'options': ['1층만', '각층', '없음']},
      {'key': 'window_condition', 'label': '창문 상태', 'type': 'select', 'options': ['철제창', '나무창']},
      {'key': 'door_condition', 'label': '문 상태', 'type': 'select', 'options': ['삐그덕댐', '잘안닫침', '잘닫침']},
      {'key': 'landlord_environment', 'label': '집주인 성격', 'type': 'select', 'options': ['이상함', '별로', '좋은것같음']},
      {'key': 'landlord_residence', 'label': '집주인 거주', 'type': 'select', 'options': ['유', '무']},
      {'key': 'nearby_bars', 'label': '집근처 술집', 'type': 'select', 'options': ['유', '무']},
      {'key': 'security_bars', 'label': '저층 방범창', 'type': 'select', 'options': ['유', '무']},
      {'key': 'day_atmosphere', 'label': '집주변 낮분위기', 'type': 'select', 'options': ['을씨년스러움', '사람들 많이다님', '사람들 안다님', '평범함', '분위기 좋음', '따뜻함']},
      {'key': 'night_atmosphere', 'label': '집주변 밤분위기', 'type': 'select', 'options': ['을씨년스러움', '무서움', '스산함', '평범함', '사람들 많이다님', '사람들 안다님']},
      {'key': 'double_lock', 'label': '2종 잠금장치', 'type': 'select', 'options': ['유', '무', '설치해준다함']},
    ],
    '소음 • 외풍 • 미세먼지': [
      {'key': 'noise_source', 'label': '집 근처 소음원', 'type': 'select', 'options': ['공장', '공사장', '폐기장', '고물상', '큰 도로', '없음']},
      {'key': 'indoor_noise', 'label': '실내소음', 'type': 'select', 'options': ['가벽']},
      {'key': 'double_window', 'label': '이중창(소음, 외풍)', 'type': 'select', 'options': ['유', '무']},
      {'key': 'window_seal', 'label': '창문 밀폐(미세먼지)', 'type': 'select', 'options': ['유', '무']},
    ],
    '청결': [
      {'key': 'water_pressure', 'label': '수압', 'type': 'select', 'options': ['약함', '보통', '강함']},
      {'key': 'water_leak', 'label': '누수', 'type': 'select', 'options': ['없음', '있음']},
      {'key': 'ac_mold', 'label': '에어컨 내부 곰팡이', 'type': 'select', 'options': ['유', '무']},
      {'key': 'ac_smell', 'label': '에어컨 냄새', 'type': 'select', 'options': ['유', '무']},
      {'key': 'ventilation', 'label': '환기(공기순환)', 'type': 'select', 'options': ['됨', '안됨']},
      {'key': 'mold', 'label': '곰팡이(벽,화장실,베란다)', 'type': 'select', 'options': ['유', '무']},
      {'key': 'smell', 'label': '냄새', 'type': 'select', 'options': ['이상함', '퀘퀘함', '담배냄새']},
      {'key': 'insects', 'label': '벌레(바퀴똥)', 'type': 'select', 'options': ['서랍', '씽크대 하부장 모서리', '씽크대 상부장']},
    ],
    '🚌 교통, 편의시설': [
      {'key': 'subway_distance', 'label': '지하철 거리', 'type': 'select', 'options': ['5분거리', '10분거리', '15분거리', '20분거리']},
      {'key': 'bus_distance', 'label': '버스 정류장', 'type': 'select', 'options': ['5분거리', '10분거리', '15분거리', '20분거리']},
      {'key': 'convenience_store', 'label': '편의점 거리', 'type': 'select', 'options': ['5분거리', '10분거리', '15분거리', '20분거리']},
    ],
    '미관': [
      {'key': 'molding', 'label': '몰딩', 'type': 'select', 'options': ['체리몰딩', '화이트몰딩', '없음', '나무']},
      {'key': 'window_film', 'label': '창문', 'type': 'select', 'options': ['난초그림시트', '격자무늬 시트지', '네모패턴시트지', '없음']},
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 갤러리 (3개 사진)
            Container(
              height: 120,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '집 이름 : ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        widget.propertyData.name.isNotEmpty 
                            ? widget.propertyData.name 
                            : '부동산 ${widget.propertyData.order}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < widget.propertyData.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📍 송파구동',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
            )),
            
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          '사진',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Map<String, dynamic>> items, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[400]!, width: 1),
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
              children: items.map((item) => _buildInfoRow(
                item['label'], 
                _getPropertyValue(item['key']),
                item,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Map<String, dynamic> itemConfig) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showEditDialog(label, value, itemConfig),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value.isNotEmpty ? value : '입력하세요',
                  style: TextStyle(
                    fontSize: 13,
                    color: value.isNotEmpty ? Colors.black87 : Colors.grey[500],
                  ),
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

  void _showEditDialog(String label, String currentValue, Map<String, dynamic> itemConfig) {
    if (itemConfig['type'] == 'select') {
      _showSelectDialog(label, currentValue, itemConfig);
    } else {
      _showTextEditDialog(label, currentValue, itemConfig);
    }
  }

  void _showSelectDialog(String label, String currentValue, Map<String, dynamic> itemConfig) {
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
              trailing: currentValue == option ? const Icon(Icons.check, color: Color(0xFFFF8A65)) : null,
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

  void _showTextEditDialog(String label, String currentValue, Map<String, dynamic> itemConfig) {
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
          maxLines: itemConfig['key'] == 'special_terms' || itemConfig['key'] == 'special_notes' ? 3 : 1,
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
}