import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/models/epi_model.dart';
import '../data/models/incident_model.dart';
import '../data/models/stock_movement_model.dart';
import '../data/repositories/epi_repository.dart';
import '../data/repositories/incident_repository.dart';
import '../data/repositories/stock_movement_repository.dart';

/// Exporte toutes les données HSE vers un fichier Excel (.xlsx) professionnel et bien structuré.
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  final EpiRepository _epiRepo = EpiRepository();
  final StockMovementRepository _movementRepo = StockMovementRepository();
  final IncidentRepository _incidentRepo = IncidentRepository();

  static const String _sheetResume = 'Résumé';
  static const String _sheetEpi = 'EPI';
  static const String _sheetMouvements = 'Mouvements';
  static const String _sheetIncidents = 'Incidents';

  static const String _appName = 'SOTASERV - CI SARL';
  static const String _reportTitle = 'Rapport HSE — Gestion EPI et Incidents';

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _graviteLabel(int g) {
    const labels = ['', '1 - Faible', '2', '3', '4', '5 - Grave'];
    return g >= 1 && g <= 5 ? labels[g] : '$g';
  }

  /// Style en-tête de tableau : fond bleu, texte blanc, gras, centré.
  CellStyle get _headerStyle => CellStyle(
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.blue800,
    bold: true,
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// Style cellule données standard.
  CellStyle get _dataStyle => CellStyle(
    fontColorHex: ExcelColor.black,
    fontSize: 10,
    verticalAlign: VerticalAlign.Center,
  );

  /// Style titre de feuille.
  CellStyle get _titleStyle =>
      CellStyle(fontColorHex: ExcelColor.blue900, bold: true, fontSize: 16);

  /// Style sous-titre / info (gris).
  CellStyle get _subtitleStyle =>
      CellStyle(fontColorHex: ExcelColor.grey, fontSize: 10);

  /// Style cellule critique (alerte stock).
  CellStyle get _criticalStyle => CellStyle(
    fontColorHex: ExcelColor.red700,
    fontSize: 10,
    bold: true,
    verticalAlign: VerticalAlign.Center,
  );

  /// Génère le fichier Excel et retourne le chemin.
  Future<String> exportToFile() async {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultName, _sheetResume);

    final exportDate = DateTime.now();
    final epis = await _epiRepo.getAll();
    final Map<int, int> stockByEpi = {};
    for (final e in epis) {
      if (e.id != null) {
        stockByEpi[e.id!] = await _epiRepo.getStockFromMovements(e.id!);
      }
    }
    final criticalCount = epis.where((e) {
      if (e.id == null) return false;
      final s = stockByEpi[e.id!] ?? 0;
      return e.seuilMin > 0 && s <= e.seuilMin;
    }).length;
    final movements = await _movementRepo.getAll();
    final incidents = await _incidentRepo.getAll();

    _writeResumeSheet(
      excel,
      exportDate,
      epis.length,
      criticalCount,
      movements.length,
      incidents.length,
    );
    await _writeEpiSheet(excel, epis, stockByEpi);
    await _writeMouvementsSheet(excel, movements);
    _writeIncidentsSheet(excel, incidents);

    excel.setDefaultSheet(_sheetResume);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Échec de la génération Excel');

    final dir = await getApplicationDocumentsDirectory();
    final dateStr =
        '${exportDate.year}${exportDate.month.toString().padLeft(2, '0')}${exportDate.day.toString().padLeft(2, '0')}_${exportDate.hour.toString().padLeft(2, '0')}${exportDate.minute.toString().padLeft(2, '0')}';
    final name = 'HSE_Export_$dateStr.xlsx';
    final path = p.join(dir.path, name);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  void _writeResumeSheet(
    Excel excel,
    DateTime exportDate,
    int nbEpi,
    int nbCritical,
    int nbMouvements,
    int nbIncidents,
  ) {
    final sheet = excel[_sheetResume];
    int row = 0;

    _setCell(sheet, 0, row, TextCellValue(_reportTitle), _titleStyle);
    row++;
    _setCell(sheet, 0, row, TextCellValue(_appName), _subtitleStyle);
    row += 2;

    _setCell(
      sheet,
      0,
      row,
      TextCellValue(
        'Date d\'export : ${_formatDate(exportDate.toIso8601String())}',
      ),
      _dataStyle,
    );
    row += 2;

    const summaryLabels = [
      'Nombre total d\'EPI',
      'EPI en stock critique (à réapprovisionner)',
      'Nombre de mouvements de stock',
      'Nombre d\'incidents déclarés',
    ];
    final summaryValues = [nbEpi, nbCritical, nbMouvements, nbIncidents];
    for (var i = 0; i < summaryLabels.length; i++) {
      _setCell(sheet, 0, row, TextCellValue(summaryLabels[i]), _dataStyle);
      _setCell(sheet, 1, row, IntCellValue(summaryValues[i]), _dataStyle);
      row++;
    }
    row += 2;
    _setCell(
      sheet,
      0,
      row,
      TextCellValue(
        'Feuilles du classeur : Résumé, EPI, Mouvements, Incidents.',
      ),
      _subtitleStyle,
    );
  }

  void _setCell(
    Sheet sheet,
    int col,
    int row,
    CellValue value,
    CellStyle style,
  ) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    cell.value = value;
    cell.cellStyle = style;
  }

  Future<void> _writeEpiSheet(
    Excel excel,
    List<EpiModel> epis,
    Map<int, int> stockByEpi,
  ) async {
    final sheet = excel[_sheetEpi];
    int row = 0;

    _setCell(sheet, 0, row, TextCellValue('Stock EPI'), _titleStyle);
    row++;
    _setCell(
      sheet,
      0,
      row,
      TextCellValue(
        'Liste des équipements de protection individuelle avec quantité et seuil d\'alerte.',
      ),
      _subtitleStyle,
    );
    row += 2;

    const headers = [
      'N°',
      'Code',
      'Désignation',
      'Quantité',
      'Seuil min.',
      'Statut',
      'Date création',
    ];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;

    for (var i = 0; i < epis.length; i++) {
      final epi = epis[i];
      final stock = epi.id != null ? (stockByEpi[epi.id!] ?? 0) : epi.stock;
      final critical = epi.seuilMin > 0 && stock <= epi.seuilMin;
      final status = critical ? 'Critique' : 'OK';
      final dateCreation = epi.dateCreation.isNotEmpty
          ? _formatDate(epi.dateCreation)
          : '';

      _setCell(sheet, 0, row, IntCellValue(i + 1), _dataStyle);
      _setCell(sheet, 1, row, TextCellValue(epi.code), _dataStyle);
      _setCell(sheet, 2, row, TextCellValue(epi.designation), _dataStyle);
      _setCell(
        sheet,
        3,
        row,
        IntCellValue(stock),
        critical ? _criticalStyle : _dataStyle,
      );
      _setCell(sheet, 4, row, IntCellValue(epi.seuilMin), _dataStyle);
      _setCell(
        sheet,
        5,
        row,
        TextCellValue(status),
        critical ? _criticalStyle : _dataStyle,
      );
      _setCell(sheet, 6, row, TextCellValue(dateCreation), _dataStyle);
      row++;
    }

    _setColumnWidths(sheet, [6, 14, 28, 10, 10, 10, 14]);
  }

  Future<void> _writeMouvementsSheet(
    Excel excel,
    List<StockMovementModel> movements,
  ) async {
    final sheet = excel[_sheetMouvements];
    int row = 0;

    _setCell(sheet, 0, row, TextCellValue('Mouvements de stock'), _titleStyle);
    row++;
    _setCell(
      sheet,
      0,
      row,
      TextCellValue('Historique des entrées et sorties par équipement.'),
      _subtitleStyle,
    );
    row += 2;

    final epis = await _epiRepo.getAll();
    final epiById = {
      for (final e in epis) e.id: e,
    }.map((k, v) => MapEntry(k!, v));

    const headers = [
      'N°',
      'Date',
      'EPI (désignation)',
      'Type',
      'Quantité',
      'Commentaire',
    ];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;

    final sorted = List<StockMovementModel>.from(movements)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var i = 0; i < sorted.length; i++) {
      final m = sorted[i];
      final epi = epiById[m.epiId];
      final designation = epi?.designation ?? 'EPI #${m.epiId}';
      final typeLabel = m.type == MovementType.entree ? 'Entrée' : 'Sortie';

      _setCell(sheet, 0, row, IntCellValue(i + 1), _dataStyle);
      _setCell(sheet, 1, row, TextCellValue(_formatDate(m.date)), _dataStyle);
      _setCell(sheet, 2, row, TextCellValue(designation), _dataStyle);
      _setCell(sheet, 3, row, TextCellValue(typeLabel), _dataStyle);
      _setCell(sheet, 4, row, IntCellValue(m.quantite), _dataStyle);
      _setCell(sheet, 5, row, TextCellValue(m.commentaire ?? ''), _dataStyle);
      row++;
    }

    _setColumnWidths(sheet, [6, 12, 28, 10, 10, 30]);
  }

  void _writeIncidentsSheet(Excel excel, List<IncidentModel> incidents) {
    final sheet = excel[_sheetIncidents];
    int row = 0;

    _setCell(
      sheet,
      0,
      row,
      TextCellValue('Accidents / Incidents'),
      _titleStyle,
    );
    row++;
    _setCell(
      sheet,
      0,
      row,
      TextCellValue(
        'Déclarations avec gravité, cause, action corrective et responsable.',
      ),
      _subtitleStyle,
    );
    row += 2;

    const headers = [
      'N°',
      'Date',
      'Zone',
      'Type',
      'Gravité',
      'Cause',
      'Action corrective',
      'Responsable',
    ];
    for (var c = 0; c < headers.length; c++) {
      _setCell(sheet, c, row, TextCellValue(headers[c]), _headerStyle);
    }
    row++;

    final sorted = List<IncidentModel>.from(incidents)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (var i = 0; i < sorted.length; i++) {
      final inc = sorted[i];
      _setCell(sheet, 0, row, IntCellValue(i + 1), _dataStyle);
      _setCell(sheet, 1, row, TextCellValue(_formatDate(inc.date)), _dataStyle);
      _setCell(sheet, 2, row, TextCellValue(inc.zone), _dataStyle);
      _setCell(
        sheet,
        3,
        row,
        TextCellValue(inc.type.isEmpty ? 'Incident' : inc.type),
        _dataStyle,
      );
      _setCell(
        sheet,
        4,
        row,
        TextCellValue(_graviteLabel(inc.gravite)),
        _dataStyle,
      );
      _setCell(sheet, 5, row, TextCellValue(inc.cause), _dataStyle);
      _setCell(sheet, 6, row, TextCellValue(inc.action), _dataStyle);
      _setCell(sheet, 7, row, TextCellValue(inc.responsable), _dataStyle);
      row++;
    }

    _setColumnWidths(sheet, [6, 12, 16, 18, 14, 24, 24, 16]);
  }

  void _setColumnWidths(Sheet sheet, List<int> widths) {
    try {
      for (var c = 0; c < widths.length; c++) {
        sheet.setColumnWidth(c, widths[c].toDouble());
      }
    } catch (_) {}
  }
}
