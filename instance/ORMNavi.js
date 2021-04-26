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

function recieveDataFromNavi(data, status) {
	hideLoading();
	var ls = null;
	switch (status) {
		case "success":
			try {
				ls = JSON.parse(data);
				if (ls.result == 'FAIL') {
					showLoadingError("Application says: " + ls.description);
				} 
			} catch(e) {
				showLoadingError("Wrong data from server: " + e + " - " + data);
			}
			break;
		default:
			showLoadingError("Unsuccessful request: " + " - " + data);
	}
	return ls;
}

function receiveHtmlFromNavi(data, status) {
	hideLoading();
	switch (status) {
		case "success":
			return data;
			break;
		default:
			clearInstance();
	}
	return null;
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
class EventHandlerPrototype {
	events_handlers = new Object();

	on(event_name, callback) {
		if (!(event_name in this.events_handlers)) {
			this.events_handlers[event_name] = [];
		}
		this.events_handlers[event_name].push(callback);
	}
	fireEvent(event_name, obj){
		if (event_name in this.events_handlers){
			for (var i in this.events_handlers[event_name]){
				var f = this.events_handlers[event_name][i];
				if (typeof(f) == 'function') f(this, obj);
				else this.events_handlers[event_name].splice(i, 1);
			}
		}
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
            var ls = recieveDataFromNavi(data, status);
            if (ls && ls.result=='OK') {
				showInformation("Message sent");
				$("#text-new-message").val("");
				$("#txt-new-message-thread").text("");
				updateMessages();
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
            var ls = recieveDataFromNavi(data, status);
            if (ls && ls.result=='OK') {
				updateMessages();
            }
		});
		ORMNaviCurrentMessage = this.id;
    }
	flag() {
        sendDataToNavi('apiFlagMessage', {message_id: this.id, flag: (this.flagged=='1'?0:1)}, 
		function(data, status) {
            var ls = recieveDataFromNavi(data, status);
            if (ls && ls.result=='OK') {
				updateMessages();
            }
		});
		ORMNaviCurrentMessage = this.id;
	}
}

class ORMNaviOrder extends EventHandlerPrototype {
    el = null;
    constructor (obj, htmlelement = null) {
		super();
        Object.assign(this, obj);
		if (!htmlelement) {
			this.el = $('<order/>');
		} else {
			this.el = htmlelement;
		}
		this.el.attr('number', obj.number);

        this.drawOrder();
        this.el[0].ORMNaviOrder = this;
    }

