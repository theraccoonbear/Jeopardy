var socket;

var Game = function(activity) {
	var ctxt = this;
	var opts = activity.game;
	ctxt.options = $.extend({
		revealSpeed: 250
	}, opts);
	ctxt.state = activity.state;
	ctxt.current = {
		answer: false,
		row: false,
		col: false
	};
	ctxt.$overlayPanes = $('.overlay-pane');
	ctxt.$answerRevealer = $('#answerRevealer');
	ctxt.$answerText = ctxt.$answerRevealer.find('h1.answer');
	ctxt.$quetionText = ctxt.$answerRevealer.find('h2.question');
	ctxt.$arbitraryPane = $('#arbitraryPane');
	ctxt.$statusPane = $('#statusPane');
	ctxt.$statusText = ctxt.$statusPane.find('h1');
	ctxt.$wagerPane = $('#wagerPane');
	ctxt.$wagerType = $('#wagerType');
	ctxt.$wagerAmount = $('#wagerAmount');
	ctxt.$wagerSubmit = $('#wagerSubmit');
	ctxt.$playerBuzzed = $('#playerBuzzed');
	ctxt.$buzzerName = $('#buzzerName');
	ctxt.$buzzIn = $('#buzzIn');
	ctxt.$window = $(window);
	ctxt.hideAllOverlays();
	ctxt.updateState(activity);
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
	}, ctxt.revealSpeed, null, function() {
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

Game.prototype.showAnswer = function(row, col, options) {
	var ctxt = this;

	var opts = $.extend({
		answering: false,
		immediate: false
	}, options);

	var $row = $('.jeopardy-board.row:eq(' + (row + 1) + ')');
	var $cell = $row.find('.point.block:eq(' + col + ')');
	//$cell.animate({opacity: 0}, 1500);
	var ans = ctxt.options.answers[row].points[col];
	ctxt.current.answer = ans;
	ctxt.current.row = row;
	ctxt.current.col = col;
	ctxt.current.$cell = $cell;
	console.log('answer:', ans);

	ctxt.hideAllOverlays();
	ctxt.$answerText.html('A: ' + ans.answer);
	ctxt.$quetionText.html(running ? ('Q: ' + ans.question) : '');

	var right = window.innerWidth - ($cell.position().left + $cell.width());
	var bottom = window.innerHeight - ($cell.position().top + $cell.height());
	
	ctxt.$answerRevealer
		.removeClass('hidden')
		.css({
			position: 'fixed',
			left: $cell.position().left,
			top: $cell.position().top,
			right: right,
			bottom: bottom,
			opacity: 0
		})
		.show()
		.animate({
			opacity: 1, 
			left: 0,
			top: 0,
			right: 0,
			bottom: 0
		}, opts.immediate ? ctxt.revealSpeed : ctxt.revealSpeed, function() {
			if (opts.answering) {
				ctxt.playerBuzzed(opts.answering);
			}
		});
};

Game.prototype.hideAllOverlays = function() {
	var ctxt = this;
	ctxt.$overlayPanes.addClass('hidden');
}

Game.prototype.showStatus = function(msg, opts) {
	var ctxt = this;
	ctxt.hideAllOverlays();
	ctxt.$statusText.html(msg);
	ctxt.$statusPane
		.removeClass('hidden')
		.animate({
			opacity: 1, 
			left: 0,
			top: 0,
			right: 0,
			bottom: 0
		}, ctxt.revealSpeed);
};

Game.prototype.showArbitrary = function(content, opts) {
	var ctxt = this;
	ctxt.hideAllOverlays();
	ctxt.$statusPane
		.html(content)
		.removeClass('hidden')
		.animate({
			opacity: 1, 
			left: 0,
			top: 0,
			right: 0,
			bottom: 0
		}, ctxt.revealSpeed);
};

Game.prototype.getAnswer = function(row, col) {
	var ctxt = this;
	row = typeof row !== 'undefined' ? row : ctxt.current.row;
	col = typeof col !== 'undefined' ? col : ctxt.current.col;
	return ctxt.options.answers[row].points[col];
}

Game.prototype.updateState = function(activity) {
	var ctxt = this;

	var origState = $.extend({}, ctxt.state);

	ctxt.state = activity.state;

	$.each(ctxt.state.players, function(i, p) {
		var $p = $('li[data-player="' + p.username + '"]');
		if ($p.length < 1) {
			$p = ctxt.addPlayer(p);
		}
		$p.find('.score').html(1 * p.score);
		if (ctxt.state.active_player && p.username == ctxt.state.active_player.username) {
			$p
				.addClass('baton')
				.find('.glyphicon')
				.addClass('glyphicon-check')
				.removeClass('glyphicon-unchecked');
		} else {
			$p
				.removeClass('baton')
				.find('.glyphicon')
				.removeClass('glyphicon-check')
				.addClass('glyphicon-unchecked');
		}
	});

	$.each(ctxt.state.claims, function(ri, r) {
		$.each(r, function(ci, c) {
			if (c !== null) {
				ctxt.removeAnswer(ri, ci, { immediate: true });
			}
		});
	});

	if (activity.state) {
		if (activity.state.phase) {
			switch (activity.state.phase) {
				case 'reveal':
					if (ctxt.state.phase !== activity.state.phase ||
						ctxt.current.row !== activity.state.meta.row ||
						ctxt.current.col !== activity.state.meta.col) {
							console.log('reveal:', activity.state);
							ctxt.showAnswer(activity.state.meta.row, activity.state.meta.col, { immediate: true });
						}
					break;
				case 'answering':
					console.log('answering:', activity.state);
					ctxt.showAnswer(activity.state.meta.row, activity.state.meta.col, { answering: activity.state.meta.user, immediate: true });
					break;
				case 'daily_double_wager':
					console.log("Daily Double!");
					ctxt.showDailyDouble();
				default:
					console.log("Unknown phase:", activity.state.phase);
			}
		}
	}
};

Game.prototype.activatePlayer = function(player) {
	var ctxt = this;
	$playerList.find('li[data-player]').removeClass('active');
	$playerList.find('li[data-player="' + player.username + '"]').addClass('active');
};

Game.prototype.addPlayer = function(player) {
	var ctxt = this;
	var $player = $playerList.find('li[data-player="' + player.username + '"]');
	
	if ($player.length < 1) {
		$player = $('<li data-player="' + player.username + '" class="list-inline-item' + (ctxt.state.active_player && ctxt.state.active_player.username == player.username ? ' baton' : '') + '"><span class="glyphicon"></span> <span class="username">' + player.username + '</span> ($<span class="score"></span>)</li>');
		$playerList.append($player);
		ctxt.showNotice(player.username + ' is playing now!');
	}
	return $player;
};

Game.prototype.isPlayerActive = function(username) {
	var ctxt = this;

	return typeof ctxt.state !== 'undefined' && 
		typeof ctxt.state.active_player !== 'undefined' &&
		ctxt.state.active_player && 
		typeof ctxt.state.active_player.username !== 'undefined' &&
		typeof ctxt.state.active_player.username &&
		ctxt.state.active_player.username === username;
};

Game.prototype.getPlayer = function(username) {
	var ctxt = this;
	var player = false;
	$.each(ctxt.state.players, function(i, p) {
		if (p.username === username) {
			player = p;
		}
	});

	return player;
};

Game.prototype.getPlayerScore = function(username) {
	var ctxt = this;
	var player = this.getPlayer(username);


	return player ? player.score : 0;
};

Game.prototype.removeAnswer = function(row, col, opts) {
	var ctxt = this;
	row = typeof row !== 'undefined' ? row : ctxt.current.row;
	col = typeof col !== 'undefined' ? col : ctxt.current.col;
	opts = $.extend({}, {
		immediate: false
	}, opts);

	ctxt
		.getAnswerCell(row, col)
		.addClass('claimed')
		.animate({
			opacity: 0,
		}, opts.immediate ? 0 : 250);
};

Game.prototype.getDailyDoubleWager = function(cb) {
	var ctxt = this;

	ctxt.hideAllOverlays();
	ctxt.$wagerType.html('Daily Double');
	ctxt.$wagerPane
		.removeClass('hidden')
		.animate({
			opacity: 1, 
			left: 0,
			top: 0,
			right: 0,
			bottom: 0
		}, ctxt.revealSpeed);
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
};

Game.prototype.playerBuzzed = function(user) {
	var ctxt = this;
	ctxt.showNotice(user.username + ' buzzed');
	ctxt.current.user = user;
	if (running) {
		ctxt.$buzzerName.html(user.username);
		ctxt.$playerBuzzed.removeClass('hidden');
	} else {
		ctxt.$buzzIn.hide();
	}
};

Game.prototype.showDailyDouble = function() {
	var ctxt = this;
	if (ctxt.state.active_player && ctxt.state.active_player.username === username) {
		ctxt.getDailyDoubleWager();
	} else if (running) {
		ctxt.showAnswer(ctxt.state.meta.row, ctxt.state.meta.col);
	} else {
		ctxt.showArbitrary('<div class="daily-double-image"></div>');
	}	
};

$(function() {
	var ws_url = "ws://" + document.location.hostname + ":5000/websocket/";
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

		$playerList.find('li').css({
			fontSize: Math.round(v / 3) + 'px'
		});
	};

	$(window).on('resize', scaleType);
	scaleType();

	var ES = new EventSocket({
		url: ws_url,
		reconnectDelay: 1000,
		reconnectLimit: 10,
		ready: function() {
			ES.send(JSON.stringify({
				action: 'subscribe',
				activity_id: activity_id
			}));

			if (running) {
				// @todo handle empty questions corretly
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

				$('#playerList').on('click', '[data-player]', function(e) {
					var $this = $(this);
					console.log('you clicked player:', $this.data('player'), $this);

					if ($this.hasClass('active')) { return; }

					$this.closest('ul').find('[data-player]').removeClass('active');

					var player = ourGame.getPlayer($this.data('player'));
					$playerScore
						.val(player.score)
						.data('active-player', player);

					$playerIsActive
						.prop('checked', ourGame.isPlayerActive(player.username));

					$this
						.addClass('active');
				});

				$savePlayer.on('click', function() {
					var player = $playerScore.data('active-player');
					ES.emitEvent('update_player', activity_id, {
						username: player.username,
						score: $playerScore.val(),
						active_player: $playerIsActive.is(':checked')
					});
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
					ES.emitEvent('buzz', activity_id, {current: ourGame.current});
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
				//console.log(payload.activity.state.active_player.username, username);
				ourGame.setCurrent(payload.row, payload.col);
				ourGame.showDailyDouble();
			},
			reveal: function(payload) {
				if (running) { $playerBuzzed.addClass('hidden'); }
				ourGame.showAnswer(payload.row, payload.col, { immediate: running });
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
				var ans = ourGame.getAnswer();
				if (ans.daily_double) {
					ourGame.hideAllOverlays();
				} else {
					if (running) {
						$playerBuzzed.addClass('hidden');
					} else {
						$buzzIn.show();
					}
				}
			},
			dismiss_answer: function(payload) {
				ourGame.hideAllOverlays();
			},
			kill_answer: function(payload) {
				ourGame.hideAllOverlays();
				ourGame.removeAnswer();
			},
			buzz: function(payload) {
				console.log('Buzz:', payload);
				ourGame.playerBuzzed(payload.user);
			},
			player_running: function(payload) {
				ourGame.showNotice(payload.player.username + ' is running the game!');
			}
		}
	});

	ES.connect();

	// var noSleep = new NoSleep();

	// function enableNoSleep() {
	// 	noSleep.enable();
	// 	document.removeEventListener('touchstart', enableNoSleep, false);
	// }

	// // Enable wake lock.
	// // (must be wrapped in a user input event handler e.g. a mouse or touch handler)
	// document.addEventListener('touchstart', enableNoSleep, false);

	// ...

	// Disable wake lock at some point in the future.
	// (does not need to be wrapped in any user input event handler)
	//noSleep.disable();
});