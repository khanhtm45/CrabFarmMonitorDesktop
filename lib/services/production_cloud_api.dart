part of 'cloud_api_client.dart';

/// CRUD phân cấp Khu → Dãy → Hộp → Đợt → Cua (domain Cloud).
extension ProductionCloudApi on CloudApiClient {
  Future<String> fetchNextAreaCode(String token, String farmId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/next-code')
        .replace(queryParameters: {'farmId': farmId});
    final res = await _client.get(uri, headers: authHeaders(token, farmId: farmId));
    return _parseNextCode(res);
  }

  Future<String> fetchNextRowCode(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/rows/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseNextCode(res);
  }

  Future<String> fetchNextBoxCode(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/boxes/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseNextCode(res);
  }

  Future<String> fetchNextBatchCode(String token, String boxId) async {
    final uri =
        Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId/batches/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseNextCode(res);
  }

  Future<String> fetchNextBatchCrabCode(String token, String batchId) async {
    final uri = Uri.parse(
        '${AppEnv.cloudApiUrl}/api/farming-batches/$batchId/crabs/next-code');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseNextCode(res);
  }

  Future<List<AreaRecord>> fetchAreas(String token, String farmId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas')
        .replace(queryParameters: {'farmId': farmId});
    final res = await _client.get(uri, headers: authHeaders(token, farmId: farmId));
    return _parseList(res, 'areas', AreaRecord.fromJson);
  }

