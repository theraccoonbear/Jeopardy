var ws_path = "ws://localhost:5000/websocket";
var socket = new WebSocket(ws_path);
socket.onopen = function() {
	//document.getElementById('conn-status').innerHTML = 'Connected';
	send_msg("Oh hai!");
};
socket.onmessage = function(e) {
	var data = JSON.parse(e.data);
	if (data.msg) {
		alert (data.msg);
	}
};
function send_msg(message) {
	socket.send(JSON.stringify({ msg: message }));
}