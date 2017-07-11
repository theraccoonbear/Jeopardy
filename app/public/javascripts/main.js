$(function() {
	// var editing = {};

	$('[id]').each(function(i, e) {
		var $e = $(e);
		window['$' + $e.attr('id')] = $e;
	});

	var $board_blocks = $('.jeopardy-board .block');
	var $point_blocks = $board_blocks.filter('.point');
});