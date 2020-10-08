#!/usr/bin/python
import sys
import logging
import xml.etree.ElementTree as ET

from classORMNavi import ORMNavi as ORM
from classORMNavi import ORMException

logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)
logging.info('\n=================Create route Started====================')


try :
	orm = ORM("example2")
	prs = []
	prs.append(orm.loadProductXMLTree("1"))
	order = orm.createOrder("ord14", "c2", prs)
	routes = orm.routeOrder(order)
	
except ORMException :
	logging.critical(sys.exc_info())
	