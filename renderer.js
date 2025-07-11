const { ipcRenderer } = require('electron');

document.getElementById('choose-folder').onclick = async () => {
  const folder = await ipcRenderer.invoke('select-folder');
  if (folder) document.getElementById('folder').value = folder;
};

document.getElementById('run').onclick = async () => {
  const folder = document.getElementById('folder').value;
  const oldExt = document.getElementById('oldExt').value.trim();
  const newExt = document.getElementById('newExt').value.trim();
  const findStr = document.getElementById('findStr').value;
  const replaceStr = document.getElementById('replaceStr').value;
  const recursive = document.getElementById('recursive').checked;
  document.getElementById('result').innerText = '';
  document.getElementById('error').innerText = '';
  if (!folder) {
    document.getElementById('error').innerText = 'Vui lòng chọn thư mục.';
    return;
  }
  const res = await ipcRenderer.invoke('rename-files', { folder, oldExt, newExt, findStr, replaceStr, recursive });
  if (res.success) {
    document.getElementById('result').innerText = `Đã đổi tên ${res.changed} file.`;
  } else {
    document.getElementById('error').innerText = 'Lỗi: ' + res.error;
  }
}; 