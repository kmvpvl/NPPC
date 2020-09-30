#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET
try:
    from configparser import ConfigParser
except ImportError:
    from ConfigParser import ConfigParser  # ver. < 3.0
#
#
class ORMException (BaseException):
	"ORMNavi Exception"
	pass
#
# 
class ORMNavi :
	# Constructor of ORMNavi class
	#
	def __init__(self,  factoryID) :
		self._factoryID = factoryID
		self._dataDir = "../" + self._factoryID + "-data/"
		try :
			cp = ConfigParser()
			self._inidata = cp.read(self._dataDir + "settings.ini")
			self._productsPath = self._dataDir + self._inidata["dir"]["products"]
			logging.debug("Products path %s was parsed successfully", self._productsPath)
			self._ordersPath = self._dataDir + self._inidata["dir"]["orders"]
			logging.debug("Orders path %s was parsed successfully", self._ordersPath)
			self._routesPath = self._dataDir + self._inidata["dir"]["routes"]
			logging.debug("Routes path %s was parsed successfully", self._routesPath)
		except :
			logging.info("Settings.ini file %s not found or has wrong format. Using default values", self._dataDir + "settings.ini")
			self._productsPath = self._dataDir + ""
			self._ordersPath = self._dataDir + ""
			self._routesPath = self._dataDir + ""
		mdmfilename = self._dataDir + "mdm.xml" 
		factoryfilename = self._dataDir + "factory.xml"
		# mdm XML loading
		try:
			mdmDOM = ET.parse(mdmfilename)
			logging.info("File with DICTIONARY %s was parsed successfully", mdmfilename)
			self.__mdmroot = mdmDOM.getroot()
		except:
			raise ORMException("Wrong xml file %s. Error message is: %s" % (mdmfilename, sys.exc_info()))
		assert(self.__mdmroot.tag == 'dictionary'), 'Wrong xml file %s. Root tag must be <dictionary>' % (mdmfilename)
			
		# factory XML loading
		try:
			fDOM = ET.parse(factoryfilename)
			logging.info("File %s was parsed successfully", factoryfilename)
			self.__factoryroot = fDOM.getroot()
		except:
			raise ORMException("Wrong xml file %s. Error message is: %s" % (factoryfilename, sys.exc_info()))
		assert (self.__factoryroot.tag == 'factory'), 'Wrong xml file %s. Root tag must be <factory>' % (factoryfilename)
	
	# Function loadProducXMLTree loads product XML tree by product reference. 
	# It looks for file product-<prod_ref>.xml in productsPath directory
	# It returns XML tree object
	def loadProductXMLTree(self, productRef):
		# product XML
		fn = self._productsPath + "product-" + productRef + ".xml"
		try:
			prodDOM = ET.parse(fn)
			logging.info("File %s was parsed successfully", fn)
			proot = prodDOM.getroot()
		except:
			raise ORMException ("Wrong xml file %s. Error message is: %s" % (fn, sys.exc_info()))
		assert (proot.tag == 'product'), 'Wrong xml file %s. Root tag must be <product>' % (fn)
		return proot
	
	# function goRoundProdLevel is recursive function for create order tree
	# rep - current root element of product
	# reo - current root element of order
	# outlinelabel - current root of part label
	def __goRoundProdLevel(self, rep, outlinelabel, reo):
		i = 1
		sum_cost = 0
		sum_duration = 0
		for el in rep :
			cost = 0
			duration = 0
			out = ""
			if "id" in el.attrib : out = el.attrib["id"]
			else : out = "%s" % (i)
			# creating new subelement of order tree
			tmp = ET.SubElement(reo, el.tag, id = "" + outlinelabel + "." + out)
			if "ref" in el.attrib : 
				tmp.set("ref", el.attrib["ref"])
				#searching in mdm by ref
				r = self.__mdmroot.findall("*[@id='" + el.attrib["ref"] + "']")
				if not r : raise ORMException("Element by ref '%s' isn't found in mdm.xml" % (el.attrib["ref"]))
				if len(r) > 1 : raise ORMException("There are several elements by ref '%s' in mdm.xml" % (el.attrib["ref"]))
				# filling info about cost, duration, workcenters
				logging.debug("Order element| %s <%s>, ref = %s", "%s.%s" % (outlinelabel, out), el.tag, el.attrib["ref"])
				if el.tag == "operation" :
					if not "cost" in r[0].attrib : raise ORMException("Operation id = '%s' have no cost" % (el.attrib["ref"]))
					if not "duration" in r[0].attrib : raise ORMException("Operation id = '%s' have no duration" % (el.attrib["ref"]))
					tmp.set("cost", r[0].attrib["cost"])
					tmp.set("duration", r[0].attrib["duration"])
					if "cost" in el.attrib : tmp.set("cost", el.attrib["cost"])
					if "duration" in el.attrib : tmp.set("duration", el.attrib["duration"])
					cost += float(tmp.attrib["cost"]);
					duration += float(tmp.attrib["duration"]);
					#looking for the same operation in factory. What center may complete this operation
					facop = self.__factoryroot.findall(".//operation[@ref='" + el.attrib["ref"] + "']/..")
					if not facop : raise ORMException("Couldn'n find workcenter for operation with id '%s' in factory" % (el.attrib["ref"]))
					else :
						logging.debug("%s workcenters for this operation found", len(facop))
						for wc in facop :
							if wc.tag <> "workcenter" : raise ORMException("Tag operation ref = '%s' in factory xml must be a child in tag workcenter" % (el.attrib["ref"]))
							logging.debug("Workcenter id = '%s' can proceed this operation", wc.attrib["id"])
							ET.SubElement(tmp, "workcenter", ref = wc.attrib["id"])
				o = self.__goRoundProdLevel(r[0], "%s.%s" % (outlinelabel, out), tmp)
				cost += o["cost"]
				duration += o["duration"]
				if el.tag == "material" :
					if not "count" in el.attrib : tmp.set("count", "1")
					else : tmp.set("count", el.attrib["count"])
					if not "cost" in r[0].attrib : raise ORMException("Material id = '%s' have no cost" % (el.attrib["ref"]))
					tmp.set("cost", r[0].attrib["cost"])
					cost += float(r[0].attrib["cost"])
					cost *= float(tmp.attrib["count"])
					duration *= float(tmp.attrib["count"])
			else : 
				raise ORMException("Product element <%s> without ref, but expected" % (el.tag))
			o = self.__goRoundProdLevel(el, "%s.%s" % (outlinelabel, out), tmp)
			cost += o["cost"]
			duration += o["duration"]
			tmp.set("overall_cost", "%s" % cost)
			tmp.set("overall_duration", "%s" % duration)
			sum_cost += cost
			sum_duration += duration
			i += 1
		return {"cost": sum_cost, "duration": sum_duration}

	# Function createOrder creates Order by Product and information from factory and MDM
	# It creates file order-<orderNum>.xml in orders directory
	# productsXMLTree must be an array with products with the same shipment address
	# Be careful! Function uses recursion function goRoundProdLevel
	def createOrder(self, orderNum, customerRef, productsXMLTree):
		logging.info("Starting CreateOrder function: orderNum = %s, customerRef = %s, productXMLTree = %s", orderNum, customerRef, productsXMLTree)
		oroot = ET.Element("order", id=orderNum)
		if (not self.__mdmroot.findall("customer[@id='" + customerRef + "']")) : raise ORMException("Couldn't find customer id '%s' if MDM" % (customerRef))
		ocust = ET.SubElement(oroot, "customer", ref=customerRef)
		i = 1
		for productXMLTree in productsXMLTree :
			outline = "%s.%s.%s" % (orderNum, i, productXMLTree.attrib["id"])
			oprod = ET.SubElement(ocust, "product", id = outline, ref = productXMLTree.attrib["ref"])
			o = self.__goRoundProdLevel(productXMLTree, outline, oprod)
			oprod.set("overall_cost", "%s" % o["cost"])
			oprod.set("overall_duration", "%s" % o["duration"])
			i += 1
		otree = ET.ElementTree(oroot)
		otree.write(self._ordersPath + "order-" + orderNum + ".xml")		
		logging.info("File " + self._ordersPath + "order-" + orderNum + ".xml saved")
		logging.debug("Finishing CreateOrder function\n")
		return oroot
	
	# Function findForks returns array of dictionaries with all permutations of workcenters
	# prodmat is xml tree with product from order
	def __findForks(self, prodmat):
		logging.debug("Finding all operations with various workcenters")
		forks = []
		x = prodmat.findall(".//operation/workcenter[2]/..")
		for op in x :
			logging.debug("The operation %s with several workcenters found", op.attrib["id"])
			y = op.findall("workcenter")
			if len(forks) > 0 :
				# if there've already some paths
				# must duplicate them by count of workcenters and fill workcenter each itself
				
				#temporary array for clones of paths, 'cause we have cycle on forks
				temp = []
				for f in forks:
					i = 0
					for wc in y :
						if i != len(y) - 1 :
							ndict = f.copy()
							temp.append(ndict)
						else :
							# last dictionary don't need to be duplicated
							ndict = f
						ndict[op.attrib["id"]] = wc.attrib["ref"]
						i += 1
				# move dictionaries from temp to forks
				for f in temp : forks.append(f)
			else :
				# The array is empty and nothing to clone
				for wc in y :
					ndict = {}
					forks.append(ndict)
					ndict[op.attrib["id"]] = wc.attrib["ref"]
		return forks
	
	# Recursive supportive function routeProduct creates a branch according with dictionary
	# Only workcenters in dictionary includes in path
	def __routeProduct(self, routeroot, orderProot, pathdict):
		if orderProot.tag == "workcenter":
			# doesn't fill workcenter if worcenter attribute was filled from path dictionary. Fills workcenter if one is only
			if not "workcenter" in routeroot.attrib: routeroot.set("workcenter", orderProot.attrib["ref"]) 
			return
		subroute = ET.SubElement(routeroot, orderProot.tag, ref = orderProot.attrib["id"])
		if subroute.tag == "operation" and orderProot.attrib["id"] in pathdict.keys():
			# fills workcenter according with dictionary
			subroute.set("workcenter", pathdict[orderProot.attrib["id"]]) 
		for el in orderProot:
			self.__routeProduct(subroute, el, pathdict)
		
	# Function routeOrder creates all routes to order produce and shipping
	# It returns XML tree of all routes
	def routeOrder(self, orderXMLTree):
		logging.info("Starting routeOrder function: orderXMLTree = %s", orderXMLTree)
		orderNum = orderXMLTree.attrib["id"]
		routesroot = ET.Element("routes", orderref="%s" % orderNum)
		#searching tag <customer>
		for customer in orderXMLTree :
			if customer.tag <> "customer" : raise ORMException("Customer tag was expected as child of order tag" % (orderNum))
			#searching specific routes to customer
			r = self.__factoryroot.findall(".//road[@to='" + customer.attrib["ref"] + "']")
			if r :
				logging.debug("Specific road to the customer '%s' found", customer.attrib["ref"])
			else :
				logging.debug("Specific road to the customer '%s' not found", customer.attrib["ref"])
				# searching common routes
				r = self.__factoryroot.findall("road[@to='customer*']")
				logging.debug("%s roads found", len(r))
			for eroute in r :
