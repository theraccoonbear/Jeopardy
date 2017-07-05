var socket;

var Game = function(activity) {
	var ctxt = this;
	var opts = activity.game;
	ctxt.options = $.extend({}, opts);
	ctxt.state = activity.state;
	ctxt.current = {
		answer: false,
		row: false,
		col: false
	};
	ctxt.$answerRevealer = $('#answerRevealer');
	ctxt.$answerText = ctxt.$answerRevealer.find('h1.answer');
	ctxt.$quetionText = ctxt.$answerRevealer.find('h2.question');
	ctxt.$statusPane = $('#statusPane');
	ctxt.$statusText = ctxt.$statusPane.find('h1');
	ctxt.$wagerPane = $('#wagerPane');
	ctxt.$wagerAmount = $('#wagerAmount');
	ctxt.$wagerSubmit = $('#wagerSubmit');
};

Game.prototype.showNotice = function(msg, opts) {
	var ctxt = this;
	opts = opts || {};
	var type = opts.type || 'info'

	var $note = $(
`<li class="alert alert-${type} alert-dismissible show" role="alert">
  <button type="button" class="close" data-dismiss="alert" aria-label="Close">
    <span aria-hidden="true">&times;</span>
  </button>
  ${msg}
</li>`);

	$note
		.css({
			opacity: 0
		})
		.animate({opacity: 1}, 250)
		.appendTo($notices);

	setTimeout(function() {
		$note.animate({
			opacity: 0,
			height: 0,
			width: 0
		}, {
			duration: 250,
			complete: function() {
				$note.remove();
				$note = null;
			}
		})
	}, 3000)
};

Game.prototype.hideAnswer = function() {
	var ctxt = this;
	ctxt.$answerRevealer.animate({
		opacity: 0
	}, 1000, null, function() {
		if (running) {
			$buzzerName.html('');
		} else {
			$buzzIn.show();
		}
		ctxt.$answerRevealer.hide();
	});
}

Game.prototype.getAnswerCell = function(row, col) {
	var $row = $('.jeopardy-board.row:eq(' + (row + 1) + ')');
	var $cell = $row.find('.point.block:eq(' + col + ')');
	return $cell;
}

Game.prototype.setCurrent = function(row, col) {
	var ctxt = this;
	ctxt.current.row = row;
	ctxt.current.col = col;
};

Game.prototype.showAnswer = function(row, col) {
	var ctxt = this;
	var $row = $('.jeopardy-board.row:eq(' + (row + 1) + ')');
	var $cell = $row.find('.point.block:eq(' + col + ')');
	//$cell.animate({opacity: 0}, 1500);
	var ans = ctxt.options.answers[row].points[col];
	ctxt.current.answer = ans;
	ctxt.current.row = row;
	ctxt.current.col = col;
	ctxt.current.$cell = $cell;
	console.log('answer:', ans);

	ctxt.$statusPane.css({opacity: 0});
	ctxt.$answerText.html('A: ' + ans.answer);
	ctxt.$quetionText.html(running ? ('Q: ' + ans.question) : '');
	//console.log($cell.position(), $cell.width(), $cell.height());
	ctxt.$answerRevealer
		.css({
			left: $cell.position().left,
			top: $cell.position().top,
			right: $cell.position().left + $cell.width(),
			botom: $cell.position().top + $cell.height(),
			opacity: 0
		}
		).show()
		.animate({
			opacity: 1, 
			left: 0,
			top: 0,
			right: 0,
			bottom: 0
		}, 1000);
};

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
};

Game.prototype.updateState = function(activity) {
	var ctxt = this;

	var origState = $.extend({}, ctxt.state);

	ctxt.state = activity.state;

	$.each(ctxt.state.players, function(i, p) {
		var $p = $('li[data-player="' + p.username + '"]');
		$p.find('.score').html(p.score);
	});

	if (activity.state) {
		if (activity.state.phase) {
			switch (activity.state.phase) {
				case 'reveal':
					break;
				default:
					console.log("Unknown phase:", activity.state.phase);
			}
		}
	}
};

Game.prototype.addPlayer = function(player) {
	var ctxt = this;
	ctxt.showNotice(player.username + ' is playing now!');
	console.log('player!', player);
	var $player = $playerList.find('li[data-player="' + player.username + '"]');
	if ($player.length < 1) {
		var $newplayer = $('<li data-player="' + player.username + '"><span class="username">' + player.username + '</span> ($<span class="score"></span>)<li>');
		$playerList.append($newplayer);
	}
};

Game.prototype.getPlayerScore = function(username) {
	var ctxt = this;
	var score = false;
	$.each(ctxt.state.players, function(i, p) {
		if (p.username === username) {
			score = p.score;
		}
	});

	return score;
};

Game.prototype.removeAnswer = function(row, col) {
	var ctxt = this;
	row = row || ctxt.current.row;
	col = col|| ctxt.current.col;

	ctxt
		.getAnswerCell(row, col)
		.addClass('claimed')
		.animate({
			opacity: 0,
		}, 250);
};

