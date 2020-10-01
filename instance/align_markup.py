def joinAll(l, t, r, b):
	return ";".join([",".join(["%.14f" % l, "%.14f" % t]), ",".join(["%.14f" % r, "%.14f" % b])])
o = "53.3834919,50.1689624;53.3780572,50.1744053"	
oltrb = o.split(";")
_ol = float(oltrb[0].split(",")[0])
_ot = float(oltrb[0].split(",")[1])
_or = float(oltrb[1].split(",")[0])
_ob = float(oltrb[1].split(",")[1])

ss = ["53.38337998854569,50.16906707115385;53.38267354749035,50.16969509807692","53.38232032696268,50.16906707115385;53.38161388590733,50.16969509807692","53.38337998854569,50.17000911153846;53.38267354749035,50.17063713846153","53.38232032696268,50.17000911153846;53.38161388590733,50.17063713846153","53.38126066537966,50.17000911153846;53.38055422432430,50.17063713846153"]
max_r = 58
max_b = 0
for s in ss :
	ltrb = s.split(";")
	l = float(ltrb[0].split(",")[0])
	t = float(ltrb[0].split(",")[1])
	r = float(ltrb[1].split(",")[0])
	b = float(ltrb[1].split(",")[1])
	if max_r > r : max_r = r
	if max_b < b : max_b = b
	
kx = (_or - _ol)/(max_r - _ol)
kx = 0.8
ky = (_ob - _ot)/(max_b - _ot)
ky = 2.2
print ("kx = %s, ky = %s" % (kx,ky))
for s in ss :
	ltrb = s.split(";")
	l = float(ltrb[0].split(",")[0])
	t = float(ltrb[0].split(",")[1])
	r = float(ltrb[1].split(",")[0])
	b = float(ltrb[1].split(",")[1])
	l += (l - _ol) * kx;
	r += (r - _ol) * kx;
	t += (t - _ot) * ky;
	b += (b - _ot) * ky;
	print (joinAll(l, t, r, b))
	
def test():
	w = r - l
	h = b - t
	
	# to right
	l += 1.5 * w
	r += 1.5 * w
	print (joinAll(l, t, r, b))
	
	# down
	l -= 1.5 * w
	r -= 1.5 * w
	t += 1.5 * h
	b += 1.5 * h
	print (joinAll(l, t, r, b))
