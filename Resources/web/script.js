const apiUrl = window.location.origin;

function onBrowse() {
    document.getElementById("uploadManual").click();
}

function handleRequest(url, success, errorMsg, body) {
    let opts = {
        method: 'POST'
    }
    if (body) {
        opts["body"] = body;
    }
    fetch(`${apiUrl}/${url}`, opts).then(async resp => {
        if (!resp.ok) {
            alert(`${errorMsg} Server responded with code: ${resp.status}. View app logs for more info.`);
            return;
        }
        alert(success);
        window.location.reload();
    }).catch(err => {
        console.error(err);
        alert(`${errorMsg} Error: ${err.message}`);
    })
}

function handleUpload(file) {
    const fileInput = document.getElementById("uploadManual");
    const formData = new FormData();
    formData.append('file', file);
    handleRequest("upload", "Uploaded geode mod!", "Couldn't upload file.", formData);
    if (fileInput) {
        fileInput.value = '';
    }
}

const uploadArea = document.getElementById("uploadArea");
const fileInput = document.getElementById("uploadManual");
if (uploadArea) {
    uploadArea.addEventListener("dragover", (e) => {
        e.preventDefault();
        uploadArea.classList.add("drag");
    });
    uploadArea.addEventListener("dragleave", (e) => {
        e.preventDefault();
        uploadArea.classList.remove("drag");
    });
    uploadArea.addEventListener("drop", (e) => {
        e.preventDefault();
        uploadArea.classList.remove("drag");
        if (e.dataTransfer.files.length > 0) {
            handleUpload(e.dataTransfer.files[0]);
        }
    });
}
if (fileInput) {
    fileInput.addEventListener("change", (e) => {
        handleUpload(e.target.files[0]);
    })
}

function onLaunch() {
    handleRequest("launch", "Launched!", "Couldn't launch game.");
}

function onStop() {
    handleRequest("stop", "Stopped!", "Couldn't stop HTTP server.");
}
let interval;
function fetchLogs() {
    const logsContainer = document.getElementById('logs-container');
    fetch(`${apiUrl}/logs`).then(resp => {
        if (!resp.ok) {
            alert(`Couldn't fetch logs: Server responded with code: ${resp.status}. View app logs for more info.`);
            clearInterval(interval)
            return "";
        }
        return resp.text();
    }).then(logData => {
        logsContainer.innerHTML = '';
        const lines = logData.split("\n");
        lines.forEach(line => {
            if (line.trim()) {
                // 00:00:00 INFO [Thread] [Geode]: Example
                const splitLog = line.split(' ');
                if (splitLog.length > 4) {
                    const level = splitLog[1];
                    /*const thread = splitLog[2];
                    const mod = splitLog[3];
                    const message = splitLog.slice(4);*/ 

                    // elements
                    // maybe dont create new classes
                    const logLine = document.createElement('div');
                    logLine.className = 'log-line';
                    const logTimestamp = document.createElement('span');
                    logTimestamp.textContent = splitLog[0];
                    logTimestamp.style.marginRight = '8px';
                    logTimestamp.style.color = '#3498db';
                    const logLevel = document.createElement('span');
                    logLevel.textContent = splitLog[1];
                    logLevel.className = 'log-level';
                    logLevel.classList.add(level.toLowerCase())
                    /*const logThread = document.createElement('span');
                    const logMod = document.createElement('span');*/
                    const logMsg = document.createElement('span');
                    logMsg.textContent = splitLog.slice(2).join(" ")
                    logTimestamp.className = 'message';

                    logLine.appendChild(logTimestamp);
                    logLine.appendChild(logLevel);
                    logLine.appendChild(logMsg);
                    logsContainer.appendChild(logLine);

                    logsContainer.scrollTop = logsContainer.scrollHeight;
                }
            }
        })
    }).catch(err => {
        console.error(err);
        alert(`Error: ${err.message}`);
        if (interval) clearInterval(interval)
    })

}
fetchLogs();
function onStartLogs() {
    clearInterval(interval)
    interval = setInterval(() => {
        fetchLogs();
    }, 1000)
}
function onStopLogs() {
    clearInterval(interval)
}
onStartLogs();