Game.prototype.getDailyDoubleWager = function(cb) {
	var ctxt = this;

	ctxt.$wagerPane.animate({
		opacity: 1, 
		left: 0,
		top: 0,
		right: 0,
		bottom: 0
	}, 1000);
};

Game.prototype.hideDailyDoubleWager = function() {
	var ctxt = this;
	ctxt.$wagerPane.animate({
		opacity: 0
	}, 250, null, function() {
		if (!running) {
			ctxt.$wagerPane.hide();
		}
		
	});
}

$(function() {
	var ws_url = "ws://" + document.location.hostname + ":5000/websocket/";
	var failedConnections = 0;
	var reconnectDelay = 1000; // ms until reconnect
	var ourGame = new Game(game);

	var $pointBlocks = $('.point.block');
	var $categoryBlocks = $('.category.block');

	var scaleType = function(e) {
		var w = $pointBlocks.width();
		var h = $pointBlocks.height();

		var v = Math.min(w, h);

		$pointBlocks.css({
			fontSize: Math.round(v / 2) + 'px'
		});
		$categoryBlocks.css({
			fontSize: Math.round(v / 3) + 'px'
		});
	};

	$(window).on('resize', scaleType);
	scaleType();

	var ES = new EventSocket({
		url: ws_url,
		reconnectDelay: reconnectDelay,
		ready: function() {
			ES.send(JSON.stringify({
				action: 'subscribe',
				activity_id: activity_id
			}));

			if (running) {
				$('.point').on('click', function(e) {
					var $this = $(this);
					if (!$this.hasClass('claimed')) {
						var col = $this.index();
						var row = $this.closest('.jeopardy-board.row').index();

						if ($this.hasClass('daily-double')) {
							ES.emitEvent('daily_double', activity_id, {row: row, col: col});
						} else {
							ES.emitEvent('reveal', activity_id, {row: row, col: col});
						}
					}
				});

				$acceptAnswer.on('click', function(e) {
					ES.emitEvent('accept_answer', activity_id, {current: ourGame.current});
				});

				$wrongAnswer.on('click', function(e) {
					ES.emitEvent('wrong_answer', activity_id, {current: ourGame.current});
				});

				$dismissAnswer.on('click', function(e) {
					ES.emitEvent('dismiss_answer', activity_id, {current: ourGame.current});
				});

				$killAnswer.on('click', function(e) {
					ES.emitEvent('kill_answer', activity_id, {current: ourGame.current});
				});
			} else {
				$buzzIn.on('click', function(e) {
					ES.emitEvent('buzz', activity_id, {});
				});

				$wagerSubmit.on('click', function(e) {
					if (!$wagerAmount.closest('div').hasClass('has-error')) {
						ourGame.hideDailyDoubleWager();
						ES.emitEvent('wager', activity_id, { 
							current: ourGame.current, 
							row: ourGame.current.row,
							col: ourGame.current.col,
							wager: $wagerAmount.val()
						});
					}
				});

				$wagerAmount.on('keypress', function(e) {
					var $this = $(this);
					var $div = $this.closest('div');
					var val = $this.val();
					if (!val || val < 0) {
						$div.addClass('has-error');
					} else {
						$div.removeClass('has-error');
					}
				});
			}
		},
		on: {
			beforeAction: function(payload) {
				if (payload.data.activity) {
					ourGame.updateState(payload.data.activity);
				}
			},
			daily_double: function(payload) {
				console.log('daily_double', payload);
				console.log(payload.activity.state.active_player.username, username);
				ourGame.setCurrent(payload.row, payload.col);
				if (payload.activity.state.active_player.username === username) {
					ourGame.getDailyDoubleWager();
				}
			},
			reveal: function(payload) {
				if (running) { $playerBuzzed.addClass('hidden'); }
				ourGame.showAnswer(payload.row, payload.col);
			},
			player_play: function(payload) {
				ourGame.addPlayer(payload.player);
			},
			accept_answer: function(payload) {
				console.log('accept_answer', payload);
				ourGame.showNotice(payload.user.username + ' was correct.  Awarded $' + payload.current.answer.value + '. New score $' + ourGame.getPlayerScore(payload.user.username), {type: 'success'});
				ourGame.hideAnswer();
				ourGame.removeAnswer();
			},
			wrong_answer: function(payload) {
				console.log('wrong_answer', payload);
				ourGame.showNotice(payload.user.username + ' was wrong', {type: 'danger'});
				if (running) {
					$playerBuzzed.addClass('hidden');
				} else {
					$buzzIn.show();
				}
			},
			dismiss_answer: function(payload) {
				ourGame.hideAnswer();
			},
			kill_answer: function(payload) {
				ourGame.hideAnswer();
				ourGame.removeAnswer();
			},
			buzz: function(payload) {
				console.log('Buzz:', payload);
				ourGame.showNotice(payload.user.username + ' buzzed');
				ourGame.current.user = payload.user;
				if (running) {
					$buzzerName.html(payload.user.username);
					$playerBuzzed.removeClass('hidden');
				} else {
					$buzzIn.hide();
				}
			},
			player_running: function(payload) {
				ourGame.showNotice(payload.player.username + ' is running the game!');
			}
		}
	});

	ES.connect();
});