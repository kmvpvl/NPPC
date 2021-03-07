/**
 * 
 * @param {string} api 
 * @param {Object} data 
 * @param {Function} callback 
 */
function sendDataToNavi(api, data, callback) {
	showLoading();
	var p = $.post(api + ".php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		data: data
	},
	callback);
	p.fail(function(data, status) {
		hideLoading();
		switch (data.status) {
			case 401:
				clearInstance();
				showLoginForm();
			default:				
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	})
}
class ORMNaviMessage {
	static current_message = null;
    el = null;
    constructor (obj) {
        Object.assign(this, obj);
        this.el = $('message[message_id="'+this.id+'"]');
        this.drawMessage();
        this.el[0].json = this;
    }
	/**
	 * 
	 */
	static send(body, type) {
		sendDataToNavi('apiSendMessage', {body: body, type:type}, this.sent)
	}

	static sent(data, status) {
        hideLoading();
		debugger;
		switch (status) {
			case "success":
			break;
			default:
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
    }

	drawMessage() {
		//debugger;
		this.el.addClass(this.type);
		this.el.html('<user>from: '+this.from+'</user>'+this.body);
	}

    dismiss(){
        sendDataToNavi('apiMakeMessageRead', {message_id: this.id}, this.hide);
		ORMNaviMessage.current_message = this.id;
    }
    hide(data, status) {
        hideLoading();
		//debugger;
		switch (status) {
			case "success":
                $("message[message_id='"+ORMNaviMessage.current_message+"']").hide();
			break;
			default:
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
    }
}

class ORMNaviFactory {
	static updateBaselines() {

	}
	static updateEstimates() {

	}
}