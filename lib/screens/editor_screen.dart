import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  EditorScreenState createState() => EditorScreenState();
}

class EditorScreenState extends State<EditorScreen> {
  FleatherController? _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _loadDocument().then((document) {
      setState(() {
        _controller = FleatherController(document: document);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveDocument(context),
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: _showUrlDialog,
          ),
        ],
      ),
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!Platform.isAndroid && !Platform.isIOS)
                  FleatherToolbar.basic(controller: _controller!),
                if (Platform.isAndroid || Platform.isIOS)
                  FleatherToolbar.basic(controller: _controller!),
                Divider(),
                Expanded(
                  child: FleatherEditor(
                    padding: const EdgeInsets.all(16),
                    controller: _controller!,
                    focusNode: _focusNode,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildLinkifiedText(),
                  ),
                ),
              ],
            ),
    );
  }

  // リンクを検出して、タップしたらURLを開くウィジェットを作成
  Widget _buildLinkifiedText() {
    final text = _controller!.document.toPlainText();
    return Linkify(
      text: text,
      onOpen: (link) async {
        if (await canLaunch(link.url)) {
          await launch(link.url);
        } else {
          throw 'Could not launch $link';
        }
      },
      style: const TextStyle(color: Colors.black),
      linkStyle: const TextStyle(color: Colors.blue),
    );
  }

  // リンクを貼り付けるためのダイアログを表示
  void _showUrlDialog() {
    String url = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URLを貼り付け'),
          content: TextField(
            onChanged: (value) {
              url = value;
            },
            decoration: const InputDecoration(hintText: "URLを入力"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _insertLink(url);
                Navigator.of(context).pop();
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  // エディターにリンクを挿入
  void _insertLink(String url) {
    if (url.isNotEmpty) {
      // EmbeddableObjectとしてURLを挿入するためのDeltaを作成
      final Delta delta = Delta()..insert(url + '\n', {'link': url});

      // ドキュメントの末尾にDeltaを追加
      _controller!.document.compose(delta, _controller!.document.length, source: ChangeSource.local);

      // UIを更新
      setState(() {});
    }
  }

  Future<ParchmentDocument> _loadDocument() async {
    final file = File(Directory.systemTemp.path + "/quick_start.json");

    if (await file.exists()) {
      final contents = await file.readAsString();
      return ParchmentDocument.fromJson(jsonDecode(contents));
    }
    final Delta delta = Delta()..insert("Fleather Quick Start\n");
    return ParchmentDocument.fromDelta(delta);
  }

  void _saveDocument(BuildContext context) {
    final contents = jsonEncode(_controller!.document);
    final file = File('${Directory.systemTemp.path}/quick_start.json');

    file.writeAsString(contents).then(
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved.')),
        );
      },
    );
  }
}
