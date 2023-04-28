import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TimeStampList(),
    );
  }
}

class TimeStampList extends StatefulWidget {
  const TimeStampList({super.key});

  @override
  State<TimeStampList> createState() => _TimeStampListState();
}

class _TimeStampListState extends State<TimeStampList> {
  final info_list = <Map<String, dynamic>>[];

  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => listerine());
  }

  Future<void> listerine() async {
    final assetPath = new Directory(".");
    await for (var v in assetPath.list()) {
      if (v.statSync().type == FileSystemEntityType.file) {
        final metaData = await MetadataRetriever.fromFile(File(v.path));

        if (metaData.trackDuration != null) {
          final filename = Uri.decodeFull(v.uri.toString());
          final duration = metaData.trackDuration;
          info_list.add({'filename': filename, 'duration': duration});
        }
      }
    }
    setState(() {});
  }

  String makeTimeStamp() {
    Duration duration = Duration(milliseconds: 0);

    final result = info_list.map((e) {
      // 파일명에서 확장자 잘라내기
      final String title =
          e['filename'].substring(0, e['filename'].lastIndexOf('.'));

      final rawTimeStamp =
          duration.toString().split(':'); // '0:00:00.000000' 형태를 분리
      final hour = rawTimeStamp[0];
      final minute = rawTimeStamp[1];
      final second = rawTimeStamp[2].substring(0, 2); // '00.000000' 에서 '.000000' 삭제

      // 시간이 '0' 일 경우 '00:00'
      // 시간이 '0' 이 아닐 경우 'xx:00:00'
      final timeStamp = '${hour != '0' ? hour.padLeft(2, '0') + ':' : ''}$minute:$second';

      // 시간 더하기
      duration += Duration(milliseconds: e['duration']);

      // [00:00] 타이틀
      return '[${timeStamp}] $title';
    }).toList();

    // '[00:00] 타이틀\n[00:00] 타이틀\n[00:00] 타이틀\n'
    return result.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    _controller.text = makeTimeStamp();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ReorderableListView(
              shrinkWrap: true,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = info_list.removeAt(oldIndex);
                  info_list.insert(newIndex, item);
                });
              },
              children: info_list.mapIndexed((index, e) {
                return ReorderableDragStartListener(
                    key: ValueKey(e['filename']),
                    index: index,
                    child: Card(
                      child: ListTile(
                        title: Text(e['filename']),
                      ),
                    ));
              }).toList(),
            ),
            TextField(
              controller: _controller,
              maxLines: null,
              readOnly: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
