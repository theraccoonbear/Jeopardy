var EventSocket = function(opts) {
	var ctxt = this;

	ctxt.options = $.extend({
		url: 'ws://' + document.location.hostname + ':' + document.location.port + '/websocket/',
		reconnectDelay: 1000,
		reconnectLimit: false,
		on: {}
	}, opts);

	ctxt._eventHandlers = {};
	ctxt._socket = false;
	$.each(ctxt.options.on, function(event, method) {
		ctxt.on(event, method);
	});
};

EventSocket.prototype.on = function(event, handler) {
	var ctxt = this;
	if (typeof ctxt._eventHandlers[event] === 'undefined') {
		ctxt._eventHandlers[event] = [];
	}

	ctxt._eventHandlers[event].push(handler);
};

EventSocket.prototype._dispatch = function(event, data) {
	var ctxt = this;
	var any = false;
	if (typeof ctxt._eventHandlers[event] !== 'undefined') {
		if (ctxt._eventHandlers[event].length > 0) {
			any = true;
			console.log('Dispatching', ctxt._eventHandlers[event].length, 'events of type', event);
			$.each(ctxt._eventHandlers[event], function(idx, hdlr) {
				hdlr(data);
			});
		}
	}

	if (!any) {
		console.log("No event handlers for:", event, data);
	}
};

EventSocket.prototype.connect = function(url) {
	var ctxt = this;
	
	url = url || ctxt.options.url;
	console.log(ctxt);

	console.log('Connecting to:', url);

	ctxt._socket = new WebSocket(url);

	ctxt._socket.onmessage = function(e) {
		var data = JSON.parse(e.data);
		console.log('data:', data);
		if (data.payload) {
			$.each(data.payload, function(i, ev) {
				if (typeof ev.action !== 'undefined') {
					ctxt._dispatch(ev.action, ev.data);
				}
			});
		} else if (data.msg) {
			console.log('MSG:', data.msg);
		}
	};

	ctxt._socket.onopen = function() {
		console.log('...Connected!');
		//console.log("Subscribing to ", activity_id);
		ctxt.options.ready();
	};

	ctxt._socket.onclose = function(x) {
		console.log('Socket closing!', x);
		console.log('Reconnecting in ' + (ctxt.reconnectDelay / 1000) + ' second(s)')
		setTimeout(function() {
			ctxt.connect();
		}, ctxt.reconnectDelay);
	}

	ctxt._socket.onerror = function(e) {
		console.log("ERROR:", e);
	}
};

EventSocket.prototype.send = function(raw) {
	var ctxt = this;
	ctxt._socket.send(raw);
};

EventSocket.prototype.emitEvent = function(action, activity_id, payload) {
	var ctxt = this;
	ctxt.send(JSON.stringify({
		action: action,
		activity_id: activity_id,
		payload: payload
	}));
};