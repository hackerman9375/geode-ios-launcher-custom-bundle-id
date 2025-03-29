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
