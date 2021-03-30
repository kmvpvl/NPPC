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
	});
}

function drawDateTime(d) {
	var options_date = {
		year: "2-digit",
		month: "2-digit",
		day: "2-digit"
	};
	var options_time = {
		hour: "2-digit",
		minute: "2-digit"
	};
	var cd = new Date();
	if (cd.getFullYear() == d.getFullYear()) {
		if (cd.getDate() == d.getDate() && cd.getMonth() == d.getMonth()) {
			return d.toLocaleTimeString($("#language").val(), options_time);			
		} else {
			return d.toLocaleDateString($("#language").val(), options_date);
		}
	} else {
		return d.toLocaleDateString($("#language").val(), options_date);
	}
}

function drawDateTimeDiff(d, cd) {
	var diff = Math.abs(d-cd)/1000;
	var inlate = d - cd > 0 ? "+" : "-";
	var outlate = d - cd > 0 ? "":"";
	if (diff > 60) {
		// sec
		diff = diff / 60;
		if (diff > 60) {
			// min
			diff = diff / 60;
			if (diff > 24) {
				//hours
				diff = diff / 24;
				if (diff > 7) {
					//weeks
					diff = diff / 7;
					return  inlate + Math.round(diff) + "w" + outlate;
				} else {
					return  inlate + Math.round(diff) + "d" + outlate;
				}
			} else {
				return  inlate + Math.round(diff) + "h" + outlate;
			}
		} else {
			return  inlate + Math.round(diff) + "m" + outlate;
		}
	} else {
		return  inlate + Math.round(diff) + "s" + outlate;
	}
}

class ORMNaviMessage {
	static current_message = null;
    el = null;
    constructor (obj) {
        Object.assign(this, obj);
        this.el = $('message[message_id="'+this.id+'"]');
        this.drawMessage();
        this.el[0].ORMNaviMessage = this;
    }
	/**
	 * 
	 */
	static send(body, type) {
		sendDataToNavi('apiSendMessage', {body: body, type:type}, 
		function(data, status) {
			hideLoading();
			//debugger;
			switch (status) {
				case "success":
				break;
				default:
					showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
			}
		});
    }

	drawMessage() {
		//debugger;
		this.el.addClass(this.type);
		var mt = new Date(this.message_time);
		this.el.html('<message_time>'+drawDateTime(mt)+'</message_time><message_from>'+this.from+'</message_from><message_body>'+this.body+'</message_body>');
	}

    dismiss(){
        sendDataToNavi('apiMakeMessageRead', {message_id: this.id}, 
		function(data, status) {
			hideLoading();
			//debugger;
			switch (status) {
				case "success":
					$("message[message_id='"+ORMNaviMessage.current_message+"']").hide();
				break;
				default:
					showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
			}
		});
		ORMNaviMessage.current_message = this.id;
    }
}

class ORMNaviOrder {
	static current_order = null;
    el = null;
    constructor (obj, htmlelement = null) {
        Object.assign(this, obj);
		if (!htmlelement) {
			this.el = $('order[number="'+this.number+'"]');
		} else {
			this.el = htmlelement;
		}
        this.drawOrder();
        this.el[0].ORMNaviOrder = this;
    }

