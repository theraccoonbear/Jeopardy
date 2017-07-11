var EventSocket = function(opts) {
	var ctxt = this;

	ctxt.options = $.extend({
		url: 'ws://' + document.location.hostname + ':' + document.location.port + '/websocket/',
		reconnectDelay: 5000,
		reconnectLimit: false,
		connectionAttempts: 0,
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
			console.log('Dispatching', ctxt._eventHandlers[event].length, 'event(s) of type', event);
			$.each(ctxt._eventHandlers[event], function(idx, hdlr) {
				hdlr(data);
			});
		}
	}

	if (!any) {
		console.log("No event handlers for:", event, data);
	}
};

EventSocket.prototype.connect = function(url, opts) {
	var ctxt = this;
	
	url = typeof url !== 'undefined' ? url : ctxt.options.url;
	var options = $.extend({
		after: false
	}, opts);

	console.log('Connecting to:', url);

	ctxt.options.connectionAttempts++;
	ctxt._socket = new WebSocket(url);

	ctxt._socket.onmessage = function(e) {
		var data = JSON.parse(e.data);
		console.log('data:', data);
		if (data.payload && data.payload.events) {
			$.each(data.payload.events, function(i, ev) {
				ctxt._dispatch('beforeAction', { action: ev.action, data: ev.data});
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
		ctxt.options.connectionAttempts = 0;
		if (options.after !== false) {
			after();
		}
		ctxt.options.ready();
		
	};

	ctxt._socket.onclose = function(x) {
		console.log('Socket closing!', x);
		if (ctxt.options.connectionAttempts < ctxt.options.reconnectLimit) {
			console.log('Reconnecting in ' + (ctxt.options.reconnectDelay / 1000) + ' second(s)')
			setTimeout(function() {
				ctxt.connect();
			}, ctxt.options.reconnectDelay);
		} else {
			ctxt.options.connectionAttempts = 0;
			console.log("I give up!");
		}
	}

	ctxt._socket.onerror = function(e) {
		console.log("WEBSOCKET ERROR:", e);
		console.log('Socket:', ctxt._socket);
	}
};

EventSocket.prototype.send = function(raw) {
	var ctxt = this;
	if (ctxt._socket.readyState === 1) {
		ctxt._socket.send(raw);
	} else {
		console.log("Send attempted while disconnected. Reconnecting...");
		ctxt.connect(ctxt.options.url, {
			after: function() {
				ctxt._socket.send(raw);
			}
		})
	}
};

EventSocket.prototype.emitEvent = function(action, activity_id, payload) {
	var ctxt = this;
	ctxt.send(JSON.stringify({
		action: action,
		activity_id: activity_id,
		payload: payload
	}));
};