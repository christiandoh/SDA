import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/models/incident_model.dart';
import '../data/models/stock_movement_model.dart';
import '../data/repositories/epi_repository.dart';
import '../data/repositories/incident_repository.dart';
import '../data/repositories/stock_movement_repository.dart';

/// Exporte les données HSE vers un fichier Excel (.xlsx) bien mis en forme.
class ExcelExportService {
  ExcelExportService._();
  static final ExcelExportService instance = ExcelExportService._();

  final EpiRepository _epiRepo = EpiRepository();
  final StockMovementRepository _movementRepo = StockMovementRepository();
  final IncidentRepository _incidentRepo = IncidentRepository();

  static const String _sheetEpi = 'EPI';
  static const String _sheetMouvements = 'Mouvements';
  static const String _sheetIncidents = 'Incidents';

  /// Style d'en-tête : fond bleu, texte blanc, gras.
  CellStyle get _headerStyle => CellStyle(
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.blue800,
    bold: true,
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  /// Style de cellule de données.
  CellStyle get _dataStyle => CellStyle(
    fontColorHex: ExcelColor.black,
    fontSize: 10,
    verticalAlign: VerticalAlign.Center,
  );

  /// Style titre de feuille.
  CellStyle get _titleStyle =>
      CellStyle(fontColorHex: ExcelColor.blue900, bold: true, fontSize: 14);

  /// Génère le fichier Excel et retourne le chemin du fichier.
  Future<String> exportToFile() async {
    final excel = Excel.createExcel();
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', _sheetEpi);

    await _writeEpiSheet(excel);

    final movements = await _movementRepo.getAll();
    _writeMouvementsSheet(excel, movements);

    final incidents = await _incidentRepo.getAll();
    _writeIncidentsSheet(excel, incidents);

    excel.setDefaultSheet(_sheetEpi);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Échec de la génération Excel');

    final dir = await getApplicationDocumentsDirectory();
    final name = 'HSE_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final path = p.join(dir.path, name);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }

  Future<void> _writeEpiSheet(Excel excel) async {
    final sheet = excel[_sheetEpi];
    int row = 0;

    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    titleCell.value = TextCellValue('Stock EPI');
    titleCell.cellStyle = _titleStyle;
    row += 2;

    const headers = [
      'Code',
      'Désignation',
      'Stock actuel',
      'Seuil min.',
      'Date création',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = _headerStyle;
    }
    row++;

    final epis = await _epiRepo.getAll();
    for (final epi in epis) {
      final stock = epi.id != null
          ? await _epiRepo.getStockFromMovements(epi.id!)
          : 0;
      final cells = [
        TextCellValue(epi.code),
        TextCellValue(epi.designation),
        IntCellValue(stock),
        IntCellValue(epi.seuilMin),
        TextCellValue(epi.dateCreation),
      ];
      for (var c = 0; c < cells.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        cell.value = cells[c];
        cell.cellStyle = _dataStyle;
      }
      row++;
    }
  }

  void _writeMouvementsSheet(Excel excel, List<StockMovementModel> movements) {
    final sheet = excel[_sheetMouvements];
    int row = 0;

    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    titleCell.value = TextCellValue('Mouvements de stock');
    titleCell.cellStyle = _titleStyle;
    row += 2;

    const headers = ['ID EPI', 'Type', 'Quantité', 'Date', 'Commentaire'];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = _headerStyle;
    }
    row++;

    for (final m in movements) {
      final cells = [
        IntCellValue(m.epiId),
        TextCellValue(m.typeRaw),
        IntCellValue(m.quantite),
        TextCellValue(m.date),
        TextCellValue(m.commentaire ?? ''),
      ];
      for (var c = 0; c < cells.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        cell.value = cells[c];
        cell.cellStyle = _dataStyle;
      }
      row++;
    }
  }

  void _writeIncidentsSheet(Excel excel, List<IncidentModel> incidents) {
    final sheet = excel[_sheetIncidents];
    int row = 0;

    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
    );
    titleCell.value = TextCellValue('Accidents / Incidents');
    titleCell.cellStyle = _titleStyle;
    row += 2;

    const headers = [
      'Date',
      'Zone',
      'Type',
      'Gravité',
      'Cause',
      'Action',
      'Responsable',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = _headerStyle;
    }
    row++;

    for (final inc in incidents) {
      final cells = [
        TextCellValue(inc.date),
        TextCellValue(inc.zone),
        TextCellValue(inc.type),
        IntCellValue(inc.gravite),
        TextCellValue(inc.cause),
        TextCellValue(inc.action),
        TextCellValue(inc.responsable),
      ];
      for (var c = 0; c < cells.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row),
        );
        cell.value = cells[c];
        cell.cellStyle = _dataStyle;
      }
      row++;
    }
  }
}
