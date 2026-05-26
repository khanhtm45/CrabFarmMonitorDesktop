import 'package:flutter/foundation.dart';

import '../data/mock_harvest_sales_data.dart';
import '../models/harvest_sales.dart';

class HarvestSalesService extends ChangeNotifier {
  final List<QualifiedCrab> _qualified =
      List.of(MockHarvestSalesData.qualifiedCrabs(), growable: true);
  final List<SalesOrder> _orders =
      List.of(MockHarvestSalesData.orders(), growable: true);
  final List<HarvestSlip> _harvests = [];

  String _search = '';

  HarvestSalesKpi get kpi => MockHarvestSalesData.kpi;
  String get aiInsight => MockHarvestSalesData.aiInsight;
  String get aiRecommendation => MockHarvestSalesData.aiRecommendation;
  MarketInfo get market => MockHarvestSalesData.market;
  List<CrabSizeSegment> get sizeDistribution =>
      MockHarvestSalesData.sizeDistribution();
  List<MonthlyFinancePoint> get monthlyFinance =>
      MockHarvestSalesData.monthlyFinance();
  List<BatchProfitPoint> get batchProfits => MockHarvestSalesData.batchProfits();
  List<Customer> get customers => MockHarvestSalesData.customers();
  List<HarvestSlip> get harvests => List.unmodifiable(_harvests);

  List<QualifiedCrab> get qualifiedCrabs {
    if (_search.trim().isEmpty) return List.unmodifiable(_qualified);
    final q = _search.toLowerCase();
    return _qualified
        .where(
          (c) =>
              c.code.toLowerCase().contains(q) ||
              c.batchId.toLowerCase().contains(q),
        )
        .toList();
  }

  List<SalesOrder> get orders {
    if (_search.trim().isEmpty) return List.unmodifiable(_orders);
    final q = _search.toLowerCase();
    return _orders
        .where(
          (o) =>
              o.code.toLowerCase().contains(q) ||
              o.customerName.toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void createHarvestSlip({
    required String harvestDate,
    required String batchId,
    required String area,
    required int quantity,
    required double totalWeightKg,
    required String performedBy,
    String? note,
  }) {
    final id = 'h-${DateTime.now().millisecondsSinceEpoch}';
    _harvests.add(
      HarvestSlip(
        id: id,
        code: 'TH${(_harvests.length + 1).toString().padLeft(4, '0')}',
        harvestDate: harvestDate,
        batchId: batchId,
        area: area,
        quantity: quantity,
        totalWeightKg: totalWeightKg,
        performedBy: performedBy,
        note: note,
      ),
    );
    notifyListeners();
  }
}
