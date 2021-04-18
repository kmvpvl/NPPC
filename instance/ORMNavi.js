var ORMNaviCurrentMessage = null;
var ORMNaviCurrentOrder = null;
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
	static send(body, type, thread) {
		sendDataToNavi('apiSendMessage', {body: body, type:type, thread:thread==""?undefined:thread}, 
		function(data, status) {
			hideLoading();
			//debugger;
			switch (status) {
				case "success":
					showInformation("Message sent");
					$("#text-new-message").val("");
					$("#txt-new-message-thread").text("");
					updateMessages();
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
		var tags = '';
		if (this.tags) {
			this.tags.forEach(element => {
				if (!tags) tags += ' ';
				tags += element.tag;
			});
		}
		var mb = '<message-time>'+drawDateTime(mt)+'</message-time><message-from>'+this.from+'</message-from><message-body>'+this.body+'</message-body><message-tags>'+tags+'</message-tags>';
		this.el.html(mb);
	}

    dismiss(){
        sendDataToNavi('apiMakeMessageRead', {message_id: this.id}, 
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
		ORMNaviCurrentMessage = this.id;
    }
	flag() {
        sendDataToNavi('apiFlagMessage', {message_id: this.id, flag: (this.flagged=='1'?0:1)}, 
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
		ORMNaviCurrentMessage = this.id;
	}
}

class ORMNaviOrder {
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
	constructor () {
		this.updateFactoryInfo();
	}
	updateFactoryInfo() {
		sendDataToNavi("apiGetFactoryInfo", undefined, function(data, status){
			hideLoading();
			switch (status) {
				case "success":
					var ls = JSON.parse(data);
					Object.assign(NaviFactory, ls.data);
					$('#menu-user').text(NaviFactory.currentUser.name);
					updateMessages();
					loadInstance();
					break;
				default:
					showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
			}
		});
	}
	draw(element) {
		var map = new nppcMap(NaviFactory.map.bounds, element.innerWidth(), element.innerHeight());
		if (!NaviFactory.workcenters || !NaviFactory.roads) return;
		var s = '<svg  width="'+element.innerWidth()+'px" height="'+element.innerHeight()+'px">';
		for(let [ind, road] of Object.entries(NaviFactory.roads)){
			var from = NaviFactory.workcenters[road.from];
			var to = NaviFactory.workcenters[road.to];
			if (from && to) {
				var fromLoc = map.parseLeftTopRightBottom(from.location);
				var toLoc = map.parseLeftTopRightBottom(to.location);
				var fromcx = map.LAT2X((fromLoc._leftEdge + fromLoc._rightEdge)/2);
				var fromcy = map.LNG2Y((fromLoc._topEdge + fromLoc._bottomEdge)/2);
				var tocx = map.LAT2X((toLoc._leftEdge + toLoc._rightEdge)/2);
				var tocy = map.LNG2Y((toLoc._topEdge + toLoc._bottomEdge)/2);
				var roadClass = "noduty";
				if (road.capacity && road.assigns) {
					var c = road.capacity;
					var a = road.assigns;
					var k = a / c;
					if (k > 1) k = 1.0;
					k = Math.round(k * 12) - 1;
					roadClass = "duty-"+k;
				}
				s += '<line road="'+ind+'" class="road '+roadClass+'" x1="'+fromcx+'" y1="'+fromcy+'" x2="'+tocx+'" y2="'+tocy+'"/>';
			}
		}
		for (let [ind, wc] of Object.entries(NaviFactory.workcenters)) {
			var wcloc = map.parseLeftTopRightBottom(wc.location);
			wcloc._leftEdge = map.LAT2X(wcloc._leftEdge);
			wcloc._rightEdge = map.LAT2X(wcloc._rightEdge);
			wcloc._topEdge = map.LNG2Y(wcloc._topEdge);
			wcloc._bottomEdge = map.LNG2Y(wcloc._bottomEdge);
			var wcClass = "noduty";
			var k = 0;
			var n = 0;
			for (let [i, op] of Object.entries(wc.capacity)) {
				k += wc.assigns[i]/op;
				n++;
			}
			k = k /n;	
			if (k > 1) k = 1.0;
			k = Math.round(k * 12) - 1;
			wcClass = "duty-"+k;

			s += '<rect class="workcenter '+wcClass+'" workcenter="'+ind+'" duty="'+k+'" x="'+wcloc._leftEdge+'" y="'+wcloc._topEdge+'" width="'+ (wcloc._rightEdge - wcloc._leftEdge)+'" height="'+(wcloc._bottomEdge - wcloc._topEdge)+'" rx="5" ry="5"/>';
			s += '<text workcenter="'+ind+'" x="0" y="0" >'+wc.name+'</text>';
		}		
		s += '</svg>';
		element.html(s);
		$('text[workcenter]').each(function(){
			var w = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('width'));
			var h = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('height'));
			var x = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('x'))+ (w * 0.05);
			var y = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('y'))+20;
			$(this).attr('x', x + 'px');
			$(this).attr('y', y + 'px');
			if (w > h) {
				$(this).attr('textLength', w * 0.9);
			} else {
				$(this).attr('textLength', h * 0.9);
				$(this).attr('transform', 'translate('+(x-y+10)+', '+(y+x+h*0.9*0.95)+') rotate(-90)');
			}

			var d = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('duty'));
			if (d < 6) {
				$(this).attr('fill', 'black');
			} else {
				$(this).attr('fill', 'white');
			}
		});
	}
}

