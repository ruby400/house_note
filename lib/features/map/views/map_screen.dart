import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: ViewModel, 지도 데이터 Provider import
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // google_maps_flutter 사용시

class MapScreen extends ConsumerStatefulWidget {
  static const routeName = 'map';
  static const routePath = '/map';

  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // GoogleMapController? _mapController; // 컨트롤러 필요시

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('지도',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
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
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 지도 옵션 메뉴
            },
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바 영역
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
                            hintText: '장소, 주소로 검색...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        color: const Color(0xFFFF8A65),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 지도 영역
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Stack(
                children: [
                  // 지도가 들어갈 자리 (현재는 플레이스홀더)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '지도 기능 업데이트 예정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '더 나은 서비스로 찾아뵙겠습니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TODO: 실제 구글 지도가 여기에 들어감
                  // GoogleMap(
                  //   initialCameraPosition: const CameraPosition(
                  //     target: LatLng(37.5665, 126.9780), // 서울 시청 좌표 예시
                  //     zoom: 11.0,
                  //   ),
                  //   onMapCreated: (GoogleMapController controller) {
                  //     _mapController = controller;
                  //   },
                  //   markers: const {
                  //     // 마커 추가
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
