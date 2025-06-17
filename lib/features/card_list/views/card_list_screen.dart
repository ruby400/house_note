import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:house_note/data/models/card_model.dart';
// import 'package:house_note/data/models/user_model.dart'; // 사용되지 않으므로 제거
import 'package:house_note/providers/card_providers.dart';
import 'package:house_note/providers/auth_providers.dart';
import 'package:house_note/providers/user_providers.dart';
import 'package:house_note/features/card_list/views/property_detail_screen.dart';
import 'package:house_note/data/models/property_chart_model.dart';
import 'package:house_note/providers/property_chart_providers.dart';

class CardListScreen extends ConsumerStatefulWidget {
  static const routeName = 'card-list';
  static const routePath = '/cards';

  const CardListScreen({super.key});

  @override
  ConsumerState<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends ConsumerState<CardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = '최신순'; // 기본 정렬 방식
  String? _selectedChartId; // 선택된 차트 ID
  // 재할당되지 않으므로 final로 변경
  final List<String> _customSortOptions = ['최신순', '거리순', '월세순']; // 사용자 정의 정렬 옵션

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateChangesProvider).asData?.value?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('카드 목록',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8A65),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색 바 및 필터 영역
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                // 검색 바
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '지역, 가격으로 검색...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            // TODO: 검색 기능 구현
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.add, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 필터 버튼들
                Row(
                  children: [
                    // 차트 선택 드롭다운
                    Consumer(
                      builder: (context, ref, child) {
                        final chartList = ref.watch(propertyChartListProvider);
                        return DropdownButton<String?>(
                          value: _selectedChartId,
                          hint: const Text('모든 차트',
                              style: TextStyle(fontSize: 14)),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('모든 차트'),
                            ),
                            ...chartList
                                .map((chart) => DropdownMenuItem<String>(
                                      value: chart.id,
                                      child: Text(chart.title.isNotEmpty
                                          ? chart.title
                                          : '차트 ${chart.id}'),
                                    )),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedChartId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // 정렬 드롭다운
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedSort,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        ..._customSortOptions
                            .map((option) => PopupMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                )),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'ADD_NEW',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text('새 정렬 방식 추가'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'ADD_NEW') {
                          _showAddSortOptionDialog();
                        } else {
                          setState(() {
                            _selectedSort = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 카드 리스트 (차트 데이터 기반)
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final chartList = ref.watch(propertyChartListProvider);
                final propertyList = <PropertyData>[];

                // 선택된 차트에 따라 필터링
                if (_selectedChartId != null) {
                  final selectedChart = chartList.firstWhere(
                    (chart) => chart.id == _selectedChartId,
                    orElse: () => PropertyChartModel(
                      id: '',
                      title: '',
                      date: DateTime.now(),
                      properties: [],
                    ),
                  );
                  propertyList.addAll(selectedChart.properties);
                } else {
                  // 모든 차트의 부동산 데이터를 하나의 리스트로 합치기
                  for (final chart in chartList) {
                    propertyList.addAll(chart.properties);
                  }
                }

                // 선택된 정렬 방식에 따라 정렬
                _sortPropertyList(propertyList);

                if (propertyList.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildCardList(propertyList);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (userId != null) {
            _showAddCardDialog(context, ref, userId);
          }
        },
        backgroundColor: const Color(0xFFFF8A65),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddSortOptionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('정렬 옵션 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '정렬 방식 이름',
              hintText: '예: 별점순, 방향순 등',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _customSortOptions.add(controller.text.trim());
                  });
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sortPropertyList(List<PropertyData> properties) {
    switch (_selectedSort) {
      case '최신순':
        properties.sort((a, b) => b.id.compareTo(a.id));
        break;
      case '거리순':
        properties.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '월세순':
        properties.sort((a, b) {
          final rentA = _extractNumberFromString(a.rent);
          final rentB = _extractNumberFromString(b.rent);
          return rentA.compareTo(rentB);
        });
        break;
      case '별점순':
        properties.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '보증금순':
        properties.sort((a, b) {
          final depositA = _extractNumberFromString(a.deposit);
          final depositB = _extractNumberFromString(b.deposit);
          return depositA.compareTo(depositB);
        });
        break;
      case '이름순':
        properties.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        if (_selectedSort.contains('순')) {
          final sortField = _selectedSort.replaceAll('순', '');
          properties.sort((a, b) {
            final valueA = _getPropertyValueForPriority(sortField, a) ?? '';
            final valueB = _getPropertyValueForPriority(sortField, b) ?? '';
            return valueA.compareTo(valueB);
          });
        }
        break;
    }
  }

  int _extractNumberFromString(String text) {
    final regex = RegExp(r'\d+');
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('등록된 카드가 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('첫 번째 카드를 추가해보세요!',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCardList(List<PropertyData> properties) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _buildCardItem(property);
      },
    );
  }

  Widget _buildCardItem(PropertyData property) {
    return Consumer(
      builder: (context, ref, child) {
        final userPriorities = ref.watch(userPrioritiesProvider);

        return GestureDetector(
          onTap: () {
            context.goNamed(
              PropertyDetailScreen.routeName,
              extra: property,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            // [수정된 부분] const 제거
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.name.isNotEmpty
                                      ? property.name
                                      : '부동산 ${property.order}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (property.rating > 0) ...[
                                  Row(
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < property.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (property.rent.isNotEmpty ||
                                    property.deposit.isNotEmpty) ...[
                                  Text(
                                    '월세: ${property.rent.isNotEmpty ? property.rent : '-'} | 보증금: ${property.deposit.isNotEmpty ? property.deposit : '-'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.home,
                              color: Colors.grey[400],
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                      if (userPriorities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildPriorityTags(property),
                      ],
                    ],
                  ),
                ),
                if (property.order.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '순번: ${property.order}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityTags(PropertyData property) {
    return Consumer(
      builder: (context, ref, child) {
        final realtimeChartList = ref.watch(propertyChartListProvider);

        PropertyChartModel? currentChart;
        for (var chart in realtimeChartList) {
          if (chart.properties.any((p) => p.id == property.id)) {
            currentChart = chart;
            break;
          }
        }

        List<Widget> tags = [];
        Set<String> addedTags = {};

        const fixedItems = {'집 이름', '월세', '보증금', '순'};

        final visibilityMap = currentChart?.columnVisibility;

        if (visibilityMap != null && visibilityMap.isNotEmpty) {
          final visibleColumns = visibilityMap.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .where((column) => !fixedItems.contains(column))
              .take(6)
              .toList();

          for (String column in visibleColumns) {
            if (addedTags.contains(column)) continue;

            String? value = _getColumnValueForProperty(column, property);

            final displayValue =
                (value != null && value.isNotEmpty && value != '-')
                    ? value
                    : '미입력';

            addedTags.add(column);
            tags.add(
              Text(
                '$column: $displayValue',
                style: TextStyle(
                  fontSize: 14,
                  color: (value != null && value.isNotEmpty && value != '-')
                      ? Colors.grey[600]
                      : Colors.orange[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            );
          }
        }

        if (tags.isEmpty) return const SizedBox.shrink();

        final tagTexts = <String>[];

        for (int i = 0; i < tags.length; i++) {
          final tag = tags[i] as Text;
          final text = tag.data!;
          tagTexts.add(text);
        }

        final combinedText = tagTexts.join(' | ');

        return Text(
          combinedText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 3,
          overflow: TextOverflow.visible,
        );
      },
    );
  }

  String? _getColumnValueForProperty(String columnName, PropertyData property) {
    switch (columnName) {
      case '집 이름':
        return property.name.isNotEmpty
            ? property.name
            : '부동산 ${property.order}';
      case '보증금':
        return property.deposit;
      case '월세':
        return property.rent;
      case '재계/방향':
        return property.direction;
      case '집주인 환경':
        return property.landlordEnvironment;
      case '별점':
        return property.rating > 0 ? property.rating.toString() : null;
      case '주거형태':
      case '건축물용도':
      case '임차권 등기명령 이력여부':
      case '수도 수납':
      case '공광비':
      case '재산/방화':
      case '소음':
      case '편의점':
      default:
        return _getAdditionalDataByColumnName(columnName, property);
    }
  }

  String? _getAdditionalDataByColumnName(
      String columnName, PropertyData property) {
    const columnIndexMap = {
      '집 이름': 1,
      '보증금': 2,
      '월세': 3,
      '주거형태': 4,
      '건축물용도': 5,
      '임차권 등기명령 이력여부': 6,
      '재계/방향': 7,
      '집주인 환경': 8,
      '별점': 9,
      '수도 수납': 10,
      '공광비': 11,
      '재산/방화': 12,
      '소음': 13,
      '편의점': 14,
    };

    final columnIndex = columnIndexMap[columnName];
    if (columnIndex != null && columnIndex >= 7) {
      final dataKey = 'col_$columnIndex';
      return property.additionalData[dataKey];
    }

    return property.additionalData[columnName];
  }

  String? _getPropertyValueForPriority(String priority, PropertyData property) {
    switch (priority) {
      case '월세':
      case '월세비용':
        return property.rent;
      case '보증금':
        return property.deposit;
      case '방향':
      case '재계/방향':
        return property.direction;
      case '집주인 환경':
      case '환경':
        return property.landlordEnvironment;
      case '별점':
      case '평점':
        return property.rating > 0 ? property.rating.toString() : null;
      case '집 이름':
      case '이름':
        return property.name;
      default:
        return property.additionalData[priority];
    }
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref, String userId) {
    final nameController = TextEditingController();
    final companyController = TextEditingController();
    final lastFourController = TextEditingController();
    final typeController = TextEditingController(text: 'credit');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('새 부동산 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '부동산 이름')),
                TextField(
                    controller: companyController,
                    decoration: const InputDecoration(labelText: '위치')),
                TextField(
                  controller: lastFourController,
                  decoration: const InputDecoration(labelText: '월세 금액'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: '부동산 종류')),
              ],
            ),
          ),
          actions: [
            TextButton(
                child: const Text('취소'),
                onPressed: () => Navigator.of(ctx).pop()),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                final newCard = CardModel(
                  id: '',
                  userId: userId,
                  name: nameController.text,
                  company: companyController.text,
                  numberLastFour: lastFourController.text,
                  type: typeController.text,
                  benefits: [],
                );
                ref.read(cardListViewModelProvider.notifier).addCard(newCard);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
