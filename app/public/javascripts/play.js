$(function() {
	var ws_path = "ws://localhost:5000/websocket/";
	var socket = new WebSocket(ws_path);

	// socket.onopen = function() {
	// 	//document.getElementById('conn-status').innerHTML = 'Connected';
	// 	//send_msg("Oh hai!");
	// 	//reveal(1, 3);
	// 	send_msg("Oh hai!");
	// };

	socket.onmessage = function(e) {
		var data = JSON.parse(e.data);
		console.log(data);
		if (data.msg) {
			alert (data.msg);
		}
	};

	function send_msg(message) {
		socket.send(JSON.stringify({ msg: message }));
	}

	function reveal(catIdx, rowIdx) {
		var msg = {
			action: 'reveal',
			catIdx: catIdx,
			rowIdx: rowIdx
		};

		socket.send(JSON.stringify(msg));
	}

	function subscribe(activity_id) {
		// socket.send(JSON.stringify({
		// 	action: 'subscribe',
		// 	activity_id: activity_id
		// }));
		emitEvent('subscribe', activity_id);
	}

	function emitEvent(action, activity_id, payload) {
		socket.send(JSON.stringify({
			action: action,
			activity_id: activity_id,
			payload: payload
		}));
	}

	socket.onopen = function() {
		console.log("Subscribing to ", activity_id);
		subscribe(activity_id);
	};

	socket.onclose = function(x) {
		console.log('Socket closing!', x);
	}

	$('.point').on('click', function(e) {
		var $this = $(this);

		emitEvent('clickNotice', activity_id, {stuff: "things"});
	});
});