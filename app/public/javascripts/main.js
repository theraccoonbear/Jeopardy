$(function() {
	// var editing = {};

	$('[id]').each(function(i, e) {
		var $e = $(e);
		window['$' + $e.attr('id')] = $e;
	});

	var $speed_bumps = $('[data-speed-bump]');
	$speed_bumps.each(function(i, e) {
		var $e = $(e);
		var message = $e.data('speed-bump');
		$e.on('click', function(e2) {
			if (!confirm(message)) {
				e2.preventDefault();
				return false;
			}
		});
	});

	var $board_blocks = $('.jeopardy-board .block');
	var $point_blocks = $board_blocks.filter('.point');
});