#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET

from classORMNavi import ORMNavi as ORM

logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
logging.info('\n=================Create Order Started====================')


try :
	orm = ORM()
	prs = []
	prs.append(orm.loadProductXMLTree("1"))
	order = orm.createOrder("1", "c2", prs)

	#easy add material with direct supply into order
	#ET.SubElement(order, "material", id="1.2", ref="box")
	
except :
	logging.critical(sys.exc_info())
	