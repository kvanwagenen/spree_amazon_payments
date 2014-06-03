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
})