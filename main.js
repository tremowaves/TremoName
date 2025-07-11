const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');

function createWindow() {
  const win = new BrowserWindow({
    width: 900,
    height: 700,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });
  win.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

// Chọn thư mục
ipcMain.handle('select-folder', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openDirectory']
  });
  if (result.canceled) return null;
  return result.filePaths[0];
});

// Lấy danh sách file theo các tuỳ chọn
ipcMain.handle('list-files', async (event, folderPath, fileType, recursive) => {
  function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      if (stat && stat.isDirectory()) {
        if (recursive) results = results.concat(walk(filePath));
      } else {
        if (!fileType || file.endsWith(fileType)) {
          results.push(filePath);
        }
      }
    });
    return results;
  }
  return walk(folderPath);
});

// Đổi tên file hàng loạt với đầy đủ tuỳ chọn
ipcMain.handle('rename-files', async (event, files, options) => {
  let renamed = 0;
  for (const file of files) {
    const dir = path.dirname(file);
    let base = path.basename(file);
    // Thay thế chuỗi
    if (options.replaceFrom) base = base.replace(options.replaceFrom, options.replaceTo);
    // Thêm tiền tố
    if (options.prefix) base = options.prefix + base;
    // Thêm hậu tố
    if (options.tail) {
      const ext = path.extname(base);
      base = base.replace(ext, options.tail + ext);
    }
    // Đổi đuôi file
    if (options.oldExt && options.newExt && base.endsWith(options.oldExt)) {
      base = base.replace(new RegExp(options.oldExt + '$'), options.newExt);
    }
    const newPath = path.join(dir, base);
    if (newPath !== file) {
      fs.renameSync(file, newPath);
      renamed++;
    }
  }
  return { success: true, changed: renamed };
}); 