var cproxy = {
	categories: {
		TV: {cat: 'tv'},
		Movies: {cat: 'movies'}
	},
	profile: {}
};


function updateUsername(username) {
	cproxy.profile.username = username;
	if (typeof $currentUsername !== 'undefined') {
		$currentUsername.html(username);
	}
	saveProfile();
}

function saveProfile() {
	localStorage.setItem('profile', JSON.stringify(cproxy.profile));
}

function loadProfile() {
	cproxy.profile = JSON.parse(localStorage.getItem('profile') || '{}') || {};
	if (typeof cproxy.profile.username !== 'undefined') {
		updateUsername(cproxy.profile.username);
	}
}

function promptForUsername() {
	var username;
	username = prompt("Username?");
	while (!username && !cproxy.profile.username) {
		username = prompt("Username?");
	}
	if (username) {
		updateUsername(username);
	}
	saveProfile();
}

function showNotification(message, alertType) {
	var type = alertType || 'info';

	if (typeof $notificationContainer !== 'undefined') {
		(function() {
			var $notification = $('<div></div>');
			$notification
				.addClass('alert alert-' + type + ' alert-dismissible')
				.attr('role', 'alert')
				.html('<button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>' + message)
				.appendTo($notificationContainer);
				
			setTimeout(function() {
				$notification.animate({
					height: 0,
					opacity: 0
				}, {
					duration: 500,
					complete: function() {
						$notification.fadeOut(500, function() {
							$notification.remove();
							$notification = undefined;
						});
					}
				});
			}, 3000);
		})();
	}
}


$(function() {
	$('[id]').each(function(i, e) {
		var $e = $(e);
		window['$'+$e.attr('id')] = $e;
	});
	
	loadProfile();
	
	if (!cproxy.profile.username) {
		promptForUsername();
	}
	
	$('a.download-link').on('click', function(e) {
		var $this = $(this);
		var url = $this.data('nzb');
		var title = $this.data('title');
		var dlType = cproxy.categories[$searchType.val()] || cproxy.categories.Movies;
		
		$.ajax({
			type: 'POST',
			url: '/api/download',
			data: {
				url: url,
				title: title,
				username: cproxy.profile.username,
				type: dlType.cat
			},
			success: function(d) {
				if (d.success) {
					//alert(title + " queued for download!");
					showNotification(title + " queued for download!", 'success');
				} else {
					//alert("Fail!");
					showNotification(title + " enque failed!", 'danger');
				}
			},
			dataType: 'json'
		});
		
		e.preventDefault();
	});
	
	var doSearch = function() {
		if ($search.val().trim().length < 1) { return; }
		var searchType = cproxy.categories[$searchType.val()] || cproxy.categories.Movies;
		var url = '/search/' + searchType.cat + '/' + encodeURIComponent($search.val());
		document.location = url;
	};
	
	$setUsernameBtn.on('click', function(e) {
		promptForUsername();
		e.preventDefault();
	});
	
	if (typeof $searchButton !== 'undefined') {
		$searchButton.on('click', function(e) {
			doSearch();
			e.preventDefault();
		});
	}
	
	if (typeof $search !== 'undefined') {
		$search.on('keydown', function(e) {
			if (e.keyCode == 13) {
				doSearch();
			}
		});
	}
});