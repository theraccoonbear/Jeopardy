var socket;
$(function() {
	var ws_path = "ws://localhost:5000/websocket/";
	socket = new WebSocket(ws_path);

	// socket.onopen = function() {
	// 	//document.getElementById('conn-status').innerHTML = 'Connected';
	// 	//send_msg("Oh hai!");
	// 	//reveal(1, 3);
	// 	send_msg("Oh hai!");
	// };

	socket.onmessage = function(e) {
		var data = JSON.parse(e.data);
		console.log(data);
		if (data.payload) {
			$.each(data.payload, function(i, ev) {
				if (ev.action === 'reveal') {
					var $row = $('.jeopardy-row:eq(' + ev.payload.row + ')');
					console.log('reveal:', $row);
				}
			});
		} else if (data.msg) {
			console.log('MSG:', data.msg);
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
		var col = $this.index();
		var row = $this.closest('.jeopardy-board.row').index();

		emitEvent('reveal', activity_id, {row: row, col: col});
	});
});