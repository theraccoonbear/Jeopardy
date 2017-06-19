$(function() {
	socket.onopen = function() {
		console.log("Subscribing to ", activity_id);
		subscribe(activity_id);
	};

	$('.point').on('click', function(e) {
		var $this = $(this);

		emitEvent('clickNotice', activity_id, {stuff: "things"});
	});
});