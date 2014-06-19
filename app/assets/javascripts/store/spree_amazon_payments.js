// require store/spree_frontend
var SpreeAmazonPayments = {

}

$(function(){
	
	// Post form before authentication request to amazon
	if(window.location.pathname === "/cart"){
		$("#AmazonPayButton img").click(function(e){
			$.post('/cart', $("#update-cart").serialize() + "&checkout");			
		});
	
	// Disable order placement button after click to prevent double authorizations
	}else if(window.location.pathname === "/amazon-payments/checkout/confirm"){
		$("#save-btn").click(function(e){
			setTimeout(function(){
				$('#save-btn').attr('disabled','disabled');
				$('#save-btn').val('Processing...');
				$('body').css('cursor', 'wait');
			}, 50);
		});
	}

	// Ensure clicking the logout button also removes amazon token
	$('[href="/logout"]').click(function(e){
		document.cookie = "amazon_Login_state_cache=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
	});
})