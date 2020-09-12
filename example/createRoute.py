#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET

from classORMNavi import ORMNavi as ORM

logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)
logging.info('\n=================Create route Started====================')


try :
	orm = ORM()
	order = orm.createOrder("1", "c2", orm.loadProducXMLTree("1"))

	#easy add material with direct supply into order
	#ET.SubElement(order, "material", id="1.2", ref="box")
	
except :
	logging.critical(sys.exc_info())
	