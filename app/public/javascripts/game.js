$(function() {
	if (typeof $point_blocks !== 'undefined') {
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
	}
});