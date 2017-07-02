var socket;

var Game = function(opts) {
	var ctxt = this;
	ctxt.options = $.extend({}, opts);
	ctxt.$answerRevealer = $('#answerRevealer');
	ctxt.$answerText = ctxt.$answerRevealer.find('h1');
	ctxt.$statusPane = $('#statusPane');
	ctxt.$statusText = ctxt.$statusPane.find('h1');
};

Game.prototype.showAnswer = function(row, col) {
	var ctxt = this;
	var $row = $('.jeopardy-board.row:eq(' + (row + 1) + ')');
	var $cell = $row.find('.point.block:eq(' + col + ')');
	$cell.animate({opacity: 0}, 1500);
	var ans = ctxt.options.answers[row].points[col];
	console.log('answer:', ans);

	ctxt.$statusPane.css({opacity: 0});
	ctxt.$answerText.html(ans.answer);
	ctxt.$answerRevealer.animate({
		opacity: 1, 
		left: 0,
		top: 0,
		right: 0,
		bottom: 0
	}, 1000);
}

Game.prototype.showStatus = function(msg, opts) {
	var ctxt = this;
	ctxt.$answerRevealer.css({opacity: 0});
	ctxt.$statusText.html(msg);
	ctxt.$statusPane.animate({
		opacity: 1, 
		left: 0,
		top: 0,
		right: 0,
		bottom: 0
	}, 1000);
}

$(function() {
	var ws_url = "ws://" + document.location.hostname + ":5000/websocket/";
	var failedConnections = 0;
	var reconnectDelay = 1000; // ms until reconnect
	var ourGame = new Game(game);

	var ES = new EventSocket({
		url: ws_url,
		ready: function() {
			ES.send(JSON.stringify({
				action: 'subscribe',
				activity_id: activity_id
			}));

			$('.point').on('click', function(e) {
				var $this = $(this);
				var col = $this.index();
				var row = $this.closest('.jeopardy-board.row').index();

				ES.emitEvent('reveal', activity_id, {row: row, col: col});
			});

			$buzzIn.on('click', function(e) {
				ES.emitEvent('buzz', activity_id, {});
			});
		},
		on: {
			reveal: function(payload) {
				ourGame.showAnswer(payload.row, payload.col)
			},
			player_play: function(payload) {
				console.log('player!', payload);
				var $player = $playerList.find('li[data-player="' + payload.player.username + '"]');
				if (!$player.length) {
					var $newplayer = $('<li data-player="' + payload.player.username + '">' + payload.player.username + '<li>');
					$playerList.append($newplayer);
				}
			},
			buzz: function(payload) {
				console.log('Buzz:', payload);
				ourGame.showStatus(payload.username + ' buzzed');
			}
		}
	});

	ES.connect();
});