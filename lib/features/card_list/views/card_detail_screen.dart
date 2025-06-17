import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/features/chart/views/image_manager_widgets.dart';
import 'package:house_note/providers/property_chart_providers.dart';
import 'dart:io';

class CardDetailScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-detail';
  static const routePath = ':cardId';

  final String cardId;
  final PropertyData? propertyData;
  final String? chartId;
  final bool isNewProperty;

  const CardDetailScreen({
    super.key,
    required this.cardId,
    this.propertyData,
    this.chartId,
    this.isNewProperty = false,
  });

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  // 실제 PropertyData (나중에 Provider로 가져올 예정)
  PropertyData? propertyData;
  bool isEditMode = false;
  Map<String, String> editedValues = {};
  Map<String, List<String>> dropdownOptions = {};

  @override
  void initState() {
    super.initState();
    // PropertyData가 생성자로 전달되었으면 사용, 아니면 기본값으로 생성
    propertyData = widget.propertyData ??
        PropertyData(
          id: widget.cardId,
          order: '',
          name: '',
          deposit: '',
          rent: '',
          direction: '',
          landlordEnvironment: '',
          rating: 0,
        );

    // 새 부동산인 경우 자동으로 편집 모드 활성화
    if (widget.isNewProperty) {
      isEditMode = true;
    }
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
              height: 140,
              padding: const EdgeInsets.all(16),
              child: _buildImageGallery(),
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
                        children: List.generate(
                            5,
                            (index) => Icon(
                                  index < propertyData!.rating
                                      ? Icons.star
                                      : Icons.star_border,
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
      bottomNavigationBar: widget.isNewProperty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFF8A65)),
                        foregroundColor: const Color(0xFFFF8A65),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveNewProperty,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('부동산 저장'),
                    ),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: !widget.isNewProperty
          ? FloatingActionButton(
              onPressed: () {
                if (isEditMode) {
                  _saveChanges();
                }
                if (mounted) {
                  setState(() {
                    isEditMode = !isEditMode;
                  });
                }
              },
              backgroundColor: const Color(0xFFFF8A65),
              child: Icon(
                isEditMode ? Icons.check : Icons.edit,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildImageGallery() {
    final List<String> allImages = propertyData?.cellImages['gallery'] ?? [];

    if (allImages.isEmpty) {
      // 사진이 없을 때는 추가 버튼만 표시
      return GestureDetector(
        onTap: () => _showImageManager('gallery'),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                '사진 추가',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 사진이 있을 때는 모든 사진을 썸네일로 표시 + 추가 버튼
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: allImages.length + 1, // 모든 이미지 + 추가 버튼
      itemBuilder: (context, index) {
        if (index < allImages.length) {
          // 기존 이미지 썸네일
          return Container(
            width: 110,
            height: 110,
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showImageManager('gallery'),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    children: [
                      Image.file(
                        File(allImages[index]),
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 32,
                            ),
                          );
                        },
                      ),
                      // 첫 번째 이미지에 대표 라벨
                      if (index == 0)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A65),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              '대표',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // 사진 순서 표시
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          // 맨 마지막에 추가 버튼
          return Container(
            width: 110,
            height: 110,
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showImageManager('gallery'),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF8A65),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      size: 24,
                      color: const Color(0xFFFF8A65),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '추가',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF8A65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 32,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 4),
        Text(
          '사진 추가',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              children: items
                  .map((item) => _buildInfoRow(
                        item['label'],
                        _getPropertyValue(item['key']),
                        item['key'],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [String? key]) {
    final String currentValue = editedValues[key] ?? value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicHeight(
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
              child: isEditMode
                  ? _buildEditableField(key, currentValue)
                  : Text(
                      currentValue.isNotEmpty ? currentValue : '입력하세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: currentValue.isNotEmpty
                            ? Colors.black87
                            : Colors.grey[500],
                        fontWeight: currentValue.isNotEmpty
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
            ),
            if (isEditMode && key != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8A65).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  offset: const Offset(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 12,
                  shadowColor: Colors.black.withOpacity(0.25),
                  surfaceTintColor: Colors.white,
                  constraints: const BoxConstraints(
                    minWidth: 180,
                    maxWidth: 220,
                  ),
                  onSelected: (String value) {
                    if (value == 'direct_input') {
                      // 직접 입력 모드는 그대로 유지
                    } else if (value == 'add_new') {
                      _showAddOptionDialog(key!);
                    } else {
                      if (mounted) {
                        setState(() {
                          editedValues[key!] = value;
                        });
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final List<String> options = dropdownOptions[key] ?? [];
                    return [
                      PopupMenuItem<String>(
                        height: 44,
                        value: 'direct_input',
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 16, color: Color(0xFF718096)),
                              SizedBox(width: 8),
                              Text(
                                '직접 입력',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (options.isNotEmpty)
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 12,
                          child: Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
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
                      ...options.map((option) => PopupMenuItem<String>(
                            height: 40,
                            value: option,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey[200]!, width: 1),
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          )),
                      PopupMenuItem<String>(
                        enabled: false,
                        height: 12,
                        child: Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
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
                        height: 44,
                        value: 'add_new',
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.grey[200]!, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.add,
                                  size: 16, color: Color(0xFF718096)),
                              SizedBox(width: 8),
                              Text(
                                '새 옵션 추가',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ),
            ],
          ],
        ),
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

  Widget _buildEditableField(String? key, String value) {
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        hintText: '입력하세요',
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (newValue) {
        if (key != null) {
          editedValues[key] = newValue;
        }
      },
    );
  }

  void _showAddOptionDialog(String key) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('새 옵션 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '새 옵션을 입력하세요',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  if (mounted) {
                    setState(() {
                      if (!dropdownOptions.containsKey(key)) {
                        dropdownOptions[key] = [];
                      }
                      dropdownOptions[key]!.add(controller.text);
                      editedValues[key] = controller.text;
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  void _saveChanges() {
    // TODO: 실제 데이터 저장 로직 구현
    // PropertyData는 immutable이므로 copyWith를 사용해서 업데이트
    Map<String, String> additionalDataUpdate =
        Map.from(propertyData!.additionalData);

    for (String key in editedValues.keys) {
      switch (key) {
        case 'order':
          propertyData = propertyData!.copyWith(order: editedValues[key]!);
          break;
        case 'name':
          propertyData = propertyData!.copyWith(name: editedValues[key]!);
          break;
        case 'deposit':
          propertyData = propertyData!.copyWith(deposit: editedValues[key]!);
          break;
        case 'rent':
          propertyData = propertyData!.copyWith(rent: editedValues[key]!);
          break;
        case 'direction':
          propertyData = propertyData!.copyWith(direction: editedValues[key]!);
          break;
        case 'landlord_environment':
          propertyData =
              propertyData!.copyWith(landlordEnvironment: editedValues[key]!);
          break;
        case 'rating':
          propertyData = propertyData!
              .copyWith(rating: int.tryParse(editedValues[key]!) ?? 0);
          break;
        case 'memo':
          propertyData = propertyData!.copyWith(memo: editedValues[key]!);
          break;
        default:
          additionalDataUpdate[key] = editedValues[key]!;
      }
    }

    // additionalData 업데이트가 있는 경우
    if (additionalDataUpdate != propertyData!.additionalData) {
      propertyData =
          propertyData!.copyWith(additionalData: additionalDataUpdate);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('변경사항이 저장되었습니다')),
    );
  }

  void _saveNewProperty() {
    if (propertyData == null || widget.chartId == null) return;

    // Apply edited values to propertyData
    Map<String, String> additionalDataUpdate =
        Map.from(propertyData!.additionalData);

    for (String key in editedValues.keys) {
      switch (key) {
        case 'order':
          propertyData = propertyData!.copyWith(order: editedValues[key]!);
          break;
        case 'name':
          propertyData = propertyData!.copyWith(name: editedValues[key]!);
          break;
        case 'deposit':
          propertyData = propertyData!.copyWith(deposit: editedValues[key]!);
          break;
        case 'rent':
          propertyData = propertyData!.copyWith(rent: editedValues[key]!);
          break;
        case 'direction':
          propertyData = propertyData!.copyWith(direction: editedValues[key]!);
          break;
        case 'landlord_environment':
          propertyData =
              propertyData!.copyWith(landlordEnvironment: editedValues[key]!);
          break;
        case 'rating':
          propertyData = propertyData!
              .copyWith(rating: int.tryParse(editedValues[key]!) ?? 0);
          break;
        case 'memo':
          propertyData = propertyData!.copyWith(memo: editedValues[key]!);
          break;
        default:
          additionalDataUpdate[key] = editedValues[key]!;
      }
    }

    // Update additionalData if needed
    if (additionalDataUpdate != propertyData!.additionalData) {
      propertyData =
          propertyData!.copyWith(additionalData: additionalDataUpdate);
    }

    // Set current chart to the target chart
    final chartList = ref.read(propertyChartListProvider);
    final targetChart = chartList.firstWhere(
      (chart) => chart.id == widget.chartId,
      orElse: () => PropertyChartModel(
        id: widget.chartId!,
        title: '새 차트',
        date: DateTime.now(),
        properties: [],
      ),
    );

    // Add the property to the chart
    ref.read(currentChartProvider.notifier).setChart(targetChart);
    ref.read(currentChartProvider.notifier).addProperty(propertyData!);

    // Update the chart in the main list
    final updatedChart = ref.read(currentChartProvider)!;
    ref.read(propertyChartListProvider.notifier).updateChart(updatedChart);

    // Show success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('새 부동산이 저장되었습니다')),
    );

    // Navigate back to card list
    Navigator.of(context).pop();
  }

  void _showImageManager(String cellKey) {
    final List<String> currentImages = propertyData?.cellImages[cellKey] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ImageManagerBottomSheet(
            rowIndex: 0,
            columnIndex: 0,
            columnName: _getCellDisplayName(cellKey),
            cellKey: cellKey,
            initialImages: currentImages,
            onImageAdded: (String imagePath) {
              if (mounted) {
                setState(() {
                  final currentImages = propertyData?.cellImages[cellKey] ?? [];
                  final updatedImages = List<String>.from(currentImages);
                  updatedImages.add(imagePath);

                  final updatedCellImages =
                      Map<String, List<String>>.from(propertyData!.cellImages);
                  updatedCellImages[cellKey] = updatedImages;

                  propertyData =
                      propertyData!.copyWith(cellImages: updatedCellImages);
                });
              }
            },
            onImageDeleted: (String imagePath) {
              if (mounted) {
                setState(() {
                  final currentImages = propertyData?.cellImages[cellKey] ?? [];
                  final updatedImages = List<String>.from(currentImages);
                  updatedImages.remove(imagePath);

                  final updatedCellImages =
                      Map<String, List<String>>.from(propertyData!.cellImages);
                  updatedCellImages[cellKey] = updatedImages;

                  propertyData =
                      propertyData!.copyWith(cellImages: updatedCellImages);
                });
              }
            },
          ),
        ),
      ),
    );
  }

  String _getCellDisplayName(String cellKey) {
    switch (cellKey) {
      case 'gallery':
        return '사진 갤러리';
      default:
        return '사진';
    }
  }
}