	drawOrder() {
		var dl = new Date(this.deadline);
		var cd = new Date();
		
		var tmp = '<order-header>';
		tmp += '<order-caption>ORDER #</order-caption>';
		tmp += '<number>'+this.number+"</number>"
		tmp += "<order-customer>"+this.customer.name+"</order-customer>"
		tmp += "<order-products>";
		for (ind in this.products) tmp += "<order-product>"+this.products[ind].name+"</order-product>"
		tmp += "</order-products>"
		tmp += "</order-header>";
		tmp += '<order-timing>';
		tmp += '<due class="'+(dl>cd?'intime':'late')+'"><absolute-date>'+drawDateTime(dl)+'</absolute-date><diff-date>'+drawDateTimeDiff(dl, cd)+'</diff-date></due>';

		if (this.estimated) {
			var est = new Date(this.estimated);
			var bl = new Date(this.baseline);
			tmp += '<estimated class="'+(est>cd?'intime':'late')+'"><absolute-date>'+drawDateTime(est)+'</absolute-date><diff-date>'+drawDateTimeDiff(est, cd)+'</diff-date></estimated>';
			tmp += '<baseline class="'+(bl>cd?'intime':'late')+'"><absolute-date>'+drawDateTime(bl)+'</absolute-date><diff-date>'+drawDateTimeDiff(bl, cd)+'</diff-date></baseline>';
		}
		tmp += '</order-timing>';
		tmp += '<order-history>';
		if (this.history) {
			//debugger;
			for (ind in this.history){
				tmp += '<event><event-time>'+drawDateTime(new Date(this.history[ind].event_time))+'</event-time>';
				tmp += '<workcenter name="'+(this.history[ind].workcenter_name?this.history[ind].workcenter_name:'')+'" operation="'+this.history[ind].operation+'">'+(this.history[ind].workcenter_desc?this.history[ind].workcenter_desc:'')+'</workcenter>';
				tmp += '<bucket>'+(this.history[ind].bucket?this.history[ind].bucket:'')+'</bucket>';
				if (this.history[ind].road_name) tmp += '<road name="'+(this.history[ind].road_name?this.history[ind].road_name:'')+'">'+(this.history[ind].road_desc?this.history[ind].road_desc:'')+'</road>';
				tmp += '</event>';
			}
		}
		tmp += '</order-history>';
		this.el.html(tmp);
	}
	static getBucket(obj, workcenter) {
		for (ind in obj.history) {
			if (workcenter == obj.history[ind].workcenter_name) {
				//debugger;
				return {bucket: obj.history[ind].bucket, assign: obj.history[ind].id, fullset:obj.history[ind].fullset, operation: obj.history[ind].operation}; 
			}
		}
		return null;
	}
}

class ORMNaviFactory {
	static workloads = null;
	static updateWorkloads() {
		sendDataToNavi("apiGetWorkloads", undefined, function(data, status){
			hideLoading();
			switch (status) {
				case "success":
					var ls = JSON.parse(data);
					ORMNaviFactory.workloads = ls.data;
					break;
				default:
					showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
			}
		});
	}
}

function modalOrderInfo(order_number) {
	$(".modal-body").html("<orderinfo/>");
	sendDataToNavi("apiGetOrderInfo", {order_number:order_number},
	function (data, status) {
        hideLoading();
		//debugger;
		switch (status) {
			case "success":
				var ls = JSON.parse(data);
				var temp = new ORMNaviOrder(ls.data, $("orderinfo"));
				$("orderinfo > order-history > event > workcenter").each (function () {
					var w = $(this).attr("name");
					var o = $(this).attr("operation");
					if (w in ORMNaviFactory.workloads.workcenters.capacity && 
						w in ORMNaviFactory.workloads.workcenters.assigns && 
						o in ORMNaviFactory.workloads.workcenters.capacity[w] &&
						o in ORMNaviFactory.workloads.workcenters.assigns[w]) {
						
						var c = ORMNaviFactory.workloads.workcenters.capacity[w][o];
						var a = ORMNaviFactory.workloads.workcenters.assigns[w][o];
						var k = a / c;
						if (k > 1) k = 1.0;
						k = Math.round(k * 12) - 1;
						$(this).addClass("duty-"+k);
					} else {
						$(this).addClass("noduty");
					}
				});

				$("orderinfo > order-history > event > road").each (function () {
					var r = $(this).attr("name");
					if (r in ORMNaviFactory.workloads.roads.capacity && r in ORMNaviFactory.workloads.roads.assigns) {
						var c = ORMNaviFactory.workloads.roads.capacity[r];
						var a = ORMNaviFactory.workloads.roads.assigns[r];
						var k = a / c;
						if (k > 1) k = 1.0;
						k = Math.round(k * 12) - 1;
						$(this).addClass("duty-"+k);
					} else {
						$(this).addClass("noduty");
					}
				});
				$("#dlgOrderModal").modal('show');
				break;
			default:
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	});
}
