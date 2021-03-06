class nppcMap {
	constructor (lefttoprightbottom, imageWidth, imageHeight) {
		Object.assign(this, nppcMap.parseLeftTopRightBottom(lefttoprightbottom));
		this._imageWidth = imageWidth;
		this._imageHeight = imageHeight;
	}
	static parseLeftTopRightBottom(lefttoprightbottom) {
		var ret = new Object();
		var lr = lefttoprightbottom.split(";");
		if (lr.length != 2) throw "Semicolon was expected as separator of left top & bottom right corners";
		var l = lr[0].split(",");
		if (l.length != 2) throw "Comma was expected as separator of LAT & LNG";
		ret._leftEdge = Number(l[0]);
		ret._topEdge = Number(l[1]);
		var r = lr[1].split(",");
		if (r.length != 2) throw "Comma was expected as separator of LAT & LNG";
		ret._rightEdge = Number(r[0]);
		ret._bottomEdge = Number(r[1]);
		return ret;
	} 
	get leftEdge() {
		return this._leftEdge;
	}
	get rightEdge() {
		return this._rightEdge;
	}
	get topEdge() {
		return this._topEdge;
	}
	get bottomEdge() {
		return this._bottmEdge;
	}
	X2LAT(x) {
		return x * (this._rightEdge - this._leftEdge) / this._imageWidth + this._leftEdge;
	}
	LAT2X(x) {
		return Math.round((x - this._leftEdge) * this._imageWidth / (this._rightEdge - this._leftEdge));
	}
	Y2LNG(x) {
		return x * (this._bottomEdge - this._topEdge) / this._imageHeight + this._topEdge;
	}
	LNG2Y(x) {
		return Math.round((x - this._topEdge) * this._imageHeight / (this._bottomEdge - this._topEdge));
	}
};

var map;