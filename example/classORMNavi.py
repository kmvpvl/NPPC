#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET

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
	def __init__(self, mdmfilename = "mdm.xml", factoryfilename = "factory.xml", productsPath = "./", ordersPath = "./") :
		self._productsPath = productsPath
		self._ordersPath = ordersPath
		# mdm XML loading
		try:
			mdmDOM = ET.parse(mdmfilename)
			logging.info("File with DICTIONARY %s was parsed successfully", mdmfilename)
			self.__mdmroot = mdmDOM.getroot()
		except:
			raise ORMException("Wrong xml file %s. Error message is: %s", mdmfilename, sys.exc_info())
		assert(self.__mdmroot.tag == 'dictionary'), 'Wrong xml file %s. Root tag must be <dictionary>' % (mdmfilename)
			
		# factory XML loading
		try:
			fDOM = ET.parse(factoryfilename)
			logging.info("File %s was parsed successfully", factoryfilename)
			self.__factoryroot = fDOM.getroot()
		except:
			raise ORMException("Wrong xml file %s. Error message is: %s", factoryfilename, sys.exc_info())
		assert (self.__factoryroot.tag == 'factory'), 'Wrong xml file %s. Root tag must be <factory>' % (factoryfilename)
	
	# Function loadProducXMLTree loads product XML tree by product reference. 
	# It looks for file product-<prod_ref>.xml in productsPath directory
	# It returns XML tree object
	def loadProducXMLTree(self, productRef):
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
		for el in rep :
			out = ""
			if "id" in el.attrib : out = el.attrib["id"]
			else : out = "%s" % (i)
			# creating new subelement of order tree
			tmp = ET.SubElement(reo, el.tag, id = "" + outlinelabel + "." + out)
			if "ref" in el.attrib : 
				logging.debug("Order element| %s <%s>, ref = %s", "%s.%s" % (outlinelabel, out), el.tag, el.attrib["ref"])
				tmp.set("ref", el.attrib["ref"])
				#searching in mdm by ref
				r = self.__mdmroot.findall("*[@id='" + el.attrib["ref"] + "']")
				if ( not r) : raise ORMException("Element by ref '%s' isn't found in mdm.xml" % (el.attrib["ref"]))
				self.__goRoundProdLevel(r[0], "%s.%s" % (outlinelabel, out), tmp)
			else : 
				try:
					logging.debug("Order element| %s <%s>, id = %s", "%s.%s" % (outlinelabel, out), el.tag, el.attrib["id"])
					tmp.set("ref", el.attrib["id"])
				except:
					raise ORMException("Product element <%s> without ref, but id expected" % (el.tag))
			self.__goRoundProdLevel(el, "%s.%s" % (outlinelabel, out), tmp)
			i += 1
	
	# Function createOrder creates Order by Product and information from factory and MDM
	# It creates file order-<orderNum>.xml in orders directory
	# Be careful! Function uses recursion function goRoundProdLevel
	def createOrder(self, orderNum, customerRef, productXMLTree):
		logging.info("Starting CreateOrder function: orderNum = %s, customerRef = %s, productXMLTree = %s", orderNum, customerRef, productXMLTree)
		oroot = ET.Element("order", id=orderNum)
		if (not self.__mdmroot.findall("customer[@id='" + customerRef + "']")) : raise ORMException("Couldn't find customer id '%s' if MDM" % (customerRef))
		ET.SubElement(oroot, "customer", ref=customerRef)
		self.__goRoundProdLevel(productXMLTree, orderNum + "." + productXMLTree.attrib["id"], oroot)
		otree = ET.ElementTree(oroot)
		otree.write(self._ordersPath + "order-" + orderNum + ".xml")		
		logging.info("File " + self._ordersPath + "order-" + orderNum + ".xml saved")
		logging.debug("Finishing CreateOrder function\n")
		return oroot