  Future<AreaRecord> createArea(
    String token,
    String farmId, {
    required String areaName,
    String? areaCode,
    String? description,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas')
        .replace(queryParameters: {'farmId': farmId});
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token, farmId: farmId), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'areaName': areaName,
        if (areaCode != null && areaCode.isNotEmpty) 'areaCode': areaCode,
        if (description != null) 'description': description,
      }),
    );
    return _parseSingle(res, 'area', AreaRecord.fromJson);
  }

  Future<AreaRecord> updateArea(
    String token,
    String areaId, {
    required String areaCode,
    required String areaName,
    String? description,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'areaCode': areaCode,
        'areaName': areaName,
        'description': description,
      }),
    );
    return _parseSingle(res, 'area', AreaRecord.fromJson);
  }

  Future<void> deleteArea(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<RowRecord>> fetchRows(String token, String areaId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/rows');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'rows', RowRecord.fromJson);
  }

  Future<RowRecord> createRow(
    String token,
    String areaId, {
    required String rowName,
    String? rowCode,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/areas/$areaId/rows');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'rowName': rowName,
        if (rowCode != null && rowCode.isNotEmpty) 'rowCode': rowCode,
      }),
    );
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<RowRecord> updateRow(
    String token,
    String rowId, {
    required String rowCode,
    required String rowName,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({'rowCode': rowCode, 'rowName': rowName}),
    );
    return _parseSingle(res, 'row', RowRecord.fromJson);
  }

  Future<void> deleteRow(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<BoxRecord>> fetchBoxes(String token, String rowId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/boxes');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'boxes', BoxRecord.fromJson);
  }

  Future<BoxRecord> createBox(
    String token,
    String rowId, {
    String? boxCode,
    String? position,
    double? volume,
    String status = 'empty',
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/boxes');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (boxCode != null && boxCode.isNotEmpty) 'boxCode': boxCode,
        if (position != null) 'position': position,
        if (volume != null) 'volume': volume,
        'status': status,
      }),
    );
    return _parseSingle(res, 'box', BoxRecord.fromJson);
  }

  Future<List<BoxRecord>> createBoxesBulk(
    String token,
    String rowId, {
    required int count,
    String? positionPrefix,
    double? volume,
    String status = 'empty',
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/boxes/bulk');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'count': count,
        if (positionPrefix != null && positionPrefix.isNotEmpty)
          'positionPrefix': positionPrefix,
        if (volume != null) 'volume': volume,
        'status': status,
      }),
    );
    return _parseList(res, 'boxes', BoxRecord.fromJson);
  }

  Future<BoxRecord> updateBox(
    String token,
    String boxId, {
    required String boxCode,
    String? position,
    double? volume,
    required String status,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'boxCode': boxCode,
        'position': position,
        'volume': volume,
        'status': status,
      }),
    );
    return _parseSingle(res, 'box', BoxRecord.fromJson);
  }

  Future<void> deleteBox(String token, String boxId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<FarmingBatchRecord>> fetchBatches(String token, String boxId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId/batches');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'batches', FarmingBatchRecord.fromJson);
  }

  Future<List<FarmingBatchRecord>> fetchBatchesByRow(
    String token,
    String rowId,
  ) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/batches');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'batches', FarmingBatchRecord.fromJson);
  }

  Future<List<FarmingBatchRecord>> createBatchesBulk(
    String token,
    String rowId, {
    required List<String> boxIds,
    required DateTime startDate,
    required DateTime expectedHarvestDate,
    int initialQuantity = 0,
    bool startNow = true,
    String status = 'active',
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/rows/$rowId/batches/bulk');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'boxIds': boxIds,
        'startDate': _dateOnly(startDate),
        'expectedHarvestDate': _dateOnly(expectedHarvestDate),
        'initialQuantity': initialQuantity,
        'startNow': startNow,
        'status': status,
      }),
    );
    return _parseList(res, 'batches', FarmingBatchRecord.fromJson);
  }

  Future<FarmingBatchRecord> createBatch(
    String token,
    String boxId, {
    String? batchCode,
    required DateTime startDate,
    DateTime? expectedHarvestDate,
    int initialQuantity = 0,
    int currentQuantity = 0,
    String status = 'active',
    bool startNow = false,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/boxes/$boxId/batches');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (batchCode != null && batchCode.isNotEmpty) 'batchCode': batchCode,
        'startDate': _dateOnly(startDate),
        'expectedHarvestDate': _dateOnly(expectedHarvestDate),
        'initialQuantity': initialQuantity,
        'currentQuantity': currentQuantity > 0 ? currentQuantity : initialQuantity,
        'status': status,
        'startNow': startNow,
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
  }

  Future<FarmingBatchRecord> updateBatch(
    String token,
    String batchId, {
    required String batchCode,
    required DateTime startDate,
    DateTime? expectedHarvestDate,
    DateTime? actualHarvestDate,
    required int initialQuantity,
    required int currentQuantity,
    required String status,
    bool startNow = false,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-batches/$batchId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'batchCode': batchCode,
        'startDate': _dateOnly(startDate),
        'expectedHarvestDate': _dateOnly(expectedHarvestDate),
        'actualHarvestDate': _dateOnly(actualHarvestDate),
        'initialQuantity': initialQuantity,
        'currentQuantity': currentQuantity,
        'status': status,
        'startNow': startNow,
      }),
    );
    return _parseSingle(res, 'batch', FarmingBatchRecord.fromJson);
  }

  Future<void> deleteBatch(String token, String batchId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/farming-batches/$batchId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  Future<List<BatchCrabRecord>> fetchBatchCrabs(String token, String batchId) async {
    final uri =
        Uri.parse('${AppEnv.cloudApiUrl}/api/farming-batches/$batchId/crabs');
    final res = await _client.get(uri, headers: authHeaders(token));
    return _parseList(res, 'crabs', BatchCrabRecord.fromJson);
  }

  Future<BatchCrabRecord> createBatchCrab(
    String token,
    String batchId, {
    String? crabCode,
    String gender = 'unknown',
    double? weight,
    double? shellWidth,
    String status = 'alive',
  }) async {
    final uri =
        Uri.parse('${AppEnv.cloudApiUrl}/api/farming-batches/$batchId/crabs');
    final res = await _client.post(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        if (crabCode != null && crabCode.isNotEmpty) 'crabCode': crabCode,
        'gender': gender,
        'weight': weight,
        'shellWidth': shellWidth,
        'status': status,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  Future<BatchCrabRecord> updateBatchCrab(
    String token,
    String crabId, {
    required String crabCode,
    required String gender,
    double? weight,
    double? shellWidth,
    required String status,
  }) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/batch-crabs/$crabId');
    final res = await _client.put(
      uri,
      headers: {...authHeaders(token), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'crabCode': crabCode,
        'gender': gender,
        'weight': weight,
        'shellWidth': shellWidth,
        'status': status,
      }),
    );
    return _parseSingle(res, 'crab', BatchCrabRecord.fromJson);
  }

  Future<void> deleteBatchCrab(String token, String crabId) async {
    final uri = Uri.parse('${AppEnv.cloudApiUrl}/api/batch-crabs/$crabId');
    final res = await _client.delete(uri, headers: authHeaders(token));
    _ensureOk(res);
  }

  String _parseNextCode(http.Response res) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Không lấy mã (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return (body['code'] ?? body['Code'] ?? '').toString();
  }

  String? _dateOnly(DateTime? dt) {
    if (dt == null) return null;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<T> _parseList<T>(
    http.Response res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Lỗi API (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final raw = body[listKey];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  T _parseSingle<T>(
    http.Response res,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = _decode(res);
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || body['ok'] == false) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Thao tác thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final raw = body[key];
    if (raw is! Map) throw CloudApiException('Phản hồi thiếu $key');
    return fromJson(Map<String, dynamic>.from(raw));
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode == 401) {
      throw CloudApiException('Phiên đăng nhập hết hạn', statusCode: 401);
    }
    if (res.statusCode == 204) return;
    final body = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CloudApiException(
        _errorMessage(body) ?? 'Xóa thất bại (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
  }

}