	drawOrder() {
		var dl = new Date(this.deadline);
		var cd = new Date();
		var tmp = '<order-operations>';
		tmp += '<i operation="info" class="fa fa-info-circle" aria-hidden="true"></i>'; //info
		tmp += '<i operation="next" class="fa fa-arrow-circle-right" aria-hidden="true"></i>'; //next
		tmp += '<i operation="finish" class="fa fa-check-circle" aria-hidden="true"></i>'; //finish
		tmp += '<i operation="priority-up" id="btnPriorityUp" class="fa fa-arrow-circle-up" aria-hidden="true"></i>'; //priority-up
		tmp += '<i operation="priority-down" id="btnPriorityDown" class="fa fa-arrow-circle-down" aria-hidden="true"></i>'; //priority-down
		tmp += '<i operation="pause" class="fa fa-pause-circle" aria-hidden="true"></i>'; //pause
		tmp += '<i operation="continue" class="fa fa-play-circle" aria-hidden="true"></i>'; //continue
		tmp += '<i operation="defect" class="fa fa-bug" aria-hidden="true"></i>'; //defect alarm
		tmp += '<i operation="print-label" class="fa fa-barcode" aria-hidden="true"></i>'; //barcode ticket
		tmp += '<i operation="subscribe" class="fa fa-link" aria-hidden="true"></i>'; //subscribe ticket
		tmp += '<i operation="unsubscribe" class="fa fa-chain-broken" aria-hidden="true"></i>'; //unsubscribe ticket
		tmp += '<i operation="message" class="fa fa-commenting" aria-hidden="true"></i>';
		tmp += '<i operation="update-estimated" class="fa fa-hourglass-end" aria-hidden="true"></i>';
		tmp += '<i operation="update-baseline" class="fa fa-thumb-tack" aria-hidden="true"></i>';
		tmp += '</order-operations>'
		tmp += '<order-header>';
		if (this.priority && this.priority !=0) {
			if (this.priority > 0) {
				tmp += '<order-priority>'+this.priority+'<i class="fa fa-long-arrow-up" aria-hidden="true"></i>'+"</order-priority>"
			} else {
				tmp += '<order-priority>'+'<i class="fa fa-long-arrow-down" aria-hidden="true"></i>'+Math.abs(this.priority)+"</order-priority>"
			}
		} else {
			//tmp += '<order-priority>'+'<i class="fa fa-square" aria-hidden="true"></i>'+"</order-priority>"
		}
		tmp += '<order-caption>ORDER #</order-caption>';
		tmp += '<order-number>'+this.number+"</order-number>"
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
	getHistoryByWorkcenterName(wc_name) {
		for (const o of this.history) {
			if (wc_name == o.workcenter_name) return o;
		}
		return null;
	}
	showOperation(operations, showOrHide){
		var i;
		var th = this;
		if (operations)	{
			if (typeof(operations) === 'object'){
				var s = '';
				for (let [k, op] of Object.entries(operations)){
					if (s.length > 0) s += ',';
					s += 'i[operation="'+op+'"]';
				}
				i = this.el.find(s);
			} else i = this.el.find('i[operation="'+operations+'"]');
		} else i = this.el.find('i[operation]');
		if (showOrHide) {
			i.show();
			i.click(function(){
				fireEvent('operation', {order: th, operation:$(this).attr('operation')});
			});
		} else i.hide();
	}
}

class ORMNaviFactory extends EventHandlerPrototype {
	constructor () {
		super();
		this.updateFactoryInfo();
	}
	updateFactoryInfo() {
		var fr = this;
		sendDataToNavi("apiGetFactoryInfo", undefined, function(data, status){
			var ls = recieveDataFromNavi(data, status);
			if (ls && ls.result=='OK') {
				Object.assign(fr, ls.data);
				$('#menu-user').text(fr.currentUser.name);
				fr.fireEvent('change', null);
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
				var fromLoc = nppcMap.parseLeftTopRightBottom(from.location);
				var toLoc = nppcMap.parseLeftTopRightBottom(to.location);
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
			var wcloc = nppcMap.parseLeftTopRightBottom(wc.location);
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
			s += '<text workcenter="'+ind+'" x="0" y="0" ><tspan caption>'+wc.name+'</tspan>';
			for (let [i, op] of Object.entries(wc.capacity)) {
				s += '<tspan description>'+i+': cap='+op+', ass='+wc.assigns[i]+'</tspan>';
			}
			s += '</text>';
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
			$(this).find('tspan:gt(0)').attr('x', x + 'px');
			$(this).find('tspan:gt(0)').attr('dy', '1.2em');
		if (w > h) {
				$(this).find('tspan:gt(0)').attr('textLength', w * 0.9);
			} else {
				$(this).find('tspan:gt(0)').attr('textLength', h * 0.9);
				$(this).attr('transform', 'translate('+(x-y+10)+', '+(y+x+h*0.9)+') rotate(-90)');
			}

			var d = Number($('rect[workcenter="'+ $(this).attr('workcenter')+'"]').attr('duty'));
			if (d < 6) {
				$(this).addClass('dark');
			} else {
				$(this).addClass('light');
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
		var ls = recieveDataFromNavi(data, status);
		if (ls && ls.result=='OK') {
			var temp = new ORMNaviOrder(ls.data, $("orderinfo"));
			$('orderinfo > order-operations').append('<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>');
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
				ORMNaviCurrentOrder = $("orderinfo order-header order-number").text();
				workcenter($(this).attr("name"));
			});

			$("orderinfo > order-history > event > road").each (function () {
				var r = $(this).attr("name");
				if (NaviFactory.roads[r].capacity && NaviFactory.roads[r].assigns) {
					var c = NaviFactory.roads[r].capacity;
					var a = NaviFactory.roads[r].assigns;
					var k = a / c;
					if (k > 1) k = 1.0;
					k = Math.round(k * 12) - 1;
					$(this).addClass("duty-"+k);
				} else {
					$(this).addClass("noduty");
				}
			});
			$("#btn-subscribe").click(function(){
				sendDataToNavi("apiSubscribe", {tag: "#"+$("orderinfo order-header order-number").text()},
				function(data, status){
					var ls = recieveDataFromNavi(data, status);
					if (ls && ls.result=='OK') {
						NaviFactory.currentUser = ls.data;
						if (NaviFactory.currentUser && 
							NaviFactory.currentUser.subscriptions.includes("#"+$("orderinfo order-header order-number").text())) {
							showInformation("You're subscribed!");
							$("#btn-subscribe").text("Unsubscribe me");
						} else {
							showInformation("You're unsubscribed!");
							$("#btn-subscribe").text("Subscribe me");
						}
						updateMessages();
					}
				});
			});
			if (NaviFactory.currentUser && 
				NaviFactory.currentUser.subscriptions.includes("#"+$("orderinfo order-header order-number").text())) {
				$("#btn-subscribe").text("Unsubscribe me");
			} else {
				$("#btn-subscribe").text("Subscribe me");
			}
			$("orderinfo > order-history > event > road").on ('click', function(){
				ORMNaviCurrentOrder = $("orderinfo order-header order-number").text();
				road($(this).attr("name"));
			});
			$("#dlgOrderModal").modal('show');
		}
	});
}
