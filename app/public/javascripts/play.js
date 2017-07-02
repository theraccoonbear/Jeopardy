var socket;

var Game = function(opts) {
	this.options = $.extend({}, opts);
};

Game.prototype.showAnswer = function(row, co) {
	var ctxt = this;

	ctxt.options
}

$(function() {
	var ws_path = "ws://localhost:5000/websocket/";
	var failedConnections = 0;
	var reconnectDelay = 5000; // ms until reconnect

	function connect() {
		console.log('Connecting to:', ws_path);
		socket = new WebSocket(ws_path);

		socket.onmessage = function(e) {
			var data = JSON.parse(e.data);
			console.log('data:', data);
			if (data.payload) {
				$.each(data.payload, function(i, ev) {
					if (ev.action === 'reveal') {
						var $row = $('.jeopardy-board.row:eq(' + (ev.data.row + 1) + ')');
						var $cell = $row.find('.point.block:eq(' + ev.data.col + ')');
						console.log('reveal:', $cell);
						console.log(game);
					}
				});
			} else if (data.msg) {
				console.log('MSG:', data.msg);
			}
		};

		socket.onopen = function() {
			console.log('...Connected!');
			console.log("Subscribing to ", activity_id);
			subscribe(activity_id);
		};

		socket.onclose = function(x) {
			console.log('Socket closing!', x);
			console.log('Reconnecting in ' + (reconnectDelay / 1000) + ' second(s)')
			setTimeout(connect, reconnectDelay);
		}

		socket.onerror = function(e) {
			console.log("ERROR:", e);
		}
	}

	

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

	$('.point').on('click', function(e) {
		var $this = $(this);
		var col = $this.index();
		var row = $this.closest('.jeopardy-board.row').index();

		emitEvent('reveal', activity_id, {row: row, col: col});
	});

	connect();
});