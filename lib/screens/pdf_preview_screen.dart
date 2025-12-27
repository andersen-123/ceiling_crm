// lib/screens/pdf_preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String proposalId;
  final String clientName;
  final double totalAmount;

  const PdfPreviewScreen({
    super.key,
    required this.proposalId,
    required this.clientName,
    required this.totalAmount,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late PdfViewerController _pdfViewerController;
  String? _pdfPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _generateAndLoadPdf();
  }

  Future<void> _generateAndLoadPdf() async {
    try {
      // Генерируем PDF
      final pdfBytes = await _generatePdf();
      
      // Сохраняем во временный файл
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/proposal_${widget.proposalId}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      setState(() {
        _pdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка генерации PDF: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Uint8List> _generatePdf() async {
    // TODO: Реализовать генерацию PDF через pdf-пакет
    // Временный заглушка
    return Uint8List(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КП для ${widget.clientName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (_pdfPath != null && File(_pdfPath!).existsSync()) {
                await _sharePdf();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // TODO: Реализовать печать
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pdfPath != null
              ? SfPdfViewer.file(
                  File(_pdfPath!),
                  controller: _pdfViewerController,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Не удалось загрузить PDF'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateAndLoadPdf,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _pdfPath != null
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Итого: ${widget.totalAmount.toStringAsFixed(2)} ₽',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_pdfPath != null) {
                        await _sharePdf();
                      }
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Отправить клиенту'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _sharePdf() async {
    try {
      // Используем share_plus вместо устаревшего share
      // Добавьте в pubspec.yaml: share_plus: ^7.0.0
      // import 'package:share_plus/share_plus.dart';
      // await Share.shareXFiles([XFile(_pdfPath!)]);
      
      // Временное решение:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Функция отправки в разработке'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
