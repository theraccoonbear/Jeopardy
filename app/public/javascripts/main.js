$(function() {
	var editing = {};

	$('[id]').each(function(i, e) {
		var $e = $(e);
		window['$' + $e.attr('id')] = $e;
	});

	var $board_blocks = $('.jeopardy-board .block');
	var $point_blocks = $board_blocks.filter('.point');

	if (typeof $new_game !== 'undefined') {
		$new_game.on('click', function(e) {
			if ($gameName.val().trim().length < 1) {
				alert("Name your game!");
				e.preventDefault();
				return;
			}
		});
	}

	$point_blocks.on('click', function(e) {
		var $this = $(this);
		$point_blocks.not($this).removeClass('selected');
		$this.addClass('selected');
		var col = $this.index();
		var row = $this.closest('.row').index();
		var challenge = game.answers[row].points[col];
		$answer.val(challenge.answer);
		$question.val(challenge.question);
		editing = {
			row: row,
			col: col
		};
	});

	$updateQuestion.on('click', function(e) {
		$.ajax({
			url: '/api/game/update/' + game._id.$oid,
			type: 'POST',
			dataType: 'json',
			data: {
				action: 'set-q-a',
				row: editing.row,
				col: editing.col,
				question: $question.val(),
				answer: $answer.val()
			},
			success: function(d, s, x) {
				console.log(d);
			},
			error: function(e) {
				console.log(e);
			}
		});
	});
});