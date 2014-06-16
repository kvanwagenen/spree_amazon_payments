// require store/spree_frontend
var SpreeAmazonPayments = {

}

$(function(){
	
	// Post form before authentication request to amazon
	if(window.location.pathname === "/cart"){
		$("#AmazonPayButton img").click(function(e){
			$.post('/cart', $("#update-cart").serialize() + "&checkout");			
		});
	}

	// Ensure clicking the logout button also removes amazon token
	$("#logout-lnk").click(function(e){
		document.cookie = "amazon_Login_state_cache=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
	});
})