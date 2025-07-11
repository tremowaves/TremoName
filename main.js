const { app, BrowserWindow, dialog, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');

function createWindow() {
  const win = new BrowserWindow({
    width: 600,
    height: 500,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });
  win.loadFile('index.html');
}

app.whenReady().then(createWindow);

ipcMain.handle('select-folder', async () => {
  const result = await dialog.showOpenDialog({
    properties: ['openDirectory']
  });
  if (result.canceled) return null;
  return result.filePaths[0];
});

function getAllFiles(dir, ext, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      getAllFiles(filePath, ext, fileList);
    } else {
      if (!ext || file.endsWith(ext)) fileList.push(filePath);
    }
  }
  return fileList;
}

ipcMain.handle('rename-files', async (event, { folder, oldExt, newExt, findStr, replaceStr, recursive }) => {
  try {
    let files;
    if (recursive) {
      files = getAllFiles(folder, oldExt);
    } else {
      files = fs.readdirSync(folder).filter(f => !oldExt || f.endsWith(oldExt)).map(f => path.join(folder, f));
    }
    let changed = 0;
    for (const filePath of files) {
      const dir = path.dirname(filePath);
      const file = path.basename(filePath);
      let newName = file;
      if (findStr) newName = newName.replace(findStr, replaceStr);
      if (oldExt && newExt) newName = newName.replace(new RegExp(oldExt + '$'), newExt);
      if (newName !== file) {
        fs.renameSync(filePath, path.join(dir, newName));
        changed++;
      }
    }
    return { success: true, changed };
  } catch (e) {
    return { success: false, error: e.message };
  }
}); 