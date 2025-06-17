import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/property_chart_model.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-detail';
  static const routePath = ':cardId';

  final String cardId;
  final PropertyData? propertyData;

  const CardDetailScreen({super.key, required this.cardId, this.propertyData});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  // 실제 PropertyData (나중에 Provider로 가져올 예정)
  PropertyData? propertyData;

  @override
  void initState() {
    super.initState();
    // PropertyData가 생성자로 전달되었으면 사용, 아니면 기본값으로 생성
    propertyData = widget.propertyData ?? PropertyData(
      id: widget.cardId,
      order: '',
      name: '',
      deposit: '',
      rent: '',
      direction: '',
      landlordEnvironment: '',
      rating: 0,
    );
  }

  // 카테고리별 항목 정의 (차트에서 사용하는 모든 항목들)
  final Map<String, List<Map<String, dynamic>>> categories = {
    '기본 정보': [
      {'key': 'order', 'label': '순번'},
      {'key': 'name', 'label': '집 이름'},
      {'key': 'deposit', 'label': '보증금'},
      {'key': 'rent', 'label': '월세'},
      {'key': 'rating', 'label': '별점 (1-5)'},
    ],
    '필수 정보': [
      {'key': 'housing_type', 'label': '주거 형태'},
      {'key': 'building_use', 'label': '건축물용도'},
      {'key': 'lease_registration', 'label': '임차권등기명령 이력'},
      {'key': 'mortgage', 'label': '근저당권'},
      {'key': 'seizure_history', 'label': '가압류, 압류, 경매 이력'},
      {'key': 'contract_conditions', 'label': '계약 조건'},
      {'key': 'property_register', 'label': '등기부등본(말소사항 포함으로)'},
      {'key': 'move_in_date', 'label': '입주 가능일'},
      {'key': 'resident_registration', 'label': '전입신고'},
      {'key': 'maintenance_fee', 'label': '관리비'},
      {'key': 'housing_insurance', 'label': '주택보증보험'},
      {'key': 'special_terms', 'label': '특약'},
      {'key': 'special_notes', 'label': '특이사항'},
    ],
    '부동산 상세 정보': [
      {'key': 'area', 'label': '평수'},
      {'key': 'room_count', 'label': '방개수'},
      {'key': 'room_structure', 'label': '방구조'},
      {'key': 'window_view', 'label': '창문 뷰'},
      {'key': 'direction', 'label': '방향(나침반)'},
      {'key': 'lighting', 'label': '채광'},
      {'key': 'floor', 'label': '층수'},
      {'key': 'elevator', 'label': '엘리베이터'},
      {'key': 'air_conditioning', 'label': '에어컨 방식'},
      {'key': 'heating', 'label': '난방방식'},
      {'key': 'veranda', 'label': '베란다'},
      {'key': 'balcony', 'label': '발코니'},
      {'key': 'parking', 'label': '주차장'},
      {'key': 'bathroom', 'label': '화장실'},
      {'key': 'gas_type', 'label': '가스'},
    ],
    '교통 및 편의시설': [
      {'key': 'subway_distance', 'label': '지하철 거리'},
      {'key': 'bus_distance', 'label': '버스 정류장'},
      {'key': 'convenience_store', 'label': '편의점 거리'},
    ],
    '치안 관련': [
      {'key': 'location_type', 'label': '위치'},
      {'key': 'cctv', 'label': 'cctv 여부'},
      {'key': 'window_condition', 'label': '창문 상태'},
      {'key': 'door_condition', 'label': '문 상태'},
      {'key': 'landlord_environment', 'label': '집주인 성격'},
      {'key': 'landlord_residence', 'label': '집주인 거주'},
      {'key': 'nearby_bars', 'label': '집근처 술집'},
      {'key': 'security_bars', 'label': '저층 방범창'},
      {'key': 'day_atmosphere', 'label': '집주변 낮분위기'},
      {'key': 'night_atmosphere', 'label': '집주변 밤분위기'},
      {'key': 'double_lock', 'label': '2종 잠금장치'},
    ],
    '환경 및 청결': [
      {'key': 'noise_source', 'label': '집 근처 소음원'},
      {'key': 'indoor_noise', 'label': '실내소음'},
      {'key': 'double_window', 'label': '이중창(소음, 외풍)'},
      {'key': 'window_seal', 'label': '창문 밀폐(미세먼지)'},
      {'key': 'water_pressure', 'label': '수압'},
      {'key': 'water_leak', 'label': '누수'},
      {'key': 'ac_mold', 'label': '에어컨 내부 곰팡이'},
      {'key': 'ac_smell', 'label': '에어컨 냄새'},
      {'key': 'ventilation', 'label': '환기(공기순환)'},
      {'key': 'mold', 'label': '곰팡이(벽,화장실,베란다)'},
      {'key': 'smell', 'label': '냄새'},
      {'key': 'insects', 'label': '벌레(바퀴똥)'},
    ],
    '미관 및 기타': [
      {'key': 'molding', 'label': '몰딩'},
      {'key': 'window_film', 'label': '창문'},
      {'key': 'related_links', 'label': '관련 링크'},
      {'key': 'real_estate_info', 'label': '부동산 정보'},
      {'key': 'landlord_info', 'label': '집주인 정보'},
      {'key': 'agent_check', 'label': '계약시 중개보조인인지 중개사인지 체크'},
      {'key': 'memo', 'label': '메모'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    if (propertyData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF8A65),
          centerTitle: true,
          title: const Text(
            '부동산 상세정보',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        title: Text(
          propertyData!.name.isNotEmpty 
            ? propertyData!.name 
            : '부동산 ${propertyData!.order.isNotEmpty ? propertyData!.order : widget.cardId}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 갤러리
            Container(
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
            
            // 기본 정보 요약
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    propertyData!.name.isNotEmpty 
                      ? propertyData!.name 
                      : '부동산 ${propertyData!.order.isNotEmpty ? propertyData!.order : widget.cardId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) => Icon(
                          index < propertyData!.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        )),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${propertyData!.rating}/5',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildSummaryItem('보증금', propertyData!.deposit),
                      const SizedBox(width: 16),
                      _buildSummaryItem('월세', propertyData!.rent),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 2),
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

  Widget _buildInfoSection(String title, List<Map<String, dynamic>> items, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: items.map((item) => _buildInfoRow(
                item['label'], 
                _getPropertyValue(item['key']),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            child: Text(
              value.isNotEmpty ? value : '입력하세요',
              style: TextStyle(
                fontSize: 13,
                color: value.isNotEmpty ? Colors.black87 : Colors.grey[500],
                fontWeight: value.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPropertyValue(String key) {
    switch (key) {
      case 'order':
        return propertyData!.order;
      case 'name':
        return propertyData!.name;
      case 'deposit':
        return propertyData!.deposit;
      case 'rent':
        return propertyData!.rent;
      case 'direction':
        return propertyData!.direction;
      case 'landlord_environment':
        return propertyData!.landlordEnvironment;
      case 'rating':
        return propertyData!.rating.toString();
      case 'memo':
        return propertyData!.memo ?? '';
      default:
        return propertyData!.additionalData[key] ?? '';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '기본 정보':
        return const Color(0xFFE3F2FD);
      case '필수 정보':
        return const Color(0xFFFFCDD2);
      case '부동산 상세 정보':
        return const Color(0xFFFFF9C4);
      case '교통 및 편의시설':
        return const Color(0xFFFFF3E0);
      case '치안 관련':
        return const Color(0xFFE8F5E8);
      case '환경 및 청결':
        return const Color(0xFFE1F5FE);
      case '미관 및 기타':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFF5F5F5);
    }
  }
}