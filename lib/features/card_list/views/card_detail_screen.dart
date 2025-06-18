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
  Map<String, bool> showPlaceholder = {};

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
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            '부동산 상세정보',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFAB91), // 밝은 주황색 (왼쪽 위)
                  Color(0xFFFF8A65), // 메인 주황색 (중간)
                  Color(0xFFFF7043), // 진한 주황색 (오른쪽 아래)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFAB91), // 밝은 주황색 (왼쪽 위)
                Color(0xFFFF8A65), // 메인 주황색 (중간)
                Color(0xFFFF7043), // 진한 주황색 (오른쪽 아래)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
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
                  // 이름 편집
                  isEditMode
                      ? TextField(
                          controller: TextEditingController(
                            text: editedValues['name'] ?? propertyData!.name,
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: '부동산 이름',
                          ),
                          onChanged: (value) {
                            editedValues['name'] = value;
                          },
                        )
                      : Text(
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
                  // 별점 편집
                  Row(
                    children: [
                      isEditMode
                          ? Row(
                              children: List.generate(5, (index) {
                                final currentRating = int.tryParse(editedValues['rating'] ?? '') ?? propertyData!.rating;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      editedValues['rating'] = (index + 1).toString();
                                    });
                                  },
                                  child: Icon(
                                    index < currentRating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                );
                              }),
                            )
                          : Row(
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
                        '${int.tryParse(editedValues['rating'] ?? '') ?? propertyData!.rating}/5',
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
                      _buildSummaryItem('보증금', propertyData!.deposit, 'deposit'),
                      const SizedBox(width: 16),
                      _buildSummaryItem('월세', propertyData!.rent, 'rent'),
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
      // 사진이 없을 때는 3개의 추가 버튼을 표시
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: i == 1 ? 8 : 4),
                child: GestureDetector(
                  onTap: () => _showImageManager('gallery'),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 243, 242, 242),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 224, 224, 224)!,
                            width: 2),
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
                  ),
                ),
              ),
            ),
        ],
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

  Widget _buildSummaryItem(String label, String value, [String? key]) {
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
            isEditMode && key != null
                ? TextField(
                    controller: TextEditingController(
                      text: editedValues[key] ?? value,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: '입력하세요',
                    ),
                    onChanged: (newValue) {
                      editedValues[key] = newValue;
                    },
                  )
                : Text(
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
              children: [
                for (int i = 0; i < items.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              items[i]['label'],
                              _getPropertyValue(items[i]['key']),
                              items[i]['key'],
                            ),
                          ),
                          if (i + 1 < items.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoRow(
                                items[i + 1]['label'],
                                _getPropertyValue(items[i + 1]['key']),
                                items[i + 1]['key'],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ],
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

  Widget _buildInfoRow(String label, String value, [String? key]) {
    final String currentValue = editedValues[key] ?? value;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레이블 섹션
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isEditMode && key != null)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 14,
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A65).withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    offset: const Offset(0, 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    surfaceTintColor: Colors.white,
                    constraints: const BoxConstraints(
                      minWidth: 260,
                      maxWidth: 320,
                    ),
                    onSelected: (String value) {
                      if (value == 'direct_input') {
                        if (mounted) {
                          setState(() {
                            showPlaceholder[key!] = true;
                          });
                        }
                      } else if (value == 'add_new') {
                        _showAddOptionDialog(key!);
                      } else {
                        if (mounted) {
                          setState(() {
                            editedValues[key!] = value;
                            showPlaceholder[key!] = false;
                          });
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final List<String> options = dropdownOptions[key] ?? [];
                      return [
                        PopupMenuItem<String>(
                          height: 48,
                          value: 'direct_input',
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[200]!, width: 1),
                            ),
                            child: Row(
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
                              height: 44,
                              value: option,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
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
                          height: 48,
                          value: 'add_new',
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey[200]!, width: 1),
                            ),
                            child: Row(children: [
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
                            ]),
                          ),
                        ),
                      ];
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 값 섹션
          SizedBox(
            height: 24,
            child: isEditMode
                ? _buildEditableField(key, currentValue)
                : currentValue.isNotEmpty 
                    ? Text(
                        currentValue,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: null,
                      )
                    : Container(),
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
        // Handle all other additional data
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
    final bool shouldShowPlaceholder = key != null && (showPlaceholder[key] ?? false);
    
    return TextField(
      controller: TextEditingController(text: value),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: shouldShowPlaceholder ? '입력하세요' : null,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 1,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 8,
          title: Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFFFECE0), width: 2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8A65).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                const Text(
                  '새 옵션 추가',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '새로운 옵션을 추가하여 선택할 수 있습니다.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D4C41)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: '옵션 이름',
                  labelStyle: const TextStyle(color: Color(0xFFFF8A65)),
                  hintText: '새 옵션을 입력하세요',
                  hintStyle: const TextStyle(color: Color(0xFFBCAAA4)),
                  prefixIcon: const Icon(Icons.edit, color: Color(0xFFFF8A65)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFF8A65), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFFFFCCBC)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF8F5),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('취소', style: TextStyle(color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A65), Color(0xFFFFAB91)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    if (mounted) {
                      setState(() {
                        if (!dropdownOptions.containsKey(key)) {
                          dropdownOptions[key] = [];
                        }
                        dropdownOptions[key]!.add(controller.text);
                        editedValues[key] = controller.text;
                        showPlaceholder[key] = false;
                      });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${controller.text}" 옵션이 추가되었습니다.', 
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        backgroundColor: const Color(0xFFFF8A65),
                        duration: const Duration(milliseconds: 1000),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
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
