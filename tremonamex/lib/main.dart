import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:animations/animations.dart';

void main() {
  runApp(const TremoNameXApp());
}

class TremoNameXApp extends StatelessWidget {
  const TremoNameXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TremoNameX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'SF Pro',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? folderPath;
  List<FileSystemEntity> files = [];
  List<_PreviewFile> previewFiles = [];
  String fileType = '';
  String prefix = '';
  String tail = '';
  String replaceFrom = '';
  String replaceTo = '';
  String oldExt = '';
  String newExt = '';
  bool recursive = false;
  bool isRenaming = false;
  String resultMsg = '';
  String errorMsg = '';

  Future<void> pickFolder() async {
    String? selected = await FilePicker.platform.getDirectoryPath();
    if (selected != null) {
      setState(() {
        folderPath = selected;
        resultMsg = '';
        errorMsg = '';
      });
      await listFiles();
    }
  }

  Future<void> listFiles() async {
    if (folderPath == null) return;
    List<FileSystemEntity> all = [];
    void scanDir(Directory dir) {
      try {
        for (var entity in dir.listSync()) {
          if (entity is Directory && recursive) {
            scanDir(entity);
          } else if (entity is File) {
            if (fileType.isEmpty || p.extension(entity.path) == fileType) {
              all.add(entity);
            }
          }
        }
      } catch (e) {
        // Bỏ qua các thư mục không có quyền truy cập
      }
    }
    scanDir(Directory(folderPath!));
    setState(() {
      files = all;
    });
    updatePreview();
  }

  void updatePreview() {
    setState(() {
      previewFiles = files.map((f) {
        String name = p.basename(f.path);
        // Thay thế chuỗi
        if (replaceFrom.isNotEmpty) name = name.replaceAll(replaceFrom, replaceTo);
        // Thêm tiền tố
        if (prefix.isNotEmpty) name = prefix + name;
        // Thêm hậu tố
        if (tail.isNotEmpty) {
          String ext = p.extension(name);
          if (ext.isNotEmpty) {
            name = name.substring(0, name.length - ext.length) + tail + ext;
          } else {
            name = name + tail;
          }
        }
        // Đổi đuôi file
        if (oldExt.isNotEmpty && newExt.isNotEmpty && name.endsWith(oldExt)) {
          name = name.replaceAll(RegExp('${RegExp.escape(oldExt)}\$'), newExt);
        }
        return _PreviewFile(f.path, name);
      }).toList();
    });
  }

  Future<void> renameFiles() async {
    setState(() {
      isRenaming = true;
      resultMsg = '';
      errorMsg = '';
    });
    int changed = 0;
    try {
      for (var f in files) {
        String dir = p.dirname(f.path);
        String name = p.basename(f.path);
        // Thay thế chuỗi
        if (replaceFrom.isNotEmpty) name = name.replaceAll(replaceFrom, replaceTo);
        // Thêm tiền tố
        if (prefix.isNotEmpty) name = prefix + name;
        // Thêm hậu tố
        if (tail.isNotEmpty) {
          String ext = p.extension(name);
          if (ext.isNotEmpty) {
            name = name.substring(0, name.length - ext.length) + tail + ext;
          } else {
            name = name + tail;
          }
        }
        // Đổi đuôi file
        if (oldExt.isNotEmpty && newExt.isNotEmpty && name.endsWith(oldExt)) {
          name = name.replaceAll(RegExp('${RegExp.escape(oldExt)}\$'), newExt);
        }
        String newPath = p.join(dir, name);
        if (newPath != f.path) {
          await File(f.path).rename(newPath);
          changed++;
        }
      }
      setState(() {
        resultMsg = 'Đã đổi tên $changed file.';
        errorMsg = '';
      });
      await listFiles();
    } catch (e) {
      setState(() {
        errorMsg = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        isRenaming = false;
      });
    }
  }

  Widget _buildFolderPicker() {
    return OpenContainer(
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: Colors.white,
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (context, open) => GestureDetector(
        onTap: pickFolder,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_outlined, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  folderPath ?? 'Chọn thư mục để bắt đầu',
                  style: const TextStyle(fontSize: 17, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
      openBuilder: (context, close) => const SizedBox.shrink(),
    );
  }

  Widget _buildOptions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Loại file (.txt, .sty...)',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => fileType = v.trim());
                    listFiles();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: recursive,
                      onChanged: (v) {
                        setState(() => recursive = v ?? false);
                        listFiles();
                      },
                    ),
                    const Expanded(child: Text('Quét thư mục con')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tiền tố',
                    prefixIcon: Icon(Icons.text_format),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => prefix = v);
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Hậu tố',
                    prefixIcon: Icon(Icons.text_format),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => tail = v);
                    updatePreview();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Thay thế',
                    prefixIcon: Icon(Icons.find_replace),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => replaceFrom = v);
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Bằng',
                    prefixIcon: Icon(Icons.arrow_forward),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => replaceTo = v);
                    updatePreview();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Đuôi cũ',
                    prefixIcon: Icon(Icons.file_copy_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => oldExt = v.trim());
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Đuôi mới',
                    prefixIcon: Icon(Icons.file_present),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => newExt = v.trim());
                    updatePreview();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewList() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text('Xem trước (${previewFiles.length} file)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.builder(
              itemCount: previewFiles.length,
              itemBuilder: (context, idx) {
                final f = previewFiles[idx];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.insert_drive_file, size: 20),
                  title: Text(p.basename(f.newName)),
                  subtitle: Text(p.basename(f.oldPath), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (files.isNotEmpty && !isRenaming) ? renameFiles : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isRenaming
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Đổi tên file hàng loạt', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text('TremoNameX - Đổi tên file hàng loạt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFolderPicker(),
              const SizedBox(height: 18),
              if (folderPath != null) ...[
                _buildOptions(),
                const SizedBox(height: 18),
                _buildPreviewList(),
                _buildActionButton(),
                if (resultMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(resultMsg, style: const TextStyle(color: Colors.green, fontSize: 16), textAlign: TextAlign.center),
                  ),
                if (errorMsg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Text(errorMsg, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewFile {
  final String oldPath;
  final String newName;
  _PreviewFile(this.oldPath, this.newName);
}
