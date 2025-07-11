const { ipcRenderer } = require('electron');

const dropArea = document.getElementById('drop-area');
const btnSelect = document.getElementById('btn-select');
const fileList = document.getElementById('file-list');
const btnProcess = document.getElementById('btn-process');
const fileTypeInput = document.getElementById('file-type');
const prefixInput = document.getElementById('prefix');
const tailInput = document.getElementById('tail');
const replaceFromInput = document.getElementById('replace-from');
const replaceToInput = document.getElementById('replace-to');
const oldExtInput = document.getElementById('oldExt');
const newExtInput = document.getElementById('newExt');
const recursiveInput = document.getElementById('recursive');
const selectedFolderDiv = document.getElementById('selected-folder');
const resultDiv = document.getElementById('result');
const errorDiv = document.getElementById('error');

let currentFolder = null;
let files = [];

function renderFileList() {
  fileList.innerHTML = '';
  files.forEach(f => {
    const li = document.createElement('li');
    li.textContent = f;
    fileList.appendChild(li);
  });
  btnProcess.disabled = files.length === 0;
}

async function selectFolder() {
  const folder = await ipcRenderer.invoke('select-folder');
  if (folder) {
    currentFolder = folder;
    selectedFolderDiv.textContent = 'Đã chọn: ' + currentFolder;
    await listFiles();
  }
}

async function listFiles() {
  let type = fileTypeInput.value.trim();
  if (type && !type.startsWith('.')) type = '.' + type;
  const recursive = recursiveInput.checked;
  if (!currentFolder) return;
  files = await ipcRenderer.invoke('list-files', currentFolder, type || null, recursive);
  renderFileList();
}

dropArea.addEventListener('dragover', (e) => {
  e.preventDefault();
  dropArea.style.background = '#e3f2fd';
});
dropArea.addEventListener('dragleave', (e) => {
  e.preventDefault();
  dropArea.style.background = '';
});
dropArea.addEventListener('drop', async (e) => {
  e.preventDefault();
  dropArea.style.background = '';
  const items = e.dataTransfer.items;
  if (items.length && items[0].kind === 'file') {
    const entry = items[0].webkitGetAsEntry();
    if (entry.isDirectory) {
      currentFolder = e.dataTransfer.files[0].path;
      selectedFolderDiv.textContent = 'Đã chọn: ' + currentFolder;
      await listFiles();
    }
  }
});

btnSelect.addEventListener('click', selectFolder);
fileTypeInput.addEventListener('input', () => { if (currentFolder) listFiles(); });
recursiveInput.addEventListener('change', () => { if (currentFolder) listFiles(); });

btnProcess.addEventListener('click', async () => {
  btnProcess.disabled = true;
  resultDiv.innerText = '';
  errorDiv.innerText = '';
  const options = {
    prefix: prefixInput.value,
    tail: tailInput.value,
    replaceFrom: replaceFromInput.value,
    replaceTo: replaceToInput.value,
    oldExt: oldExtInput.value.trim(),
    newExt: newExtInput.value.trim(),
    recursive: recursiveInput.checked
  };
  try {
    const res = await ipcRenderer.invoke('rename-files', files, options);
    if (res.success) {
      await listFiles();
      resultDiv.innerText = `Đã đổi tên ${res.changed} file.`;
    } else {
      errorDiv.innerText = 'Lỗi: ' + res.error;
    }
  } catch (e) {
    errorDiv.innerText = 'Lỗi: ' + e.message;
  }
  btnProcess.disabled = false;
}); 