def joinAll(l, t, r, b):
	return ";".join([",".join(["%.14f" % l, "%.14f" % t]), ",".join(["%.14f" % r, "%.14f" % b])])
	
s = "53.38232032696268,50.17000911153846;53.38161388590733,50.17063713846153"
ltrb = s.split(";")
l = float(ltrb[0].split(",")[0])
t = float(ltrb[0].split(",")[1])
r = float(ltrb[1].split(",")[0])
b = float(ltrb[1].split(",")[1])

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
