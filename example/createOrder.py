#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET
orderID = "1"
oroot = ET.Element("order", id=orderID)
ET.SubElement(oroot, "customer", ref="2")
mdmfile = "mdm.xml"
fctfile = "factory.xml"
logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
logging.info('\n±±±±±±±±±±± Started ±±±±±±±±±±±±±±±')
try :
	logging.info("Product file is %s", sys.argv[1])
except:
	logging.critical("Product file isn't specified")
	logging.critical("usage python createOrder.py <productfile.xml>")
	sys.exit(1)
# product XML
try:
	prodDOM = ET.parse(sys.argv[1])
	logging.info("File %s was parsed successfully", sys.argv[1])
	proot = prodDOM.getroot()
	if proot.tag != 'product' :
		logging.critical('Wrong xml file %s. Root tag must be <product>', sys.argv[1])
		sys.exit(1)
except:
	logging.critical("Wrong xml file %s", sys.argv[1])
	sys.exit(1)

# mdm XML
try:
	mdmDOM = ET.parse(mdmfile)
	logging.info("File %s was parsed successfully", mdmfile)
	mroot = mdmDOM.getroot()
	if mroot.tag != 'dictionary' :
		logging.critical('Wrong xml file %s. Root tag must be <dictionary>', mdmfile)
		sys.exit(1)
except:
	logging.critical("Wrong xml file %s", mdmfile)
	sys.exit(1)

# factory XML
try:
	fDOM = ET.parse(fctfile)
	logging.info("File %s was parsed successfully", fctfile)
	froot = fDOM.getroot()
	if froot.tag != 'factory' :
		logging.critical('Wrong xml file %s. Root tag must be <factory>', fctfile)
		sys.exit(1)
except:
	logging.critical("Wrong xml file %s", fctfile)
	sys.exit(1)

#rep - root element of product
#reo - root element of order
# recursive function for create order tree
def logProdLevel (rep, outlinenumber, reo) : 
	i = 1
	for el in rep :
		out = ""
		if "id" in el.attrib : out = el.attrib["id"]
		else : out = "%s" % (i)
		# creating new subelement of order tree
		tmp = ET.SubElement(reo, el.tag, id = "" + outlinenumber + "." + out)
		if "ref" in el.attrib : 
			logging.info("Product element| %s <%s>, ref = %s", "%s.%s" % (outlinenumber, out), el.tag, el.attrib["ref"])
			tmp.set("ref", el.attrib["ref"])
			#searching in mdm by ref
			r = mroot.findall("*[@id='" + el.attrib["ref"] + "']")
			if not r : 
				logging.critical("Element by ref '%s' isn't found in mdm.xml", el.attrib["ref"])
				sys.exit(1)
			logProdLevel(r[0], "%s.%s" % (outlinenumber, out), tmp)
		else : 
			try:
				logging.info("Product element| %s <%s>, id = %s", "%s.%s" % (outlinenumber, out), el.tag, el.attrib["id"])
				tmp.set("ref", el.attrib["id"])
			except:
				logging.critical("Product element <%s> without ref, but id expected", el.tag)
		logProdLevel(el, "%s.%s" % (outlinenumber, out), tmp)
		i += 1

logging.info("========Starting product jorney")
logProdLevel(proot, orderID + "." + proot.attrib["id"], oroot)
#easy add material with direct supply into order
ET.SubElement(oroot, "material", id=orderID + ".2", ref="box")

otree = ET.ElementTree(oroot)
otree.write("order1.xml")