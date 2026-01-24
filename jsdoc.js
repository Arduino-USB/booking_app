function send_json(endpoint, jsonData) {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', endpoint, false); // synchronous

    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.setRequestHeader('Accept', 'application/json');

    try {
        xhr.send(JSON.stringify(jsonData));
    } catch (e) {
        return null;
    }

    try {
        return JSON.parse(xhr.responseText);
    } catch {
        return null;
    }
}


function get_json(endpoint, params = {}) {
    const query = new URLSearchParams(params).toString();
    const url = query ? `${endpoint}?${query}` : endpoint;

    const xhr = new XMLHttpRequest();
    xhr.open('GET', url, false); // synchronous
    xhr.setRequestHeader('Accept', 'application/json');

    try {
        xhr.send(null);
    } catch (e) {
        return null;
    }

    try {
        return JSON.parse(xhr.responseText);
    } catch {
        return null;
    }
}