#we think that customers ship themselves 
				logging.debug("%s products or materials in shipment found", len(customer))
				for prodmat in customer :
					if prodmat.tag == "product" :
						# searching all paths for product
						fs = self.__findForks(prodmat)
						logging.debug("There're paths for product found: %s" % fs)
						if not fs :
							logging.debug("Route has path from '%s' to '%s' route", eroute.attrib["from"], eroute.attrib["to"])
							route = ET.SubElement(routesroot, "route", id = "%s.%s" % (orderNum, 1 + len(routesroot)), workcenter = "%s" % eroute.attrib["from"])
							logging.debug("There's product '%s' in shipment found", prodmat.attrib["ref"])
							self.__routeProduct(route, prodmat, {})
						else :
							for path in fs :
								logging.debug("Route has path from '%s' to '%s' route", eroute.attrib["from"], eroute.attrib["to"])
								route = ET.SubElement(routesroot, "route", id = "%s.%s" % (orderNum, 1 + len(routesroot)), workcenter = "%s" % eroute.attrib["from"])
								logging.debug("There's product '%s' in shipment found", prodmat.attrib["ref"])
								self.__routeProduct(route, prodmat, path)
					if prodmat.tag == "material" :
						logging.debug("There's material '%s' in shipment found", prodmat.attrib["ref"])
						
		rtree = ET.ElementTree(routesroot)
		rtree.write(self._routesPath + "route-" + orderNum + ".xml")		
		logging.info("File " + self._ordersPath + "route-" + orderNum + ".xml saved")
		logging.debug("Finishing routeOrder function\n")
		#
		return routesroot