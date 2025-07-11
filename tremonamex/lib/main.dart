import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:animations/animations.dart';

void main() {
  runApp(const TremoNameXApp());
}

class TremoNameXApp extends StatefulWidget {
  const TremoNameXApp({super.key});

  @override
  State<TremoNameXApp> createState() => _TremoNameXAppState();
}

class _TremoNameXAppState extends State<TremoNameXApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TremoNameX',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro',
        scaffoldBackgroundColor: const Color(0xFF0F0F23),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1A1B3A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1B3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
      ),
      home: HomeScreen(
        onThemeChanged: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> pickFolder() async {
    String? selected = await FilePicker.platform.getDirectoryPath();
    if (selected != null) {
      setState(() {
        folderPath = selected;
        resultMsg = '';
        errorMsg = '';
      });
      await listFiles();
      _slideController.forward();
      _fadeController.forward();
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

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDarkMode
              ? [
                  const Color(0xFF0F0F23),
                  const Color(0xFF1A1B3A),
                  const Color(0xFF2D2E5F),
                ]
              : [
                  const Color(0xFFF8FAFC),
                  const Color(0xFFE2E8F0),
                  const Color(0xFFF1F5F9),
                ],
        ),
      ),
    );
  }

  Widget _buildFolderPicker() {
    return Hero(
      tag: 'folder-picker',
      child: OpenContainer(
        closedElevation: 0,
        closedColor: Colors.transparent,
        openColor: Theme.of(context).cardColor,
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 500),
        closedBuilder: (context, open) => GestureDetector(
          onTap: pickFolder,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isDarkMode
                    ? [
                        const Color(0xFF6366F1).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF6366F1).withOpacity(0.05),
                        const Color(0xFF8B5CF6).withOpacity(0.05),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  folderPath ?? 'Chọn thư mục để bắt đầu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn để chọn thư mục chứa file cần đổi tên',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        openBuilder: (context, close) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildAnimatedCard({required Widget child, int delay = 0}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return _buildAnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Tuỳ chọn đổi tên',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Loại file',
                    hintText: '.txt, .sty, .pdf...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  onChanged: (v) {
                    setState(() => fileType = v.trim());
                    listFiles();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: recursive,
                        onChanged: (v) {
                          setState(() => recursive = v ?? false);
                          listFiles();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quét thư mục con',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
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
                    hintText: 'Thêm vào đầu tên',
                    prefixIcon: Icon(Icons.text_format),
                  ),
                  onChanged: (v) {
                    setState(() => prefix = v);
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Hậu tố',
                    hintText: 'Thêm vào cuối tên',
                    prefixIcon: Icon(Icons.text_format),
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
                    hintText: 'Chuỗi cần thay',
                    prefixIcon: Icon(Icons.find_replace),
                  ),
                  onChanged: (v) {
                    setState(() => replaceFrom = v);
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Thay bằng',
                    hintText: 'Chuỗi mới',
                    prefixIcon: Icon(Icons.arrow_forward),
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
                    hintText: '.old',
                    prefixIcon: Icon(Icons.file_copy_outlined),
                  ),
                  onChanged: (v) {
                    setState(() => oldExt = v.trim());
                    updatePreview();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Đuôi mới',
                    hintText: '.new',
                    prefixIcon: Icon(Icons.file_present),
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
    return _buildAnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.preview, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Xem trước (${previewFiles.length} file)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: previewFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có file nào',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: previewFiles.length,
                    itemBuilder: (context, idx) {
                      final f = previewFiles[idx];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (idx * 50)),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          title: Text(
                            p.basename(f.newName),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            p.basename(f.oldPath),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(top: 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (files.isNotEmpty && !isRenaming) ? renameFiles : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isRenaming
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow, size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Đổi tên file hàng loạt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultMessage() {
    if (resultMsg.isEmpty && errorMsg.isEmpty) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultMsg.isNotEmpty 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resultMsg.isNotEmpty 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            resultMsg.isNotEmpty ? Icons.check_circle : Icons.error,
            color: resultMsg.isNotEmpty ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resultMsg.isNotEmpty ? resultMsg : errorMsg,
              style: TextStyle(
                color: resultMsg.isNotEmpty ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'TremoNameX',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6366F1).withOpacity(0.1),
                            const Color(0xFF8B5CF6).withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        ),
                        onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildFolderPicker(),
                        const SizedBox(height: 24),
                        if (folderPath != null) ...[
                          _buildOptions(),
                          _buildPreviewList(),
                          _buildActionButton(),
                          _buildResultMessage(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFile {
  final String oldPath;
  final String newName;
  _PreviewFile(this.oldPath, this.newName);
}