class ORMNaviUser {
	constructor(obj) {
		Object.assign(this, obj);
	}
	getSubscriptions() {
		
	}
}

function modalOrderInfo(order_number) {
	$("#dlgOrderModalBody").html("<orderinfo/>");
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
					if (o in NaviFactory.workcenters[w].capacity &&
						o in NaviFactory.workcenters[w].assigns) {
						
						var c = NaviFactory.workcenters[w].capacity[o];
						var a = NaviFactory.workcenters[w].assigns[o];
						var k = a / c;
						if (k > 1) k = 1.0;
						k = Math.round(k * 12) - 1;
						$(this).addClass("duty-"+k);
					} else {
						$(this).addClass("noduty");
					}
				});
				$("orderinfo > order-history > event > workcenter").on ('click', function(){
					ORMNaviCurrentOrder = $("orderinfo order-header number").text();
					workcenter($(this).attr("name"));
				});

				$("orderinfo > order-history > event > road").each (function () {
					var r = $(this).attr("name");
					if (NaviFactory.roads[r].capacity && NaviFactory.roads[r].assigns) {
						var c = NaviFactory.roads[r].capacity;
						var a = NaviFactory.roads[r].assigns[r];
						var k = a / c;
						if (k > 1) k = 1.0;
						k = Math.round(k * 12) - 1;
						$(this).addClass("duty-"+k);
					} else {
						$(this).addClass("noduty");
					}
				});
				$("#btn-subscribe").click(function(){
					sendDataToNavi("apiSubscribe", {tag: "#"+$("orderinfo order-header number").text()},
					function(data, status){
						hideLoading();
						//debugger;
						switch (status) {
							case "success":
								ls = JSON.parse(data);
								NaviFactory.currentUser = ls.data;
								if (NaviFactory.currentUser && 
									NaviFactory.currentUser.subscriptions.includes("#"+$("orderinfo order-header number").text())) {
									showInformation("You're subscribed!");
									$("#btn-subscribe").text("Unsubscribe");
								} else {
									showInformation("You're unsubscribed!");
									$("#btn-subscribe").text("Subscribe");
								}
								updateMessages();
							break;
							default:
								showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
						}
					});
				});
				if (NaviFactory.currentUser && 
					NaviFactory.currentUser.subscriptions.includes("#"+$("orderinfo order-header number").text())) {
					$("#btn-subscribe").text("Unsubscribe");
				} else {
					$("#btn-subscribe").text("Subscribe");
				}
				$("orderinfo > order-history > event > road").on ('click', function(){
					ORMNaviCurrentOrder = $("orderinfo order-header number").text();
					road($(this).attr("name"));
				});
				$("#dlgOrderModal").modal('show');
				break;
			default:
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	});
}
