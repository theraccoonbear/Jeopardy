$(function() {
	var editing = {};

	$point_blocks = typeof $point_blocks !== 'undefined' ? $point_blocks : $('.point.block');

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

	if (typeof $new_game !== 'undefined') {
		$new_game.on('click', function(e) {
			if ($gameName.val().trim().length < 1) {
				alert("Name your game!");
				e.preventDefault();
				return;
			}
		});
	}

	if (typeof $updateQuestion !== 'undefined') {
		$updateQuestion.on('click', function(e) {
			var _local_editing = editing;
			_local_editing.question = $question.val();
			_local_editing.answer = $answer.val();
			$.ajax({
				url: '/api/game/update/' + game._id.$oid,
				type: 'POST',
				dataType: 'json',
				data: {
					action: 'set-q-a',
					row: _local_editing.row,
					col: _local_editing.col,
					question: $question.val(),
					answer: $answer.val()
				},
				success: function(d, s, x) {
					var $cell = $('.jeopardy-board.row:eq(' + (_local_editing.row + 1) + ') .point.block:eq(' + (_local_editing.col) + ')');
					game.answers[_local_editing.row].points[_local_editing.col].question = _local_editing.question;
					game.answers[_local_editing.row].points[_local_editing.col].answer = _local_editing.answer;
					console.log(d, $cell);
				},
				error: function(e) {
					console.log(e);
				}
			});
		});
	}

	if (typeof $jArchiveSubmit !== 'undefined') {
		$jArchiveSubmit.on('click', function(e) {
			var $form = $jArchiveSubmit.closest('form');
			$form.attr('action', '/game/j-archive/' + $jArchiveId.val());
			$form.submit();
		});
	}
});